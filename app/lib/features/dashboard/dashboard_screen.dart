import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:suraksha_women_safety_app/features/auth/auth_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contact_guard.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/emergency_mode_screen.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_screen.dart';
import 'package:suraksha_women_safety_app/features/maps/safety_map_screen.dart';
import 'package:suraksha_women_safety_app/features/medical/medical_vault_screen.dart';
import 'package:suraksha_women_safety_app/features/posh/posh_chat_screen.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/nearby_places_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/community_alerts_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_display_provider.dart';
import 'package:suraksha_women_safety_app/features/routes/route_safety_provider.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

final _manualSosLaunchingProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showProfilePhotoPreview(
    BuildContext context,
    ImageProvider<Object> profileImage,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image(image: profileImage, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _pushPremium(BuildContext context, Widget screen) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 480),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndOpenOnMap(
    BuildContext context,
    NearbyPlaceItem place,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldOpen = await showPremiumDialog<bool>(
      context: context,
      title: l10n.t('openSafetyMap'),
      message: l10n.t('openSafetyMapConfirm'),
      icon: Icons.map_rounded,
      accentColor: const Color(0xFF3B82F6), // A more appropriate map color
      actions: [
        PremiumDialogAction(
          label: l10n.t('no'),
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        PremiumDialogAction(
          label: l10n.t('yes'),
          isPrimary: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );

    if (shouldOpen != true || !context.mounted) return;

    _pushPremium(
      context,
      SafetyMapScreen(
        initialTargetLatitude: place.latitude,
        initialTargetLongitude: place.longitude,
        initialTargetName: place.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 68) / 2;
    final safetyState = ref.watch(safetyMonitorProvider);
    ref.watch(appLocaleProvider);
    ref.listen(appLocaleProvider, (previous, next) {
      if (previous?.languageCode == next.languageCode) return;
      final nearbyState = ref.read(nearbyPlacesProvider);
      final activeType = nearbyState.activeType;
      if (activeType != null && nearbyState.places.isNotEmpty) {
        unawaited(
          ref.read(nearbyPlacesProvider.notifier).fetchNearby(activeType),
        );
      }
    });

    if (!safetyState.gpsEnabled || !safetyState.permissionGranted) {
      return _buildLocationRequiredScreen(context, ref, safetyState);
    }

    return Scaffold(
      body: Stack(
        children: [
          const _DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 40),
                    duration: const Duration(milliseconds: 420),
                    from: 10,
                    child: _buildHeader(context, ref),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 120),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildQuickActions(context, cardWidth),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildSOSButton(context, ref),
                  ),
                  const SizedBox(height: 14),
                  FadeInUp(
                    delay: const Duration(milliseconds: 240),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildPoliceNumberCard(context),
                  ),
                  const SizedBox(height: 14),
                  FadeInUp(
                    delay: const Duration(milliseconds: 260),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildSafetyIntelligenceCard(context, ref),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 280),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildWomenHelplineCard(context),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 290),
                    duration: const Duration(milliseconds: 430),
                    from: 10,
                    child: _buildRouteSafetyCard(context, ref),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 440),
                    from: 10,
                    child: _buildRecentAlerts(context, ref),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 380),
                    duration: const Duration(milliseconds: 440),
                    from: 10,
                    child: _buildNearbyServicesBlock(context, ref),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final user = ref.watch(authProvider).user;
    final profileDisplay = ref.watch(profileDisplayProvider);
    final greetingPrefix = AppLocalizations.of(context).t('greetingHello');
    final displayName = profileDisplay.name.trim().isNotEmpty
        ? profileDisplay.name.trim()
        : (user?.name ?? '').trim().isNotEmpty
        ? (user?.name ?? '').trim()
        : l10n.t('userFallback');
    final localPhotoPath = profileDisplay.photoPath;
    final hasLocalPhoto =
        localPhotoPath.isNotEmpty && File(localPhotoPath).existsSync();
    final remotePhotoUrl = user?.profilePhoto;
    final hasRemotePhoto = remotePhotoUrl != null && remotePhotoUrl.isNotEmpty;
    final ImageProvider<Object>? profileImage = hasLocalPhoto
        ? FileImage(File(localPhotoPath))
        : (hasRemotePhoto ? NetworkImage(remotePhotoUrl) : null);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFFFF), Color(0xFFF3F7FF), Color(0xFFEAF1FF)]
              : const [Color(0xFF1A1A1A), Color(0xFF000000), Color(0xFF2A2A2A)],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight
              ? const Color(0xFFD7E3F5)
              : Colors.white.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF7E8FB0).withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: 0.55),
            blurRadius: isLight ? 16 : 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isLight
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.65)
                : const Color(0xFF8FA2BE).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('appTitle'),
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greetingPrefix, $displayName',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isLight ? const Color(0xFF172235) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFE6FAF2)
                      : const Color(0xFF194E43),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 14,
                      color: Color(0xFF69E5C8),
                    ),
                    SizedBox(width: 6),
                    Text(
                      l10n.t('safeZoneActive'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A8E7C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _pushPremium(context, const ProfileScreen()),
            onLongPress: profileImage == null
                ? null
                : () => _showProfilePhotoPreview(context, profileImage),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A436B), Color(0xFF1A2B48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFD9E5F8)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: ClipOval(
                child: profileImage != null
                    ? Image(
                        image: profileImage,
                        fit: BoxFit.cover,
                        width: 58,
                        height: 58,
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosProvider);
    final isLaunching = ref.watch(_manualSosLaunchingProvider);

    final button = Container(
      width: 172,
      height: 172,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFF5A4A),
            const Color(0xFFE53935),
            const Color(0xFFB71C1C),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(
              alpha: sosState.isActive || isLaunching ? 0.48 : 0.24,
            ),
            blurRadius: sosState.isActive || isLaunching ? 36 : 16,
            spreadRadius: sosState.isActive || isLaunching ? 10 : 3,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new, size: 58, color: Colors.white),
            const SizedBox(height: 4),
            const Text(
              'SOS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );

    return Center(
      child: GestureDetector(
        onTap: () async {
          if (isLaunching) return;
          if (sosState.isActive) {
            _pushPremium(context, const EmergencyModeScreen());
            return;
          }
          final canTriggerSos = await ensureEmergencyContactsSaved(
            context,
            ref,
          );
          if (!canTriggerSos) return;
          ref.read(_manualSosLaunchingProvider.notifier).state = true;
          unawaited(ref.read(sosProvider.notifier).triggerSOS());
          // Keep the launch animation to exactly 3 pulse cycles before opening SOS mode.
          await Future<void>.delayed(const Duration(milliseconds: 2400));
          ref.read(_manualSosLaunchingProvider.notifier).state = false;
          if (!context.mounted) {
            return;
          }
          _pushPremium(context, const EmergencyModeScreen());
        },
        child: sosState.isActive || isLaunching
            ? Pulse(
                infinite: true,
                duration: const Duration(milliseconds: 800),
                child: button,
              )
            : button,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, double cardWidth) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('emergencyServices'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isLight ? const Color(0xFF172235) : Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              context,
              Icons.map_rounded,
              l10n.t('map'),
              const Color(0xFF3B82F6),
              const SafetyMapScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.medical_services_rounded,
              l10n.t('medical'),
              const Color(0xFFE66E41),
              const MedicalVaultScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.security_rounded,
              l10n.t('cyber'),
              const Color(0xFFEC9F2A),
              const CyberCrimeScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.gavel_rounded,
              'POSH',
              const Color(0xFF2FB79E),
              const POSHLegalPortalScreen(),
              cardWidth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyIntelligenceCard(BuildContext context, WidgetRef ref) {
    final safetyState = ref.watch(safetyMonitorProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tone = safetyState.safetyScore >= 81
        ? const Color(0xFF15803D)
        : safetyState.safetyScore >= 61
        ? const Color(0xFF16A34A)
        : safetyState.safetyScore >= 41
        ? const Color(0xFFEAB308)
        : safetyState.safetyScore >= 21
        ? const Color(0xFFF97316)
        : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  const Color(0xFFFFFFFF),
                  Color.lerp(const Color(0xFFF5FAFF), tone, 0.12)!,
                ]
              : [
                  Color.lerp(AppTheme.cardColor, tone, 0.18)!,
                  const Color(0xFF101827),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tone.withValues(alpha: isLight ? 0.24 : 0.36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: isLight ? 0.12 : 0.20),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.shield_rounded, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Safety Intelligence',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF172235) : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      safetyState.summary ?? safetyState.statusMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF627491)
                            : Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${safetyState.safetyScore}',
                    style: TextStyle(
                      color: tone,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF627491)
                          : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _routeChip(
                context,
                icon: Icons.flag_rounded,
                label: safetyState.riskLabel,
                color: tone,
              ),
              _routeChip(
                context,
                icon: Icons.verified_rounded,
                label: safetyState.aiConfidenceVisible
                    ? 'AI Confidence ${safetyState.aiConfidence}%'
                    : 'Safety Assessment Limited',
                color: const Color(0xFF3B82F6),
              ),
              if (safetyState.nearbyPoliceCount > 0)
                _routeChip(
                  context,
                  icon: Icons.local_police_rounded,
                  label: '${safetyState.nearbyPoliceCount} police nearby',
                  color: const Color(0xFF2563EB),
                ),
              if (safetyState.nearbyHospitalCount > 0)
                _routeChip(
                  context,
                  icon: Icons.local_hospital_rounded,
                  label:
                      '${safetyState.nearbyHospitalCount} hospitals nearby',
                  color: const Color(0xFFE11D48),
                ),
            ],
          ),
          if (safetyState.upcomingRisk != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(
                  alpha: isLight ? 0.08 : 0.20,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${safetyState.upcomingRisk!.summary} ${safetyState.upcomingRisk!.recommendedAction}',
                style: TextStyle(
                  color: isLight ? const Color(0xFF6B1D1D) : Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (safetyState.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              safetyState.contributingFactors.take(4).join(' | '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF546784)
                    : Colors.white.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (safetyState.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...safetyState.recommendations.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $item',
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF334158)
                        : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ref.read(safetyMonitorProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh intelligence'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Widget? screen,
    double width,
  ) {
    return _PoppingActionCard(
      icon: icon,
      label: label,
      color: color,
      width: width,
      onTap: screen == null ? null : () => _pushPremium(context, screen),
    );
  }

  Widget _buildRouteSafetyCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routeState = ref.watch(routeSafetyProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final danger = routeState.pendingSafetyCheck || routeState.safetyScore < 60;
    final tone = routeState.pendingSafetyCheck
        ? const Color(0xFFE53935)
        : routeState.safetyScore >= 80
        ? const Color(0xFF2FB79E)
        : routeState.safetyScore >= 60
        ? const Color(0xFFF3B13E)
        : const Color(0xFFE66E41);
    final countdownText = _formatRouteCountdown(routeState.countdownSeconds);
    final deviation = routeState.deviationMeters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  const Color(0xFFFFFFFF),
                  Color.lerp(const Color(0xFFF5FAFF), tone, 0.08)!,
                ]
              : [
                  Color.lerp(AppTheme.cardColor, tone, danger ? 0.2 : 0.08)!,
                  const Color(0xFF101827),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger
              ? tone.withValues(alpha: 0.54)
              : isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: isLight ? 0.15 : 0.24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.route_rounded, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeState.pendingSafetyCheck
                          ? l10n.t('safeRouteChanged')
                          : l10n.t('dailyRouteGuard'),
                      style: TextStyle(
                        color: isLight ? const Color(0xFF172235) : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      routeState.statusMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF627491)
                            : Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${routeState.safetyScore}',
                style: TextStyle(
                  color: tone,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _routeChip(
                context,
                icon: Icons.shield_rounded,
                label: routeState.riskLabel,
                color: tone,
              ),
              _routeChip(
                context,
                icon: routeState.hasLearnedRoute
                    ? Icons.task_alt_rounded
                    : Icons.sync_rounded,
                label: routeState.monitoringMapRoute
                    ? '${routeState.activeMapRoutePointCount} map points'
                    : routeState.hasLearnedRoute
                    ? '${routeState.routeLogCount} route logs'
                    : 'Learning route',
                color: const Color(0xFF3B82F6),
              ),
              if (routeState.activeMapRouteScore != null)
                _routeChip(
                  context,
                  icon: Icons.map_rounded,
                  label: 'Map score ${routeState.activeMapRouteScore}',
                  color: const Color(0xFF2FB79E),
                ),
              if (deviation != null)
                _routeChip(
                  context,
                  icon: Icons.social_distance_rounded,
                  label: '${deviation.round()} m from pattern',
                  color: routeState.pendingSafetyCheck
                      ? const Color(0xFFE53935)
                      : const Color(0xFF8E7CF4),
                ),
            ],
          ),
          if (routeState.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              routeState.riskFactors.take(3).join(' | '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF546784)
                    : Colors.white.withValues(alpha: 0.64),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (routeState.monitoringMapRoute &&
              routeState.activeMapRouteReason != null) ...[
            const SizedBox(height: 8),
            Text(
              routeState.activeMapRouteReason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF546784)
                    : Colors.white.withValues(alpha: 0.64),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    unawaited(
                      ref
                          .read(safetyMonitorProvider.notifier)
                          .start()
                          .catchError((_) {}),
                    );
                    await ref.read(routeSafetyProvider.notifier).refreshNow();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(l10n.t('refresh')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _pushPremium(context, const SafetyMapScreen()),
                  icon: const Icon(Icons.map_rounded, size: 17),
                  label: Text(l10n.t('openMap')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await ref
                    .read(routeSafetyProvider.notifier)
                    .resetLearnedRoute();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('homeWorkplaceRouteLearningReset')),
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: Text(l10n.t('resetHomeWorkplaceRouteLearning')),
            ),
          ),
          if (routeState.pendingSafetyCheck) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFE53935,
                ).withValues(alpha: isLight ? 0.09 : 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.t('safetyCheckEndsIn')} $countdownText ${l10n.t('unlessYouConfirm')}',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF6B1D1D) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(routeSafetyProvider.notifier).markUserSafe(),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(l10n.t('imSafe')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2FB79E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(116, 42),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _routeChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.1 : 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isLight ? const Color(0xFF334158) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRouteCountdown(int seconds) {
    if (seconds <= 0) return '0s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${remainingSeconds}s';
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  Widget _buildRecentAlerts(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final safetyState = ref.watch(safetyMonitorProvider);
    final localAlertsState = ref.watch(communityAlertsProvider);
    final alerts = _resolveCommunityAlerts(safetyState, localAlertsState);
    final isRefreshing =
        safetyState.isRefreshing || localAlertsState.isLoading;

    ref.listen<SafetyMonitorState>(safetyMonitorProvider, (previous, next) {
      if (next.communityAlerts.isEmpty &&
          !next.isRefreshing &&
          next.position != null &&
          !ref.read(communityAlertsProvider).isLoading &&
          ref.read(communityAlertsProvider).alerts.isEmpty) {
        unawaited(ref.read(communityAlertsProvider.notifier).refresh());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('communityAlerts'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFF172235) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('checkingTrafficTransportNearbyActivity'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isLight ? const Color(0xFF627491) : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: alerts.isNotEmpty
                          ? [
                              const Color(0xFF3B82F6).withValues(alpha: 0.22),
                              const Color(0xFF26BF96).withValues(alpha: 0.24),
                            ]
                          : [
                              const Color(0xFF3B82F6).withValues(alpha: 0.10),
                              const Color(0xFF26BF96).withValues(alpha: 0.12),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: alerts.isNotEmpty
                          ? const Color(0xFF3B82F6).withValues(alpha: isLight ? 0.40 : 0.55)
                          : const Color(0xFF3B82F6).withValues(alpha: isLight ? 0.22 : 0.34),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: alerts.isNotEmpty
                              ? const Color(0xFF26BF96)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${alerts.length} live cards',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: alerts.isNotEmpty
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                _buildCommunityAlertsRefreshButton(
                  context,
                  isLight: isLight,
                  canRefresh: true,
                  isRefreshing: isRefreshing,
                  shouldEmphasizeRefresh: alerts.isEmpty && !isRefreshing,
                  onPressed: () async {
                    await Future.wait([
                      ref.read(safetyMonitorProvider.notifier).refresh(),
                      ref.read(communityAlertsProvider.notifier).refresh(),
                    ]);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isRefreshing && alerts.isEmpty)
          _PoppingAlertCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFEAF2FF)
                    : const Color(0xFF10233D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.t('loadingLiveAreaAlerts'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isLight
                            ? const Color(0xFF172235)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (alerts.isEmpty)
          _PoppingAlertCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFE6F7EC)
                    : const Color(0xFF112B22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF26BF96).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26BF96).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_searching_rounded,
                      color: Color(0xFF26BF96),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localAlertsState.error ??
                              l10n.t('liveAlertsWillAppearHere'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF172235)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localAlertsState.error != null
                              ? l10n.t('tapRefreshTryAgain')
                              : l10n.t('keepGpsOnForRealtimeCommunityUpdates'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isLight
                                ? const Color(0xFF546784)
                                : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...alerts.asMap().entries.map((entry) {
            final alert = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCommunityAlertCard(context, alert),
            );
          }),
      ],
    );
  }

  List<SafetyCommunityAlert> _resolveCommunityAlerts(
    SafetyMonitorState safetyState,
    CommunityAlertsState localAlertsState,
  ) {
    if (safetyState.communityAlerts.isNotEmpty) {
      return safetyState.communityAlerts;
    }
    return localAlertsState.alerts
        .map(_mapLocalCommunityAlert)
        .toList(growable: false);
  }

  SafetyCommunityAlert _mapLocalCommunityAlert(CommunityAlertItem item) {
    final priority = switch (item.kind) {
      CommunityAlertKind.roadBlock => 'critical',
      CommunityAlertKind.lonelyRoad => 'caution',
      CommunityAlertKind.silentZone => 'caution',
      CommunityAlertKind.traffic => 'information',
      CommunityAlertKind.transport => 'information',
      CommunityAlertKind.lighting => 'information',
    };

    return SafetyCommunityAlert(
      category: item.title,
      priority: priority,
      distanceMeters: 0,
      timestamp: item.updatedAt,
      summary: item.detail,
      recommendedAction:
          'Review nearby conditions on the map and stay aware while moving.',
    );
  }

  Widget _buildCommunityAlertCard(BuildContext context, SafetyCommunityAlert alert) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = _colorForCommunityAlert(alert.priority);
    final icon = _iconForCommunityAlert(alert.priority, alert.category);
    final priorityLabel = alert.priority == 'critical'
        ? 'CRITICAL'
        : alert.priority == 'caution'
        ? 'CAUTION'
        : 'INFO';
    final priorityBgColor = alert.priority == 'critical'
        ? const Color(0xFFB91C1C)
        : alert.priority == 'caution'
        ? const Color(0xFFB45309)
        : const Color(0xFF1D4ED8);
    final now = DateTime.now();
    final diff = now.difference(alert.timestamp);
    final timeAgo = diff.inMinutes < 1
        ? 'Just now'
        : diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';
    final distanceLabel = alert.distanceMeters == 0
        ? 'Current location'
        : alert.distanceMeters >= 1000
        ? '${(alert.distanceMeters / 1000).toStringAsFixed(1)} km away'
        : '${alert.distanceMeters} m away';

    return _PoppingAlertCard(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: isLight ? 0.20 : 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isLight ? 0.08 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: category, priority badge, distance
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isLight ? 0.06 : 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isLight ? 0.14 : 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert.category,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isLight ? const Color(0xFF172235) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priorityLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Meta row: distance + timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 13,
                    color: color.withValues(alpha: 0.80),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distanceLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLight ? const Color(0xFF64748B) : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            // Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                alert.summary,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: isLight ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
            // Recommended action
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isLight ? 0.07 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        alert.recommendedAction,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: isLight
                              ? const Color(0xFF334158)
                              : Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityAlertsRefreshButton(
    BuildContext context, {
    required bool isLight,
    required bool canRefresh,
    required bool isRefreshing,
    required bool shouldEmphasizeRefresh,
    required VoidCallback onPressed,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canRefresh && !isRefreshing ? onPressed : null,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: canRefresh
                  ? [
                      const Color(0xFF3B82F6),
                      const Color(0xFF1D4ED8),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      const Color(0xFFBFD1E8).withValues(alpha: 0.8),
                      const Color(0xFF7FA0C8).withValues(alpha: 0.9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: shouldEmphasizeRefresh && !isRefreshing
                  ? const Color(
                      0xFFF3B13E,
                    ).withValues(alpha: isLight ? 0.64 : 0.5)
                  : Colors.white.withValues(alpha: 0.18),
              width: shouldEmphasizeRefresh && !isRefreshing ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shouldEmphasizeRefresh && !isRefreshing
                    ? const Color(
                        0xFFF3B13E,
                      ).withValues(alpha: isLight ? 0.42 : 0.28)
                    : const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: isLight ? 0.30 : 0.22),
                blurRadius: shouldEmphasizeRefresh && !isRefreshing ? 28 : 18,
                spreadRadius: shouldEmphasizeRefresh && !isRefreshing ? 2 : 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: isLight ? 0.42 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: isRefreshing
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      const Icon(
                        Icons.refresh_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return button;
  }

  IconData _iconForCommunityAlert(String priority, String category) {
    final c = category.toLowerCase();
    if (c.contains('police activity') || c.contains('police station')) return Icons.local_police_rounded;
    if (c.contains('hospital')) return Icons.local_hospital_rounded;
    if (c.contains('safe route') || c.contains('safer corridor')) return Icons.alt_route_rounded;
    if (c.contains('incident') || c.contains('theft')) return Icons.warning_amber_rounded;
    if (c.contains('lighting') || c.contains('road light')) return Icons.lightbulb_rounded;
    if (c.contains('pedestrian')) return Icons.directions_walk_rounded;
    if (c.contains('construction')) return Icons.construction_rounded;
    if (c.contains('emergency response')) return Icons.emergency_rounded;
    if (c.contains('safety score')) return Icons.shield_rounded;
    if (c.contains('upcoming risk')) return Icons.dangerous_rounded;
    if (c.contains('support coverage') || c.contains('area incident')) return Icons.info_rounded;
    return priority == 'critical'
        ? Icons.warning_amber_rounded
        : Icons.notifications_active_rounded;
  }

  Color _colorForCommunityAlert(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'caution':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _openDialPad(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('couldNotOpenDialer')),
        ),
      );
    }
  }

  Widget _buildLocationRequiredScreen(
    BuildContext context,
    WidgetRef ref,
    SafetyMonitorState safetyState,
  ) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLight
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFF1F2937),
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    size: 56,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.t('locationRequiredTitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('locationRequiredMessage'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF4B5563)
                        : Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  safetyState.statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF475569)
                        : Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('locationAutoRefreshMessage'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF64748B)
                        : Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    unawaited(
                      ref
                          .read(safetyMonitorProvider.notifier)
                          .retry()
                          .catchError((_) {}),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.t('retryLocation')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoliceNumberCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163A63), Color(0xFF1E4B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163A63).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_police_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('policeEmergency'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '100',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openDialPad(context, '100'),
            icon: const Icon(Icons.call, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildWomenHelplineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF184D3B), Color(0xFF1E664E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF184D3B).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('womenHelpline'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '1091',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openDialPad(context, '1091'),
            icon: const Icon(Icons.call, color: Colors.green),
          ),
        ],
      ),
    );
  }



  Widget _buildNearbyServicesBlock(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final nearbyState = ref.watch(nearbyPlacesProvider);
    final activeType = nearbyState.activeType;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFFFF), Color(0xFFF6FAFF), Color(0xFFEAF3FF)]
              : const [Color(0xFF15233A), Color(0xFF0B172A), Color(0xFF101827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight
              ? const Color(0xFFCFE0F6)
              : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF7892B8).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2FB79E), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2FB79E).withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('nearbyServices'),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: isLight ? const Color(0xFF13243D) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nearbyState.places.isNotEmpty
                          ? l10n
                                .t('nearbyResultsCount')
                                .replaceFirst(
                                  '{count}',
                                  nearbyState.places.length.toString(),
                                )
                          : l10n.t('chooseServiceToScanYourArea'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLight
                            ? const Color(0xFF627491)
                            : Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;
              Widget rowTile({
                required String label,
                required IconData icon,
                required Color color,
                required NearbyPlaceType type,
                bool useCustomAsset = false,
              }) {
                return _nearbyServiceTile(
                  context: context,
                  width: tileWidth,
                  label: label,
                  icon: icon,
                  color: color,
                  active: activeType == type,
                  loading: nearbyState.isLoading && activeType == type,
                  useCustomAsset: useCustomAsset,
                  onPressed: () => ref
                      .read(nearbyPlacesProvider.notifier)
                      .toggleNearby(type),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      rowTile(
                        label: l10n.t('nearbyHospitals'),
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFFE45858),
                        type: NearbyPlaceType.hospitals,
                      ),
                      const SizedBox(width: gap),
                      rowTile(
                        label: l10n.t('policeStations'),
                        icon: Icons.local_police_rounded,
                        color: const Color(0xFF3B82F6),
                        type: NearbyPlaceType.policeStations,
                      ),
                    ],
                  ),
                  const SizedBox(height: gap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      rowTile(
                        label: l10n.t('nearbyPharmacies'),
                        icon: Icons.local_pharmacy_rounded,
                        color: const Color(0xFF2EAD74),
                        type: NearbyPlaceType.pharmacies,
                        useCustomAsset: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: gap),
                  Row(
                    children: [
                      rowTile(
                        label: l10n.t('nearbyWashrooms'),
                        icon: Icons.wc_rounded,
                        color: const Color(0xFF2FB79E),
                        type: NearbyPlaceType.washrooms,
                      ),
                      const SizedBox(width: gap),
                      rowTile(
                        label: l10n.t('nearbyBloodBanks'),
                        icon: Icons.bloodtype_rounded,
                        color: const Color(0xFFD64271),
                        type: NearbyPlaceType.bloodBanks,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (nearbyState.error != null)
            _nearbyStatusPanel(
              context: context,
              icon: Icons.warning_amber_rounded,
              title: nearbyState.error!,
              tone: const Color(0xFFE66E41),
            )
          else if (nearbyState.isLoading)
            _nearbyStatusPanel(
              context: context,
              icon: Icons.radar_rounded,
              title: 'Scanning nearby places...',
              tone: activeType == NearbyPlaceType.bloodBanks
                  ? const Color(0xFFD64271)
                  : activeType == NearbyPlaceType.pharmacies
                  ? const Color(0xFF2EAD74)
                  : activeType == NearbyPlaceType.washrooms
                  ? const Color(0xFF2FB79E)
                  : activeType == NearbyPlaceType.policeStations
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE45858),
              loading: true,
            )
          else if (nearbyState.activeType != null && nearbyState.places.isEmpty)
            _nearbyStatusPanel(
              context: context,
              icon: Icons.search_off_rounded,
              title: l10n.t('noNearbyPlaces'),
              tone: const Color(0xFF8E7CF4),
            )
          else if (nearbyState.places.isNotEmpty)
            Column(
              children: nearbyState.places.take(8).map((place) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _nearbyResultCard(
                    context: context,
                    place: place,
                    onTap: () => _confirmAndOpenOnMap(context, place),
                  ),
                );
              }).toList(),
            )
          else
            _nearbyStatusPanel(
              context: context,
              icon: Icons.touch_app_rounded,
              title: l10n.t('tapToLoadNearby'),
              tone: const Color(0xFF3B82F6),
            ),
        ],
      ),
    );
  }

  Widget _nearbyServiceTile({
    required BuildContext context,
    required double width,
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    required bool loading,
    required bool useCustomAsset,
    required VoidCallback onPressed,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = active
        ? Colors.white
        : (isLight ? const Color(0xFF172235) : Colors.white);
    final inactiveBase = color.withValues(alpha: isLight ? 0.12 : 0.18);
    final inactiveEdge = color.withValues(alpha: isLight ? 0.2 : 0.28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      inactiveBase,
                      color.withValues(alpha: isLight ? 0.06 : 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.32)
                  : inactiveEdge,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? color.withValues(alpha: 0.32)
                    : isLight
                    ? color.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: active ? 18 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.22)
                          : color.withValues(alpha: isLight ? 0.14 : 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : useCustomAsset
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: SvgPicture.asset(
                              'assets/icons/pharmacy_badge.svg',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(icon, color: active ? Colors.white : color),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: active
                        ? Colors.white.withValues(alpha: 0.86)
                        : color.withValues(alpha: 0.82),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nearbyStatusPanel({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color tone,
    bool loading = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.76)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFD8E5F7)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: isLight ? 0.13 : 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tone,
                    ),
                  )
                : Icon(icon, color: tone, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isLight ? const Color(0xFF334158) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nearbyResultCard({
    required BuildContext context,
    required NearbyPlaceItem place,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ratingText = place.rating != null
        ? place.rating!.toStringAsFixed(1)
        : 'N/A';
    final openText = place.isOpenNow == null
        ? 'Hours unavailable'
        : (place.isOpenNow! ? 'Open now' : 'Closed now');
    final openColor = place.isOpenNow == true
        ? const Color(0xFF2FB79E)
        : place.isOpenNow == false
        ? const Color(0xFFE66E41)
        : const Color(0xFF8E7CF4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withValues(alpha: 0.88)
                : AppTheme.surfaceSoft.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFD8E5F7)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF3B82F6,
                  ).withValues(alpha: isLight ? 0.12 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Color(0xFF3B82F6),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF172235) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF627491)
                            : Colors.white.withValues(alpha: 0.64),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _nearbyChip(
                          context: context,
                          icon: Icons.route_rounded,
                          label: place.distanceTextFor(
                            Localizations.localeOf(context).languageCode,
                          ),
                          color: const Color(0xFF3B82F6),
                        ),
                        _nearbyChip(
                          context: context,
                          icon: Icons.star_rounded,
                          label: ratingText,
                          color: const Color(0xFFF3B13E),
                        ),
                        _nearbyChip(
                          context: context,
                          icon: Icons.schedule_rounded,
                          label: openText,
                          color: openColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isLight ? const Color(0xFF8FA2BE) : Colors.white30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nearbyChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.1 : 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isLight ? const Color(0xFF334158) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoppingActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final VoidCallback? onTap;

  const _PoppingActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  State<_PoppingActionCard> createState() => _PoppingActionCardState();
}

class _PoppingActionCardState extends State<_PoppingActionCard> {
  bool _pressed = false;
  bool _popped = false;

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;

    setState(() {
      _pressed = false;
      _popped = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 135));
    if (!mounted) return;

    setState(() => _popped = false);
    await Future<void>.delayed(const Duration(milliseconds: 55));
    if (!mounted) return;

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172235) : Colors.white;
    final mutedIconColor = isLight
        ? const Color(0xFF60708B)
        : Colors.white.withValues(alpha: 0.66);
    final scale = _pressed ? 0.96 : (_popped ? 1.07 : 1.0);
    final lift = _popped ? -5.0 : (_pressed ? 2.0 : 0.0);
    final safeWidth = widget.width.clamp(0.0, double.infinity);
    final compact = safeWidth < 176;
    final horizontalPadding = compact ? 12.0 : 16.0;
    final iconBoxSize = compact ? 42.0 : 46.0;
    final labelFontSize = compact ? 13.5 : 15.0;
    final gap = compact ? 10.0 : 13.0;
    final arrowSize = compact ? 17.0 : 19.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 165),
        curve: Curves.easeOutBack,
        child: AnimatedSlide(
          offset: Offset(0, lift / 100),
          duration: const Duration(milliseconds: 165),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            width: safeWidth,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isLight
                      ? Color.lerp(Colors.white, widget.color, 0.08)!
                      : Color.lerp(AppTheme.cardColor, widget.color, 0.18)!,
                  isLight
                      ? Color.lerp(const Color(0xFFF8FBFF), widget.color, 0.16)!
                      : Color.lerp(
                          const Color(0xFF0C182D),
                          widget.color,
                          0.26,
                        )!,
                  isLight
                      ? Color.lerp(
                          const Color(0xFFF2F6FF),
                          widget.color,
                          _popped ? 0.22 : 0.13,
                        )!
                      : Color.lerp(
                          const Color(0xFF071121),
                          widget.color,
                          _popped ? 0.34 : 0.22,
                        )!,
                ],
                stops: const [0.0, 0.58, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _popped
                    ? widget.color.withValues(alpha: isLight ? 0.42 : 0.48)
                    : widget.color.withValues(alpha: isLight ? 0.20 : 0.26),
                width: _popped ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(
                    alpha: isLight
                        ? (_popped ? 0.22 : 0.12)
                        : (_popped ? 0.30 : 0.18),
                  ),
                  blurRadius: _popped ? 24 : 14,
                  spreadRadius: _popped ? 1 : 0,
                  offset: Offset(0, _popped ? 11 : 7),
                ),
                BoxShadow(
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.65)
                      : Colors.black.withValues(alpha: 0.24),
                  blurRadius: _popped ? 14 : 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -18,
                  top: -22,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 190),
                    width: _popped ? 72 : 58,
                    height: _popped ? 72 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(
                        alpha: isLight ? 0.10 : 0.16,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withValues(
                              alpha: isLight ? 0.22 : 0.28,
                            ),
                            widget.color.withValues(
                              alpha: _popped ? 0.34 : 0.16,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: compact ? 22 : 24,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: SizedBox(
                        height: 22,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    AnimatedRotation(
                      turns: _popped ? -0.08 : 0,
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: arrowSize,
                        color: _popped ? widget.color : mutedIconColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoppingAlertCard extends StatefulWidget {
  const _PoppingAlertCard({required this.child});

  final Widget child;

  @override
  State<_PoppingAlertCard> createState() => _PoppingAlertCardState();
}

class _PoppingAlertCardState extends State<_PoppingAlertCard> {
  bool _pressed = false;
  bool _popped = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    if (!pressed) {
      unawaited(_pop());
    }
    setState(() => _pressed = pressed);
  }

  Future<void> _pop() async {
    setState(() => _popped = true);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _popped = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final scale = _pressed ? 0.94 : (_popped ? 1.06 : 1.0);
    final lift = _pressed ? 2.0 : (_popped ? -4.0 : 0.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        scale: scale,
        child: Transform.translate(
          offset: Offset(0, lift),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _popped ? 0.02 : 0.08),
                  blurRadius: _popped ? 10 : 16,
                  offset: Offset(0, _popped ? 2 : 7),
                ),
                BoxShadow(
                  color: isLight
                      ? const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: _popped ? 0.18 : 0.06)
                      : const Color(
                          0xFF2ED6C5,
                        ).withValues(alpha: _popped ? 0.16 : 0.04),
                  blurRadius: _popped ? 18 : 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? const [Color(0xFFF8FBFF), Color(0xFFF3F7FD), Color(0xFFEFF4FA)]
              : const [Colors.black, Color(0xFF07101F), Color(0xFF050A14)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -100,
            child: _glowCircle(
              isLight ? const Color(0xFFBFD7FF) : const Color(0xFF133B5F),
              280,
              opacity: isLight ? 0.34 : 0.16,
            ),
          ),
          Positioned(
            right: -110,
            top: 100,
            child: _glowCircle(
              isLight ? const Color(0xFFCCF4E8) : const Color(0xFF2A1A43),
              240,
              opacity: isLight ? 0.26 : 0.12,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -40,
            child: _glowCircle(
              isLight ? const Color(0xFFF8DCE8) : const Color(0xFF0E2A48),
              300,
              opacity: isLight ? 0.24 : 0.10,
            ),
          ),
          Positioned(
            top: 180,
            left: 36,
            right: 36,
            child: IgnorePointer(
              child: Opacity(
                opacity: isLight ? 0.15 : 0.06,
                child: CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _SoftWavePainter(
                    color: isLight
                        ? const Color(0xFFB3C7E3)
                        : const Color(0xFF29405F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size, {double opacity = 0.14}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.8),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _SoftWavePainter extends CustomPainter {
  _SoftWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.34);
    path.cubicTo(
      size.width * 0.18,
      size.height * 0.12,
      size.width * 0.36,
      size.height * 0.55,
      size.width * 0.52,
      size.height * 0.36,
    );
    path.cubicTo(
      size.width * 0.66,
      size.height * 0.20,
      size.width * 0.80,
      size.height * 0.58,
      size.width,
      size.height * 0.32,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
