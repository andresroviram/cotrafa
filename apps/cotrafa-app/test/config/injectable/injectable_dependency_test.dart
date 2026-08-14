import 'package:cotrafa_app/config/injectable/injectable_dependency.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/get_it.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_transfer/domain/repository/i_transfer_repository.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:feature_user/data/datasources/user_local_datasource.dart';
import 'package:feature_user/domain/repository/i_user_repository.dart';
import 'package:feature_user/domain/usecases/user_usecases.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App composes the database with feature datasource ports', () async {
    await getIt.reset();
    addTearDown(() async {
      if (getIt.isRegistered<CotrafaDatabase>()) {
        await getIt<CotrafaDatabase>().close();
      }
      await getIt.reset();
    });

    await configureDependencies();

    expect(getIt.isRegistered<CotrafaDatabase>(), isTrue);
    expect(getIt<IAuthLocalDatasource>(), isA<AuthLocalDatasource>());
    expect(getIt<IUserLocalDatasource>(), isA<UserLocalDatasource>());
    expect(getIt.isRegistered<IUserRepository>(), isTrue);
    expect(getIt.isRegistered<ListUsers>(), isTrue);
    expect(getIt.isRegistered<CreateClient>(), isTrue);
    expect(getIt.isRegistered<UserBloc>(), isTrue);
    expect(getIt<AddressLocalDatasource>(), isA<AddressLocalDatasource>());
    expect(getIt<ITransferLocalDatasource>(), isA<TransferLocalDatasource>());
    expect(getIt.isRegistered<ITransferRepository>(), isTrue);
    expect(getIt.isRegistered<ListTransferParties>(), isTrue);
    expect(getIt.isRegistered<ListTransfers>(), isTrue);
    expect(getIt.isRegistered<CreateTransfer>(), isTrue);
    expect(getIt.isRegistered<TransferBloc>(), isTrue);
    expect(getIt.isRegistered<TransferHistoryBloc>(), isTrue);
  });
}
