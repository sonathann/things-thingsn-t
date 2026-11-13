import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedapp/data/app_exception.dart';
import 'package:schedapp/data/models/booking.dart';
import 'package:schedapp/data/models/service.dart';
import 'package:schedapp/l10n/app_localizations_ru.dart';
import 'package:schedapp/screens/booking/booking_calendar_sheet.dart';
import 'package:schedapp/screens/booking/booking_helpers.dart';

Booking _booking(
  String id, {
  DateTime? date,
  int? start,
  BookingStatus status = BookingStatus.pendingReview,
}) => Booking(id: id, bookingDate: date, startMinutes: start, status: status);

void main() {
  group('BookingStatus.label', () {
    test('human labels', () {
      expect(BookingStatus.fromString('pending_review').label, 'Pending');
      expect(BookingStatus.fromString('pending').label, 'Pending');
      expect(BookingStatus.fromString('confirmed').label, 'Confirmed');
      expect(BookingStatus.fromString('accepted').label, 'Confirmed');
      expect(BookingStatus.fromString('completed').label, 'Completed');
      expect(BookingStatus.fromString('canceled').label, 'Cancelled');
      expect(BookingStatus.fromString('declined').label, 'Declined');
      expect(BookingStatus.fromString('rejected').label, 'Declined');
      expect(BookingStatus.fromString(null).label, 'Unknown');
    });
  });

  group('Booking upcoming / past', () {
    final now = DateTime(2026, 11, 3, 12, 0);

    test('startsAt combines date and minutes; null without a date', () {
      expect(
        _booking('a', date: DateTime(2026, 11, 3), start: 9 * 60 + 30).startsAt,
        DateTime(2026, 11, 3, 9, 30),
      );
      expect(_booking('a', start: 600).startsAt, isNull);
    });

    test('isUpcoming excludes past, closed, completed and undated', () {
      final tomorrow = DateTime(2026, 11, 4);
      expect(_booking('a', date: tomorrow, start: 600).isUpcoming(now), isTrue);
      expect(
        _booking('b', date: DateTime(2026, 11, 3), start: 600).isUpcoming(now),
        isFalse,
      );
      expect(
        _booking(
          'c',
          date: tomorrow,
          start: 600,
          status: BookingStatus.cancelled,
        ).isUpcoming(now),
        isFalse,
      );
      expect(
        _booking(
          'd',
          date: tomorrow,
          start: 600,
          status: BookingStatus.completed,
        ).isUpcoming(now),
        isFalse,
      );
      expect(_booking('e').isUpcoming(now), isFalse);
    });

    test('canCustomerCancel only for upcoming pending/confirmed', () {
      final tomorrow = DateTime(2026, 11, 4);
      expect(
        _booking('a', date: tomorrow, start: 0).canCustomerCancel(now),
        isTrue,
      );
      expect(
        _booking(
          'b',
          date: tomorrow,
          start: 0,
          status: BookingStatus.confirmed,
        ).canCustomerCancel(now),
        isTrue,
      );
      expect(
        _booking(
          'c',
          date: tomorrow,
          start: 0,
          status: BookingStatus.unknown,
        ).canCustomerCancel(now),
        isFalse,
      );
    });

    test('splitBookings sorts upcoming soonest-first, past newest-first', () {
      final bookings = [
        _booking('past-old', date: DateTime(2026, 10, 1), start: 600),
        _booking('soon-2', date: DateTime(2026, 11, 10), start: 600),
        _booking('undated'),
        _booking('soon-1', date: DateTime(2026, 11, 4), start: 600),
        _booking('past-new', date: DateTime(2026, 11, 1), start: 600),
        _booking(
          'cancelled-future',
          date: DateTime(2026, 12, 1),
          start: 600,
          status: BookingStatus.cancelled,
        ),
      ];

      final (upcoming, past) = splitBookings(bookings, now);

      expect(upcoming.map((b) => b.id), ['soon-1', 'soon-2']);
      expect(past.map((b) => b.id), [
        'cancelled-future',
        'past-new',
        'past-old',
        'undated',
      ]);
    });

    test('displayPrice falls back to the service price', () {
      const service = Service(id: 's', venueId: 'v', name: 'Cut', price: 40);
      expect(const Booking(id: 'a', service: service).displayPrice, 40);
      expect(
        const Booking(
          id: 'a',
          service: service,
          estimatedPrice: 55,
        ).displayPrice,
        55,
      );
    });
  });

  group('booking helpers', () {
    test('price and duration labels handle nulls', () {
      expect(priceLabel(25), '25 GEL');
      expect(priceLabel(null), 'Price on request');
      expect(durationLabel(60), '60 min');
      expect(durationLabel(null), 'Duration varies');
      expect(durationLabel(0), 'Duration varies');
    });

    test('errorMessage translates by kind, fallback otherwise', () {
      expect(
        errorMessage(const AppException('x', kind: AppErrorKind.slotTaken)),
        AppException.slotTaken,
      );
      expect(
        errorMessage(
          const AppException('x', kind: AppErrorKind.slotTaken),
          l10n: AppLocalizationsRu(),
        ),
        AppLocalizationsRu().errorSlotTaken,
      );
      expect(errorMessage(StateError('boom'), fallback: 'Oops'), 'Oops');
      expect(errorMessage(const AppException('x'), fallback: 'Oops'), 'Oops');
      expect(errorMessage(StateError('boom')), AppException.generic);
    });

    test('formatLongDate', () {
      expect(formatLongDate(DateTime(2026, 11, 3)), 'November 3, 2026');
      expect(monthNames, hasLength(12));
    });

    test('serviceAllowsConsultation guesses from name/category', () {
      expect(
        serviceAllowsConsultation(
          const Service(id: 's', venueId: 'v', name: 'Small Tattoo'),
        ),
        isTrue,
      );
      expect(
        serviceAllowsConsultation(
          const Service(id: 's', venueId: 'v', name: 'Haircut'),
        ),
        isFalse,
      );
    });
  });

  testWidgets('calendar sheet returns a tapped available day', (tester) async {
    final now = DateTime.now();
    // A day later this month when possible, otherwise next month (both are
    // inside the browsable range).
    final available = DateTime(now.year, now.month + 1, 15);
    DateTime? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showBookingCalendarSheet(
                context: context,
                availableDates: {available},
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Opens on the month of the first available date.
    expect(
      find.text('${monthNames[available.month - 1]} ${available.year}'),
      findsWidgets,
    );

    // An unavailable day does nothing.
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(picked, isNull);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(picked, available);
  });
}
