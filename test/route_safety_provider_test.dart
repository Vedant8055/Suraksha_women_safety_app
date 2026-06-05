import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/features/routes/route_safety_provider.dart';

void main() {
  group('RouteSafetyAnalyzer', () {
    const analyzer = RouteSafetyAnalyzer();

    test('learns route and keeps familiar path safer', () {
      final learnedRoute = List.generate(
        RouteSafetyAnalyzer.learnedRouteThreshold,
        (index) => RoutePoint(
          latitude: 19.0760 + (index * 0.0001),
          longitude: 72.8777 + (index * 0.0001),
          timestamp: DateTime(2026, 6, 5, 9, index),
        ),
      );

      final assessment = analyzer.assess(
        position: _position(latitude: 19.0761, longitude: 72.8778),
        learnedRoute: learnedRoute,
        areaSafetyScore: 82,
        nearbyPoliceCount: 2,
        nearbyHospitalCount: 1,
        now: DateTime(2026, 6, 5, 10),
      );

      expect(assessment.hasLearnedRoute, true);
      expect(assessment.deviatedFromLearnedRoute, false);
      expect(assessment.label, 'Safest Route');
      expect(assessment.riskFactors, contains('Known daily route'));
    });

    test('detects route deviation and lowers score at night', () {
      final learnedRoute = List.generate(
        RouteSafetyAnalyzer.learnedRouteThreshold,
        (index) => RoutePoint(
          latitude: 19.0760 + (index * 0.0001),
          longitude: 72.8777 + (index * 0.0001),
          timestamp: DateTime(2026, 6, 5, 9, index),
        ),
      );

      final assessment = analyzer.assess(
        position: _position(latitude: 19.0900, longitude: 72.9000),
        learnedRoute: learnedRoute,
        areaSafetyScore: 78,
        nearbyPoliceCount: 0,
        nearbyHospitalCount: 0,
        now: DateTime(2026, 6, 5, 23),
      );

      expect(assessment.deviatedFromLearnedRoute, true);
      expect(assessment.score, lessThan(60));
      expect(
        assessment.riskFactors,
        contains('Route changed from daily safe pattern'),
      );
      expect(assessment.riskFactors, contains('Night travel'));
    });

    test('stores route samples only after useful movement or time', () {
      final route = [
        RoutePoint(
          latitude: 19.0760,
          longitude: 72.8777,
          timestamp: DateTime(2026, 6, 5, 9),
        ),
      ];

      expect(
        analyzer.shouldStoreSample(
          sample: RoutePoint(
            latitude: 19.07601,
            longitude: 72.87771,
            timestamp: DateTime(2026, 6, 5, 9, 0, 5),
          ),
          route: route,
        ),
        false,
      );
      expect(
        analyzer.shouldStoreSample(
          sample: RoutePoint(
            latitude: 19.0765,
            longitude: 72.8782,
            timestamp: DateTime(2026, 6, 5, 9, 0, 5),
          ),
          route: route,
        ),
        true,
      );
    });
  });
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 6, 5, 10),
    accuracy: 12,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
