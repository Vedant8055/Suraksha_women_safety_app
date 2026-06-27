import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/core/network/backend_url_resolver.dart';
import 'package:suraksha_women_safety_app/core/network/network_manager.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

Future<bool> ensureBackendReachable({bool force = false}) {
  return NetworkManager.instance.ensureReachable(force: force);
}

Future<void> showBackendConfigDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(
    text: NetworkManager.instance.currentBaseUrl,
  );

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.t('configureServer')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('configureServerHint')),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.t('serverUrlHint'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () async {
            await BackendUrlResolver.saveOverride(controller.text);
            await NetworkManager.instance.ensureReachable(force: true);
            if (context.mounted) Navigator.of(context).pop(true);
          },
          child: Text(l10n.t('save')),
        ),
      ],
    ),
  );

  controller.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('serverUrlSaved'))),
    );
  }
}
