import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class LiveSafetyControlsSheet extends StatelessWidget {
  final Position? position;
  final String? statusText;
  final VoidCallback onMyLocation;
  final VoidCallback onRefreshNearby;
  final VoidCallback onRetryLiveLocation;

  const LiveSafetyControlsSheet({
    super.key,
    required this.position,
    required this.statusText,
    required this.onMyLocation,
    required this.onRefreshNearby,
    required this.onRetryLiveLocation,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.28,
      maxChildSize: 0.84,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Safety Map',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        position == null
                            ? 'Locating...'
                            : '${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                  if (statusText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      statusText!,
                      style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMyLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('My Location'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRefreshNearby,
                          icon: const Icon(Icons.local_police, size: 16),
                          label: const Text('Refresh Nearby'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRetryLiveLocation,
                      icon: const Icon(Icons.gps_fixed, size: 16),
                      label: const Text('Retry Live Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
