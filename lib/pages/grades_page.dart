import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:pluto_grid/pluto_grid.dart';


class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final eventController = Get.put(EventController());
  List<PlutoColumn> columns = [
    /// Text Column definition
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 90,
      readOnly: true,
      title: 'מספר',
      field: 'number_field',
      type: PlutoColumnType.number(),
      frozen: PlutoColumnFrozen.start,
    ),
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 100,
      title: 'ציון סופי',
      field: 'final_grade_field',
      type: PlutoColumnType.number(
        negative: true,
        format: '#',
        applyFormatOnInit: true,
        allowFirstDot: false,
      ),
    ),
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 120,
      readOnly: true,
      title: 'ציוו מערכת',
      field: 'system_grade_field',
      type: PlutoColumnType.number(
        negative: false,
        format: '#.##',
        applyFormatOnInit: true,
        allowFirstDot: false,
      ),
    ),
    /// Number Column definition
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 90,
      readOnly: true,
      title: 'משולש',
      field: 'meeshulash_field',
      type: PlutoColumnType.number(
        negative: false,
        format: '#.#',
        applyFormatOnInit: true,
        allowFirstDot: false,
      ),
    ),
    /// Select Column definition
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 90,
      readOnly: true,
      title: 'אלונקה',
      field: 'alonka_field',
      type: PlutoColumnType.number(
        negative: false,
        format: '#.#',
        applyFormatOnInit: true,
        allowFirstDot: false,
      ),
    ),
    /// Datetime Column definition
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 70,
      readOnly: true,
      title: 'בור',
      field: 'bur_field',
      type: PlutoColumnType.number(
        negative: false,
        format: '#.#',
        applyFormatOnInit: true,
        allowFirstDot: true,
      ),
    ),
    PlutoColumn(
      textAlign: PlutoColumnTextAlign.center,
      width: 70,
      readOnly: true,
      title: 'שקים',
      field: 'sakim_field',
      type: PlutoColumnType.number(
        negative: false,
        format: '#.#',
        applyFormatOnInit: true,
        allowFirstDot: true,
      ),
    ),
  ];


  @override
  void initState() {
    eventController.calculateGrades();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
            appBar: AppBar(
              //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              centerTitle: true,
              title: Text(' דף ציונים לקבוצה ${eventController.currentEvent.value.groupNumber} '),
            ),
            body: Container(
              padding: const EdgeInsets.all(1),
              child:Container(
                padding: const EdgeInsets.all(8), // Add padding for aesthetics
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double gridWidth = constraints.maxWidth; // Get available screen width
                    double columnWidth = gridWidth / 7; // Divide evenly among 7 columns

                    return PlutoGrid(
                      mode: eventController.currentEvent.value.finalized
                          ? PlutoGridMode.readOnly
                          : PlutoGridMode.normal,
                      rowColorCallback: (rowColorContext) {
                        final double finalGrade =
                            (rowColorContext.row.cells['final_grade_field']?.value as num?)?.toDouble() ?? 0.0;
                        final double systemGrade =
                            (rowColorContext.row.cells['system_grade_field']?.value as num?)?.toDouble() ?? 0.0;

                        if (finalGrade >= 5) {
                          return Colors.greenAccent;
                        } else if (systemGrade >= 5 && finalGrade < 1) {
                          return Colors.greenAccent;
                        } else {
                          return Colors.white;
                        }
                      },
                      configuration: const PlutoGridConfiguration(
                        style: PlutoGridStyleConfig(
                          activatedBorderColor: Colors.transparent, // remove cell border highlight
                        ),
                        //columnSize: PlutoGridColumnSizeConfig(autoSizeMode: PlutoAutoSizeMode.scale),
                      ),
                      columns: [
                        PlutoColumn(
                          title: 'מספר',
                          titleSpan: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(Icons.numbers, size: 20, color: Colors.black),
                              ),
                            ],
                          ),
                          field: 'number_field',
                          type: PlutoColumnType.number(),
                          width: columnWidth,
                        ),
                        PlutoColumn(
                          title: 'סופי',
                          field: 'final_grade_field',
                          type: PlutoColumnType.number(),
                          width: 80,
                        ),
                        PlutoColumn(
                          title: 'מערכת',
                          field: 'system_grade_field',
                          type: PlutoColumnType.number(),
                          width: 85,
                        ),
                        PlutoColumn(
                          title: 'משולש',
                          field: 'meeshulash_field',
                          type: PlutoColumnType.number(),
                          width: 85,
                        ),
                        PlutoColumn(
                          title: 'אלונקה',
                          field: 'alonka_field',
                          type: PlutoColumnType.number(),
                          width: 90,
                        ),
                        PlutoColumn(
                          title: 'בור',
                          field: 'bur_field',
                          type: PlutoColumnType.number(),
                          width: 75,
                        ),
                        PlutoColumn(
                          title: 'שקים',
                          field: 'sakim_field',
                          type: PlutoColumnType.number(),
                          width: 85,
                        ),
                      ],
                      rows: List.generate(
                        eventController.currentEvent.value.participants.length,
                            (index) {
                          final participant = eventController.currentEvent.value.participants[index];

                          return PlutoRow(
                            cells: {
                              'number_field': PlutoCell(value: participant.number),
                              'final_grade_field': PlutoCell(value: (participant.instructorGrade as num?)?.toDouble() ?? 0.0),
                              'system_grade_field': PlutoCell(value: (participant.systemGrade as num?)?.toDouble() ?? 0.0),
                              'meeshulash_field': PlutoCell(value: (participant.meshulashGrade as num?)?.toDouble() ?? 0.0),
                              'alonka_field': PlutoCell(value: (participant.alonkaGrade as num?)?.toDouble() ?? 0.0),
                              'bur_field': PlutoCell(value: (participant.burGrade as num?)?.toDouble() ?? 0.0),
                              'sakim_field': PlutoCell(value: (participant.sakimGrade as num?)?.toDouble() ?? 0.0),
                            },
                          );
                        },
                      ),
                      onSelected: (PlutoGridOnSelectedEvent event) {
                        print("selected");
                      },
                      onChanged: (PlutoGridOnChangedEvent event) {
                        if (event.columnIdx == 1 && !eventController.currentEvent.value.finalized) {
                          final int participantNumber = event.row.cells['number_field']?.value as int;
                          final double newGrade = (event.value as num?)?.toDouble() ?? 0.0;

                          eventController.setParticipantsGrade(participantNumber, newGrade.toInt());
                        }
                      },
                      onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {
                        final int participantNumber = event.row.cells['number_field']?.value as int;
                        Get.toNamed('/performance_page/$participantNumber');
                      },
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        event.stateManager.setSelecting(true);
                      },
                    );
                  },
                ),
              ),
            )),
      ),
    );
  }
}
