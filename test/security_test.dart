import 'package:flutter_test/flutter_test.dart';
import 'package:split_wise/core/security.dart';

void main() {
  group('Input Sanitization', () {
    test('sanitizes normal text', () {
      expect(sanitizeInput('Hello World'), 'Hello World');
    });

    test('removes null bytes', () {
      expect(sanitizeInput('Hello\x00World'), 'HelloWorld');
    });

    test('removes control characters', () {
      expect(sanitizeInput('Hello\x01\x02\x03World'), 'HelloWorld');
    });

    test('preserves newlines and tabs', () {
      expect(sanitizeInput('Hello\n\tWorld'), 'Hello\n\tWorld');
    });

    test('trims whitespace', () {
      expect(sanitizeInput('  Hello  '), 'Hello');
    });

    test('blocks script tags in trip name', () {
      expect(sanitizeTripName('<script>alert(1)</script>'), isNull);
    });

    test('blocks script tags in member name', () {
      expect(sanitizeMemberName('<script>xss</script>'), isNull);
    });

    test('blocks script tags in note', () {
      expect(sanitizeNote('<img onerror=alert(1)>'), isNull);
    });

    test('rejects empty trip name', () {
      expect(sanitizeTripName(''), isNull);
    });

    test('rejects empty member name', () {
      expect(sanitizeMemberName(''), isNull);
    });

    test('rejects overly long trip name', () {
      expect(sanitizeTripName('A' * 200), isNull);
    });

    test('rejects overly long member name', () {
      expect(sanitizeMemberName('A' * 100), isNull);
    });

    test('sanitizes trip name correctly', () {
      expect(sanitizeTripName('  Goa Trip 2026  '), 'Goa Trip 2026');
    });
  });

  group('Invite Code Validation', () {
    test('accepts valid alphanumeric code', () {
      expect(sanitizeInviteCode('ABC123'), 'ABC123');
    });

    test('converts to uppercase', () {
      expect(sanitizeInviteCode('abc123'), 'ABC123');
    });

    test('rejects special characters', () {
      expect(sanitizeInviteCode('ABC@123'), isNull);
    });

    test('rejects spaces', () {
      expect(sanitizeInviteCode('ABC 123'), isNull);
    });

    test('rejects empty code', () {
      expect(sanitizeInviteCode(''), isNull);
    });

    test('rejects overly long code', () {
      expect(sanitizeInviteCode('A' * 50), isNull);
    });
  });

  group('Amount Validation', () {
    test('valid amount passes', () {
      expect(validateAmount(100.50), 100.50);
    });

    test('rejects NaN', () {
      expect(validateAmount(double.nan), isNull);
    });

    test('rejects Infinity', () {
      expect(validateAmount(double.infinity), isNull);
    });

    test('rejects negative infinity', () {
      expect(validateAmount(double.negativeInfinity), isNull);
    });

    test('rejects negative amount', () {
      expect(validateAmount(-100), isNull);
    });

    test('rejects zero', () {
      expect(validateAmount(0), isNull);
    });

    test('rejects amount exceeding max', () {
      expect(validateAmount(1e15), isNull);
    });

    test('rounds to 2 decimal places', () {
      expect(validateAmount(100.456), 100.46);
      expect(validateAmount(100.454), 100.45);
    });

    test('parseAmount from valid string', () {
      expect(parseAmount('100.50'), 100.50);
    });

    test('parseAmount from invalid string', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('-100'), isNull);
      expect(parseAmount('NaN'), isNull);
    });

    test('minimum valid amount', () {
      expect(validateAmount(0.01), 0.01);
    });
  });

  group('Safe Arithmetic', () {
    test('safeAdd normal', () {
      expect(safeAdd(10, 20), 30);
    });

    test('safeAdd overflow', () {
      final result = safeAdd(double.maxFinite, 1e308);
      expect(result.isInfinite, isFalse);
    });

    test('safeMul normal', () {
      expect(safeMul(10, 20), 200);
    });

    test('safeMul overflow', () {
      final result = safeMul(double.maxFinite, 2);
      expect(result.isInfinite, isFalse);
    });

    test('safeSub normal', () {
      expect(safeSub(30, 10), 20);
    });

    test('safeSub underflow', () {
      final result = safeSub(-double.maxFinite, 1e308);
      expect(result.isInfinite, isFalse);
    });
  });

  group('Rate Limiter', () {
    test('allows first action', () {
      final limiter = RateLimiter();
      expect(limiter.allowAction('test'), isTrue);
    });

    test('blocks rapid duplicate action', () {
      final limiter = RateLimiter();
      expect(limiter.allowAction('test'), isTrue);
      expect(limiter.allowAction('test'), isFalse);
    });

    test('different actions are independent', () {
      final limiter = RateLimiter();
      expect(limiter.allowAction('action1'), isTrue);
      expect(limiter.allowAction('action2'), isTrue);
    });

    test('reset allows actions again', () {
      final limiter = RateLimiter();
      expect(limiter.allowAction('test'), isTrue);
      expect(limiter.allowAction('test'), isFalse);
      limiter.reset();
      expect(limiter.allowAction('test'), isTrue);
    });
  });

  group('Data Integrity', () {
    test('validateSplitIntegrity: exact match', () {
      expect(validateSplitIntegrity([50, 50], 100), isTrue);
    });

    test('validateSplitIntegrity: penny difference ok', () {
      expect(validateSplitIntegrity([33.34, 33.33, 33.33], 100), isTrue);
    });

    test('validateSplitIntegrity: large difference fails', () {
      expect(validateSplitIntegrity([60, 60], 100), isFalse);
    });

    test('validateSplitIntegrity: empty splits', () {
      expect(validateSplitIntegrity([], 0), isTrue);
      expect(validateSplitIntegrity([], 100), isFalse);
    });

    test('isValidMemberId: valid UUID-like', () {
      expect(isValidMemberId('abc-123_def'), isTrue);
    });

    test('isValidMemberId: rejects special chars', () {
      expect(isValidMemberId('abc@123'), isFalse);
    });

    test('isValidMemberId: rejects empty', () {
      expect(isValidMemberId(''), isFalse);
    });

    test('isValidExpenseId: valid', () {
      expect(isValidExpenseId('e1'), isTrue);
    });

    test('isValidExpenseId: rejects injection', () {
      expect(isValidExpenseId('e1; DROP TABLE'), isFalse);
    });
  });

  group('List Safety', () {
    test('safeSublist normal', () {
      expect(safeSublist([1, 2, 3, 4, 5], offset: 1, limit: 3), [2, 3, 4]);
    });

    test('safeSublist empty', () {
      expect(safeSublist<int>([]), isEmpty);
    });

    test('safeSublist offset beyond length', () {
      expect(safeSublist([1, 2, 3], offset: 10), isEmpty);
    });

    test('safeSublist limit beyond length', () {
      expect(safeSublist([1, 2, 3], limit: 10), [1, 2, 3]);
    });

    test('deduplicateBy', () {
      final items = [1, 2, 2, 3, 3, 3];
      final result = deduplicateBy(items, (int i) => i);
      expect(result, [1, 2, 3]);
    });

    test('deduplicateBy preserves first', () {
      final items = ['a', 'b', 'c'];
      final result = deduplicateBy(items, (String s) => s.length);
      expect(result, ['a']);
    });
  });
}
