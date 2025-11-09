import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Sections, Missions, KeepBoxes])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._internal();

  @override
  int get schemaVersion => 1;

  //단일 사용자이므로 ID는 1
  Future<User> getOrCreateUser(int userId) async {
    final user =
        await (select(users)
          ..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (user != null) {
      return user;
    } else {
      await into(users).insert(UsersCompanion.insert(id: userId, type: ''));

      return await (select(users)
        ..where((u) => u.id.equals(userId))).getSingle();
    }
  }

  Future<void> updateUserType(int userId, String userType) {
    return (update(users)..where(
      (u) => u.id.equals(userId),
    )).write(UsersCompanion(type: Value(userType)));
  }

  Future<String?> getUserType(int userId) async {
    final user =
        await (select(users)
          ..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (user != null && user.type.isNotEmpty) {
      return user.type;
    }
    return null;
  }

  Future<List<Section>> getSectionsForUser(int userId) {
    return (select(sections)..where((s) => s.userId.equals(userId))).get();
  }

  Future<void> batchInsertSections(int userId, List<String> names) async {
    await batch((batch) {
      for (final name in names) {
        batch.insert(
          sections,
          SectionsCompanion.insert(
            userId: userId,
            name: name,
            clutterLevel: "분석 전",
            progress: const Value(0),
          ),
        );
      }
    });
  }

  Future<void> addSection(int userId, String name) {
    return into(sections).insert(
      SectionsCompanion.insert(
        userId: userId,
        name: name,
        clutterLevel: "분석 전",
        progress: const Value(0),
      ),
    );
  }

  Future<void> updateSectionClutterByName(
    int userId,
    String name,
    String clutterLevel,
  ) {
    return (update(sections)..where(
      (s) => s.userId.equals(userId) & s.name.equals(name),
    )).write(SectionsCompanion(clutterLevel: Value(clutterLevel)));
  }

  Future<void> deleteSectionByName(int userId, String name) {
    return (delete(sections)
      ..where((s) => s.userId.equals(userId) & s.name.equals(name))).go();
  }

  Future<void> deleteAllSectionsForUser(int userId) {
    return (delete(sections)..where((s) => s.userId.equals(userId))).go();
  }

  Future<void> updateMissionOrder(
    int userId,
    List<String> orderedSectionNames,
  ) async {
    await transaction(() async {
      await (update(sections)..where(
        (s) => s.userId.equals(userId),
      )).write(const SectionsCompanion(missionOrder: Value(null)));

      for (int i = 0; i < orderedSectionNames.length; i++) {
        final sectionName = orderedSectionNames[i];
        await (update(sections)..where(
          (s) => s.userId.equals(userId) & s.name.equals(sectionName),
        )).write(SectionsCompanion(missionOrder: Value(i)));
      }
    });
  }

  Future<List<Section>> getOrderedMissions(int userId) {
    return (select(sections)
          ..where((s) => s.userId.equals(userId) & s.missionOrder.isNotNull())
          ..orderBy([
            (s) => OrderingTerm(
              expression: s.missionOrder,
              mode: OrderingMode.asc,
            ),
          ]))
        .get();
  }

  Future<int> getUserMissionIndex(int userId) async {
    final user =
        await (select(users)
          ..where((u) => u.id.equals(userId))).getSingleOrNull();
    return user?.currentMissionIndex ?? 0;
  }

  Future<void> updateUserMissionIndex(int userId, int index) {
    return (update(users)..where(
      (u) => u.id.equals(userId),
    )).write(UsersCompanion(currentMissionIndex: Value(index)));
  }

  Future<void> updateSectionProgress(int sectionId, int progress) {
    return (update(sections)..where(
      (s) => s.id.equals(sectionId),
    )).write(SectionsCompanion(progress: Value(progress)));
  }

  Future<List<KeepBox>> getAllKeepBoxes() {
    return (select(keepBoxes)..orderBy([
      (k) => OrderingTerm(expression: k.type, mode: OrderingMode.asc),
    ])).get();
  }

  Future<List<KeepBox>> getTopTowUrgentItems() {
    final now = DateTime.now();
    return (select(keepBoxes)
          ..where((k) => k.expirationAt.isBiggerThanValue(now))
          ..orderBy([
            (k) => OrderingTerm(
              expression: k.expirationAt,
              mode: OrderingMode.asc,
            ),
          ])
          ..limit(2))
        .get();
  }

  Future<void> replaceAllKeepBoxes(List<KeepBoxesCompanion> items) async {
    await transaction(() async {
      await delete(keepBoxes).go();
      await batch((batch) {
        batch.insertAll(keepBoxes, items);
      });
    });
  }

  Future<List<KeepBox>> getImpendingDDayItems() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final targetDateStart = today.add(const Duration(days: 1));

    final targetDateEnd_day = today.add(const Duration(days: 3));
    final targetDateEnd = DateTime(
      targetDateEnd_day.year,
      targetDateEnd_day.month,
      targetDateEnd_day.day,
      23,
      59,
      59,
    );

    return (select(keepBoxes)..where((tbl) {
      return tbl.expirationAt.isBetween(
        Constant(targetDateStart),
        Constant(targetDateEnd),
      );
    })).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
