import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

Future<void> showSaveSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showPremiumDialog<void>(
    context: context,
    title: title,
    message: message,
    icon: Icons.check_circle_rounded,
    accentColor: const Color(0xFF2ED6C5),
    barrierDismissible: true,
    actions: [
      PremiumDialogAction(
        label: 'OK',
        isPrimary: true,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    ],
  );
}
