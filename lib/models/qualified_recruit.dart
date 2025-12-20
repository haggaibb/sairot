import 'package:cloud_firestore/cloud_firestore.dart';

enum FinalClassification {
  passed,
  rejected,
  requestedDifferentUnit,
}

extension FinalClassificationExtension on FinalClassification {
  String get valueAsString => toString().split('.').last;
  
  String get displayName {
    switch (this) {
      case FinalClassification.passed:
        return 'עבר ועדה';
      case FinalClassification.rejected:
        return 'נדחה';
      case FinalClassification.requestedDifferentUnit:
        return 'ביקש יחידה אחרת';
    }
  }
  
  static FinalClassification? fromString(String? value) {
    if (value == null) return null;
    return FinalClassification.values.firstWhere(
      (e) => e.valueAsString == value,
      orElse: () => FinalClassification.passed,
    );
  }
}

class QualifiedRecruit {
  QualifiedRecruit({
    required this.participantNumber,
    required this.groupNumber,
    required this.instructorId,
    required this.instructorName,
    required this.instructorGrade,
    required this.systemGrade,
    required this.fullName,
    required this.name,
    required this.alonkaGrade,
    required this.sakimGrade,
    required this.meshulashGrade,
    required this.burGrade,
    required this.eventName,
    required this.date,
    this.finalizedAt,
  });

  int participantNumber;
  int groupNumber;
  String instructorId;
  String instructorName;
  int instructorGrade;
  double systemGrade;
  String fullName;
  String name;
  double alonkaGrade;
  double sakimGrade;
  double meshulashGrade;
  double burGrade;
  Timestamp? finalizedAt;
  String eventName;
  String date;
  // Note: finalClassification, classifiedAt, classifiedBy removed - sairot app doesn't handle final classification

  /// Convert QualifiedRecruit to JSON format for Firestore
  /// Note: This method is kept for backward compatibility but new structure uses participantData
  Map<String, dynamic> toJson() {
    return {
      'participantNumber': participantNumber,
      'groupNumber': groupNumber,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'instructorGrade': instructorGrade,
      'systemGrade': systemGrade,
      'fullName': fullName,
      'name': name,
      'alonkaGrade': alonkaGrade,
      'sakimGrade': sakimGrade,
      'meshulashGrade': meshulashGrade,
      'burGrade': burGrade,
      'finalizedAt': finalizedAt ?? FieldValue.serverTimestamp(),
      'eventName': eventName,
      'day': date, // Use 'day' for consistency
      'date': date, // Keep for backward compatibility
      // Note: finalClassification removed - sairot app doesn't handle this
    };
  }

  /// Create an instance of QualifiedRecruit from JSON
  /// Supports both old flat structure and new unified structure with participantData
  factory QualifiedRecruit.fromJson(Map<String, dynamic> json) {
    // Try to extract from participantData first (new structure)
    if (json['participantData'] != null) {
      return QualifiedRecruit.fromUnifiedStructure(json);
    }
    
    // Fall back to old flat structure
    return QualifiedRecruit(
      participantNumber: json['participantNumber'] ?? 0,
      groupNumber: json['groupNumber'] ?? 0,
      instructorId: json['instructorId'] ?? '',
      instructorName: json['instructorName'] ?? '',
      instructorGrade: json['instructorGrade'] ?? 0,
      systemGrade: (json['systemGrade'] ?? 0).toDouble(),
      fullName: json['fullName'] ?? '',
      name: json['name'] ?? '',
      alonkaGrade: (json['alonkaGrade'] ?? 0).toDouble(),
      sakimGrade: (json['sakimGrade'] ?? 0).toDouble(),
      meshulashGrade: (json['meshulashGrade'] ?? 0).toDouble(),
      burGrade: (json['burGrade'] ?? 0).toDouble(),
      eventName: json['eventName'] ?? '',
      date: json['day'] ?? json['date'] ?? '', // Support both 'day' and 'date'
      finalizedAt: json['finalizedAt'] as Timestamp?,
      // Note: finalClassification removed - sairot app doesn't handle this
    );
  }

  /// Create QualifiedRecruit from unified structure with participantData
  factory QualifiedRecruit.fromUnifiedStructure(Map<String, dynamic> data) {
    // Extract participant data from nested participantData
    Map<String, dynamic>? participantData = data['participantData'] as Map<String, dynamic>?;
    
    if (participantData == null) {
      throw Exception('Cannot create QualifiedRecruit: missing participantData');
    }
    
    // Extract participant fields from participantData
    return QualifiedRecruit(
      participantNumber: data['participantNumber'] ?? participantData['number'] ?? 0,
      groupNumber: data['groupNumber'] ?? participantData['groupNumber'] ?? 0,
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'] ?? '',
      instructorGrade: participantData['instructorGrade'] ?? 0,
      systemGrade: (participantData['systemGrade'] ?? 0).toDouble(),
      fullName: participantData['fullName'] ?? '',
      name: participantData['name'] ?? '',
      alonkaGrade: (participantData['alonkaGrade'] ?? 0).toDouble(),
      sakimGrade: (participantData['sakimGrade'] ?? 0).toDouble(),
      meshulashGrade: (participantData['meshulashGrade'] ?? 0).toDouble(),
      burGrade: (participantData['burGrade'] ?? 0).toDouble(),
      eventName: data['eventName'] ?? '',
      date: data['day'] ?? data['date'] ?? '', // Support both 'day' and 'date'
      finalizedAt: data['finalizedAt'] as Timestamp?,
      // Note: finalClassification removed - sairot app doesn't handle this
    );
  }
}

