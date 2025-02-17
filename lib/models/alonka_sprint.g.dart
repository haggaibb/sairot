// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alonka_sprint.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlonkaSprintAdapter extends TypeAdapter<AlonkaSprint> {
  @override
  final int typeId = 3;

  @override
  AlonkaSprint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlonkaSprint(
      round: fields[0] as int,
      activeParticipants: (fields[5] as List).cast<int>(),
    )
      ..alonkaCredits = (fields[1] as List).cast<int>()
      ..gerikanCredits = (fields[2] as List).cast<int>()
      ..runCredits = (fields[3] as List).cast<int>()
      ..participationCredits = (fields[4] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, AlonkaSprint obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.round)
      ..writeByte(1)
      ..write(obj.alonkaCredits)
      ..writeByte(2)
      ..write(obj.gerikanCredits)
      ..writeByte(3)
      ..write(obj.runCredits)
      ..writeByte(4)
      ..write(obj.participationCredits)
      ..writeByte(5)
      ..write(obj.activeParticipants);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlonkaSprintAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
