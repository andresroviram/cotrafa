part of '../cootrafa_database.dart';

class LoginIdentifiers extends Table {
  TextColumn get normalized => text()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('email', 'username'))",
  )();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{normalized};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{userId, kind},
  ];
}
