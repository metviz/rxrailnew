import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:RXrail/app/services/crash_hotspots.dart';

// Glenwood Ave at Lead Mine Rd, the top Wake cluster.
const Hotspot glenwood =
    (lat: 35.83817, lng: -78.67405, label: 'Glenwood Ave at Lead Mine Rd', stretch: false);
// The same point as a ~1-mile stretch.
const Hotspot stretch =
    (lat: 35.83817, lng: -78.67405, label: 'I 440', stretch: true);

final now = DateTime(2026, 11, 23, 18);

/// [metresSouth] of the hotspot, driving at [speed] m/s on [heading].
Position at(double metresSouth, {double speed = 15, double heading = 0}) =>
    Position(
      latitude: glenwood.lat - metresSouth / 111195,
      longitude: glenwood.lng,
      accuracy: 5,
      altitude: 0,
      heading: heading,
      speed: speed,
      timestamp: now,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

void main() {
  test('junction ahead within 300 m alerts', () {
    expect(pickHotspot(at(250), [glenwood], {}, now), glenwood);
  });

  test('junction is silent beyond 300 m, a stretch alerts out to 800 m', () {
    expect(pickHotspot(at(600), [glenwood], {}, now), isNull);
    expect(pickHotspot(at(600), [stretch], {}, now), stretch);
    expect(pickHotspot(at(900), [stretch], {}, now), isNull);
  });

  test('silent below driving speed', () {
    expect(pickHotspot(at(100, speed: 1), [glenwood], {}, now), isNull);
  });

  test('silent when the hotspot is behind', () {
    expect(pickHotspot(at(100, heading: 180), [glenwood], {}, now), isNull);
  });

  test('silent again for 30 minutes after an alert, then alerts', () {
    final alerted = {hotspotKey(glenwood): now};
    final later = now.add(const Duration(minutes: 29));
    expect(pickHotspot(at(100), [glenwood], alerted, later), isNull);
    expect(
        pickHotspot(at(100), [glenwood], alerted,
            now.add(const Duration(minutes: 31))),
        glenwood);
  });

  test('every published state file parses and names its roads', () {
    final files = Directory('hotspots').listSync().whereType<File>().toList();
    expect(files.length, 51);
    for (final f in files) {
      final spots = parseHotspots(f.readAsStringSync());
      expect(spots.length, greaterThanOrEqualTo(50), reason: f.path);
      expect(spots.every((h) => h.label.isNotEmpty), isTrue, reason: f.path);
    }
  });

  test('a downloaded state replaces the bundled copy of that state', () {
    const tx = '[[32.7,-96.8,"I-30","s"]]';
    const ncOld = '[[35.8,-78.6,"Old","j"]]';
    const ncNew = '[[35.9,-78.7,"New","j"],[35.7,-78.5,"Newer","s"]]';
    final labels = mergeHotspots({'NC': ncOld}, {'TX': tx, 'NC': ncNew})
        .map((h) => h.label);
    expect(labels, unorderedEquals(['I-30', 'New', 'Newer']));
  });

  test('a corrupt downloaded file is skipped, the rest still load', () {
    final spots = mergeHotspots(
        {'NC': '[[35.8,-78.6,"Old","j"]]'}, {'TX': '<html>404', 'NC': '{'});
    expect(spots.single.label, 'Old');
  });

  test('state file URL', () {
    expect(hotspotsUri('TX').toString(),
        'https://raw.githubusercontent.com/metviz/rxrailnew/main/hotspots/TX.json');
  });

  test('bundled asset parses', () {
    final spots = parseHotspots(
        File('assets/data/crash_hotspots_nc.json').readAsStringSync());
    expect(spots.length, greaterThan(500));
    expect(spots.first.label, 'Glenwood Ave at Lead Mine Rd');
    expect(spots.first.stretch, isFalse);
    expect(spots.last.stretch, isTrue);
  });
}
