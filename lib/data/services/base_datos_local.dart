import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base SQLite local de la app (sqflite).
///
/// El esquema se versiona: [versionBaseDatos] sube cada vez que cambia y
/// [_actualizarEsquema] aplica los pasos que faltan desde la versión que
/// tenga el celular (nunca se borran datos del usuario).
const String nombreBaseDatos = 'streamtunes.db';
const int versionBaseDatos = 1;

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
