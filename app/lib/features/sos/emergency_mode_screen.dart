import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

class EmergencyModeScreen extends ConsumerStatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  ConsumerState<EmergencyModeScreen> createState() =>
      _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends ConsumerState<EmergencyModeScreen> {
  bool _contactPopupShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contactPopupShown) return;
    _contactPopupShown = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showContactsInformedPopup(),
    );
  }

  void _showContactsInformedPopup() {
    final contacts = ref.read(emergencyContactsProvider);
    if (contacts.isEmpty || !mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => PremiumDialogSurface(
        title: 'Emergency Contacts Informed',
        message: 'Live location has been shared with:',
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFFE53935),
        actions: [
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  Theme.of(dialogContext).brightness == Brightness.light
                  ? const Color(0xFF172235)
                  : Colors.white,
              side: BorderSide(
                color: const Color(0xFFE53935).withValues(
                  alpha: Theme.of(dialogContext).brightness == Brightness.light
                      ? 0.34
                      : 0.42,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(dialogContext).brightness ==
                                Brightness.light
                            ? const Color(0xFFF4F7FC)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(
                            alpha:
                                Theme.of(dialogContext).brightness ==
                                    Brightness.light
                                ? 0.14
                                : 0.24,
                          ),
                        ),
                      ),
                      child: Text(
                        '${c.name} (${c.phone})',
                        style: TextStyle(
                          color:
                              Theme.of(dialogContext).brightness ==
                                  Brightness.light
                              ? const Color(0xFF172235)
                              : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);

    final locationText = sosState.currentPosition != null
        ? '${sosState.currentPosition!.latitude.toStringAsFixed(4)}, ${sosState.currentPosition!.longitude.toStringAsFixed(4)}'
        : 'Fetching location...';

    final statusText = sosState.isStreaming
        ? (sosState.lastLocationUpdate != null
              ? 'Live Feed Active (${TimeOfDay.fromDateTime(sosState.lastLocationUpdate!).format(context)})'
              : 'Starting live transmission...')
        : 'Live transmission paused';

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Flash(
                infinite: true,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'EMERGENCY MODE ACTIVE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help is on the way. Your live location is being shared.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const Spacer(),
              _buildInfoCard('Current Location', locationText),
              const SizedBox(height: 16),
              _buildInfoCard('Status', statusText),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(sosProvider.notifier).cancelSOS();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                  ),
                  child: const Text('I AM SAFE - CANCEL SOS'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
