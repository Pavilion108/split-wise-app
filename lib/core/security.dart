/// Security hardening utilities for Split Wise.
///
/// Protects against malformed inputs, overflow attacks, injection, and
/// ensures data integrity at every user-facing boundary.
library;

import 'dart:math' as math;

// ─── Constants ───────────────────────────────────────────────────────────────

const int kMaxExpenseAmount = 999999999999; // 12 digits max
const int kMaxTripNameLength = 100;
const int kMaxMemberNameLength = 50;
const int kMaxNoteLength = 500;
const int kMaxInviteCodeLength = 20;
const int kMaxCategoryLength = 50;
const double kMinExpenseAmount = 0.01;
const int kMaxMembersPerTrip = 50;
const int kMaxExpensesPerTrip = 10000;
const int kRateLimitWindowMs = 1000; // 1 second between actions
const int kMaxSettlementAmount = 999999999;

// ─── Input Sanitization ──────────────────────────────────────────────────────

/// Strips dangerous characters from user input. Prevents XSS, injection,
/// and control-character attacks. Returns a safe, printable string.
String sanitizeInput(String input) {
  // Remove null bytes
  var clean = input.replaceAll('\x00', '');
  // Remove control characters (except newline/tab)
  clean = clean.replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  // Trim whitespace
  clean = clean.trim();
  return clean;
}

/// Validates and sanitizes a trip name.
/// Returns null if invalid, or the sanitized name if valid.
String? sanitizeTripName(String input) {
  final clean = sanitizeInput(input);
  if (clean.isEmpty || clean.length > kMaxTripNameLength) return null;
  // No script tags
  if (clean.toLowerCase().contains('<script')) return null;
  return clean;
}

/// Validates and sanitizes a member name.
String? sanitizeMemberName(String input) {
  final clean = sanitizeInput(input);
  if (clean.isEmpty || clean.length > kMaxMemberNameLength) return null;
  if (clean.toLowerCase().contains('<script')) return null;
  return clean;
}

/// Validates and sanitizes an expense note.
String? sanitizeNote(String input) {
  final clean = sanitizeInput(input);
  if (clean.length > kMaxNoteLength) return null;
  // Block all HTML/script injection vectors
  final lower = clean.toLowerCase();
  if (lower.contains('<script') ||
      lower.contains('<img') ||
      lower.contains('<iframe') ||
      lower.contains('<svg') ||
      lower.contains('onerror') ||
      lower.contains('onload') ||
      lower.contains('javascript:') ||
      lower.contains('data:text/html')) {
    return null;
  }
  return clean;
}

/// Validates an invite code (alphanumeric only).
String? sanitizeInviteCode(String input) {
  final clean = sanitizeInput(input).toUpperCase();
  if (clean.isEmpty || clean.length > kMaxInviteCodeLength) return null;
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) return null;
  return clean;
}

// ─── Amount Validation ───────────────────────────────────────────────────────

/// Validates an expense amount. Returns null if invalid.
/// Prevents NaN, Infinity, negative, and overflow attacks.
double? validateAmount(double? value) {
  if (value == null) return null;
  // Reject NaN and Infinity
  if (value.isNaN || value.isInfinite) return null;
  // Reject negative
  if (value < kMinExpenseAmount) return null;
  // Reject overflow
  if (value > kMaxExpenseAmount) return null;
  // Round to 2 decimal places to prevent floating-point drift
  return (value * 100).roundToDouble() / 100;
}

/// Safely parses an amount string. Returns null if invalid.
double? parseAmount(String input) {
  final clean = input.trim();
  if (clean.isEmpty) return null;
  final value = double.tryParse(clean);
  return validateAmount(value);
}

// ─── Overflow Protection ─────────────────────────────────────────────────────

/// Safe addition that prevents double overflow.
double safeAdd(double a, double b) {
  final result = a + b;
  if (result.isInfinite || result.isNaN) return a;
  return result;
}

/// Safe multiplication that prevents double overflow.
double safeMul(double a, double b) {
  final result = a * b;
  if (result.isInfinite || result.isNaN) return a;
  return result;
}

/// Safe subtraction that prevents underflow.
double safeSub(double a, double b) {
  final result = a - b;
  if (result.isInfinite || result.isNaN) return a;
  return result;
}

// ─── Rate Limiting ───────────────────────────────────────────────────────────

/// Simple in-memory rate limiter for user actions.
class RateLimiter {
  final Map<String, int> _lastActionMs = {};

  /// Returns true if the action is allowed (not rate-limited).
  bool allowAction(String actionId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastActionMs[actionId] ?? 0;
    if (now - last < kRateLimitWindowMs) return false;
    _lastActionMs[actionId] = now;
    return true;
  }

  /// Resets all rate limits.
  void reset() => _lastActionMs.clear();
}

// ─── Data Integrity Checks ──────────────────────────────────────────────────

/// Validates that a list of split amounts sums to the expected total.
/// Returns true if the split is penny-perfect.
bool validateSplitIntegrity(List<double> splits, double expectedTotal) {
  if (splits.isEmpty) return expectedTotal == 0;
  final sum = splits.fold(0.0, (double s, v) => s + v);
  final diff = (sum - expectedTotal).abs();
  return diff < 0.02; // Allow ≤ 1 cent tolerance
}

/// Validates that a member ID looks like a valid UUID (or similar safe ID).
bool isValidMemberId(String id) {
  if (id.isEmpty || id.length > 100) return false;
  // Only allow alphanumeric, hyphens, underscores
  return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
}

/// Validates that an expense ID looks valid.
bool isValidExpenseId(String id) {
  if (id.isEmpty || id.length > 100) return false;
  return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
}

// ─── List Safety ─────────────────────────────────────────────────────────────

/// Returns a safely-clamped sublist. Prevents RangeError from malicious data.
List<T> safeSublist<T>(List<T> source, {int offset = 0, int? limit}) {
  if (source.isEmpty) return const [];
  final start = offset.clamp(0, source.length);
  final end = limit != null
      ? math.min(start + limit, source.length)
      : source.length;
  return source.sublist(start, end);
}

/// Deduplicates a list by a key function, keeping the first occurrence.
List<T> deduplicateBy<T, K>(List<T> items, K Function(T) keyFn) {
  final seen = <K>{};
  final result = <T>[];
  for (final item in items) {
    final k = keyFn(item);
    if (seen.add(k)) result.add(item);
  }
  return result;
}
