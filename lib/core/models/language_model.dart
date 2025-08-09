class LanguageModel {
  final String code;
  final String name;
  final String flag;
  final bool isRTL;
  
  const LanguageModel({
    required this.code,
    required this.name,
    required this.flag,
    this.isRTL = false,
  });
  
  factory LanguageModel.fromCode(String code) {
    switch (code) {
      case 'en':
        return const LanguageModel(
          code: 'en',
          name: 'English',
          flag: '🇺🇸',
          isRTL: false,
        );
      case 'bn':
        return const LanguageModel(
          code: 'bn',
          name: 'বাংলা',
          flag: '🇧🇩',
          isRTL: false,
        );
      default:
        return const LanguageModel(
          code: 'en',
          name: 'English',
          flag: '🇺🇸',
          isRTL: false,
        );
    }
  }
  
  static List<LanguageModel> get supportedLanguages => [
    const LanguageModel(code: 'en', name: 'English', flag: '🇺🇸'),
    const LanguageModel(code: 'bn', name: 'বাংলা', flag: '🇧🇩'),
  ];
}
