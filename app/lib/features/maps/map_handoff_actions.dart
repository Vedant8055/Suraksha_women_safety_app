import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

enum MapHandoffOption {
  surakshaMap,
  googleMaps,
}

Future<MapHandoffOption?> showMapHandoffDialog(
  BuildContext context, {
  required String placeName,
  String? placeAddress,
}) {
  final l10n = AppLocalizations.of(context);
  final trimmedName = placeName.trim();
  final trimmedAddress = placeAddress?.trim();
  final messageLines = <String>[
    l10n.t('mapOpenChoiceMessage'),
    if (trimmedName.isNotEmpty) trimmedName,
    if (trimmedAddress != null && trimmedAddress.isNotEmpty) trimmedAddress,
  ];

  return showPremiumDialog<MapHandoffOption>(
    context: context,
    title: l10n.t('mapOpenChoiceTitle'),
    message: messageLines.join('\n\n'),
    icon: Icons.map_rounded,
    accentColor: const Color(0xFF3B82F6),
    barrierDismissible: true,
    actions: [
      PremiumDialogAction(
        label: l10n.t('mapOpenChoiceSuraksha'),
        isPrimary: true,
        onPressed: () => Navigator.of(
          context,
          rootNavigator: true,
        ).pop(MapHandoffOption.surakshaMap),
      ),
      PremiumDialogAction(
        label: l10n.t('mapOpenChoiceGoogle'),
        onPressed: () => Navigator.of(
          context,
          rootNavigator: true,
        ).pop(MapHandoffOption.googleMaps),
      ),
    ],
  );
}

Future<bool> launchGoogleMapsDirections({
  required double latitude,
  required double longitude,
}) async {
  final queryParameters = <String, String>{
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  };

  final uri = Uri.https('www.google.com', '/maps/dir/', queryParameters);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
