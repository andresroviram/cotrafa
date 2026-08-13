part of '../cootrafa_database.dart';

class LocalSession extends Table {
  IntColumn get slot =>
      integer().customConstraint('NOT NULL CHECK (slot = 1)')();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{slot};
}
