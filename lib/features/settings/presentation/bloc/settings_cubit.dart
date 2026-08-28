import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void toggleSecurity(bool enabled) {
    emit(state.copyWith(isSecurityEnabled: enabled));
  }

  void toggleDarkMode(bool enabled) {
    emit(state.copyWith(isDarkMode: enabled));
  }
}
