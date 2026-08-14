import 'package:core/security/credential_hasher.dart';
import 'package:drift/native.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CotrafaDatabase db;
  late TransferLocalDatasource transfers;
  setUp(() async {
    db = CotrafaDatabase.forTesting(
      NativeDatabase.memory(),
      CredentialHasher(
        memoryKiB: 64,
        iterations: 1,
        saltFactory: () => List<int>.filled(16, 7),
      ),
    );
    transfers = TransferLocalDatasource.forTesting(
      db,
      idGenerator: () => 'transfer-1',
      clock: () => DateTime.fromMillisecondsSinceEpoch(1234),
    );
    await db.customSelect('SELECT 1').getSingle();
    await _user(db, 2, 'Origin', 100);
    await _user(db, 3, 'Destination', 10);
    await _user(db, 4, 'Other', 50);
  });
  tearDown(() => db.close());

  test('client and admin create atomic address-free receipts', () async {
    final receipt = (await transfers.execute(
      const TransferCommand(2, 2, 3, 30, 'Rent'),
    )).value!;
    expect(await _balance(db, 2), 70);
    expect(await _balance(db, 3), 40);
    expect(receipt.id, 'transfer-1');
    expect(receipt.createdAt, 1234);
    expect(receipt.status, 'completed');
    expect(receipt.amountCop, 30);
    expect(receipt.description, 'Rent');
    expect(receipt.originSnapshot, 'Origin <user2@example.com>');
    expect(receipt.destinationSnapshot, 'Destination <user3@example.com>');
    expect(await _count(db, 'addresses'), 0);
    await db.customStatement("UPDATE users SET full_name='Changed' WHERE id=2");
    expect((await transfers.receipt('transfer-1')).value, receipt);
    expect(
      (await transfers.execute(const TransferCommand(2, 2, 3, 5, null))).error,
      TransferError.storageFailure,
    );
    expect(await _balance(db, 2), 70);
    expect(await _balance(db, 3), 40);
    expect(await _count(db, 'transfers'), 1);
    expect(
      (await TransferLocalDatasource.forTesting(
        db,
        idGenerator: () => 'transfer-2',
        clock: () => DateTime.fromMillisecondsSinceEpoch(2000),
      ).execute(const TransferCommand(1, 4, 3, 10, null))).value?.id,
      'transfer-2',
    );
    expect(await _balance(db, 4), 40);
  });

  test('invalid commands are typed no-ops', () async {
    for (final entry in <(TransferCommand, TransferError)>[
      (const TransferCommand(2, 4, 3, 10, null), TransferError.unauthorized),
      (const TransferCommand(2, 2, 2, 10, null), TransferError.selfTransfer),
      (const TransferCommand(2, 2, 3, 0, null), TransferError.invalidAmount),
      (
        const TransferCommand(2, 2, 3, 101, null),
        TransferError.insufficientFunds,
      ),
      (const TransferCommand(9, 2, 3, 1, null), TransferError.unauthorized),
      (const TransferCommand(2, 9, 3, 1, null), TransferError.notFound),
      (const TransferCommand(2, 2, 9, 1, null), TransferError.notFound),
    ]) {
      expect((await transfers.execute(entry.$1)).error, entry.$2);
    }
    await db.customStatement("UPDATE users SET status='inactive' WHERE id=3");
    expect(
      (await transfers.execute(const TransferCommand(2, 2, 3, 10, null))).error,
      TransferError.inactiveParty,
    );
    await db.customStatement("UPDATE users SET status='active' WHERE id=3");
    await db.customStatement("UPDATE users SET status='inactive' WHERE id=2");
    expect(
      (await transfers.execute(const TransferCommand(2, 2, 3, 10, null))).error,
      TransferError.unauthorized,
    );
    expect(await _balance(db, 2), 100);
    expect(await _balance(db, 3), 10);
    expect(await _count(db, 'transfers'), 0);
  });

  test('predicate mismatches roll back balances and operation', () async {
    for (final mutation in <String>[
      'UPDATE users SET balance_cop=5 WHERE id=2',
      "UPDATE users SET status='inactive' WHERE id=2",
      "UPDATE users SET status='inactive' WHERE id=3",
    ]) {
      var called = false;
      final service = TransferLocalDatasource.forTesting(
        db,
        idGenerator: () => 'race-${mutation.hashCode}',
        clock: () => DateTime.fromMillisecondsSinceEpoch(1),
        afterRead: () async {
          called = true;
          await db.customStatement(mutation);
        },
      );
      expect(
        (await service.execute(const TransferCommand(2, 2, 3, 10, null))).error,
        TransferError.concurrentChange,
      );
      expect(called, isTrue);
      expect(await _balance(db, 2), 100);
      expect(await _balance(db, 3), 10);
      expect(await _status(db, 2), 'active');
      expect(await _status(db, 3), 'active');
      expect(await _count(db, 'transfers'), 0);
    }
  });

  test('post-insert receipt read failure rolls back everything', () async {
    await db.customStatement(
      'CREATE TRIGGER erase_receipt AFTER INSERT ON transfers '
      'BEGIN DELETE FROM transfers WHERE id=NEW.id; END',
    );
    final result = await transfers.execute(
      const TransferCommand(2, 2, 3, 10, null),
    );
    expect(result.error, TransferError.storageFailure);
    expect(await _balance(db, 2), 100);
    expect(await _balance(db, 3), 10);
    expect(await _count(db, 'transfers'), 0);
  });

  test('receipt is read-only and mutation/export/sharing are denied', () async {
    await transfers.execute(const TransferCommand(2, 2, 3, 10, null));
    for (final action in ReceiptAction.values) {
      expect(
        (await transfers.requestReceiptAction('transfer-1', action)).error,
        TransferError.unsupportedAction,
      );
    }
    expect((await transfers.receipt('transfer-1')).value?.amountCop, 10);
  });
}

Future<void> _user(CotrafaDatabase db, int id, String name, int balance) =>
    db.customStatement(
      "INSERT INTO users (id,email,full_name,role,status,password_hash,"
      "activation_code_hash,balance_cop,created_at,updated_at) VALUES "
      "($id,'user$id@example.com','$name','client','active',NULL,NULL,"
      "$balance,1,1)",
    );
Future<int> _balance(CotrafaDatabase db, int id) => db
    .customSelect('SELECT balance_cop FROM users WHERE id=$id')
    .map((row) => row.read<int>('balance_cop'))
    .getSingle();
Future<String> _status(CotrafaDatabase db, int id) => db
    .customSelect('SELECT status FROM users WHERE id=$id')
    .map((row) => row.read<String>('status'))
    .getSingle();
Future<int> _count(CotrafaDatabase db, String table) => db
    .customSelect('SELECT COUNT(*) AS count FROM $table')
    .map((row) => row.read<int>('count'))
    .getSingle();
