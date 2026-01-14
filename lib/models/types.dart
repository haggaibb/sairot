import 'dart:core';


enum ParticipantStatus {
  Active,
  Droped,
}

enum AlonkaCreditTypes {
  Alonka,
  Gerikan,
  Runner,
  Participated
}

enum SortColumn {
  number,
  finalGrade,
  systemGrade,
  meshulash,
  alonka,
  bur,
  sakim,
  instructorGrade,
  instructorMeshulash,
  instructorAlonka,
  instructorSakim,
}

enum SortDirection {
  ascending,
  descending,
  none,
}

enum GroupStrength {
  weak,
  normal,
  strong,
}

enum ExerciseType {
  meshulash,
  alonka,
  sakim,
  bur,
  leadership,
  interview,
  generic,
}

extension ExerciseTypeExtension on ExerciseType {
  String get name {
    switch (this) {
      case ExerciseType.meshulash:
        return 'meshulash';
      case ExerciseType.alonka:
        return 'alonka';
      case ExerciseType.sakim:
        return 'sakim';
      case ExerciseType.bur:
        return 'bur';
      case ExerciseType.leadership:
        return 'leadership';
      case ExerciseType.interview:
        return 'interview';
      case ExerciseType.generic:
        return 'generic';
    }
  }

  static ExerciseType? fromString(String name) {
    switch (name.toLowerCase()) {
      case 'meshulash':
        return ExerciseType.meshulash;
      case 'alonka':
        return ExerciseType.alonka;
      case 'sakim':
        return ExerciseType.sakim;
      case 'bur':
        return ExerciseType.bur;
      case 'leadership':
        return ExerciseType.leadership;
      case 'interview':
        return ExerciseType.interview;
      case 'generic':
        return ExerciseType.generic;
      default:
        return null;
    }
  }
}

