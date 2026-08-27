import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:feature_user/data/models/user_address_model.dart';
import 'package:feature_user/data/repository/address_repository_impl.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/domain/repository/i_address_repository.dart';
import 'package:feature_user/domain/usecases/address_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Datasource extends Mock implements IAddressLocalDatasource {}

class _Repository extends Mock implements IAddressRepository {}

void main() {
  const addressModel = UserAddressModel(
    id: 1,
    userId: 2,
    line1: 'Calle 10 # 20-30',
    line2: 'El Poblado',
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: '050021',
    country: 'Colombia',
    label: 'Casa',
    isPrimary: true,
  );
  const address = UserAddress(
    id: 1,
    userId: 2,
    line1: 'Calle 10 # 20-30',
    line2: 'El Poblado',
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: '050021',
    country: 'Colombia',
    label: 'Casa',
    isPrimary: true,
  );

  late _Datasource datasource;

  setUp(() => datasource = _Datasource());

  test('repository exposes datasource values through Core Result', () async {
    when(
      () => datasource.list(1, 2),
    ).thenAnswer((_) async => const [addressModel]);
    final repository = AddressRepositoryImpl(datasource);

    final result = await repository.list(1, 2);
    expect(result.valueOrNull, const [address]);
    expect(addressModel.toEntity(), address);
  });

  test(
    'repository maps authorization exceptions without local wrappers',
    () async {
      when(
        () => datasource.list(2, 3),
      ).thenAnswer((_) async => throw const UnauthorizedException());
      final repository = AddressRepositoryImpl(datasource);

      expect(
        await repository.list(2, 3),
        const Error(UnauthorizedFailure(message: 'Unauthorized operation')),
      );
    },
  );

  test('use case forwards address creation to its repository', () async {
    const draft = AddressDraft(
      line1: 'Calle 10 # 20-30',
      line2: 'El Poblado',
      city: 'Medellín',
      state: 'Antioquia',
      postalCode: '050021',
      country: 'Colombia',
      label: 'Casa',
    );
    final repository = _Repository();
    when(
      () => repository.create(1, 2, draft),
    ).thenAnswer((_) async => const Success(address));

    expect(
      await CreateAddress(repository)(1, 2, draft),
      const Success(address),
    );
  });

  test('use case validates and normalizes address input', () async {
    final repository = _Repository();
    const normalized = AddressDraft(
      line1: 'Calle 10',
      line2: null,
      city: 'Medellín',
      state: null,
      postalCode: null,
      country: 'Colombia',
      label: 'Casa',
    );
    when(
      () => repository.create(1, 2, normalized),
    ).thenAnswer((_) async => const Success(address));

    expect(
      await CreateAddress(repository)(
        1,
        2,
        const AddressDraft(
          line1: ' Calle 10 ',
          line2: ' ',
          city: ' Medellín ',
          state: null,
          postalCode: null,
          country: ' Colombia ',
          label: ' Casa ',
        ),
      ),
      const Success(address),
    );
    expect(
      await CreateAddress(repository)(
        1,
        2,
        const AddressDraft(
          line1: ' ',
          line2: null,
          city: 'Medellín',
          state: null,
          postalCode: null,
          country: 'Colombia',
          label: 'Casa',
        ),
      ),
      const Error<UserAddress>(
        ValidationFailure(message: 'Address is required.'),
      ),
    );
    verify(() => repository.create(1, 2, normalized)).called(1);
  });
}
