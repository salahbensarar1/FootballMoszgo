import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/main.dart';

class LanguageSelectionDialog extends StatelessWidget {
  final Function(String) onLanguageChanged;

  const LanguageSelectionDialog({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectLanguage),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(context, 'en', 'English', '🇺🇸'),
          _buildLanguageOption(context, 'hu', 'Magyar', '🇭🇺'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF27121),
          ),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(BuildContext context, String languageCode,
      String languageName, String flag) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == languageCode;

    return Material(
      color: isSelected ? const Color(0xFFF27121).withOpacity(0.1) : null,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(languageName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFF27121))
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () {
          Navigator.of(context).pop();
          _changeLanguage(context, languageCode);
        },
      ),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    final newLocale = Locale(languageCode);
    MyApp.setLocale(context, newLocale);

    // Use a delay to allow the locale to update before accessing the new translations
    Future.delayed(const Duration(milliseconds: 100), () {
      final l10n = AppLocalizations.of(context)!;
      final languageName = _getLanguageName(languageCode);
      onLanguageChanged('${l10n.languageChanged} $languageName');
    });
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hu':
        return 'Magyar';
      default:
        return 'English';
    }
  }

  static Future<void> show(
      BuildContext context, Function(String) onLanguageChanged) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return LanguageSelectionDialog(onLanguageChanged: onLanguageChanged);
      },
    );
  }
}
