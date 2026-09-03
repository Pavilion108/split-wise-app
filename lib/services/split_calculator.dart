class SplitInput {
  const SplitInput(this.memberId, this.amount);
  final String memberId;
  final double amount;
}

List<SplitInput> computeSplits({
  required double amount,
  required String type,
  required List<String> allMemberIds,
  List<String>? subsetIds,
}) {
  if (amount <= 0 || allMemberIds.isEmpty) return const [];

  final ids = type == 'custom' && subsetIds != null && subsetIds.isNotEmpty
      ? subsetIds
      : allMemberIds;

  final n = ids.length;
  if (n == 0) return const [];

  // Compute fair share with 2-decimal rounding, then assign any leftover
  // pennies to the first member so the total always matches exactly.
  final base = (amount / n * 100).floorToDouble() / 100;
  final remainder = ((amount - base * n) * 100).round() / 100;

  final splits = <SplitInput>[];
  for (var i = 0; i < n; i++) {
    final extra = i == 0 ? remainder : 0.0;
    splits.add(SplitInput(ids[i], ((base + extra) * 100).roundToDouble() / 100));
  }
  return splits;
}
