import 'package:flutter/material.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'package:pluto_grid/pluto_grid.dart';


class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final eventController = Get.put(Controller());
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
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(' דף ציונים לקבוצה ${eventController.currentEvent.value.groupNumber} '),
          ),
          body: GetX<Controller>(builder: (_) {
            return Container(
              padding: const EdgeInsets.all(1),
              child: PlutoGrid(
                  mode: eventController.currentEvent.value.finalized?PlutoGridMode.readOnly:PlutoGridMode.normal,
                  rowColorCallback: (rowColorContext) {
                    if (rowColorContext.row.cells.entries.elementAt(1).value.value >= 5) {
                      return Colors.greenAccent;
                    } else if (rowColorContext.row.cells.entries.elementAt(2).value.value >= 5 && rowColorContext.row.cells.entries.elementAt(1).value.value<1) {
                      return Colors.greenAccent;
                    } else {
                      return Colors.white;
                    }
                  },
                  configuration: const PlutoGridConfiguration(
                      columnSize: PlutoGridColumnSizeConfig(
                          autoSizeMode: PlutoAutoSizeMode.none
                      )
                  ),
                  columns: columns,
                  rows: List.generate(_.currentEvent.value.participants.length, (index) {
                    return PlutoRow(
                      cells: {
                        'number_field': PlutoCell(value: _.currentEvent.value.participants[index].number),
                        'final_grade_field': PlutoCell(value: _.currentEvent.value.participants[index].instructorGrade),
                        'system_grade_field': PlutoCell(value: _.currentEvent.value.participants[index].systemGrade),
                        'meeshulash_field': PlutoCell(value: (_.currentEvent.value.participants[index].meshulashGrade)),
                        'alonka_field': PlutoCell(value: (_.currentEvent.value.participants[index].alonkaGrade)),
                        'bur_field': PlutoCell(value: _.currentEvent.value.participants[index].burGrade),
                        'sakim_field': PlutoCell(value: _.currentEvent.value.participants[index].sakimGrade),

                      },
                    );
                  }),
                  onChanged: (PlutoGridOnChangedEvent event) {
                    if (event.columnIdx==1 && !_.currentEvent.value.finalized) {
                      eventController.setParticipantsGrade(event.row.cells.values.first.value,event.value);
                    }
                    //print();
                  },
                  onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {
                    Get.toNamed('/performance_page/${event.row.cells.values.first.value}');
                  },
                  onLoaded: (PlutoGridOnLoadedEvent event) {
      
                  }
              ),
            );
          })),
    );
  }
}
