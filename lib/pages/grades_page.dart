import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';

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
      enableEditingMode: false,
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
      enableEditingMode: false,
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
      enableEditingMode: false,
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
      enableEditingMode: false,
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
      enableEditingMode: false,
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'מדריך למשתמש',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: const ManualWebView(
                          url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_135',
                          //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
            body: Container(
              padding: const EdgeInsets.all(1),
              child:Container(
                padding: const EdgeInsets.all(8), // Add padding for aesthetics
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool tablet = isTablet(context);
                    double gridWidth = constraints.maxWidth; // Get available screen width
                    
                    // For mobile, use original fixed widths. For tablets, use proportional widths
                    double numberColumnWidth;
                    double finalGradeWidth;
                    double systemGradeWidth;
                    double meeshulashWidth;
                    double alonkaWidth;
                    double burWidth;
                    double sakimWidth;
                    
                    if (tablet) {
                      // Calculate proportional widths for tablets
                      double totalFixedWidth = 80 + 85 + 85 + 90 + 75 + 85;
                      double availableWidth = gridWidth - totalFixedWidth;
                      numberColumnWidth = availableWidth > 90 ? availableWidth : 90;
                      double otherColumnsWidth = (gridWidth - numberColumnWidth) / 6;
                      finalGradeWidth = otherColumnsWidth;
                      systemGradeWidth = otherColumnsWidth;
                      meeshulashWidth = otherColumnsWidth;
                      alonkaWidth = otherColumnsWidth;
                      burWidth = otherColumnsWidth;
                      sakimWidth = otherColumnsWidth;
                    } else {
                      // Use original fixed widths for mobile (from the unused columns list)
                      numberColumnWidth = 90;
                      finalGradeWidth = 100;
                      systemGradeWidth = 120;
                      meeshulashWidth = 90;
                      alonkaWidth = 90;
                      burWidth = 70;
                      sakimWidth = 70;
                    }

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
                          readOnly: true,
                          frozen: PlutoColumnFrozen.start,
                          titleSpan: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(Icons.numbers, size: 20, color: Colors.black),
                              ),
                            ],
                          ),
                          field: 'number_field',
                          type: PlutoColumnType.number(),
                          width: numberColumnWidth,
                        ),
                        PlutoColumn(
                          title: 'סופי',
                          field: 'final_grade_field',
                          type: PlutoColumnType.number(),
                          width: finalGradeWidth,
                        ),
                        PlutoColumn(
                          title: 'מערכת',
                          readOnly: true,
                          field: 'system_grade_field',
                          type: PlutoColumnType.number(
                            format: '#,##0.00', // Always shows 2 digits after the decimal
                          ),
                          width: systemGradeWidth,
                        ),
                        PlutoColumn(
                          title: 'משולש',
                          readOnly: true,
                          field: 'meeshulash_field',
                          type: PlutoColumnType.number(
                            format: '#,##0.00', // Always shows 2 digits after the decimal
                          ),
                          width: meeshulashWidth,
                        ),
                        PlutoColumn(
                          title: 'אלונקה',
                          readOnly: true,
                          field: 'alonka_field',
                          type: PlutoColumnType.number(
                            format: '#,##0.00', // Always shows 2 digits after the decimal
                          ),
                          width: alonkaWidth,
                        ),
                        PlutoColumn(
                          title: 'בור',
                          readOnly: true,
                          field: 'bur_field',
                          type: PlutoColumnType.number(
                            format: '#,##0.00', // Always shows 2 digits after the decimal
                          ),
                          width: burWidth,
                        ),
                        PlutoColumn(
                          title: 'שקים',
                          readOnly: true,
                          field: 'sakim_field',
                          type: PlutoColumnType.number(
                            format: '#,##0.00', // Always shows 2 digits after the decimal
                          ),
                          width: sakimWidth,
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
