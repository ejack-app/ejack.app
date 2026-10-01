import 'package:flutter_test/flutter_test.dart';
import 'package:ejack/features/auth/domain/user.dart';

void main() {
  group('AppUser.fromJson', () {
    test('reads flat role field', () {
      final u = AppUser.fromJson({
        'id': 7,
        'username': 'driver1',
        'email': 'd@example.com',
        'first_name': 'Ali',
        'last_name': 'Driver',
        'role': 'driver',
      });
      expect(u.id, 7);
      expect(u.role, UserRole.driver);
      expect(u.fullName, 'Ali Driver');
    });

    test('falls back to nested profile.role', () {
      final u = AppUser.fromJson({
        'id': 1,
        'username': 'mgr',
        'email': 'm@e.co',
        'full_name': 'Manager',
        'profile': {'role': 'manager'},
      });
      expect(u.role, UserRole.manager);
    });

    test('maps client to customer', () {
      final u = AppUser.fromJson({
        'id': 2, 'username': 'c', 'email': '', 'role': 'client',
      });
      expect(u.role, UserRole.customer);
    });

    test('unknown role falls back to UserRole.unknown', () {
      final u = AppUser.fromJson({
        'id': 3, 'username': 'x', 'email': '', 'role': 'ghost',
      });
      expect(u.role, UserRole.unknown);
    });

    test('empty name uses username', () {
      final u = AppUser.fromJson({
        'id': 4, 'username': 'solo', 'email': '', 'first_name': '', 'last_name': '',
      });
      expect(u.fullName, 'solo');
    });
  });

  group('roleFromString', () {
    test('is case-insensitive', () {
      expect(roleFromString('DRIVER'), UserRole.driver);
      expect(roleFromString('Admin'), UserRole.admin);
    });
    test('null → unknown', () {
      expect(roleFromString(null), UserRole.unknown);
    });
  });
}
