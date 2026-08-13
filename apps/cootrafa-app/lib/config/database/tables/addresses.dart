part of '../cootrafa_database.dart';

class Addresses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get line1 => text()();
  TextColumn get line2 => text().nullable()();
  TextColumn get city => text()();
  TextColumn get state => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get label => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
}
