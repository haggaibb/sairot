import 'package:flutter/material.dart';
import 'admin_controller.dart';
import 'package:get/get.dart';
import '../widgets/tablet_group_status_bar.dart';
import '../widgets/last_update_widget.dart';

class AdminLiveEventPage extends StatefulWidget {
  const AdminLiveEventPage({super.key});

  @override
  State<AdminLiveEventPage> createState() => _AdminLiveEventPageState();
}

class _AdminLiveEventPageState extends State<AdminLiveEventPage> {
  final adminController = Get.put(AdminController());
  //final connectivityController = Get.put(ConnectivityController());

  @override
  void initState() {
    DateTime today = DateTime.now();
    String formattedToday =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
    //adminController.startLiveListener(formattedToday);
    /// line below is for debug mode.
    adminController.startLiveListener('22-02-2025');
    super.initState();
  }

  @override
  void dispose() {
    adminController
        .stopLiveListener(); // ✅ Cancel timer when leaving the screen
    print("🚫 Timer canceled!");
    super.dispose();
  }

  /// 📏 Measure the max width required for a column
  double measureMaxColumnWidth(
      List<String> texts, TextStyle style, BuildContext context) {
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    double maxWidth = 0.0;
    for (var text in texts) {
      painter.text = TextSpan(text: text, style: style);
      painter.layout();
      maxWidth = maxWidth < painter.width ? painter.width : maxWidth;
    }
    return maxWidth + 16; // Add some padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('סטטוס ארוע פעיל')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600; // 📌 Detect tablet
            double availableWidth = constraints.maxWidth;
            return Obx(() {
              if (adminController.isDownloadingLiveEvents.value) {
                return Center(
                    child:
                        CircularProgressIndicator()); // ✅ Show loader while fetching data
              }
              if (adminController.liveEvents.isEmpty) {
                return Center(child: Text("No active groups found."));
              }
              // 📏 Measure text widths for dynamic column sizing
              TextStyle textStyle = TextStyle(fontSize: isTablet ? 18 : 14);
              double col1Width = measureMaxColumnWidth(
                  adminController.liveEvents
                      .map((e) => e.groupNumber.toString())
                      .toList(),
                  textStyle,
                  context);
              double col2Width = measureMaxColumnWidth(
                  adminController.liveEvents
                      .map((e) =>
                          adminController.getInstructorName(e.instructorId))
                      .toList(),
                  textStyle,
                  context);
              double col4Width = 50; // Icon column fixed size
              double col5Width = measureMaxColumnWidth(
                adminController.liveEvents
                    .map((e) => "לפני      דקות")
                    .toList(),
                textStyle,
                context,
              );
              // 📌 Distribute remaining width to the 3rd column ("סטטוס")
              double remainingWidth = availableWidth -
                  (col1Width + col2Width + col4Width + col5Width);
              remainingWidth = remainingWidth > 100
                  ? remainingWidth
                  : 100; // Minimum width for "סטטוס"
              return SingleChildScrollView(
                scrollDirection: Axis.vertical, // ✅ Prevents vertical overflow
                child: Column(
                  children: [
                    Text(adminController.liveEvents[0].date,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 250 : 80, vertical: 10),
                      padding: EdgeInsets.only(
                          left: 60, right: 10, top: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            /// number of groups
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(' מספר הקבוצות :',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                                Text(
                                    adminController.liveEvents.length
                                        .toString(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                              ],
                            ),

                            /// active groups
                            Row(
                              //mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(' קבוצות פעילות :',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                                Text(
                                    adminController.liveEvents
                                        .where((e) =>
                                            adminController.getGroupStatus(
                                                e.groupNumber.toString()) !=
                                            -4)
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                              ],
                            ),

                            /// groups that are done
                            Row(
                              //mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(' קבוצות שסיימו :',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                                Text(
                                    adminController.liveEvents
                                        .where((e) =>
                                            adminController.getGroupStatus(
                                                e.groupNumber.toString()) ==
                                            -4)
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth:
                                availableWidth), // ✅ Prevents horizontal overflow
                        child: Align(
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            scrollDirection: Axis
                                .horizontal, // ✅ Allows scrolling if content overflows
                            child: DataTable(
                              columnSpacing: 10.0,
                              border: TableBorder.all(
                                  width: 2.0, color: Colors.black26),
                              columns: [
                                DataColumn(
                                    label: SizedBox(
                                        width: col1Width,
                                        child: Text('#',
                                            style: TextStyle(
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight.bold)))),
                                DataColumn(
                                    label: Container(
                                        width: col2Width,
                                        child: Text('מדריך',
                                            style: TextStyle(
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight.bold)))),
                                DataColumn(
                                    label: SizedBox(
                                        width: isTablet ? 100 : null,
                                        child: Text('סטטוס',
                                            style: TextStyle(
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight
                                                    .bold)))), // ✅ Uses remaining space
                                DataColumn(
                                    label: SizedBox(
                                        width: col4Width,
                                        child: Text('סגור',
                                            style: TextStyle(
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight.bold)))),
                                DataColumn(
                                    label: SizedBox(
                                        width: col5Width,
                                        child: Text('עדכון אחרון',
                                            style: TextStyle(
                                                fontSize: isTablet ? 20 : 17,
                                                fontWeight: FontWeight.bold)))),
                              ],
                              rows: adminController.liveEvents.map((event) {
                                return DataRow(cells: [
                                  DataCell(SizedBox(
                                      width: col1Width,
                                      child:
                                          Text(event.groupNumber.toString()))),
                                  DataCell(SizedBox(
                                      width: col2Width,
                                      child: Text(
                                          adminController.getInstructorName(
                                              event.instructorId)))),
                                  DataCell(SizedBox(
                                      width: isTablet ? 300 : null,
                                      child: Obx(() => adminController
                                              .isDownloadingLiveEvents.value
                                          ? Text('')
                                          : isTablet
                                              ? TabletGroupStatusBar(
                                                  event: event)
                                              : GestureDetector(
                                                  child: Text(adminController
                                                      .getGroupStatus(event
                                                          .groupNumber
                                                          .toString())),
                                                  onLongPress: () async {
                                                    var res = await showDialog<void>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                            content: SizedBox(
                                                              height: 50,
                                                              width: 60,
                                                              child: TabletGroupStatusBar(
                                                                  event: event),
                                                            ),
                                                          ),
                                                    );
                                                  },
                                                )))),
                                  DataCell(
                                    SizedBox(
                                      width: col4Width,
                                      child: Icon(
                                        event.finalized
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: event.finalized
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                        width: col5Width,
                                        child: Obx(() => LastUpdateWidget(
                                            lastUpdate: event.lastUpdate!,
                                            now: adminController.now.value))),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
