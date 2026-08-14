import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state_x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const party = TransferParty(
    id: 1,
    fullName: 'User',
    email: 'user@test.co',
    balanceCop: 100,
  );

  test('resolves initial loading and initial failure', () {
    expect(
      const TransferState().resolve(
        loading: () => 'loading',
        failure: (message) => message,
        data: (_) => 'data',
      ),
      'loading',
    );
    expect(
      const TransferState(
        status: TransferStatus.failure,
        message: 'failure',
      ).resolve(
        loading: () => 'loading',
        failure: (message) => message,
        data: (_) => 'data',
      ),
      'failure',
    );
  });

  test('keeps populated form data visible during submit and failure', () {
    for (final state in const [
      TransferState(status: TransferStatus.submitting, parties: [party]),
      TransferState(
        status: TransferStatus.failure,
        parties: [party],
        message: 'failure',
      ),
    ]) {
      expect(
        state.resolve(
          loading: () => 'loading',
          failure: (message) => message,
          data: (_) => 'data',
        ),
        'data',
      );
    }
  });
}
