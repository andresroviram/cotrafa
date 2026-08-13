import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance_settings_state.freezed.dart';
part 'performance_settings_state.g.dart';

@freezed
abstract class PerformanceSettingsState with _$PerformanceSettingsState {
  const factory PerformanceSettingsState({@Default(true) bool useIsolate}) =
      _PerformanceSettingsState;

  factory PerformanceSettingsState.fromJson(Map<String, dynamic> json) =>
      _$PerformanceSettingsStateFromJson(json);
}
