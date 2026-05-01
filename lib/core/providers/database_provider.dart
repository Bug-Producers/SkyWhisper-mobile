/// Riverpod providers for database access and initialization.
///
/// Exposes the [DatabaseHelper] singleton and [FakeDataSeeder] as
/// Riverpod providers, allowing dependent providers and widgets to
/// access the database layer through the standard `ref.watch` /
/// `ref.read` pattern.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';
import '../data/database/fake_data_seeder.dart';

/// Provides the [DatabaseHelper] singleton instance.
///
/// All database operations in the app should go through this provider
/// rather than accessing [DatabaseHelper.instance] directly. This
/// enables easier testing (override in [ProviderScope]) and ensures
/// a single point of access.
///
/// ```dart
/// final db = ref.read(databaseProvider);
/// final latest = await db.getLatestReading();
/// ```
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provides the [FakeDataSeeder] for one-time historical data injection.
///
/// Depends on [databaseProvider] to get the database helper. Call
/// `ref.read(fakeDataSeederProvider).seedIfNeeded()` during app
/// initialization to populate the database on first launch.
///
/// The seeder is idempotent — it checks a metadata flag before
/// inserting and will no-op on subsequent calls.
final fakeDataSeederProvider = Provider<FakeDataSeeder>((ref) {
  final dbHelper = ref.watch(databaseProvider);
  return FakeDataSeeder(dbHelper);
});

/// Provides the database initialization future.
///
/// Watch this provider in the app's root widget to ensure the
/// database is ready before any queries are executed. Also handles
/// fake data seeding on first launch.
///
/// Returns `true` if fake data was seeded (first launch), `false`
/// if the database was already populated.
final databaseInitProvider = FutureProvider<bool>((ref) async {
  /// Ensure the database tables exist by accessing the getter.
  final dbHelper = ref.read(databaseProvider);
  await dbHelper.database;

  /// Seed fake historical data if this is the first launch.
  final seeder = ref.read(fakeDataSeederProvider);
  final didSeed = await seeder.seedIfNeeded();

  return didSeed;
});
