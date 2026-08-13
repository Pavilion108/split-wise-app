import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.tripId,
    required this.baseCurrency,
  });

  final String tripId;
  final String baseCurrency;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  String _category = 'Food';
  String _currency = 'INR';
  String _splitType = 'equal';
  List<String> _subsetIds = [];
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: StreamBuilder<List<Member>>(
        stream: repo.watchMembers(widget.tripId),
        builder: (context, membersSnap) {
          final members = membersSnap.data ?? [];
          return StreamBuilder<List<Category>>(
            stream: repo.watchCategories(widget.tripId),
            builder: (context, catSnap) {
              final categories = catSnap.data ?? [];
              return _buildForm(members, categories);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(List<Member> members, List<Category> categories) {
    final myDeviceId = ref.read(deviceIdentityProvider).id;
    final me = members.firstWhereOrNull((m) => m.deviceId == myDeviceId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: [
                  for (final c in kDefaultCurrencies)
                    DropdownMenuItem(
                      value: c['code'],
                      child: Text(c['code']!),
                    ),
                ],
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ),
          ],
        ),
        if (_currency != widget.baseCurrency) ...[
          const SizedBox(height: 8),
          Text(
            'Will convert to ${widget.baseCurrency} using cached rate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final c in categories)
              DropdownMenuItem(value: c.name, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customCategoryCtrl,
          decoration: const InputDecoration(
            labelText: 'Or type a new category',
            hintText: 'Memorize for future use',
          ),
          onSubmitted: (v) async {
            if (v.trim().isEmpty) return;
            final cat = await ref
                .read(tripRepositoryProvider)
                .rememberCategory(widget.tripId, v.trim());
            setState(() {
              _category = cat.name;
              _customCategoryCtrl.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'equal', label: Text('Equal (all)')),
            ButtonSegment(value: 'custom', label: Text('Subset')),
          ],
          selected: {_splitType},
          onSelectionChanged: (s) => setState(() {
            _splitType = s.first;
            _subsetIds = [];
          }),
        ),
        if (_splitType == 'custom') ...[
          const SizedBox(height: 12),
          Text('Who splits?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in members)
                FilterChip(
                  label: Text(m.name),
                  selected: _subsetIds.contains(m.id),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _subsetIds.add(m.id);
                      } else {
                        _subsetIds.remove(m.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (me != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text('Paid by: ${me.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'What was this for?',
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')),
        );
      }
      return;
    }

    final repo = ref.read(tripRepositoryProvider);
    final members = await repo.watchMembers(widget.tripId).first;
    final me = members.firstWhereOrNull(
      (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
    );
    if (me == null) return;

    setState(() => _saving = true);

    try {
      await ref.read(expenseRepositoryProvider).addExpense(
            tripId: widget.tripId,
            authorId: me.id,
            category: _category,
            amount: amount,
            currency: _currency,
            baseCurrency: widget.baseCurrency,
            splitType: _splitType,
            allMemberIds: members.map((m) => m.id).toList(),
            subsetIds: _splitType == 'custom' ? _subsetIds : null,
            note: _noteCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
