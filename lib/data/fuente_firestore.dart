import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Un documento de una colección: su id de Firestore + sus datos.
class DocumentoFirestore {
  const DocumentoFirestore({required this.id, required this.datos});

  final String id;
  final Map<String, dynamic> datos;
}

/// Transacción mínima sobre documentos (la usa el Bloque B para el descuento
/// atómico de entradas; acá sólo se define el contrato).
abstract class TransaccionFirestore {
  /// Lee un documento dentro de la transacción (null si no existe).
  Future<DocumentoFirestore?> leer(String coleccion, String id);

  /// Crea o reemplaza un documento dentro de la transacción.
  void set(String coleccion, String id, Map<String, dynamic> datos);
}

/// Abstracción mínima de acceso a Firestore. Los repositorios dependen de
/// ESTA interfaz y no de [FirebaseFirestore] directamente, así en los tests
/// siembran un fake sin tocar la red ni Firebase.
///
/// No se sobredimensiona: sólo las operaciones que usan los repositorios y la
/// semilla.
abstract class FuenteFirestore {
  /// Snapshots en tiempo real de una colección. Emite el estado actual apenas
  /// alguien se suscribe y después cada cambio (igual que Firestore).
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion);

  /// Cantidad de documentos de una colección.
  Future<int> contar(String coleccion);

  /// ¿Existe el documento [id] en [coleccion]?
  Future<bool> existeDocumento(String coleccion, String id);

  /// Crea o reemplaza el documento [id] (id determinístico, para semilla).
  Future<void> setDocumento(
    String coleccion,
    String id,
    Map<String, dynamic> datos,
  );

  /// Agrega un documento con id autogenerado y devuelve ese id.
  Future<String> agregarDocumento(String coleccion, Map<String, dynamic> datos);

  /// Ejecuta [actualizar] dentro de una transacción atómica.
  Future<T> runTransaction<T>(
    Future<T> Function(TransaccionFirestore txn) actualizar,
  );
}

/// Capacidad OPCIONAL de generar ids de documento (fuera de la interfaz
/// `FuenteFirestore`, para no romper los fakes existentes que sólo hacen
/// `implements FuenteFirestore`). Las implementaciones que la declaran
/// (p. ej. `FuenteFirestoreFirebase`) usan su propio generador; las que no,
/// usan el respaldo de la extensión [FuenteFirestoreIds].
abstract class GeneradorIdsFirestore {
  /// Genera un id de documento NUEVO para [coleccion] SIN escribir nada.
  String generarId(String coleccion);
}

/// Generación de ids de documento SIN escribir nada (Bloque B: los ids de la
/// compra atómica se preparan ANTES de la transacción, así permanecen
/// estables ante los reintentos automáticos de Firestore).
///
/// Despacho dinámico: si la implementación declara [GeneradorIdsFirestore],
/// se delega en su método; si no, se usa el generador de respaldo (id
/// aleatorio de 20 caracteres, mismo formato que los auto-id de Firestore).
extension FuenteFirestoreIds on FuenteFirestore {
  String generarId(String coleccion) {
    final self = this;
    if (self is GeneradorIdsFirestore) {
      return _generarIdDe(self as GeneradorIdsFirestore, coleccion);
    }
    const caracteres =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => caracteres.codeUnitAt(random.nextInt(caracteres.length)),
      ),
    );
  }
}

/// Delega en el generador propio de la implementación. El parámetro es
/// `GeneradorIdsFirestore` (que NO es subtipo de `FuenteFirestore`) para que
/// la llamada resuelva al miembro de instancia y no a la extensión
/// [FuenteFirestoreIds] (que si no, se llamaría a sí misma recursivamente).
String _generarIdDe(GeneradorIdsFirestore generador, String coleccion) =>
    generador.generarId(coleccion);

/// Implementación real sobre [FirebaseFirestore]. Ojo: el constructor NO
/// toca `FirebaseFirestore.instance` (lanzaria si Firebase no está
/// inicializado; en tests este objeto existe pero nunca se usa porque
/// `firebaseInicializado` es false). Cada método recién accede al instance al
/// llamarse.
class FuenteFirestoreFirebase
    implements FuenteFirestore, GeneradorIdsFirestore {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) {
    return _db
        .collection(coleccion)
        .snapshots()
        .map(
          (qs) => [
            for (final d in qs.docs)
              DocumentoFirestore(id: d.id, datos: d.data()),
          ],
        );
  }

  @override
  Future<int> contar(String coleccion) async {
    // get() en vez de count(): mismo resultado y estable entre versiones del
    // SDK; la semilla lo llama una sola vez por colección al arrancar.
    return (await _db.collection(coleccion).get()).docs.length;
  }

  @override
  Future<bool> existeDocumento(String coleccion, String id) async {
    return (await _db.collection(coleccion).doc(id).get()).exists;
  }

  @override
  Future<void> setDocumento(
    String coleccion,
    String id,
    Map<String, dynamic> datos,
  ) {
    return _db.collection(coleccion).doc(id).set(datos);
  }

  @override
  Future<String> agregarDocumento(
    String coleccion,
    Map<String, dynamic> datos,
  ) async {
    return (await _db.collection(coleccion).add(datos)).id;
  }

  @override
  String generarId(String coleccion) {
    // doc() sin argumentos = referencia con id autogenerado, sin escribir.
    return _db.collection(coleccion).doc().id;
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(TransaccionFirestore txn) actualizar,
  ) {
    return _db.runTransaction(
      (txn) async => actualizar(_TransaccionFirebase(_db, txn)),
    );
  }
}

class _TransaccionFirebase implements TransaccionFirestore {
  _TransaccionFirebase(this._db, this._txn);

  final FirebaseFirestore _db;
  final Transaction _txn;

  @override
  Future<DocumentoFirestore?> leer(String coleccion, String id) async {
    final snap = await _txn.get(_db.collection(coleccion).doc(id));
    return snap.exists
        ? DocumentoFirestore(id: snap.id, datos: snap.data()!)
        : null;
  }

  @override
  void set(String coleccion, String id, Map<String, dynamic> datos) {
    _txn.set(_db.collection(coleccion).doc(id), datos);
  }
}

/// Instancia compartida (lazy; recién toca Firebase al usarse).
final FuenteFirestore fuenteFirestore = FuenteFirestoreFirebase();
