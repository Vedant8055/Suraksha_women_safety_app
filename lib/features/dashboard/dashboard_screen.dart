import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/emergency_mode_screen.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_screen.dart';
import 'package:suraksha_women_safety_app/features/maps/safety_map_screen.dart';
import 'package:suraksha_women_safety_app/features/medical/medical_vault_screen.dart';
import 'package:suraksha_women_safety_app/features/posh/posh_chat_screen.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/nearby_places_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Safety Map'),
        content: const Text(
          'Willing to see this location on the safety map?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
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

    return Scaffold(
      body: Stack(
        children: [
          const _DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 40),
                    duration: const Duration(milliseconds: 420),
                    from: 10,
                    child: _buildHeader(context),
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
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 280),
                    duration: const Duration(milliseconds: 440),
                    from: 10,
                    child: _buildRecentAlerts(),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 360),
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

  Widget _buildHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFFFFF), Color(0xFFF0F5FF)]
              : const [Color(0xFF13213B), Color(0xFF0C172B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDDE6F7)
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF7E8FB0).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.32),
            blurRadius: isLight ? 16 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suraksha',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hello, Kaveri',
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
                  children: const [
                    Icon(
                      Icons.verified_user,
                      size: 14,
                      color: Color(0xFF69E5C8),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Safe Zone Active',
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosProvider);

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
              alpha: sosState.isActive ? 0.48 : 0.24,
            ),
            blurRadius: sosState.isActive ? 36 : 16,
            spreadRadius: sosState.isActive ? 10 : 3,
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
          await ref.read(sosProvider.notifier).triggerSOS();
          if (!context.mounted) {
            return;
          }
          _pushPremium(context, const EmergencyModeScreen());
        },
        child: sosState.isActive
            ? Pulse(infinite: true, child: button)
            : button,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, double cardWidth) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Services',
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
              'Map',
              const Color(0xFF3B82F6),
              const SafetyMapScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.medical_services_rounded,
              'Medical',
              const Color(0xFFE66E41),
              const MedicalVaultScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.security_rounded,
              'Cyber',
              const Color(0xFFEC9F2A),
              const CyberCrimeScreen(),
              cardWidth,
            ),
            _buildActionCard(
              context,
              Icons.gavel_rounded,
              'POSH Portal',
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: screen != null ? () => _pushPremium(context, screen) : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isLight ? const Color(0xFFFFFFFF) : AppTheme.cardColor.withValues(alpha: 0.95),
              isLight ? const Color(0xFFF2F6FF) : const Color(0xFF0C182D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLight
                ? const Color(0xFFDCE5F6)
                : Colors.white.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? const Color(0xFF8A9FBE).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.26),
              blurRadius: isLight ? 12 : 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: isLight ? Color(0xFF172235) : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    // keep colors adaptive for premium light mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final isLight = Theme.of(context).brightness == Brightness.light;
            return Text(
          'Community Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
                  color: isLight ? const Color(0xFF172235) : Colors.white,
          ),
            );
          },
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) => _buildAlertCard(
            context,
          'Safe zone updated nearby',
          '2 mins ago',
          Icons.location_on_rounded,
          const Color(0xFF26BF96),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) => _buildAlertCard(
            context,
          'Crowded area warning',
          '15 mins ago',
          Icons.warning_amber_rounded,
          const Color(0xFFF3B13E),
          ),
        ),
      ],
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
    return Container(
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
                    fontWeight: FontWeight.w600,
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
          Icon(
            Icons.chevron_right,
            color: isLight ? const Color(0xFF8FA2BE) : Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyServicesBlock(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final nearbyState = ref.watch(nearbyPlacesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF121E34), Color(0xFF0B172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: isLight ? const Color(0xFFFFFFFF) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isLight ? const Color(0xFF172235) : Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _nearbyButton(
                  context: context,
                  label: 'Nearby Hospitals',
                  icon: Icons.local_hospital_rounded,
                  loading:
                      nearbyState.isLoading &&
                      nearbyState.activeType == NearbyPlaceType.hospitals,
                  onPressed: () => ref
                      .read(nearbyPlacesProvider.notifier)
                      .fetchNearby(NearbyPlaceType.hospitals),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _nearbyButton(
                  context: context,
                  label: 'Police Stations',
                  icon: Icons.local_police_rounded,
                  loading:
                      nearbyState.isLoading &&
                      nearbyState.activeType == NearbyPlaceType.policeStations,
                  onPressed: () => ref
                      .read(nearbyPlacesProvider.notifier)
                      .fetchNearby(NearbyPlaceType.policeStations),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (nearbyState.error != null)
            Text(
              nearbyState.error!,
              style: const TextStyle(
                color: Color(0xFFFFB3B3),
                fontWeight: FontWeight.w600,
              ),
            )
          else if (nearbyState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (nearbyState.activeType != null && nearbyState.places.isEmpty)
            const Text(
              'No nearby places found in 5 km radius.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else if (nearbyState.places.isNotEmpty)
            Column(
              children: nearbyState.places.take(8).map((place) {
                final ratingText = place.rating != null
                    ? 'Rating ${place.rating!.toStringAsFixed(1)}'
                    : 'Rating N/A';
                final openText = place.isOpenNow == null
                    ? 'Hours unavailable'
                    : (place.isOpenNow! ? 'Open now' : 'Closed now');

                return InkWell(
                  onTap: () => _confirmAndOpenOnMap(context, place),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFF4F8FF)
                          : AppTheme.surfaceSoft.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLight
                            ? const Color(0xFFDCE5F6)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            color: isLight ? const Color(0xFF172235) : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.address,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$ratingText | $openText',
                          style: const TextStyle(
                            color: Color(0xFFC6D6EC),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Text(
              'Tap a button to load nearby real-time services.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _nearbyButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    // keep contrast high in both modes
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center),
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeData.estimateBrightnessForColor(Theme.of(context).scaffoldBackgroundColor) == Brightness.light
            ? const Color(0xFFEAF2FF)
            : const Color(0xFF1A355A),
        foregroundColor: ThemeData.estimateBrightnessForColor(Theme.of(context).scaffoldBackgroundColor) == Brightness.light
            ? const Color(0xFF173056)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
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
      color: isLight ? const Color(0xFFF6F8FC) : Colors.black,
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -90,
            child: _glowCircle(const Color(0xFF133B5F), 250),
          ),
          Positioned(
            right: -95,
            top: 140,
            child: _glowCircle(const Color(0xFF2A1A43), 220),
          ),
          Positioned(
            bottom: -150,
            left: 30,
            child: _glowCircle(const Color(0xFF0E2A48), 260),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
}
