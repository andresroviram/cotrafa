import 'package:core/errors/error.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:drift/native.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
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

  test('lists active parties for an authenticated actor', () async {
    final parties = await transfers.listParties(2);

    expect(parties.map((party) => party.id), containsAll([1, 2, 3, 4]));
    expect(parties.singleWhere((party) => party.id == 2).balanceCop, 100);
    await expectLater(
      transfers.listParties(99),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('lists only the transfer history visible to the actor', () async {
    await transfers.createTransfer(
      const TransferCommand(
        actorId: 2,
        originId: 2,
        destinationId: 3,
        amountCop: 10,
      ),
    );
    await TransferLocalDatasource.forTesting(
      db,
      idGenerator: () => 'transfer-2',
      clock: () => DateTime.fromMillisecondsSinceEpoch(2000),
    ).createTransfer(
      const TransferCommand(
        actorId: 1,
        originId: 4,
        destinationId: 3,
        amountCop: 10,
      ),
    );

    expect((await transfers.listTransfers(2)).map((transfer) => transfer.id), [
      'transfer-1',
    ]);
    expect((await transfers.listTransfers(3)).map((transfer) => transfer.id), [
      'transfer-2',
      'transfer-1',
    ]);
    expect((await transfers.listTransfers(1)).map((transfer) => transfer.id), [
      'transfer-2',
      'transfer-1',
    ]);
    await expectLater(
      transfers.listTransfers(99),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('client and admin create atomic address-free receipts', () async {
    final receipt = await transfers.createTransfer(
      const TransferCommand(
        actorId: 2,
        originId: 2,
        destinationId: 3,
        amountCop: 30,
        description: 'Rent',
      ),
    );
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
    expect(await transfers.getReceipt('transfer-1'), receipt);
    await expectLater(
      transfers.createTransfer(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 5,
        ),
      ),
      throwsA(anything),
    );
    expect(await _balance(db, 2), 70);
    expect(await _balance(db, 3), 40);
    expect(await _count(db, 'transfers'), 1);
    final adminReceipt =
        await TransferLocalDatasource.forTesting(
          db,
          idGenerator: () => 'transfer-2',
          clock: () => DateTime.fromMillisecondsSinceEpoch(2000),
        ).createTransfer(
          const TransferCommand(
            actorId: 1,
            originId: 4,
            destinationId: 3,
            amountCop: 10,
          ),
        );
    expect(adminReceipt.id, 'transfer-2');
    expect(await _balance(db, 4), 40);
  });

  test('invalid commands are typed no-ops', () async {
    for (final entry in <(TransferCommand, Matcher)>[
      (
        const TransferCommand(
          actorId: 2,
          originId: 4,
          destinationId: 3,
          amountCop: 10,
        ),
        isA<UnauthorizedException>(),
      ),
      (
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 101,
        ),
        isA<ValidationException>(),
      ),
      (
        const TransferCommand(
          actorId: 9,
          originId: 2,
          destinationId: 3,
          amountCop: 1,
        ),
        isA<UnauthorizedException>(),
      ),
      (
        const TransferCommand(
          actorId: 2,
          originId: 9,
          destinationId: 3,
          amountCop: 1,
        ),
        isA<NotFoundException>(),
      ),
      (
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 9,
          amountCop: 1,
        ),
        isA<NotFoundException>(),
      ),
    ]) {
      await expectLater(transfers.createTransfer(entry.$1), throwsA(entry.$2));
    }
    await db.customStatement("UPDATE users SET status='inactive' WHERE id=3");
    await expectLater(
      transfers.createTransfer(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 10,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    await db.customStatement("UPDATE users SET status='active' WHERE id=3");
    await db.customStatement("UPDATE users SET status='inactive' WHERE id=2");
    await expectLater(
      transfers.createTransfer(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 10,
        ),
      ),
      throwsA(isA<UnauthorizedException>()),
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
      final datasource = TransferLocalDatasource.forTesting(
        db,
        idGenerator: () => 'race-${mutation.hashCode}',
        clock: () => DateTime.fromMillisecondsSinceEpoch(1),
        afterRead: () async {
          called = true;
          await db.customStatement(mutation);
        },
      );
      await expectLater(
        datasource.createTransfer(
          const TransferCommand(
            actorId: 2,
            originId: 2,
            destinationId: 3,
            amountCop: 10,
          ),
        ),
        throwsA(isA<StorageException>()),
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
    await expectLater(
      transfers.createTransfer(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 10,
        ),
      ),
      throwsA(isA<StorageException>()),
    );
    expect(await _balance(db, 2), 100);
    expect(await _balance(db, 3), 10);
    expect(await _count(db, 'transfers'), 0);
  });

  test('persisted receipts remain readable', () async {
    await transfers.createTransfer(
      const TransferCommand(
        actorId: 2,
        originId: 2,
        destinationId: 3,
        amountCop: 10,
      ),
    );
    expect((await transfers.getReceipt('transfer-1')).amountCop, 10);
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
