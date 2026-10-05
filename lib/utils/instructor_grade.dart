import 'package:flutter/services.dart';

/// Instructor grades are whole numbers from 1 to 9. An empty field means none.
const TextInputType instructorGradeKeyboard =
    TextInputType.numberWithOptions(decimal: false, signed: false);

class InstructorGradeInputFormatter extends TextInputFormatter {
  const InstructorGradeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final grade = int.tryParse(newValue.text);
    if (grade == null || grade < 1 || grade > 9) return oldValue;
    return newValue;
  }
}

const instructorGradeInputFormatters = [InstructorGradeInputFormatter()];

/// Stored value: 0 when unset, otherwise an integer from 1 to 9.
double normalizeInstructorGrade(num grade) {
  if (grade <= 0) return 0;
  final rounded = grade.round();
  if (rounded < 1) return 0;
  return rounded.clamp(1, 9).toDouble();
}

double parseInstructorGrade(String value) {
  final grade = int.tryParse(value.trim());
  if (grade == null) return 0;
  return normalizeInstructorGrade(grade);
}

/// Empty when no grade is stored. Otherwise a digit from 1 to 9.
String formatInstructorGrade(num grade) {
  final normalized = normalizeInstructorGrade(grade);
  if (normalized == 0) return '';
  return normalized.toInt().toString();
}
