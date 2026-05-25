import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/emergency_mode_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_screen.dart';
import 'package:suraksha_women_safety_app/features/maps/safety_map_screen.dart';
import 'package:suraksha_women_safety_app/features/medical/medical_vault_screen.dart';
import 'package:suraksha_women_safety_app/features/posh/posh_chat_screen.dart';
import 'package:suraksha_women_safety_app/widgets/safety_radar.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 68) / 2;

    return Scaffold(
      body: Stack(
        children: [
          const _DashboardBackground(),
          SafeArea(
            child: FadeInUp(
              duration: const Duration(milliseconds: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 22),
                    _buildSafetyPanel(),
                    const SizedBox(height: 26),
                    _buildSOSButton(context, ref),
                    const SizedBox(height: 28),
                    _buildQuickActions(context, cardWidth),
                    const SizedBox(height: 26),
                    _buildRecentAlerts(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
              const Text(
                'Hello, Kaveri',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF194E43),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        color: Color(0xFFB8FAE8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
            child: Container(
              width: 56,
              height: 56,
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

  Widget _buildSafetyPanel() {
    return Consumer(
      builder: (context, ref, _) {
        final monitor = ref.watch(safetyMonitorProvider);
        final monitorNotifier = ref.read(safetyMonitorProvider.notifier);
        final lastUpdate = monitor.lastUpdatedAt == null
            ? 'Waiting...'
            : TimeOfDay.fromDateTime(monitor.lastUpdatedAt!).format(context);
        final gpsStateText = monitor.gpsEnabled
            ? (monitor.permissionGranted ? 'GPS ON' : 'Permission Needed')
            : 'GPS OFF';

        final riskColor = monitor.riskLabel == 'Low Risk'
            ? const Color(0xFFA9F9E3)
            : monitor.riskLabel == 'Moderate Risk'
                ? const Color(0xFFFFE2A1)
                : const Color(0xFFFFD0D0);
        final riskBg = monitor.riskLabel == 'Low Risk'
            ? const Color(0xFF174A40)
            : monitor.riskLabel == 'Moderate Risk'
                ? const Color(0xFF5E4412)
                : const Color(0xFF5C1E1E);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF193251), Color(0xFF12243B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              const SafetyRadar(),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety Score',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${monitor.safetyScore}%',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: riskBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      monitor.riskLabel,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSoft.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Realtime Monitor: $gpsStateText | Updated $lastUpdate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC6D6EC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      monitor.statusMessage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _miniChip('Police Nearby: ${monitor.nearbyPoliceCount}'),
                        _miniChip('Hospitals Nearby: ${monitor.nearbyHospitalCount}'),
                        _miniChip(
                          monitor.trackingActive ? 'Tracking Active' : 'Tracking Paused',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => monitorNotifier.retry(),
                        icon: const Icon(Icons.gps_fixed, size: 16),
                        label: const Text('Retry GPS'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3556),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFD3DFEF),
          fontWeight: FontWeight.w600,
        ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmergencyModeScreen(),
            ),
          );
        },
        child: sosState.isActive
            ? Pulse(infinite: true, child: button)
            : button,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, double cardWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
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
    return GestureDetector(
      onTap: screen != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            )
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        _buildAlertCard(
          'Safe zone updated nearby',
          '2 mins ago',
          Icons.location_on_rounded,
          const Color(0xFF26BF96),
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          'Crowded area warning',
          '15 mins ago',
          Icons.warning_amber_rounded,
          const Color(0xFFF3B13E),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                  style: const TextStyle(
                    color: Colors.white,
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
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08111F), Color(0xFF101E35), Color(0xFF07162B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            child: _glowCircle(const Color(0xFF1FAE95), 230),
          ),
          Positioned(
            right: -70,
            top: 90,
            child: _glowCircle(const Color(0xFFE34D47), 180),
          ),
          Positioned(
            bottom: -120,
            left: 60,
            child: _glowCircle(const Color(0xFF2B74B6), 220),
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
        color: color.withValues(alpha: 0.24),
      ),
    );
  }
}
