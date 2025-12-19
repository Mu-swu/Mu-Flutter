import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Users, Sections, Missions, KeepBoxes, SpaceProgresses, MissionLogs,Guestbooks],
)
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

  Future<int> insertGuestbook(GuestbooksCompanion entry) {
    return into(guestbooks).insert(entry);
  }

  // 3. 방명록 목록 불러오기 (최신순)
  Future<List<Guestbook>> getAllGuestbooks() {
    return (select(guestbooks)
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
        .get();
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

  Future<void> logMissionCompletion(int userId) async {
    await into(missionLogs).insert(
      MissionLogsCompanion.insert(userId: userId, completedAt: DateTime.now()),
    );
  }

  Future<List<Map<String, dynamic>>> getWeeklyMissionStats(int userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));

    final totalMissions = (await getSectionsForUser(userId)).length;
    final int maxMissions = totalMissions > 0 ? totalMissions : 1;

    List<Map<String, dynamic>> weeklyData = [];

    for (int i = 0; i < 7; i++) {
      final targetDate = startOfWeek.add(Duration(days: i));
      final nextDate = targetDate.add(const Duration(days: 1));

      final countResult =
          await (select(missionLogs)..where(
            (tbl) =>
                tbl.userId.equals(userId) &
                tbl.completedAt.isBetweenValues(targetDate, nextDate),
          )).get();
      int completedCount = countResult.length;

      double percentage = (completedCount / maxMissions) * 100;
      if (percentage > 100) percentage = 100;

      weeklyData.add({"x": i.toDouble(), "y": percentage, "date": targetDate});
    }
    return weeklyData;
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

  Future<Map<String, dynamic>> getMyPageStatistics(int userId) async {
    final allSections =
        await (select(sections)..where((s) => s.userId.equals(userId))).get();

    final completedCount = allSections.where((s) => s.progress == 100).length;
    final totalCount = allSections.length;

    int achievementRate = 0;
    if (totalCount > 0) {
      achievementRate = ((completedCount / totalCount * 100).toInt());
    }
    return {
      'total': totalCount,
      'completed': completedCount,
      'rate': achievementRate,
      'sections': allSections,
    };
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

  Future<void> initializeSpaceProgress(int userId, String userType) async {
    final existing =
        await (select(spaceProgresses)
          ..where((s) => s.userId.equals(userId))).get();

    if (existing.isNotEmpty) {
      return;
    }

    Map<String, bool> initialUnlockStatus = {
      '냉장고': false,
      '서랍장': false,
      '옷장': false,
    };

    switch (userType) {
      case '방치형':
        initialUnlockStatus['냉장고'] = true;
        break;
      case '감정형':
        initialUnlockStatus['옷장'] = true;
        break;
      case '몰라형':
      default:
        initialUnlockStatus['서랍장'] = true;
        break;
    }

    await batch((batch) {
      for (var entry in initialUnlockStatus.entries) {
        batch.insert(
          spaceProgresses,
          SpaceProgressesCompanion.insert(
            userId: userId,
            spaceName: entry.key,
            isUnlocked: Value(entry.value),
            isCompleted: const Value(false),
          ),
        );
      }
    });
  }

  Future<List<SpaceProgress>> getSpaceProgressForUser(int userId) {
    return (select(spaceProgresses)
      ..where((s) => s.userId.equals(userId))).get();
  }

  String getSpaceNameForSection(String sectionName) {
    final Set<String> fridgeSections = {"냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"};
    final Set<String> closetSections = {"선반", "행거 구역", "옷장 바닥 공간", "서랍"};
    final Set<String> drawerSections = {"1단", "2단", "3단"};

    if (fridgeSections.contains(sectionName)) return '냉장고';
    if (closetSections.contains(sectionName)) return '옷장';
    if (drawerSections.contains(sectionName)) return '서랍장';

    return 'Unknown';
  }

  Future<String?> inferCurrentSpaceName(int userId) async {
    final userSections = await getSectionsForUser(userId);
    if (userSections.isEmpty) return null;

    final Set<String> fridgeSections = {"냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"};
    final Set<String> closetSections = {"선반", "행거 구역", "옷장 바닥 공간", "서랍"};
    final Set<String> drawerSections = {"1단", "2단", "3단"};

    for (final section in userSections) {
      if (fridgeSections.contains(section.name)) return '냉장고';
      if (closetSections.contains(section.name)) return '옷장';
      if (drawerSections.contains(section.name)) return '서랍장';
    }

    print("경고: 현재 섹션들의 부모 가구(space)를 찾을 수 없습니다.");

    return null;
  }

  Future<void> completeSpaceAndUnlockAll(
    int userId,
    String completedSpaceName,
  ) async {
    await transaction(() async {
      await (update(spaceProgresses)..where(
        (s) => s.userId.equals(userId) & s.spaceName.equals(completedSpaceName),
      )).write(const SpaceProgressesCompanion(isCompleted: Value(true)));

      await (update(spaceProgresses)..where(
        (s) => s.userId.equals(userId),
      )).write(const SpaceProgressesCompanion(isUnlocked: Value(true)));
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
