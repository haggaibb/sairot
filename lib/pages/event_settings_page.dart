import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/event.dart';
import '../models/participant.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';


class EventSettingsPage extends StatefulWidget {
  const EventSettingsPage({super.key});

  @override
  State<EventSettingsPage> createState() => _EventSettingsPageState();
}

class _EventSettingsPageState extends State<EventSettingsPage> {
  var eventController = Get.put(EventController());
  var dateKey = Get.parameters['date'] ?? '';
  TextEditingController groupNumber = TextEditingController();
  TextEditingController instructorId = TextEditingController();
  TextEditingController participantName = TextEditingController();
  TextEditingController participantNumber = TextEditingController();

  List<Participant> participants = [];
  bool isNew = true;
  late Event thisEvent;

 /// OCR
  ///
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash-001');
  // 📸 Capture image from camera
  Future<void> _captureImage(ImageSource src) async {
    final XFile? image = await _picker.pickImage(source: src);
    if (image == null) return;

    setState(() {
      _imageFile = File(image.path);
    });

    // Send to Vertex AI
    await _sendToVertexAI(_imageFile!);
  }

  // 📤 Convert image to Base64 and send to Vertex AI
  Future<void> _sendToVertexAI(File imageFile) async {
  // Provide a text prompt to include with the image
    eventController.loading.value = true;
    final prompt = TextPart("extract the data into json");
  // Prepare images for input
    final image = await imageFile.readAsBytes();
    final imagePart = InlineDataPart('image/jpeg', image);

// To generate text output, call generateContent with the text and image
    final response = await model.generateContent(
      generationConfig: GenerationConfig(
        responseMimeType: "application/json",
      ),
        [Content.multi([prompt,imagePart],
        )
    ]);
    try {
      // ✅ Now decode JSON properly
      var jsonData = jsonDecode(response.text??'');
      groupNumber.text = jsonData[0]['מספר קבוצה'].toString();
      participants = [];
      for (var element in jsonData) {
        participants.add(Participant(
            number: int.parse(element['מספר רץ']),
            name: element['תעודת זהות']
        ));
      }
      //print("✅ Decoded JSON: $jsonData");
    } catch (e) {
      print("❌ JSON Decoding Error: $e");
    }
    processResponse(response.text??'');
    eventController.loading.value = false;
  }
  //
  void processResponse(String response) {
    // 🔹 Remove first line if it starts with ```json
    if (response.startsWith("```json")) {
      response = response.replaceFirst("```json", "").trim();
    }

    // 🔹 Remove last line if it contains ```
    if (response.endsWith("```")) {
      response = response.substring(0, response.length - 3).trim();
    }

    try {
      // ✅ Now decode JSON properly
      var jsonData = jsonDecode(response);
      //print("✅ Decoded JSON: $jsonData");
    } catch (e) {
      print("❌ JSON Decoding Error: $e");
    }
  }


  void addParticipant() {
    if (participantNumber.text.isNotEmpty) {
      setState(() {
        participants.add(Participant(
            number: int.parse(participantNumber.text),
            name: participantName.text
        ));
        participants.sort((a, b) => a.number.compareTo(b.number));
      });
      participantNumber.clear();
      participantName.clear();
    }
  }

  @override
  void initState() {
    if (eventController.currentEvent.value.date==dateKey) {
      groupNumber.text = eventController.currentEvent.value.groupNumber.toString();
      instructorId.text = eventController.currentInstructor.id;
      thisEvent = eventController.currentEvent.value;
      participants =  eventController.currentEvent.value.participants;
      isNew = false;
    } else {
      thisEvent = Event(date: dateKey, instructorId:eventController.currentInstructor.id, eventName: eventController.currentEventName);
      isNew = true;
    }
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
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
          title: const Text('דף הגדרות יום סיירות'),
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
                      url:
                      'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_0',
                      //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                    ),
                  ),
                );
              },
            )
          ],
        ),
        body: Directionality(
          textDirection: TextDirection.rtl, // Enforce LTR layout for the entire body
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    eventController.currentEventName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateKey,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(" מדריך ${eventController.currentInstructor.id}"),
                  Obx(()  {
                    if (eventController.loading.value) {
                      return SizedBox.shrink();
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            iconSize: 40,
                            onPressed: () {
                              _captureImage(ImageSource.camera);
                            } ,
                            icon: Icon(Icons.camera_alt_outlined)
                        ),
                        IconButton(
                            iconSize: 40,
                            onPressed: () {
                              _captureImage(ImageSource.gallery);
                            } ,
                            icon: Icon(Icons.image_search)
                        ),
                      ],
                    );
                  }),
                  const SizedBox(
                    height: 10,
                  ),
                  Obx (()  {
                    if (eventController.loading.value) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(),
                          ),
                          Text('סבלנות, זה יכול לקחת כמה דקות')
                        ],
                      );
                    }
                    participants.sort((a, b) => a.number.compareTo(b.number));
                    return Column(
                    children: [
                      SizedBox(height: 10,),
                      SizedBox(
                        width: 125,
                        child: TextField(
                          controller: groupNumber,
                          decoration: const InputDecoration(
                            labelText: 'מספר הקבוצה',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(height: 10,),
                      // Input fields and add button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: participantName,
                                decoration: const InputDecoration(
                                  labelText: 'שם או ת.ז.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: participantNumber,
                                decoration: const InputDecoration(
                                  labelText: 'מספר חולצה',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: addParticipant,
                              child: const Text("הוסף",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wrap DataTable in a container with fixed height or use Flexible
                      Container(
                        height: 300, // Set height as per your requirement
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: participants.isNotEmpty
                              ? DataTable(
                            columns: const [
                              DataColumn(label: SizedBox(width: 20,child: Text(''))),
                              DataColumn(label: SizedBox(width: 25, child: Text('שם או ת.ז.'))),
                              DataColumn(label: SizedBox(width: 40, child: Text('חולצה'))),
                              DataColumn(label: SizedBox.shrink()),
                            ],
                            rows: participants.asMap().entries.map(
                                  (entry) => DataRow(
                                cells: [
                                  DataCell(SizedBox(width:20, child: Text((entry.key + 1).toString()))), // ✅ Print index (1-based)
                                  DataCell(Text(entry.value.name)),           // ✅ Contact Name
                                  DataCell(SizedBox( child: Text(entry.value.number.toString()))), // ✅ Contact Number
                                  DataCell(
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          var res = await showDialog(
                                            context: context,
                                            builder:
                                                (BuildContext context) {
                                              return YesNoDialog();
                                            },
                                          );
                                          if (res) {
                                            setState(() {
                                              participants.removeWhere((participant) => participant.number == entry.value.number);
                                            });
                                          }
                                        },
                                        splashColor: Colors.red,
                                      ),
                                    )
                                  ), // ✅ Contact Number

                                ],
                              ),
                            ).toList(),
                          )
                              : SizedBox.shrink(),
                        ),
                      ),
                      //SizedBox(height: ,),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                          onPressed: () async {
                            if (participants.isNotEmpty && groupNumber.text !='') {
                              eventController.loading.value = true;
                              thisEvent.groupNumber = int.parse(groupNumber.text);
                              thisEvent.participants = participants;
                              if (eventController.firestoreGradeSettings.version>thisEvent.gradeSettings.version) {
                                thisEvent.gradeSettings = eventController.firestoreGradeSettings;
                              }
                              if (isNew) {
                                await eventController.createNewEvent(thisEvent);
                                // eventController.currentEvent.value = thisEvent;
                                // await eventController.currentEvent.value.save();
                                //eventController.unfinalizedEvents =[];
                                //await eventController.getUnfinalizedEvents();
                                Get.toNamed('/event_home');
                                return;
                              }
                              else {
                                eventController.currentEvent.value = thisEvent;
                                await eventController.currentEvent.value.saveToFirestore();
                              }
                              eventController.loading.value = false;
                              Get.back();
                              Get.back();
                            }
                            else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("לא הוזו מספר קבוצה או לא הוזנו משתתפים!"),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: const Text('שמור',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),

                    ],
                  );}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
