import 'package:feature_user/domain/entities/delete_outcome.dart';

enum DeleteOutcomeModel { deleted, deactivated }

extension DeleteOutcomeModelMapper on DeleteOutcomeModel {
  DeleteOutcome toEntity() => switch (this) {
    DeleteOutcomeModel.deleted => DeleteOutcome.deleted,
    DeleteOutcomeModel.deactivated => DeleteOutcome.deactivated,
  };
}
