import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  korean('ko-KR', '한국어', 'Korean'),
  english('en-US', 'English', 'English');

  const AppLanguage(this.localeId, this.displayName, this.englishName);

  final String localeId;
  final String displayName;
  final String englishName;
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.korean;
  static const String _languageKey = 'selected_language';

  LanguageProvider() {
    loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;

  /// 음성 인식에 사용할 localeId 반환
  String get speechLocaleId => _currentLanguage.localeId;

  /// 현재 언어 표시명 반환
  String get displayName => _currentLanguage.displayName;

  /// 언어 설정 초기화
  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        for (AppLanguage lang in AppLanguage.values) {
          if (lang.localeId == languageCode) {
            _currentLanguage = lang;
            break;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('언어 설정 로드 실패: $e');
    }
  }

  /// 언어 변경
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.localeId);
      _currentLanguage = language;
      notifyListeners();
    } catch (e) {
      debugPrint('언어 설정 저장 실패: $e');
    }
  }

  /// 언어 토글 (한국어 ↔ 영어)
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == AppLanguage.korean 
        ? AppLanguage.english 
        : AppLanguage.korean;
    await setLanguage(newLanguage);
  }
}