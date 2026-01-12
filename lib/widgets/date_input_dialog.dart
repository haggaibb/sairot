import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateInputDialog extends StatefulWidget {
  final DateTime initialDate;

  const DateInputDialog({super.key, required this.initialDate});

  @override
  State<DateInputDialog> createState() => _DateInputDialogState();
}

class _DateInputDialogState extends State<DateInputDialog> {
  late TextEditingController _dayController;
  late TextEditingController _monthController;
  late TextEditingController _yearController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController(
      text: widget.initialDate.day.toString().padLeft(2, '0'),
    );
    _monthController = TextEditingController(
      text: widget.initialDate.month.toString().padLeft(2, '0'),
    );
    _yearController = TextEditingController(
      text: widget.initialDate.year.toString(),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool _validateDate() {
    final dayStr = _dayController.text.trim();
    final monthStr = _monthController.text.trim();
    final yearStr = _yearController.text.trim();

    if (dayStr.isEmpty || monthStr.isEmpty || yearStr.isEmpty) {
      setState(() {
        _errorMessage = 'יש למלא את כל השדות';
      });
      return false;
    }

    int? day = int.tryParse(dayStr);
    int? month = int.tryParse(monthStr);
    int? year = int.tryParse(yearStr);

    if (day == null || month == null || year == null) {
      setState(() {
        _errorMessage = 'יש להזין מספרים בלבד';
      });
      return false;
    }

    if (month < 1 || month > 12) {
      setState(() {
        _errorMessage = 'חודש חייב להיות בין 1 ל-12';
      });
      return false;
    }

    if (day < 1 || day > 31) {
      setState(() {
        _errorMessage = 'יום חייב להיות בין 1 ל-31';
      });
      return false;
    }

    // Check if the date is valid (e.g., not Feb 30)
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        setState(() {
          _errorMessage = 'תאריך לא תקין';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'תאריך לא תקין';
      });
      return false;
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  String? _formatDate() {
    if (!_validateDate()) {
      return null;
    }

    final day = int.parse(_dayController.text.trim());
    final month = int.parse(_monthController.text.trim());
    final year = int.parse(_yearController.text.trim());

    return "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('בחר תאריך'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day field (leftmost)
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _dayController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        hintText: 'יום',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '-',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Month field (middle)
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _monthController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        hintText: 'חודש',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '-',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Year field (rightmost)
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _yearController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        hintText: 'שנה',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              final formattedDate = _formatDate();
              if (formattedDate != null) {
                Navigator.pop(context, formattedDate);
              }
            },
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
