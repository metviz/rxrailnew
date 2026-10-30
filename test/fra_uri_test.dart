import 'package:flutter_test/flutter_test.dart';
import 'package:RXrail/app/services/crossing_cache_service.dart';

void main() {
  test('FRA query groups, orders, pages and filters stray quotes', () {
    final q = Uri.decodeFull(fraCrossingsUri(35.76386, -78.93443, page: 2).query);
    expect(q, contains(r'$group=crossingid,latitude,longitude'));
    expect(q, contains(r'$order=crossingid'));
    expect(q, contains(r'$limit=1000&$offset=2000'));
    expect(q, contains("latitude NOT LIKE '%''%'"));
    expect(q, contains("longitude NOT LIKE '%°%'"));
  });

  test('state box query uses the given bounds', () {
    final q = Uri.decodeFull(fraCrossingsInBox(33.8, 36.6, -84.3, -75.4).query);
    expect(q, contains('latitude::number>33.800000'));
    expect(q, contains('longitude::number<-75.400000'));
    expect(q, contains(r'$offset=0'));
  });
}
