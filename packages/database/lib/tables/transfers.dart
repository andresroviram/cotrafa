part of '../cotrafa_database.dart';

@TableIndex(name: 'transfers_origin_idx', columns: <Symbol>{#originUserId})
@TableIndex(
  name: 'transfers_destination_idx',
  columns: <Symbol>{#destinationUserId},
)
class Transfers extends Table {
  TextColumn get id => text()();
  @ReferenceName('originTransfers')
  IntColumn get originUserId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destinationTransfers')
  IntColumn get destinationUserId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountCop =>
      integer().customConstraint('NOT NULL CHECK (amount_cop > 0)')();
  TextColumn get status =>
      text().customConstraint("NOT NULL CHECK (status = 'completed')")();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get originSnapshot => text()();
  TextColumn get destinationSnapshot => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (origin_user_id <> destination_user_id)',
  ];
}
