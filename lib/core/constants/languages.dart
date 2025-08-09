class Languages {
  static const String english = 'en';
  static const String bangla = 'bn';

  static const Map<String, String> languageNames = {
    english: 'English',
    bangla: 'বাংলা',
  };

  static const Map<String, String> languageFlags = {
    english: '🇺🇸',
    bangla: '🇧🇩',
  };

  static const List<String> supportedLanguages = [english, bangla];

  static const String defaultLanguage = english;
}
