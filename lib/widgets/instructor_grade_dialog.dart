import 'package:flutter/material.dart';

/// Opens a large 1–9 pad. Returns 1–9, 0 when cleared, or null if dismissed.
Future<int?> showInstructorGradeDialog(
  BuildContext context, {
  int? selected,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      final shortest = MediaQuery.sizeOf(context).shortestSide;
      final buttonSize = shortest >= 600 ? 92.0 : 76.0;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('בחר ציון'),
          content: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: buttonSize * 3 + 24,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var number = 1; number <= 9; number++)
                    _GradeKey(
                      number: number,
                      size: buttonSize,
                      selected: selected == number,
                      onTap: () => Navigator.of(context).pop(number),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (selected != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(0),
                child: const Text('נקה'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
          ],
        ),
      );
    },
  );
}

class _GradeKey extends StatelessWidget {
  final int number;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  const _GradeKey({
    required this.number,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primary : colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.bold,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
