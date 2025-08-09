import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/languages.dart';
import '../models/language_model.dart';
import '../constants/app_strings.dart';

class LanguageNotifier extends StateNotifier<LanguageModel> {
  static const String _languageKey = 'selected_language';

  LanguageNotifier()
    : super(LanguageModel.fromCode(Languages.defaultLanguage)) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null &&
          Languages.supportedLanguages.contains(savedLanguage)) {
        state = LanguageModel.fromCode(savedLanguage);
      }
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      if (!Languages.supportedLanguages.contains(languageCode)) {
        throw Exception('Unsupported language: $languageCode');
      }

      state = LanguageModel.fromCode(languageCode);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      print('Language changed to: ${state.name}');
    } catch (e) {
      print('Error changing language: $e');
      rethrow;
    }
  }

  String getString(String key) {
    return AppStrings.getString(key, state.code);
  }

  String getStringWithFallback(String key) {
    return AppStrings.getStringWithFallback(key, state.code);
  }

  // Convenience getters
  String get currentLanguageCode => state.code;
  bool get isEnglish => state.code == Languages.english;
  bool get isBangla => state.code == Languages.bangla;

  // Toggle between English and Bangla
  Future<void> toggleLanguage() async {
    final newLanguage = isEnglish ? Languages.bangla : Languages.english;
    await changeLanguage(newLanguage);
  }
}

// Provider instance
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageModel>(
  (ref) {
    return LanguageNotifier();
  },
);
