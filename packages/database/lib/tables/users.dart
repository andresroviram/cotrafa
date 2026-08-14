part of '../cotrafa_database.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get role =>
      text().customConstraint("NOT NULL CHECK (role IN ('admin', 'client'))")();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('pendingActivation', 'active', 'inactive'))",
  )();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get activationCodeHash => text().nullable()();
  IntColumn get balanceCop => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (balance_cop >= 0)',
  )();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  IntColumn get birthDate => integer().nullable()();
  TextColumn get phone => text().nullable()();
}
