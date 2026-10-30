import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:RXrail/app/services/background_location_service.dart';

Position _pos({required double heading, required double speed}) => Position(
      latitude: 35.7800,
      longitude: -78.6700,
      accuracy: 4,
      altitude: 0,
      heading: heading,
      speed: speed,
      timestamp: DateTime.now(),
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

void main() {
  // ~150 m north / east of the reference point.
  const north = 35.7800 + 0.00135;
  const east = -78.6700 + 0.00166;

  test('bearing: due north ≈ 0, due east ≈ 90', () {
    expect(bearingDegrees(35.78, -78.67, north, -78.67), closeTo(0, 1));
    expect(bearingDegrees(35.78, -78.67, 35.78, east), closeTo(90, 1));
  });

  test('driving north: crossing ahead passes, crossing beside is gated', () {
    final p = _pos(heading: 0, speed: 15);
    expect(isCrossingAhead(p, north, -78.67), isTrue);
    expect(isCrossingAhead(p, 35.78, east), isFalse); // parallel track
  });

  test('wraparound: heading 350 vs bearing 10 counts as ahead', () {
    final p = _pos(heading: 350, speed: 15);
    expect(isCrossingAhead(p, north + 0.0002, -78.67 + 0.0003), isTrue);
  });

  test('below driving speed the gate is bypassed', () {
    final p = _pos(heading: 0, speed: 1);
    expect(isCrossingAhead(p, 35.78, east), isTrue);
  });
}
