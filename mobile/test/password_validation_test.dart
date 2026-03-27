import 'package:flutter_test/flutter_test.dart';

// RegisterScreen의 _validatePassword 로직을 별도로 테스트
String? validatePassword(String password) {
  if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
  if (!password.contains(RegExp(r'[A-Za-z]'))) return '영문자를 포함해야 합니다.';
  if (!password.contains(RegExp(r'\d'))) return '숫자를 포함해야 합니다.';
  return null;
}

void main() {
  group('비밀번호 검증', () {
    test('유효한 비밀번호는 null 반환', () {
      expect(validatePassword('Password1'), isNull);
      expect(validatePassword('abc12345'), isNull);
      expect(validatePassword('ABCD1234'), isNull);
    });

    test('8자 미만이면 에러', () {
      expect(validatePassword('Pass1'), contains('8자 이상'));
      expect(validatePassword('Ab1'), contains('8자 이상'));
    });

    test('영문자 없으면 에러', () {
      expect(validatePassword('12345678'), contains('영문자'));
    });

    test('숫자 없으면 에러', () {
      expect(validatePassword('PasswordOnly'), contains('숫자'));
    });

    test('빈 문자열이면 에러', () {
      expect(validatePassword(''), isNotNull);
    });
  });
}
