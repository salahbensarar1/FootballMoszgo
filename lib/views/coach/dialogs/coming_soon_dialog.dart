import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ComingSoonDialog extends StatelessWidget {
  final String title;
  final String message;

  const ComingSoonDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF27121)),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.close,
            style: const TextStyle(color: Color(0xFFF27121)),
          ),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, String title, String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ComingSoonDialog(title: title, message: message);
      },
    );
  }
}
