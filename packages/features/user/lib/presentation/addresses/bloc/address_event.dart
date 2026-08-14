import 'package:feature_user/domain/entities/user_address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_event.freezed.dart';

@freezed
sealed class AddressEvent with _$AddressEvent {
  const factory AddressEvent.listRequested(int actorUserId, int userId) =
      AddressListRequested;
  const factory AddressEvent.formRequested(
    int actorUserId,
    int userId, {
    int? addressId,
  }) = AddressFormRequested;
  const factory AddressEvent.createRequested(
    int actorUserId,
    int userId,
    AddressDraft draft,
  ) = AddressCreateRequested;
  const factory AddressEvent.updateRequested(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  ) = AddressUpdateRequested;
  const factory AddressEvent.primaryRequested(
    int actorUserId,
    int userId,
    int addressId,
  ) = AddressPrimaryRequested;
  const factory AddressEvent.deleteRequested(
    int actorUserId,
    int userId,
    int addressId,
  ) = AddressDeleteRequested;
}
