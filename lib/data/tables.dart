import 'package:drift/drift.dart';


@DataClassName('SpaceProgress')
class SpaceProgresses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get spaceName => text()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get userId => integer().references(Users, #id)();
}

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get type => text()();
  IntColumn get currentMissionIndex =>
      integer().withDefault(const Constant(0))();
}

@DataClassName('Section')
class Sections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get clutterLevel => text()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get missionOrder => integer().nullable()();
  IntColumn get userId => integer().references(Users, #id)();
}

@DataClassName('Mission')
class Missions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get difficulty => integer()();
  TextColumn get status => text()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get sectionId => integer().references(Sections, #id)();
}

@DataClassName('KeepBox')
class KeepBoxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get expirationAt => dateTime()();
}

@DataClassName('MissionLog')
class MissionLogs extends Table{
  IntColumn get id=>integer().autoIncrement()();
  IntColumn get userId=>integer().references(Users, #id)();
  DateTimeColumn get completedAt=>dateTime()();
}


