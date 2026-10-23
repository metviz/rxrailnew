import 'package:flutter_test/flutter_test.dart';
import 'package:RXrail/app/services/background_location_service.dart';

// Real FRA coordinates from the S26 10-22 20:25 drive (Morrisville).
const CrossingPoint pkwy = (key: '946853A', lat: 35.8110379, lng: -78.8250880);
const CrossingPoint pkwyDup = (key: '904436A', lat: 35.8111818, lng: -78.8250526);
const CrossingPoint privateRd = (key: '244168T', lat: 35.8104710, lng: -78.8244630);
// ~450 m east of pkwy: a separate crossing.
const CrossingPoint farther = (key: 'X', lat: 35.8110379, lng: -78.8200880);

InRangeCrossing r(CrossingPoint c, double d, {bool ahead = true}) =>
    (c: c, distance: d, ahead: ahead);

void main() {
  test('first approach alerts nearest ahead and consumes its duplicate', () {
    final p = pickAlert([r(pkwyDup, 194), r(pkwy, 200)], const []);
    expect(p.alert?.c.key, '904436A');
    expect(p.consumed.map((c) => c.key), containsAll(['904436A', '946853A']));
  });

  test('crossing 85 m past an alerted one is absorbed, not re-alerted', () {
    final p = pickAlert([r(pkwy, 37), r(privateRd, 120)], [pkwy, pkwyDup]);
    expect(p.alert, isNull);
    expect(p.consumed.map((c) => c.key), ['244168T']);
  });

  test('separate crossing alerts on entering range, even when not nearest', () {
    final p = pickAlert([r(pkwy, 30), r(farther, 190)], [pkwy]);
    expect(p.alert?.c.key, 'X');
  });

  test('crossing behind is not alerted', () {
    final p = pickAlert([r(farther, 150, ahead: false)], const []);
    expect(p.alert, isNull);
  });
}
