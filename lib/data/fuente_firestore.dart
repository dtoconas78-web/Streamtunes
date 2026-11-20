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

/// Implementación real sobre [FirebaseFirestore]. Ojo: el constructor NO
/// toca `FirebaseFirestore.instance` (lanzaria si Firebase no está
/// inicializado; en tests este objeto existe pero nunca se usa porque
/// `firebaseInicializado` es false). Cada método recién accede al instance al
/// llamarse.
class FuenteFirestoreFirebase implements FuenteFirestore {
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
