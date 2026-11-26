import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_provider.dart';

/// Pre-populates a realistic demo ledger ("Swiss Alps Expedition 2026")
/// for Amazon Appstore certification reviewers on Fire OS devices.
Future<void> seedReviewerSampleTrip(WidgetRef ref) async {
  try {
    final tripRepo = ref.read(tripRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);
    const reviewerId = 'amz_reviewer_test_user';
    const reviewerEmail = 'reviewer@amazon-test.com';

    // Check if reviewer already has any trips
    final existingTrips = await tripRepo
        .watchTripsForUser(
          googleId: reviewerId,
          email: reviewerEmail,
        )
        .first;

    if (existingTrips.isNotEmpty) return;

    // 1. Create Sample Trip: "Swiss Alps Expedition 2026"
    final trip = await tripRepo.createTrip(
      name: 'Swiss Alps Expedition 2026',
      baseCurrency: 'EUR',
      memberName: 'Spliti5 Reviewer',
      deviceId: 'amz_device_review',
      googleId: reviewerId,
      emailLower: reviewerEmail,
    );

    // Get the author member ID
    final members = await tripRepo.watchMembers(trip.id).first;
    final reviewerMember = members.firstWhere((m) => m.name == 'Spliti5 Reviewer');

    // 2. Add sample travel companions
    final elena = await tripRepo.addMember(
      tripId: trip.id,
      name: 'Elena Rostova',
      deviceId: 'demo_dev_elena',
      avatarColor: 0xFF2E7D32,
    );
    final liam = await tripRepo.addMember(
      tripId: trip.id,
      name: 'Liam Vance',
      deviceId: 'demo_dev_liam',
      avatarColor: 0xFF0288D1,
    );

    final allMemberIds = [reviewerMember.id, elena.id, liam.id];

    // 3. Add realistic split expenses
    await expenseRepo.addExpense(
      tripId: trip.id,
      authorId: reviewerMember.id,
      category: 'Lodging',
      amount: 450.00,
      currency: 'EUR',
      baseCurrency: 'EUR',
      splitType: 'equal',
      allMemberIds: allMemberIds,
      note: 'Zermatt Chalet Reservation',
    );

    await expenseRepo.addExpense(
      tripId: trip.id,
      authorId: elena.id,
      category: 'Transport',
      amount: 180.00,
      currency: 'EUR',
      baseCurrency: 'EUR',
      splitType: 'equal',
      allMemberIds: allMemberIds,
      note: 'Glacier Express Scenic Rail Passes',
    );

    await expenseRepo.addExpense(
      tripId: trip.id,
      authorId: liam.id,
      category: 'Food',
      amount: 120.00,
      currency: 'EUR',
      baseCurrency: 'EUR',
      splitType: 'equal',
      allMemberIds: allMemberIds,
      note: 'Matterhorn Alpine Fondue Dinner',
    );
  } catch (e) {
    debugPrint('Reviewer seed notice: $e');
  }
}
