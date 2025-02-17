// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParticipantAdapter extends TypeAdapter<Participant> {
  @override
  final int typeId = 1;

  @override
  Participant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Participant(
      number: fields[0] as int,
      name: fields[9] as String,
    )
      ..sakimGrade = fields[1] as double
      ..alonkaGrade = fields[2] as double
      ..meshulashGrade = fields[3] as double
      ..burGrade = fields[4] as double
      ..status = fields[5] as ParticipantStatus
      ..fullName = fields[6] as String
      ..instructorGrade = fields[7] as int
      ..systemGrade = fields[8] as double
      ..groupNumber = fields[10] as int
      ..meshulashPositions = (fields[11] as List).cast<int>()
      ..sakimPositions = (fields[12] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, Participant obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.sakimGrade)
      ..writeByte(2)
      ..write(obj.alonkaGrade)
      ..writeByte(3)
      ..write(obj.meshulashGrade)
      ..writeByte(4)
      ..write(obj.burGrade)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.fullName)
      ..writeByte(7)
      ..write(obj.instructorGrade)
      ..writeByte(8)
      ..write(obj.systemGrade)
      ..writeByte(9)
      ..write(obj.name)
      ..writeByte(10)
      ..write(obj.groupNumber)
      ..writeByte(11)
      ..write(obj.meshulashPositions)
      ..writeByte(12)
      ..write(obj.sakimPositions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
