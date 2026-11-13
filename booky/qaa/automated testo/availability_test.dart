import 'package:flutter_test/flutter_test.dart';
import 'package:schedapp/data/availability.dart';
import 'package:schedapp/data/models/artist.dart';
import 'package:schedapp/data/models/booking.dart';
import 'package:schedapp/data/models/schedule_day.dart';

// 2026-11-02 is a Monday (weekday 1).
final monday = DateTime(2026, 11, 2);
final tuesday = DateTime(2026, 11, 3);
// "now" well before the test dates so nothing is filtered as past.
final earlier = DateTime(2026, 10, 1, 8);

const artist = Artist(id: 'a1', name: 'Ana');

ScheduleDay day(
  int weekday,
  String start,
  String end, {
  String? artistId,
  bool working = true,
}) => ScheduleDay.fromJson({
  'day_of_week': weekday,
  'is_working': working,
  'start_time': start,
  'end_time': end,
  'artist_id': artistId,
});

Booking block(
  String date,
  String? time,
  Object? duration, {
  String? artistId,
  String? status,
}) => Booking.fromJson({
  'booking_date': date,
  'booking_time': time,
  'duration_minutes': duration,
  'artist_id': artistId,
  'status': status,
});

List<String> times(List<AvailabilitySlot> slots) =>
    slots.map((s) => s.timeString.substring(0, 5)).toList();

void main() {
  group('generateVenueSlots', () {
    test('slots fit fully inside working hours on a 15 min grid', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00:00', '10:00:00')],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 30,
        now: earlier,
      );
      expect(times(slots), ['09:00', '09:15', '09:30']);
      expect(slots.first.dateString, '2026-11-02');
      expect(slots.first.artistId, isNull);
    });

    test('duration longer than the working day gives no slots', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '09:45')],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 60,
        now: earlier,
      );
      expect(slots, isEmpty);
    });

    test('overlap is half-open: may start exactly when a booking ends', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '11:00')],
        bookings: [block('2026-11-02', '09:30:00', 30)],
        startDate: monday,
        endDate: monday,
        durationMinutes: 30,
        now: earlier,
      );
      // 09:00 ends exactly at 09:30 (ok); 09:15 overlaps; 09:30 overlaps;
      // 09:45 overlaps (09:45 < 10:00); 10:00 starts when booking ends (ok).
      expect(times(slots), ['09:00', '10:00', '10:15', '10:30']);
    });

    test('inactive (cancelled / rejected) bookings do not block', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '10:00')],
        bookings: [
          block('2026-11-02', '09:00', 60, status: 'canceled'),
          block('2026-11-02', '09:00', 60, status: 'declined'),
        ],
        startDate: monday,
        endDate: monday,
        durationMinutes: 60,
        now: earlier,
      );
      expect(times(slots), ['09:00']);
    });

    test('unassigned venue offers block venue-wide slots', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '10:00')],
        bookings: [block('2026-11-02', '09:00', 60)],
        startDate: monday,
        endDate: monday,
        durationMinutes: 60,
        now: earlier,
      );
      expect(slots, isEmpty);
    });

    test('rows with null time or duration are skipped, not thrown on', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '10:00')],
        bookings: [
          block('2026-11-02', null, 60),
          block('2026-11-02', '09:00', null),
        ],
        startDate: monday,
        endDate: monday,
        durationMinutes: 60,
        now: earlier,
      );
      expect(times(slots), ['09:00']);
    });

    test('past slots are filtered relative to the injected now', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '11:00'), day(2, '09:00', '10:00')],
        bookings: const [],
        startDate: DateTime(2026, 11, 1),
        endDate: tuesday,
        durationMinutes: 30,
        now: DateTime(2026, 11, 2, 9, 40),
      );
      expect(slots.map((s) => '${s.dateString} ${s.timeString}').toList(), [
        '2026-11-02 09:45:00',
        '2026-11-02 10:00:00',
        '2026-11-02 10:15:00',
        '2026-11-02 10:30:00',
        '2026-11-03 09:00:00',
        '2026-11-03 09:15:00',
        '2026-11-03 09:30:00',
      ]);
    });

    test('a slot starting exactly now is not offered', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '10:00')],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 30,
        now: DateTime(2026, 11, 2, 9, 15),
      );
      expect(times(slots), ['09:30']);
    });

    test('no schedule gives an empty list', () {
      final slots = generateVenueSlots(
        schedules: const [],
        bookings: const [],
        startDate: monday,
        endDate: tuesday,
        durationMinutes: 30,
        now: earlier,
      );
      expect(slots, isEmpty);
    });

    test('non-working and inverted (overnight) rows give no slots', () {
      final slots = generateVenueSlots(
        schedules: [
          day(1, '09:00', '17:00', working: false),
          day(2, '22:00', '02:00'),
        ],
        bookings: const [],
        startDate: monday,
        endDate: tuesday,
        durationMinutes: 30,
        now: earlier,
      );
      expect(slots, isEmpty);
    });

    test('zero or negative duration gives no slots', () {
      final slots = generateVenueSlots(
        schedules: [day(1, '09:00', '10:00')],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 0,
        now: earlier,
      );
      expect(slots, isEmpty);
    });
  });

  group('generateArtistSlots', () {
    test('only the artist\'s own bookings block (B-1 documented gap)', () {
      final slots = generateArtistSlots(
        artists: [artist],
        schedules: [day(1, '09:00', '11:00', artistId: 'a1')],
        bookings: [
          block('2026-11-02', '09:00', 60, artistId: 'a1'),
          block('2026-11-02', '10:00', 60, artistId: 'other'),
          // Unassigned offer: does not block a specific artist (yet).
          block('2026-11-02', '10:00', 60),
        ],
        startDate: monday,
        endDate: monday,
        durationMinutes: 60,
        now: earlier,
      );
      expect(times(slots), ['10:00']);
      expect(slots.single.artistId, 'a1');
      expect(slots.single.artistName, 'Ana');
    });

    test('ignores schedules of other artists', () {
      final slots = generateArtistSlots(
        artists: [artist],
        schedules: [day(1, '09:00', '10:00', artistId: 'someone-else')],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 30,
        now: earlier,
      );
      expect(slots, isEmpty);
    });

    test('results are sorted by date then time', () {
      final slots = generateArtistSlots(
        artists: [
          artist,
          const Artist(id: 'a2', name: 'Bo'),
        ],
        schedules: [
          day(1, '10:00', '10:30', artistId: 'a1'),
          day(1, '09:00', '09:30', artistId: 'a2'),
        ],
        bookings: const [],
        startDate: monday,
        endDate: monday,
        durationMinutes: 30,
        now: earlier,
      );
      expect(times(slots), ['09:00', '10:00']);
    });
  });

  group('daysInRange (DST-safe)', () {
    test('each date appears exactly once across DST changes', () {
      // Covers the EU (last Sunday of Oct / Mar) and US (first Sunday of Nov
      // / second Sunday of Mar) transitions, whatever the test machine's TZ.
      for (final range in [
        (DateTime(2026, 10, 20), DateTime(2026, 11, 10), 22),
        (DateTime(2026, 3, 1), DateTime(2026, 4, 5), 36),
      ]) {
        final days = daysInRange(range.$1, range.$2);
        final keys = days.map((d) => '${d.year}-${d.month}-${d.day}').toList();
        expect(keys.toSet().length, keys.length, reason: 'duplicate date');
        expect(days.length, range.$3);
        expect(days.every((d) => d.hour == 0 && d.minute == 0), isTrue);
      }
    });

    test('slot generation across a DST weekend has no duplicate slots', () {
      final slots = generateVenueSlots(
        schedules: [for (var d = 1; d <= 7; d++) day(d, '09:00', '09:30')],
        bookings: const [],
        startDate: DateTime(2026, 10, 24),
        endDate: DateTime(2026, 11, 3),
        durationMinutes: 30,
        now: earlier,
      );
      final keys = slots.map((s) => s.dateString).toList();
      expect(keys.length, 11);
      expect(keys.toSet().length, 11);
    });

    test('start after end gives no days', () {
      expect(daysInRange(tuesday, monday), isEmpty);
    });
  });
}
