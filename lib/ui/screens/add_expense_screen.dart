import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../ui/widgets/responsive_layout.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.tripId,
    required this.baseCurrency,
    this.editExpense,
  });

  final String tripId;
  final String baseCurrency;
  final Expense? editExpense;

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
  String? _paidById;
  bool _paidByIdInitialized = false;

  bool get _isEditing => widget.editExpense != null;

  /// Exchange rate (1 [_currency] = [_rate] [baseCurrency]).
  double? _rate;
  String _rateMode = 'auto';
  bool _fetchingRate = false;
  DateTime? _rateFetchedAt;
  String? _rateError;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.editExpense!;
      _amountCtrl.text = e.amount.toString();
      _noteCtrl.text = e.note;
      _category = e.category;
      _currency = e.currency;
      _splitType = e.splitType;
      _paidById = e.authorId;
    }
  }

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
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
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
      body: CenteredBody(
        child: StreamBuilder<List<Member>>(
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
      ),
    );
  }

  Widget _buildForm(List<Member> members, List<Category> categories) {
    final myDeviceId = ref.read(deviceIdentityProvider).id;
    final me = members.firstWhereOrNull((m) => m.deviceId == myDeviceId);

    // Default paid by to current user on first render.
    if (!_isEditing && !_paidByIdInitialized && me != null) {
      _paidByIdInitialized = true;
      _paidById = me.id;
    }

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
                onChanged: (v) {
                  setState(() {
                    _currency = v!;
                    _rate = null;
                    _rateError = null;
                    _rateFetchedAt = null;
                  });
                  if (_currency != widget.baseCurrency && _rateMode == 'auto') {
                    _fetchRate();
                  }
                },
              ),
            ),
          ],
        ),
        if (_currency != widget.baseCurrency) _buildRateSection(),
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
        if (_splitType == 'equal') ...[
          const SizedBox(height: 6),
          Text(
            'Split equally among all ${members.length} current members. '
            'New members who join later will be included in future equal splits.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
        ],
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
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Paid by'),
          items: [
            for (final m in members)
              DropdownMenuItem(value: m.id, child: Text(m.name)),
          ],
          value: _paidById,
          onChanged: (v) => setState(() => _paidById = v),
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

  Widget _buildRateSection() {
    final cs = Theme.of(context).colorScheme;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final preview = (_rate != null && amount > 0) ? amount * _rate! : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Exchange rate to ${widget.baseCurrency}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'auto', label: Text('Auto (live)')),
            ButtonSegment(value: 'manual', label: Text('Manual')),
          ],
          selected: {_rateMode},
          onSelectionChanged: (s) => setState(() => _rateMode = s.first),
        ),
        const SizedBox(height: 8),
        if (_rateMode == 'auto')
          _fetchingRate
              ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Fetching live rate…'),
                  ],
                )
              : FilledButton.icon(
                  onPressed: _fetchRate,
                  icon: const Icon(Icons.sync),
                  label: const Text('Get live rate'),
                ),
        if (_rateMode == 'manual')
          TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '1 ${_currency} = ? ${widget.baseCurrency}',
            ),
            onChanged: (v) =>
                setState(() => _rate = double.tryParse(v.trim())),
          ),
        if (_rate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _rateMode == 'auto'
                  ? 'Live market rate: 1 ${_currency} = '
                      '${_rate!.toStringAsFixed(4)} ${widget.baseCurrency}'
                      '${_rateFetchedAt != null ? '  · fetched ${TimeOfDay.fromDateTime(_rateFetchedAt!).format(context)}' : ''}'
                  : 'Manual rate: 1 ${_currency} = '
                      '${_rate!.toStringAsFixed(4)} ${widget.baseCurrency}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 4),
          Text(
            '≈ ${formatMoney(preview, widget.baseCurrency)} '
            'in ${widget.baseCurrency}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
        if (_rateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _rateError!,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _fetchRate() async {
    if (_currency == widget.baseCurrency) return;
    setState(() => _fetchingRate = true);
    try {
      final currencyService = ref.read(currencyServiceProvider);

      // Check if cached rate is stale and warn.
      final isStale = await currencyService.isRateStale(
        fromCurrency: _currency,
        toBase: widget.baseCurrency,
      );

      final live = await currencyService.fetchLiveRate(
            fromCurrency: _currency,
            toBase: widget.baseCurrency,
          );
      if (mounted) {
        setState(() {
          _rate = live.rate;
          _rateFetchedAt = live.fetchedAt;
          _rateError = isStale ? 'Previous rate was stale (>7 days old). Using fresh rate.' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _rateError = 'Could not fetch live rate: $e');
      }
    } finally {
      if (mounted) setState(() => _fetchingRate = false);
    }
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

    if (_currency != widget.baseCurrency && _rate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set the exchange rate (auto or manual) first'),
          ),
        );
      }
      return;
    }

    final repo = ref.read(tripRepositoryProvider);
    final members = await repo.watchMembers(widget.tripId).first;
    final me = members.firstWhereOrNull(
      (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
    );

    // Default paidById to current device's member on first submit.
    if (_paidById == null) _paidById = me?.id;
    final paidById = _paidById;
    if (paidById == null) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        final old = widget.editExpense!;
        final changes = <String>[];
        if (old.amount != amount) changes.add('Amount: ${formatMoney(old.amount, old.currency)} → ${formatMoney(amount, _currency)}');
        if (old.category != _category) changes.add('Category: ${old.category} → $_category');
        if (old.currency != _currency) changes.add('Currency: ${old.currency} → $_currency');
        if (old.note != _noteCtrl.text.trim()) changes.add('Note: "${old.note}" → "${_noteCtrl.text.trim()}"');
        if (old.splitType != _splitType) changes.add('Split: ${old.splitType} → $_splitType');

        await ref.read(expenseRepositoryProvider).editExpense(
          original: old,
          amount: amount,
          currency: _currency,
          category: _category,
          splitType: _splitType,
          subsetIds: _splitType == 'custom' ? _subsetIds : null,
          note: _noteCtrl.text.trim(),
          rate: _rate,
          baseCurrency: widget.baseCurrency,
          allMemberIds: members.map((m) => m.id).toList(),
        );

        if (mounted && changes.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated: ${changes.join(", ")}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        await ref.read(expenseRepositoryProvider).addExpense(
          tripId: widget.tripId,
          authorId: paidById,
          category: _category,
          amount: amount,
          currency: _currency,
          baseCurrency: widget.baseCurrency,
          splitType: _splitType,
          allMemberIds: members.map((m) => m.id).toList(),
          subsetIds: _splitType == 'custom' ? _subsetIds : null,
          note: _noteCtrl.text.trim(),
          rate: _rate,
          rateSource: _rateMode == 'auto' ? 'live' : 'manual',
        );
      }
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
