import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base SQLite local de la app (sqflite).
///
/// El esquema se versiona: [versionBaseDatos] sube cada vez que cambia y
/// [_actualizarEsquema] aplica los pasos que faltan desde la versión que
/// tenga el celular (nunca se borran datos del usuario).
const String nombreBaseDatos = 'streamtunes.db';
const int versionBaseDatos = 2;

/// Opciones de apertura compartidas por la app y los tests (que abren la
/// misma base en memoria con sqflite_common_ffi; ahí [unicaInstancia] va en
/// false para que cada test tenga su propia base vacía).
OpenDatabaseOptions opcionesBaseDatos({bool unicaInstancia = true}) =>
    OpenDatabaseOptions(
      version: versionBaseDatos,
      singleInstance: unicaInstancia,
      // Sin esto SQLite ignora las FOREIGN KEY (y el ON DELETE CASCADE).
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _actualizarEsquema(db, 0, version),
      onUpgrade: _actualizarEsquema,
    );

/// Abre (o crea) la base en la carpeta de bases de datos de la app.
Future<Database> abrirBaseDatosLocal() async {
  final ruta = join(await getDatabasesPath(), nombreBaseDatos);
  return databaseFactory.openDatabase(ruta, options: opcionesBaseDatos());
}

Future<void> _actualizarEsquema(Database db, int desde, int hasta) async {
  if (desde < 1) await _crearV1(db);
  if (desde < 2) await _crearV2(db);
}

// v1: playlists del oyente. Las canciones de cada playlist van en una tabla
// aparte (relación 1 a N) con su posición, en vez de una lista serializada.
Future<void> _crearV1(Database db) async {
  final batch = db.batch()
    ..execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        nombre TEXT NOT NULL,
        orden INTEGER NOT NULL
      )''')
    ..execute('CREATE INDEX idx_playlists_uid ON playlists(uid)')
    ..execute('''
      CREATE TABLE playlist_canciones (
        playlist_id TEXT NOT NULL
          REFERENCES playlists(id) ON DELETE CASCADE,
        cancion_id TEXT NOT NULL,
        posicion INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, cancion_id)
      )''');
  await batch.commit(noResult: true);
}

// v2: cola de reproducciones contadas, pendientes de sumar a las métricas
// de Firestore. Cada fila es UNA reproducción; al sincronizarse se borra.
// `lote` / `lote_fecha` marcan las filas que está subiendo alguien (la app o
// la tarea de workmanager, que corre en otro isolate) para no sumarlas dos
// veces.
Future<void> _crearV2(Database db) async {
  final batch = db.batch()
    ..execute('''
      CREATE TABLE reproducciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cancion_id TEXT NOT NULL,
        ciudad TEXT NOT NULL,
        franja TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        lote TEXT,
        lote_fecha INTEGER
      )''')
    ..execute('CREATE INDEX idx_reproducciones_lote ON reproducciones(lote)');
  await batch.commit(noResult: true);
}
