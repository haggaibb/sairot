import 'package:flutter/material.dart';
import '../models/qualified_recruit.dart';

class FinalClassificationDialog extends StatelessWidget {
  final FinalClassification? currentClassification;

  const FinalClassificationDialog({
    this.currentClassification,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('סיווג סופי'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('בחר סיווג סופי:'),
            const SizedBox(height: 16),
            // Passed option
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentClassification == FinalClassification.passed
                    ? Colors.green
                    : Colors.grey[300],
                foregroundColor: currentClassification == FinalClassification.passed
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () => Navigator.pop(context, FinalClassification.passed),
              child: Text(FinalClassification.passed.displayName),
            ),
            const SizedBox(height: 8),
            // Rejected option
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentClassification == FinalClassification.rejected
                    ? Colors.red
                    : Colors.grey[300],
                foregroundColor: currentClassification == FinalClassification.rejected
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () => Navigator.pop(context, FinalClassification.rejected),
              child: Text(FinalClassification.rejected.displayName),
            ),
            const SizedBox(height: 8),
            // Requested different unit option
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentClassification == FinalClassification.requestedDifferentUnit
                    ? Colors.orange
                    : Colors.grey[300],
                foregroundColor: currentClassification == FinalClassification.requestedDifferentUnit
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () => Navigator.pop(context, FinalClassification.requestedDifferentUnit),
              child: Text(FinalClassification.requestedDifferentUnit.displayName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }
}





