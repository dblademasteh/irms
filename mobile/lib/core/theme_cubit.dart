import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _prefKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModeStr = prefs.getString(_prefKey);
    if (savedModeStr != null) {
      if (savedModeStr == 'light') emit(ThemeMode.light);
      if (savedModeStr == 'dark') emit(ThemeMode.dark);
      if (savedModeStr == 'system') emit(ThemeMode.system);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
