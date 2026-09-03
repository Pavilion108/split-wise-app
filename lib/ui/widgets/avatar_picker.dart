import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/avatar_service.dart';

class AvatarPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const AvatarPicker(
      {super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: AvatarService.avatars.length,
      itemBuilder: (_, i) {
        final a = AvatarService.avatars[i];
        final id = a['id'] as String;
        final emoji = a['emoji'] as String;
        final name = a['name'] as String;
        final color = Color(a['color'] as int);
        final isSel = id == selected;
        return GestureDetector(
          onTap: () => onSelect(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSel
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel ? color : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: isSel ? 36 : 30),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? color : cs.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
            .animate(target: isSel ? 1 : 0)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

Future<String?> showAvatarPicker(BuildContext context, String current) {
  String sel = current;
  final selectedController = ValueNotifier<String>(current);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with preview
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ValueListenableBuilder<String>(
                valueListenable: selectedController,
                builder: (_, selVal, __) {
                  final selAvatar = AvatarService.byId(selVal);
                  final selColor = selVal.isNotEmpty
                      ? AvatarService.colorFor(selVal)
                      : Theme.of(ctx).colorScheme.primary;
                  return Row(
                    children: [
                      // Preview circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: selColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selColor.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            selAvatar != null
                                ? selAvatar['emoji'] as String
                                : '?',
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose your avatar',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selVal.isEmpty
                                  ? 'Pick a character below'
                                  : '${selAvatar?['name'] ?? 'Unknown'} selected',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(ctx).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Scrollable grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AvatarPicker(
                  selected: sel,
                  onSelect: (v) {
                    sel = v;
                    selectedController.value = v;
                    setState(() {});
                  },
                ),
              ),
            ),
            // Sticky confirm button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: sel.isNotEmpty
                        ? () => Navigator.pop(ctx, sel)
                        : null,
                    child: const Text('Use this avatar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() => selectedController.dispose());
}
