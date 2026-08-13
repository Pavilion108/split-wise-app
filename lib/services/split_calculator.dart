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

  final share = (amount / ids.length * 100).roundToDouble() / 100;
  return [for (final id in ids) SplitInput(id, share)];
}
