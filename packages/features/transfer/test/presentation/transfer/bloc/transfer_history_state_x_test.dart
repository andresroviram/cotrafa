import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state_x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transfer = TransferReceipt(
    id: 'transfer-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 100,
    status: 'completed',
    description: null,
    createdAt: 1,
    originSnapshot: 'Origin',
    destinationSnapshot: 'Destination',
  );

  test('resolves loading, failure, empty and populated history', () {
    String resolve(TransferHistoryState state) => state.resolve(
      loading: () => 'loading',
      failure: (message) => message,
      empty: () => 'empty',
      data: (_) => 'data',
    );

    expect(resolve(const TransferHistoryState()), 'loading');
    expect(
      resolve(
        const TransferHistoryState(
          status: TransferHistoryStatus.failure,
          message: 'failure',
        ),
      ),
      'failure',
    );
    expect(
      resolve(const TransferHistoryState(status: TransferHistoryStatus.loaded)),
      'empty',
    );
    expect(
      resolve(
        const TransferHistoryState(
          status: TransferHistoryStatus.loaded,
          transfers: [transfer],
        ),
      ),
      'data',
    );
  });
}
