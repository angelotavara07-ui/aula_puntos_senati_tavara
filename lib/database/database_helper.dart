import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('aula_puntos.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _crearTablas,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE grupos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        periodo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE estudiantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupo_id INTEGER NOT NULL,
        codigo TEXT NOT NULL,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Activo',
        FOREIGN KEY (grupo_id) REFERENCES grupos(id)
          ON DELETE CASCADE,
        UNIQUE (grupo_id, codigo)
      )
    ''');

    await db.execute('''
      CREATE TABLE sesiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupo_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        tema TEXT NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Programada',
        FOREIGN KEY (grupo_id) REFERENCES grupos(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_id INTEGER NOT NULL,
        estudiante_id INTEGER NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (sesion_id) REFERENCES sesiones(id)
          ON DELETE CASCADE,
        FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id)
          ON DELETE CASCADE,
        UNIQUE (sesion_id, estudiante_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE participaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_id INTEGER NOT NULL,
        estudiante_id INTEGER NOT NULL,
        actividad TEXT NOT NULL,
        puntos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (sesion_id) REFERENCES sesiones(id)
          ON DELETE CASCADE,
        FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id)
          ON DELETE CASCADE
      )
    ''');
  }

  // GRUPOS

  Future<int> insertarGrupo(Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert('grupos', datos);
  }

  Future<List<Map<String, dynamic>>> obtenerGrupos() async {
    final db = await database;
    return await db.query('grupos', orderBy: 'nombre ASC');
  }

  Future<int> actualizarGrupo(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;
    return await db.update(
      'grupos',
      datos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarGrupo(int id) async {
    final db = await database;
    return await db.delete(
      'grupos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ESTUDIANTES

  Future<int> insertarEstudiante(Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert('estudiantes', datos);
  }

  Future<List<Map<String, dynamic>>> obtenerEstudiantes(
    int grupoId,
  ) async {
    final db = await database;
    return await db.query(
      'estudiantes',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      orderBy: 'apellidos ASC',
    );
  }

  Future<int> actualizarEstudiante(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;
    return await db.update(
      'estudiantes',
      datos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarEstudiante(int id) async {
    final db = await database;
    return await db.delete(
      'estudiantes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SESIONES

  Future<int> insertarSesion(Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert('sesiones', datos);
  }

  Future<List<Map<String, dynamic>>> obtenerSesiones(
    int grupoId,
  ) async {
    final db = await database;
    return await db.query(
      'sesiones',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      orderBy: 'fecha DESC',
    );
  }

  Future<int> actualizarSesion(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;
    return await db.update(
      'sesiones',
      datos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarSesion(int id) async {
    final db = await database;
    return await db.delete(
      'sesiones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ASISTENCIAS

  Future<void> registrarAsistencia(
    int sesionId,
    int estudianteId,
    String estado,
  ) async {
    final db = await database;

    await db.insert(
      'asistencias',
      {
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'estado': estado,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerAsistencias(
    int sesionId,
  ) async {
    final db = await database;
    return await db.query(
      'asistencias',
      where: 'sesion_id = ?',
      whereArgs: [sesionId],
    );
  }

  // PARTICIPACIONES

  Future<int> insertarParticipacion(
    Map<String, dynamic> datos,
  ) async {
    final db = await database;
    return await db.insert('participaciones', datos);
  }

  Future<List<Map<String, dynamic>>> obtenerParticipaciones(
    int sesionId,
  ) async {
    final db = await database;
    return await db.query(
      'participaciones',
      where: 'sesion_id = ?',
      whereArgs: [sesionId],
      orderBy: 'fecha DESC',
    );
  }

  Future<int> eliminarParticipacion(int id) async {
    final db = await database;
    return await db.delete(
      'participaciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}