import 'dart:core';
import 'package:hive/hive.dart';
part 'types.g.dart';

@HiveType(typeId: 100)
enum ParticipantStatus {
  @HiveField(0)
  Active,
  @HiveField(1)
  Droped,
}

@HiveType(typeId: 101)
enum AlonkaCreditTypes {
  @HiveField(0)
  Alonka,
  @HiveField(1)
  Gerikan,
  @HiveField(3)
  Runner,
  @HiveField(4)
  Participated
}

