import 'package:flutter_test/flutter_test.dart';
import 'package:schedapp/data/models/venue.dart';
import 'package:schedapp/services/location_service.dart';
import 'package:schedapp/services/venue_proximity.dart';

void main() {
  const tbilisi = LocationSelection(
    label: 'Tbilisi, Georgia',
    latitude: 41.7151,
    longitude: 44.8271,
  );

  test('sorts by distance, drops far venues, keeps unlocated ones last', () {
    final venues = [
      const Venue(id: 'far', name: 'Batumi', latitude: 41.64, longitude: 41.63),
      const Venue(id: 'b', name: 'Zeta', latitude: 41.73, longitude: 44.80),
      const Venue(id: 'a', name: 'Alpha', latitude: 41.715, longitude: 44.827),
      const Venue(id: 'none', name: 'No coords'),
    ];
    final result = VenueProximity.filter(venues, tbilisi);
    expect(result.map((v) => v.id), ['a', 'b', 'none']);
  });

  test('falls back to area text when no venue has coordinates', () {
    final venues = [
      const Venue(id: '1', name: 'In town', city: 'Tbilisi'),
      const Venue(id: '2', name: 'Elsewhere', city: 'Kutaisi'),
    ];
    final result = VenueProximity.filter(venues, tbilisi);
    expect(result.map((v) => v.id), ['1']);
  });

  test('no location means no nearby venues', () {
    expect(VenueProximity.filter(const [Venue(id: '1', name: 'x')], null), []);
  });

  test('distanceKm is roughly right', () {
    // Tbilisi -> Batumi is about 270 km as the crow flies.
    final d = VenueProximity.distanceKm(41.7151, 44.8271, 41.6168, 41.6367);
    expect(d, closeTo(265, 15));
  });
}
