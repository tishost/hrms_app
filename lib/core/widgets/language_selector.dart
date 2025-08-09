import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../constants/languages.dart';
import '../models/language_model.dart';

class LanguageSelector extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final double? width;
 
  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);
    
    return Container(
      width: width,
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              languageNotifier.getString('language'),
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: currentLanguage.code,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: LanguageModel.supportedLanguages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.code,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language.flag, style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(language.name, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageNotifier.changeLanguage(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Compact language toggle button
class LanguageToggleButton extends ConsumerWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
 
  const LanguageToggleButton({
    super.key,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);
    
    final nextLanguage = currentLanguage.code == Languages.english
        ? LanguageModel.fromCode(Languages.bangla)
        : LanguageModel.fromCode(Languages.english);
 
    return GestureDetector(
      onTap: () {
        languageNotifier.changeLanguage(nextLanguage.code);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.blue.shade50,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Center(
          child: Text(
            nextLanguage.flag,
            style: TextStyle(fontSize: size * 0.4),
          ),
        ),
      ),
    );
  }
}
