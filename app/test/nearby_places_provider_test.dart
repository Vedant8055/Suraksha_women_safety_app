import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/dashboard/nearby_places_provider.dart';

void main() {
  group('NearbyPlacesNotifier', () {
    test(
      'toggleNearby collapses results when tapping the same service again',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(nearbyPlacesProvider.notifier);
        notifier.debugSetState(
          const NearbyPlacesState(
            activeType: NearbyPlaceType.washrooms,
            places: [
              NearbyPlaceItem(
                id: 'washroom-1',
                name: 'Public Washroom',
                address: 'Main Road',
                latitude: 19.1,
                longitude: 72.8,
                distanceMeters: 120,
              ),
            ],
          ),
        );

        notifier.toggleNearby(NearbyPlaceType.washrooms);

        expect(notifier.state.activeType, isNull);
        expect(notifier.state.places, isEmpty);
        expect(notifier.state.error, isNull);
        expect(notifier.state.isLoading, isFalse);
      },
    );
  });
}
