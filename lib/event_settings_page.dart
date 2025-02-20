import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'models/event.dart';
import 'models/participant.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'widgets/yes_no.dart';


class EventSettingsPage extends StatefulWidget {
  const EventSettingsPage({super.key});

  @override
  State<EventSettingsPage> createState() => _EventSettingsPageState();
}

class _EventSettingsPageState extends State<EventSettingsPage> {
  var eventController = Get.put(Controller());
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
    //print(response.text);
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
      print('current event:');
      print(thisEvent.date);
      isNew = false;
    } else {
      thisEvent = Event(date: dateKey, instructorId:eventController.currentInstructor.id, eventName: eventController.currentEventName);
      print('new event:');
      print(thisEvent.date);
      isNew = true;
    }
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('דף הגדרות יום סיירות'),
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
                    return SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(),
                    );
                  }
                  participants.sort((a, b) => a.number.compareTo(b.number));
                  return Column(
                  children: [
                    const Text("מספר הקבוצה"),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: groupNumber,
                      ),
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(100, 20),
                        ),
                        onPressed: () async {
                          eventController.loading.value = true;
                          thisEvent.groupNumber = int.parse(groupNumber.text);
                          thisEvent.participants = participants;
                          if (eventController.firestoreGradeSettings.version>thisEvent.gradeSettings.version) {
                            thisEvent.gradeSettings = eventController.firestoreGradeSettings;
                          }
                          if (isNew) {
                            print('new event to create');
                            print(thisEvent.date);
                            await eventController.createNewEvent(thisEvent);
                            // eventController.currentEvent.value = thisEvent;
                            // await eventController.currentEvent.value.save();
                            //eventController.unfinalizedEvents =[];
                            //await eventController.getUnfinalizedEvents();
                            Get.toNamed('/event_home');
                            return;
                          } else {
                            print('event settings update');
                            eventController.currentEvent.value = thisEvent;
                            await eventController.currentEvent.value.saveToFirestore();
                          }
                          eventController.loading.value = false;
                          Get.back();
                          Get.back();
                        },
                        child: const Text('שמור')),
                    // Wrap DataTable in a container with fixed height or use Flexible
                    Container(
                      height: 300, // Set height as per your requirement
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
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
                        ),
                      ),
                    ),
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
                            child: const Text("הוסף"),
                          ),
                        ],
                      ),
                    ),
                  ],
                );}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
