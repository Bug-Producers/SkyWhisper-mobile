/// SQLite database helper for the SkyWhisper application.
///
/// Manages the lifecycle of the local `sky_whisper.db` database,
/// including table creation, CRUD operations for sensor readings,
/// and aggregation queries for daily averages. Uses the singleton
/// pattern to ensure a single database connection across the app.
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/daily_average.dart';
import '../models/sensor_reading.dart';

/// Provides all SQLite operations for sensor reading persistence.
///
/// Call [initDatabase] once during app startup before performing
/// any reads or writes. The database contains two tables:
///
/// - `sensor_readings` — individual 4-hour interval measurements.
/// - `app_metadata` — key-value store for flags like `data_seeded`.
class DatabaseHelper {
  /// Private constructor — use the [instance] singleton.
  DatabaseHelper._();

  /// Singleton instance of [DatabaseHelper].
  static final DatabaseHelper instance = DatabaseHelper._();

  /// The underlying SQLite database connection.
  Database? _database;

  // ───────────────────── Initialization ─────────────────────

  /// Opens (or creates) the database and returns the active instance.
  ///
  /// The database file is stored at the default platform path
  /// under the name `sky_whisper.db`. Tables are created via
  /// [_onCreate] if this is the first launch.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// Internal initializer — builds the file path and opens the DB.
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sky_whisper.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Creates the initial database schema.
  ///
  /// Two tables are defined:
  /// 1. `sensor_readings` — stores each measurement with an
  ///    auto-incremented primary key and an ISO-8601 timestamp.
  /// 2. `app_metadata` — lightweight key-value store used to
  ///    track one-time operations like fake data seeding.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_readings (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        temperature REAL    NOT NULL,
        humidity    REAL    NOT NULL,
        pressure    REAL    NOT NULL,
        timestamp   TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_metadata (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    /// Index on timestamp for efficient date-range queries.
    await db.execute('''
      CREATE INDEX idx_readings_timestamp
      ON sensor_readings (timestamp)
    ''');
  }

  // ───────────────────── Insert Operations ─────────────────────

  /// Inserts a single [SensorReading] into the database.
  ///
  /// Returns the auto-generated row ID on success.
  Future<int> insertReading(SensorReading reading) async {
    final db = await database;
    return db.insert('sensor_readings', reading.toMap());
  }

  /// Inserts multiple readings in a single transaction (batch).
  ///
  /// Significantly faster than individual inserts when seeding
  /// historical data (e.g. 192 rows for the fake data set).
  Future<void> insertReadingsBatch(List<SensorReading> readings) async {
    final db = await database;
    final batch = db.batch();

    for (final reading in readings) {
      batch.insert('sensor_readings', reading.toMap());
    }

    await batch.commit(noResult: true);
  }

  // ───────────────────── Query Operations ─────────────────────

  /// Retrieves the most recent sensor reading from the database.
  ///
  /// Returns `null` if the table is empty. Useful as a fallback
  /// when the device is offline and no live data is available.
  Future<SensorReading?> getLatestReading() async {
    final db = await database;
    final rows = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return SensorReading.fromMap(rows.first);
  }

  /// Retrieves all raw readings within a specific date and time range.
  ///
  /// Useful for granular analysis of weather events like rapid
  /// pressure drops or temperature shifts.
  Future<List<SensorReading>> getReadingsInRange(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'sensor_readings',
      where: "timestamp >= ? AND timestamp <= ?",
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return rows.map(SensorReading.fromMap).toList();
  }

  /// Retrieves all readings for a specific calendar [date].

  /// Computes daily averages for all readings within a date range.
  ///
  /// If [from] or [to] are omitted, no lower/upper bound is applied.
  /// Returns a list of [DailyAverage] sorted by date ascending.
  ///
  /// The underlying SQL groups by `date(timestamp)` and computes
  /// `AVG()` for temperature, humidity, and pressure, along with
  /// a `COUNT(*)` for each day.
  Future<List<DailyAverage>> getDailyAverages({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;

    /// Build WHERE clause dynamically based on provided bounds.
    final conditions = <String>[];
    final args = <String>[];

    if (from != null) {
      conditions.add("date(timestamp) >= ?");
      args.add(
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}',
      );
    }
    if (to != null) {
      conditions.add("date(timestamp) <= ?");
      args.add(
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}',
      );
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT date(timestamp) AS day,
             AVG(temperature) AS avg_temp,
             AVG(humidity)    AS avg_hum,
             AVG(pressure)    AS avg_pres,
             COUNT(*)         AS count
      FROM sensor_readings
      $whereClause
      GROUP BY day
      ORDER BY day ASC
    ''', args);

    return rows.map(DailyAverage.fromMap).toList();
  }

  /// Returns today's running average (if any readings exist today).
  ///
  /// Useful for displaying a "today so far" summary on the dashboard.
  Future<DailyAverage?> getTodayAverage() async {
    final now = DateTime.now();
    final averages = await getDailyAverages(from: now, to: now);
    return averages.isEmpty ? null : averages.first;
  }

  // ───────────────────── Metadata Operations ─────────────────────

  /// Checks whether the fake historical data has already been seeded.
  ///
  /// Reads the `data_seeded` key from the `app_metadata` table.
  /// Returns `true` if the value is `"true"`, `false` otherwise.
  Future<bool> isDataSeeded() async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      where: "key = ?",
      whereArgs: ['data_seeded'],
    );

    if (rows.isEmpty) return false;
    return rows.first['value'] == 'true';
  }

  /// Marks the fake data seeding as complete.
  ///
  /// Sets the `data_seeded` metadata key to `"true"` so that
  /// [FakeDataSeeder] skips re-insertion on subsequent launches.
  Future<void> markDataSeeded() async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': 'data_seeded', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ───────────────────── Housekeeping ─────────────────────

  /// Deletes readings older than [maxAge] from the database.
  ///
  /// Call periodically to prevent unbounded storage growth.
  /// Returns the number of deleted rows.
  Future<int> deleteOldReadings(Duration maxAge) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(maxAge).toIso8601String();

    return db.delete(
      'sensor_readings',
      where: "timestamp < ?",
      whereArgs: [cutoff],
    );
  }

  /// Wipes all data from the database, including readings and metadata.
  ///
  /// Used for resetting the application state or clearing fake data
  /// to trigger a re-seed.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sensor_readings');
    await db.delete('app_metadata');
  }

  /// Returns the total number of sensor readings in the database.
  ///
  /// Useful for debugging and verifying fake data seeding.
  Future<int> getReadingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM sensor_readings');
    return (result.first['cnt'] as num).toInt();
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is disposed to release resources.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
