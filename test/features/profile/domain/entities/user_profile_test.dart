import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('an empty name falls back to the wallet surface', () {
      const profile = UserProfile();

      expect(profile.hasName, isFalse);
      expect(profile.greetingName, 'Wallet');
      expect(profile.initials, '?');
    });

    test('a set name is greeted and initialed', () {
      const profile = UserProfile(displayName: '  Ada Lovelace  ');

      expect(profile.hasName, isTrue);
      expect(profile.greetingName, 'Ada Lovelace');
      expect(profile.initials, 'AL');
    });
  });
}
