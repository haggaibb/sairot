// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sakim_round.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SakimRoundAdapter extends TypeAdapter<SakimRound> {
  @override
  final int typeId = 5;

  @override
  SakimRound read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SakimRound(
      round: fields[0] as int,
      participantsInRound: (fields[1] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SakimRound obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.round)
      ..writeByte(1)
      ..write(obj.participantsInRound);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SakimRoundAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
