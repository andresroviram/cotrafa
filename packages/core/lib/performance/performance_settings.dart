import 'package:core/performance/performance_settings_state.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PerformanceSettingsCubit extends HydratedCubit<PerformanceSettingsState> {
  PerformanceSettingsCubit() : super(const PerformanceSettingsState());

  void toggleIsolate() {
    emit(state.copyWith(useIsolate: !state.useIsolate));
  }

  @override
  PerformanceSettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return PerformanceSettingsState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PerformanceSettingsState state) {
    try {
      return state.toJson();
    } catch (_) {
      return null;
    }
  }
}
