import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:suraksha_women_safety_app/features/dashboard/community_alerts_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/nearby_places_provider.dart';
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
      accentColor: const Color(0xFF3B82F6),
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
          await Future<void>.delayed(const Duration(milliseconds: 3200));
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
    final alertsState = ref.watch(communityAlertsProvider);
    final shouldEmphasizeRefresh =
        !alertsState.isLoading &&
        (alertsState.error != null || alertsState.alerts.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.t('communityAlerts'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isLight ? const Color(0xFF172235) : Colors.white,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!alertsState.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.16),
                          const Color(0xFF26BF96).withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: isLight ? 0.22 : 0.34),
                      ),
                    ),
                    child: Text(
                      l10n.t('tapForAlerts'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Color(0xFF2E4E74),
                      ),
                    ),
                  ),
                const SizedBox(height: 7),
                _buildCommunityAlertsRefreshButton(
                  context,
                  isLight: isLight,
                  alertsState: alertsState,
                  shouldEmphasizeRefresh: shouldEmphasizeRefresh,
                  onPressed: () =>
                      ref.read(communityAlertsProvider.notifier).refresh(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (alertsState.error != null)
          _buildAlertCard(
            context,
            alertsState.error!,
            l10n.t('tapRefreshTryAgain'),
            Icons.warning_amber_rounded,
            const Color(0xFFF3B13E),
          )
        else if (alertsState.alerts.isEmpty && alertsState.isLoading)
          _buildAlertCard(
            context,
            l10n.t('loadingLiveAreaAlerts'),
            l10n.t('checkingTrafficTransportNearbyActivity'),
            Icons.sync_rounded,
            AppTheme.primaryColor,
          )
        else if (alertsState.alerts.isEmpty)
          _buildAlertCard(
            context,
            l10n.t('liveAlertsWillAppearHere'),
            l10n.t('keepGpsOnForRealtimeCommunityUpdates'),
            Icons.location_searching_rounded,
            const Color(0xFF26BF96),
          )
        else
          ...alertsState.alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAlertCard(
                context,
                alert.title,
                '${alert.detail} | ${alert.timeText(l10n.locale.languageCode)}',
                _iconForCommunityAlert(alert.kind),
                _colorForCommunityAlert(alert.kind),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommunityAlertsRefreshButton(
    BuildContext context, {
    required bool isLight,
    required CommunityAlertsState alertsState,
    required bool shouldEmphasizeRefresh,
    required VoidCallback onPressed,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alertsState.isLoading ? null : onPressed,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: alertsState.isLoading
                  ? [
                      const Color(0xFFBFD1E8).withValues(alpha: 0.8),
                      const Color(0xFF7FA0C8).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFF3B82F6),
                      const Color(0xFF1D4ED8),
                      const Color(0xFF0F172A),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: shouldEmphasizeRefresh
                  ? const Color(
                      0xFFF3B13E,
                    ).withValues(alpha: isLight ? 0.64 : 0.5)
                  : Colors.white.withValues(alpha: 0.18),
              width: shouldEmphasizeRefresh ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shouldEmphasizeRefresh
                    ? const Color(
                        0xFFF3B13E,
                      ).withValues(alpha: isLight ? 0.42 : 0.28)
                    : const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: isLight ? 0.30 : 0.22),
                blurRadius: shouldEmphasizeRefresh ? 28 : 18,
                spreadRadius: shouldEmphasizeRefresh ? 2 : 0,
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
            child: alertsState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
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
                      Icon(
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

    return shouldEmphasizeRefresh && !alertsState.isLoading
        ? Pulse(
            infinite: true,
            duration: const Duration(milliseconds: 1200),
            child: button,
          )
        : button;
  }

  String _greetingPrefix(BuildContext context) {
    return AppLocalizations.of(context).t('greetingHello');
  }

  IconData _iconForCommunityAlert(CommunityAlertKind kind) {
    switch (kind) {
      case CommunityAlertKind.traffic:
        return Icons.traffic_rounded;
      case CommunityAlertKind.transport:
        return Icons.directions_bus_rounded;
      case CommunityAlertKind.lonelyRoad:
        return Icons.route_rounded;
      case CommunityAlertKind.silentZone:
        return Icons.volume_off_rounded;
      case CommunityAlertKind.roadBlock:
        return Icons.construction_rounded;
      case CommunityAlertKind.lighting:
        return Icons.lightbulb_circle_rounded;
    }
  }

  Color _colorForCommunityAlert(CommunityAlertKind kind) {
    switch (kind) {
      case CommunityAlertKind.traffic:
        return const Color(0xFFF3B13E);
      case CommunityAlertKind.transport:
        return const Color(0xFF1D8CF8);
      case CommunityAlertKind.lonelyRoad:
        return const Color(0xFFFF5D73);
      case CommunityAlertKind.silentZone:
        return const Color(0xFF8E7CF4);
      case CommunityAlertKind.roadBlock:
        return const Color(0xFFE66E41);
      case CommunityAlertKind.lighting:
        return const Color(0xFFF4C542);
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

  Widget _buildPoliceNumberCard(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFFFF), Color(0xFFF2F6FF)]
              : const [AppTheme.cardColor, AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF8A9FBE).withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_police_rounded,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('policeEmergency'),
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '100',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFFFF), Color(0xFFF2F6FF)]
              : const [AppTheme.cardColor, AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF8A9FBE).withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('womenHelpline'),
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '1091',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
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

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return _PoppingAlertCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isLight
                  ? const Color(0xFFFFFFFF)
                  : AppTheme.surfaceSoft.withValues(alpha: 0.72),
              isLight
                  ? const Color(0xFFF1F6FF)
                  : AppTheme.cardColor.withValues(alpha: 0.76),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLight
                ? const Color(0xFFDCE5F6)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF172235) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                          .replaceFirst('{count}', nearbyState.places.length.toString())
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
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _nearbyServiceTile(
                    context: context,
                    width: tileWidth,
                    label: l10n.t('nearbyHospitals'),
                    icon: Icons.local_hospital_rounded,
                    color: const Color(0xFFE45858),
                    active: activeType == NearbyPlaceType.hospitals,
                    loading:
                        nearbyState.isLoading &&
                        activeType == NearbyPlaceType.hospitals,
                    onPressed: () => ref
                        .read(nearbyPlacesProvider.notifier)
                        .toggleNearby(NearbyPlaceType.hospitals),
                  ),
                  _nearbyServiceTile(
                    context: context,
                    width: tileWidth,
                    label: l10n.t('policeStations'),
                    icon: Icons.local_police_rounded,
                    color: const Color(0xFF3B82F6),
                    active: activeType == NearbyPlaceType.policeStations,
                    loading:
                        nearbyState.isLoading &&
                        activeType == NearbyPlaceType.policeStations,
                    onPressed: () => ref
                        .read(nearbyPlacesProvider.notifier)
                        .toggleNearby(NearbyPlaceType.policeStations),
                  ),
                  _nearbyServiceTile(
                    context: context,
                    width: tileWidth,
                    label: l10n.t('nearbyWashrooms'),
                    icon: Icons.wc_rounded,
                    color: const Color(0xFF2FB79E),
                    active: activeType == NearbyPlaceType.washrooms,
                    loading:
                        nearbyState.isLoading &&
                        activeType == NearbyPlaceType.washrooms,
                    onPressed: () => ref
                        .read(nearbyPlacesProvider.notifier)
                        .toggleNearby(NearbyPlaceType.washrooms),
                  ),
                  _nearbyServiceTile(
                    context: context,
                    width: tileWidth,
                    label: l10n.t('nearbyBloodBanks'),
                    icon: Icons.bloodtype_rounded,
                    color: const Color(0xFFD64271),
                    active: activeType == NearbyPlaceType.bloodBanks,
                    loading:
                        nearbyState.isLoading &&
                        activeType == NearbyPlaceType.bloodBanks,
                    onPressed: () => ref
                        .read(nearbyPlacesProvider.notifier)
                        .toggleNearby(NearbyPlaceType.bloodBanks),
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
    required VoidCallback onPressed,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = active
        ? Colors.white
        : (isLight ? const Color(0xFF172235) : Colors.white);

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
                    colors: isLight
                        ? const [Color(0xFFFFFFFF), Color(0xFFF2F7FF)]
                        : [
                            AppTheme.surfaceSoft.withValues(alpha: 0.72),
                            const Color(0xFF10213A),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.32)
                  : isLight
                  ? const Color(0xFFD8E5F7)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? color.withValues(alpha: 0.32)
                    : isLight
                    ? const Color(0xFF8A9FBE).withValues(alpha: 0.12)
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
                      ? const Color(0xFF3B82F6).withValues(
                          alpha: _popped ? 0.18 : 0.06,
                        )
                      : const Color(0xFF2ED6C5).withValues(
                          alpha: _popped ? 0.16 : 0.04,
                        ),
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
