import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }

enum AppThemeOption { ocean, forest, sunset, ruby, slate }

class AppSettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _unitKey = 'selected_unit';
  static const String _modeKey = 'selected_mode';

  AppThemeOption _selectedTheme = AppThemeOption.ocean;
  WeightUnit _selectedUnit = WeightUnit.kg;
  ThemeMode _themeMode = ThemeMode.dark;

  AppThemeOption get selectedTheme => _selectedTheme;
  WeightUnit get selectedUnit => _selectedUnit;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get selectedThemeIndex => _selectedTheme.index;
  String get selectedUnitApiValue => _selectedUnit.name;
  String get selectedModeApiValue => isDarkMode ? 'dark' : 'light';

  ThemeData get currentThemeData =>
      _buildTheme(themeOption: _selectedTheme, brightness: Brightness.light);

  ThemeData get currentDarkThemeData =>
      _buildTheme(themeOption: _selectedTheme, brightness: Brightness.dark);

  Future<void> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themeKey);
    final savedUnit = preferences.getString(_unitKey);
    final savedMode = preferences.getString(_modeKey);

    if (savedTheme != null) {
      _selectedTheme = AppThemeOption.values.firstWhere(
        (theme) => theme.name == savedTheme,
        orElse: () => AppThemeOption.ocean,
      );
    }

    if (savedUnit != null) {
      _selectedUnit = WeightUnit.values.firstWhere(
        (unit) => unit.name == savedUnit,
        orElse: () => WeightUnit.kg,
      );
    }

    if (savedMode != null) {
      _themeMode = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
  }

  Future<void> setTheme(AppThemeOption theme, {bool persist = true}) async {
    _selectedTheme = theme;
    notifyListeners();

    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeKey, theme.name);
    }
  }

  Future<void> setWeightUnit(WeightUnit unit, {bool persist = true}) async {
    _selectedUnit = unit;
    notifyListeners();

    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_unitKey, unit.name);
    }
  }

  Future<void> setThemeMode(ThemeMode mode, {bool persist = true}) async {
    _themeMode = mode;
    notifyListeners();

    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _modeKey,
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    }
  }

  Future<void> applyRemotePreferences({
    required String preferredUnit,
    required int preferredTheme,
    required String preferredMode,
    bool persist = true,
  }) async {
    _selectedUnit = preferredUnit == 'lbs' ? WeightUnit.lbs : WeightUnit.kg;
    _selectedTheme = AppThemeOption.values[preferredTheme.clamp(0, 4)];
    _themeMode = preferredMode == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_unitKey, _selectedUnit.name);
      await preferences.setString(_themeKey, _selectedTheme.name);
      await preferences.setString(_modeKey, selectedModeApiValue);
    }
  }

  ThemeData _buildTheme({
    required AppThemeOption themeOption,
    required Brightness brightness,
  }) {
    final seedColor = switch (themeOption) {
      AppThemeOption.ocean => const Color(0xFF24A0ED),
      AppThemeOption.forest => const Color(0xFF2ECC71),
      AppThemeOption.sunset => const Color(0xFFFF8A3D),
      AppThemeOption.ruby => const Color(0xFFFF4D6D),
      AppThemeOption.slate => const Color(0xFF7A8CA5),
    };

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );

    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF141A24) : Colors.white;
    final scaffoldColor = isDark
        ? const Color(0xFF0B1017)
        : const Color(0xFFF3F6FB);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldColor,
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: isDark ? 0 : 12,
        shadowColor: seedColor.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2331) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: seedColor.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
