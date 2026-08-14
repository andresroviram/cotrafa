import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/domain/repository/i_address_repository.dart';
import 'package:feature_user/domain/usecases/address_usecases.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements IAddressRepository {}

void main() {
  const first = UserAddress(
    id: 10,
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
  const second = UserAddress(
    id: 11,
    userId: 2,
    line1: 'Carrera 40 # 10-15',
    line2: null,
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: null,
    country: 'Colombia',
    label: 'Trabajo',
    isPrimary: false,
  );
  const primarySecond = UserAddress(
    id: 11,
    userId: 2,
    line1: 'Carrera 40 # 10-15',
    line2: null,
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: null,
    country: 'Colombia',
    label: 'Trabajo',
    isPrimary: true,
  );
  const draft = AddressDraft(
    line1: 'Carrera 40 # 10-15',
    line2: null,
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: null,
    country: 'Colombia',
    label: 'Trabajo',
  );

  late _Repository repository;

  AddressBloc build() => AddressBloc(
    ListAddresses(repository),
    CreateAddress(repository),
    UpdateAddress(repository),
    SelectPrimaryAddress(repository),
    DeleteAddress(repository),
  );

  setUp(() {
    repository = _Repository();
    registerFallbackValue(draft);
  });

  blocTest<AddressBloc, AddressState>(
    'loads addresses for an authorized actor',
    setUp: () => when(
      () => repository.list(1, 2),
    ).thenAnswer((_) async => const Success([first, second])),
    build: build,
    act: (bloc) => bloc.add(const AddressEvent.listRequested(1, 2)),
    expect: () => const [
      AddressState(status: AddressStatus.loading),
      AddressState(status: AddressStatus.loaded, addresses: [first, second]),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'opens a create form without querying persistence',
    build: build,
    act: (bloc) => bloc.add(const AddressEvent.formRequested(1, 2)),
    expect: () => const [
      AddressState(status: AddressStatus.loading),
      AddressState(status: AddressStatus.ready),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'loads the selected address before editing',
    setUp: () => when(
      () => repository.list(1, 2),
    ).thenAnswer((_) async => const Success([first, second])),
    build: build,
    act: (bloc) =>
        bloc.add(const AddressEvent.formRequested(1, 2, addressId: 11)),
    expect: () => const [
      AddressState(status: AddressStatus.loading),
      AddressState(
        status: AddressStatus.ready,
        addresses: [first, second],
        selectedAddress: second,
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'creates an address and exposes it to the view listener',
    setUp: () => when(
      () => repository.create(1, 2, draft),
    ).thenAnswer((_) async => const Success(second)),
    build: build,
    seed: () => const AddressState(status: AddressStatus.ready),
    act: (bloc) => bloc.add(const AddressEvent.createRequested(1, 2, draft)),
    expect: () => const [
      AddressState(status: AddressStatus.saving),
      AddressState(
        status: AddressStatus.created,
        addresses: [second],
        selectedAddress: second,
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'replaces the primary address without reloading the screen',
    setUp: () => when(
      () => repository.selectPrimary(1, 2, 11),
    ).thenAnswer((_) async => const Success(primarySecond)),
    build: build,
    seed: () => const AddressState(
      status: AddressStatus.loaded,
      addresses: [first, second],
    ),
    act: (bloc) => bloc.add(const AddressEvent.primaryRequested(1, 2, 11)),
    expect: () => const [
      AddressState(status: AddressStatus.saving, addresses: [first, second]),
      AddressState(
        status: AddressStatus.primaryUpdated,
        addresses: [
          UserAddress(
            id: 10,
            userId: 2,
            line1: 'Calle 10 # 20-30',
            line2: 'El Poblado',
            city: 'Medellín',
            state: 'Antioquia',
            postalCode: '050021',
            country: 'Colombia',
            label: 'Casa',
            isPrimary: false,
          ),
          primarySecond,
        ],
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'deletes then reloads addresses to preserve primary promotion',
    setUp: () {
      when(
        () => repository.delete(1, 2, 10),
      ).thenAnswer((_) async => const Success(null));
      when(
        () => repository.list(1, 2),
      ).thenAnswer((_) async => const Success([primarySecond]));
    },
    build: build,
    seed: () => const AddressState(
      status: AddressStatus.loaded,
      addresses: [first, second],
    ),
    act: (bloc) => bloc.add(const AddressEvent.deleteRequested(1, 2, 10)),
    expect: () => const [
      AddressState(status: AddressStatus.saving, addresses: [first, second]),
      AddressState(status: AddressStatus.deleted, addresses: [primarySecond]),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'preserves loaded content when an address action fails',
    setUp: () => when(
      () => repository.delete(1, 2, 11),
    ).thenAnswer((_) async => const Error(StorageFailure())),
    build: build,
    seed: () => const AddressState(
      status: AddressStatus.loaded,
      addresses: [first, second],
    ),
    act: (bloc) => bloc.add(const AddressEvent.deleteRequested(1, 2, 11)),
    expect: () => const [
      AddressState(status: AddressStatus.saving, addresses: [first, second]),
      AddressState(
        status: AddressStatus.actionFailure,
        addresses: [first, second],
        message: 'address.errors.delete',
      ),
    ],
  );
}
