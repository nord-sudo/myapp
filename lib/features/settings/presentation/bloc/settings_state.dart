part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool isSecurityEnabled;
  final bool isDarkMode;

  const SettingsState({
    this.isSecurityEnabled = false,
    this.isDarkMode = false,
  });

  SettingsState copyWith({bool? isSecurityEnabled, bool? isDarkMode}) {
    return SettingsState(
      isSecurityEnabled: isSecurityEnabled ?? this.isSecurityEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  List<Object?> get props => [isSecurityEnabled, isDarkMode];
}
