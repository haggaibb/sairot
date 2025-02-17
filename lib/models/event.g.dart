// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      date: fields[0] as String,
      instructorId: fields[29] as String,
      eventName: fields[32] as String,
    )
      ..alonkaSprints = (fields[1] as List).cast<AlonkaSprint>()
      ..sakimRounds = (fields[2] as List).cast<SakimRound>()
      ..meshulashRounds = (fields[3] as List).cast<MeshulashRound>()
      ..participants = (fields[4] as List).cast<Participant>()
      ..ALONKA_CREDIT = fields[5] as double
      ..GERIKAN_CREDIT = fields[6] as double
      ..RUNNER_CREDIT = fields[7] as double
      ..groupNumber = fields[8] as int
      ..instructorName = fields[9] as String
      ..activeParticipants = (fields[10] as List).cast<Participant>()
      ..burGrades = (fields[11] as List).cast<Bur>()
      ..gradeSettings = fields[20] as GradeSettings
      ..burStartTime = fields[21] as DateTime?
      ..burEndTime = fields[22] as DateTime?
      ..alonkaStartTime = fields[23] as DateTime?
      ..alonkaEndTime = fields[24] as DateTime?
      ..meshulashStartTime = fields[25] as DateTime?
      ..meshulashEndTime = fields[26] as DateTime?
      ..sakimStartTime = fields[27] as DateTime?
      ..sakimEndTime = fields[28] as DateTime?
      ..finalized = fields[30] as bool
      ..isBackedUp = fields[31] as bool;
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.alonkaSprints)
      ..writeByte(2)
      ..write(obj.sakimRounds)
      ..writeByte(3)
      ..write(obj.meshulashRounds)
      ..writeByte(4)
      ..write(obj.participants)
      ..writeByte(5)
      ..write(obj.ALONKA_CREDIT)
      ..writeByte(6)
      ..write(obj.GERIKAN_CREDIT)
      ..writeByte(7)
      ..write(obj.RUNNER_CREDIT)
      ..writeByte(8)
      ..write(obj.groupNumber)
      ..writeByte(9)
      ..write(obj.instructorName)
      ..writeByte(10)
      ..write(obj.activeParticipants)
      ..writeByte(11)
      ..write(obj.burGrades)
      ..writeByte(20)
      ..write(obj.gradeSettings)
      ..writeByte(21)
      ..write(obj.burStartTime)
      ..writeByte(22)
      ..write(obj.burEndTime)
      ..writeByte(23)
      ..write(obj.alonkaStartTime)
      ..writeByte(24)
      ..write(obj.alonkaEndTime)
      ..writeByte(25)
      ..write(obj.meshulashStartTime)
      ..writeByte(26)
      ..write(obj.meshulashEndTime)
      ..writeByte(27)
      ..write(obj.sakimStartTime)
      ..writeByte(28)
      ..write(obj.sakimEndTime)
      ..writeByte(29)
      ..write(obj.instructorId)
      ..writeByte(30)
      ..write(obj.finalized)
      ..writeByte(31)
      ..write(obj.isBackedUp)
      ..writeByte(32)
      ..write(obj.eventName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
