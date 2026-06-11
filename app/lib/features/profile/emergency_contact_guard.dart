import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_screen.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

const String kEmergencyContactsReminderTitle = 'Save emergency contact first';
const String kEmergencyContactsReminderMessage =
    'Please save the emergency contact first, so that in any emergency, your loved ones will get to know first.';

Future<bool> hasSavedEmergencyContacts(WidgetRef ref) {
  return ref.read(emergencyContactsProvider.notifier).hasSavedContacts();
}

Future<void> showMissingEmergencyContactsDialog(
  BuildContext context, {
  bool barrierDismissible = true,
}) async {
  if (!context.mounted) return;

  await showPremiumDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    title: kEmergencyContactsReminderTitle,
    message: kEmergencyContactsReminderMessage,
    icon: Icons.contact_emergency_rounded,
    accentColor: const Color(0xFFE53935),
    actions: [
      PremiumDialogAction(
        label: 'Later',
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
      PremiumDialogAction(
        label: 'Open contacts',
        isPrimary: true,
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (!context.mounted) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
      ),
    ],
  );
}

Future<bool> ensureEmergencyContactsSaved(
  BuildContext context,
  WidgetRef ref,
) async {
  final hasContacts = await hasSavedEmergencyContacts(ref);
  if (hasContacts) return true;

  if (context.mounted) {
    await showMissingEmergencyContactsDialog(context);
  }
  return false;
}
