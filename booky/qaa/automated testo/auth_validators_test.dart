import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedapp/l10n/app_localizations.dart';
import 'package:schedapp/screens/auth/auth_validators.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final v = AuthValidators(en);

  group('isValidEmail', () {
    test('accepts ordinary addresses (trimmed)', () {
      expect(isValidEmail('a@b.co'), isTrue);
      expect(isValidEmail('  first.last+tag@mail.example.ge '), isTrue);
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        '',
        'plain',
        'a@b',
        '@b.co',
        'a@.',
        'a b@c.d',
        'a@b@c.d',
      ]) {
        expect(isValidEmail(bad), isFalse, reason: bad);
      }
    });
  });

  group('AuthValidators.email', () {
    test('empty', () {
      expect(v.email(null), en.authEmailRequired);
      expect(v.email('   '), en.authEmailRequired);
    });
    test('invalid', () => expect(v.email('nope'), en.authEmailInvalid));
    test('valid', () => expect(v.email(' me@booky.ge '), isNull));
  });

  group('passwords', () {
    test('existing password only needs to be present', () {
      expect(v.existingPassword(''), en.authPasswordRequired);
      expect(v.existingPassword('x'), isNull);
    });

    test('new password enforces minimum length', () {
      expect(v.newPassword(null), en.authNewPasswordRequired);
      expect(
        v.newPassword('a' * (authMinPasswordLength - 1)),
        en.authPasswordTooShort(authMinPasswordLength),
      );
      expect(v.newPassword('a' * authMinPasswordLength), isNull);
    });

    test('confirmation must match current password', () {
      var current = 'secret1';
      final confirm = v.confirmPassword(() => current);
      expect(confirm(''), en.authConfirmPasswordRequired);
      expect(confirm('secret2'), en.authPasswordsDoNotMatch);
      expect(confirm('secret1'), isNull);
      current = 'changed';
      expect(confirm('secret1'), en.authPasswordsDoNotMatch);
    });
  });

  group('name and business fields', () {
    test('name', () {
      expect(v.name(' '), en.authNameRequired);
      expect(v.name('A'), en.authNameTooShort(authMinNameLength));
      expect(v.name('Al'), isNull);
    });

    test('business name and category', () {
      expect(v.businessName('  '), en.authBusinessNameRequired);
      expect(v.businessName('Nail Studio'), isNull);
      expect(v.businessCategory(null), en.authBusinessCategoryRequired);
      expect(v.businessCategory('Other'), isNull);
    });
  });

  test('messages are localised', () {
    final ru = AuthValidators(lookupAppLocalizations(const Locale('ru')));
    final ka = AuthValidators(lookupAppLocalizations(const Locale('ka')));
    expect(ru.email(''), isNot(en.authEmailRequired));
    expect(ka.email(''), isNot(en.authEmailRequired));
    expect(ru.newPassword('abc'), contains('6 символов'));
  });
}
