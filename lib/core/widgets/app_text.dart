import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../constants/app_strings.dart';

class AppText extends ConsumerWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final String? fallbackText;

  const AppText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    String displayText;
    if (fallbackText != null) {
      displayText = AppStrings.getStringWithFallback(
        textKey,
        currentLanguage.code,
      );
      if (displayText == textKey) displayText = fallbackText!;
    } else {
      displayText = AppStrings.getString(textKey, currentLanguage.code);
    }

    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: softWrap,
    );
  }
}

// Rich text version for complex text with multiple language keys
class AppRichText extends ConsumerWidget {
  final List<TextSpan> textSpans;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const AppRichText(
    this.textSpans, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    final translatedSpans = textSpans.map((span) {
      if (span.text != null) {
        final translatedText = AppStrings.getString(
          span.text!,
          currentLanguage.code,
        );
        return TextSpan(
          text: translatedText,
          style: span.style,
          recognizer: span.recognizer,
        );
      }
      return span;
    }).toList();

    return RichText(
      text: TextSpan(children: translatedSpans, style: style),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: softWrap,
    );
  }
}

// Helper class for creating text spans with language keys
class AppTextSpan extends TextSpan {
  const AppTextSpan({
    required String textKey,
    TextStyle? style,
    GestureRecognizer? recognizer,
  }) : super(text: textKey, style: style, recognizer: recognizer);
}
