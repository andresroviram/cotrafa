import 'package:cootrafa_app/config/injectable/injectable_dependency.dart';
import 'package:cootrafa_database/cootrafa_database.dart';
import 'package:core/get_it.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:feature_user/data/datasources/user_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App composes the database with feature datasource ports', () async {
    await getIt.reset();
    addTearDown(() async {
      if (getIt.isRegistered<CootrafaDatabase>()) {
        await getIt<CootrafaDatabase>().close();
      }
      await getIt.reset();
    });

    await configureDependencies();

    expect(getIt.isRegistered<CootrafaDatabase>(), isTrue);
    expect(getIt<IAuthLocalDatasource>(), isA<AuthLocalDatasource>());
    expect(getIt<IUserLocalDatasource>(), isA<UserLocalDatasource>());
    expect(getIt<AddressLocalDatasource>(), isA<AddressLocalDatasource>());
    expect(getIt<TransferLocalDatasource>(), isA<TransferLocalDatasource>());
  });
}
