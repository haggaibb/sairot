import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../services/ocr_service.dart';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../widgets/wifi_settings_button.dart';


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
  Uint8List? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  final OCRService _ocrService = OCRService();
  String? _lastOcrMethod; // Track which OCR method was used (mlkit or vertexai)
  bool _showRetryOption = false; // Show retry with Vertex AI option
  String _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות'; // Dynamic loading message
  
  // 📸 Capture image from camera
  Future<void> _captureImage(ImageSource src) async {
    // Use high quality settings for better OCR accuracy
    final XFile? image = await _picker.pickImage(
      source: src,
      imageQuality: 90, // High quality for better OCR
      maxWidth: 1920, // Limit size for performance
      maxHeight: 2560,
    );
    if (image == null) return;

    // Read image bytes directly (works on both mobile and web)
    final imageBytes = await image.readAsBytes();

    setState(() {
      _imageFile = imageBytes;
    });

    // Process with OCR service (ML Kit first, Vertex AI fallback)
    await _processImageOCR(_imageFile!);
  }

  // 📤 Process image with OCR service (ML Kit offline, Vertex AI fallback)
  Future<void> _processImageOCR(Uint8List imageBytes, {bool forceVertexAI = false}) async {
    eventController.loading.value = true;
    _showRetryOption = false;
    
    try {
      Map<String, dynamic>? result;
      
      if (forceVertexAI) {
        // Update loading message for cloud scan
        setState(() {
          _loadingMessage = 'מנסה סריקה מתקדמת בענן... זה עשוי לקחת כמה דקות';
        });
        // Force Vertex AI (for retry)
        if (!eventController.isConnected.value) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "אין חיבור לאינטרנט. אנא בדוק את החיבור ונסה שוב.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16
                  ),
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          eventController.loading.value = false;
          return;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "מחפש חיבור לאינטרנט ומנסה סריקה מתקדמת...",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16
                ),
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          result = await _ocrService.processImageWithVertexAIOnly(imageBytes);
          _lastOcrMethod = 'vertexai';
          _showRetryOption = false; // Don't show retry option after using Vertex AI
          
          // Check if Vertex AI failed
          if (result != null && result['success'] == false) {
            // Vertex AI failed - show specific error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "❌ סריקה מתקדמת נכשלה",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "הסריקה המתקדמת לא הצליחה לחלץ את הנתונים מהתמונה.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "טיפים: ודא שהתמונה ברורה, יש תאורה טובה, והטקסט לא מטושטש.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 6),
                ),
              );
            }
            eventController.loading.value = false;
            setState(() {
              _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
            });
            return;
          }
        } catch (e) {
          print("❌ Vertex AI failed: $e");
          // Vertex AI threw an exception - show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "❌ שגיאה בסריקה המתקדמת",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "הסריקה המתקדמת נכשלה. אנא נסה שוב או ודא שיש חיבור יציב לאינטרנט.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          eventController.loading.value = false;
          setState(() {
            _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
          });
          return;
        }
      } else {
        // Normal flow: ML Kit first, then Vertex AI if needed
        // Update loading message for local scan
        setState(() {
          _loadingMessage = 'מנסה סריקה מקומית וחילוץ נתונים...';
        });
        
        result = await _ocrService.processImage(imageBytes);
        _lastOcrMethod = result?['method'] ?? 'unknown';
        
        // If ML Kit was used (successful or not), we'll show retry option after processing
        // This will be set in the success handler below
        
        // If ML Kit failed and we're trying Vertex AI, show message and progress
        if (result != null && result['success'] == false && result['method'] == 'mlkit') {
          // Update loading message for cloud fallback - use setState to update UI immediately
          if (mounted) {
            setState(() {
              _loadingMessage = 'סריקה מקומית נכשלה. מנסה כעת סריקה מתקדמת בענן... זה עשוי לקחת כמה דקות';
            });
          }
          // Give UI time to render the updated message before showing dialog
          await Future.delayed(Duration(milliseconds: 500));
          
          if (eventController.isConnected.value) {
            if (mounted) {
              // Show failure message and cloud retry attempt
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue[700], size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "סריקה מקומית נכשלה",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "הסריקה המקומית לא הצליחה לחלץ את הנתונים.",
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "מנסה כעת סריקה מתקדמת בענן...",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "זה עשוי לקחת דקה או שתיים",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              );
              
              // Wait a bit for the dialog to show, then retry with Vertex AI
              await Future.delayed(Duration(milliseconds: 500));
              
              // Retry with Vertex AI
              try {
                result = await _ocrService.processImageWithVertexAIOnly(imageBytes);
                _lastOcrMethod = 'vertexai';
                _showRetryOption = false; // Don't show retry option after using Vertex AI
                
                // Close the dialog before checking result
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst || !(route is DialogRoute));
                }
                
                // Check if Vertex AI also failed
                if (result != null && result['success'] == false) {
                  // Vertex AI failed - show specific error
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "❌ סריקה מתקדמת נכשלה",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "גם הסריקה המקומית וגם הסריקה המתקדמת לא הצליחו לחלץ את הנתונים.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "טיפים: ודא שהתמונה ברורה, יש תאורה טובה, והטקסט לא מטושטש.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 6),
                      ),
                    );
                  }
                  eventController.loading.value = false;
                  setState(() {
              _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
            });
                  return;
                }
              } catch (e) {
                print("❌ Vertex AI retry failed: $e");
                // Close dialog before showing error
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst || !(route is DialogRoute));
                }
                // Vertex AI threw an exception - show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "❌ שגיאה בסריקה המתקדמת",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "הסריקה המקומית נכשלה, וגם ניסיון הסריקה המתקדמת נכשל.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "אנא נסה שוב או ודא שיש חיבור יציב לאינטרנט.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontStyle: FontStyle.italic
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 6),
                    ),
                  );
                }
                eventController.loading.value = false;
                setState(() {
              _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
            });
                return;
              }
            } else {
              // No internet connection - close dialog and show error
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst || !(route is DialogRoute));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "❌ סריקה מקומית נכשלה",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "הסריקה המקומית לא הצליחה, ואין חיבור לאינטרנט לסריקה מתקדמת.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "אנא בדוק את החיבור לאינטרנט ונסה שוב.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              eventController.loading.value = false;
              setState(() {
              _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
            });
              return;
            }
          }
        }
      }
      
      if (result != null && result['success'] == true) {
        // Close progress dialog if it's open (should already be closed, but just in case)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst || !(route is DialogRoute));
        }
        
        final data = result['data'] as List;
        
        if (data.isNotEmpty) {
          // Extract group number
          if (result['groupNumber'] != null) {
            groupNumber.text = result['groupNumber'].toString();
          } else if (data[0]['מספר קבוצה'] != null) {
            groupNumber.text = data[0]['מספר קבוצה'].toString();
          }
          
          // Extract participants
          participants = [];
          for (var element in data) {
            if (element['מספר רץ'] != null && element['תעודת זהות'] != null) {
              participants.add(Participant(
                number: int.parse(element['מספר רץ'].toString()),
                name: element['תעודת זהות'].toString()
              ));
            }
          }
          
          // Sort participants by number
          participants.sort((a, b) => a.number.compareTo(b.number));
          
          // ALWAYS show retry option if ML Kit was used (even if successful, user should double-check)
          // Only hide it if Vertex AI was already used
          if (_lastOcrMethod == 'mlkit') {
            _showRetryOption = true; // Always show panel after local scan for user to verify
            print("✅ ML Kit was used - showing retry panel");
          } else if (_lastOcrMethod == 'vertexai') {
            _showRetryOption = false; // Already used cloud service, no need for retry
            print("✅ Vertex AI was used - hiding retry panel");
          }
          
          print("📊 Panel visibility: _showRetryOption=$_showRetryOption, _lastOcrMethod=$_lastOcrMethod, participants=${participants.length}, _imageFile=${_imageFile != null}");
          
          setState(() {});
          
          if (mounted) {
            String methodText = _lastOcrMethod == 'vertexai' ? ' (סריקה מתקדמת)' : '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ סריקה הושלמה בהצלחה$methodText",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16
                  ),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception("No data extracted from image");
        }
      } else {
        // This handles cases where result is null or success is false but we haven't handled it yet
        // (shouldn't happen often, but good to have as fallback)
        throw Exception(result?['error'] ?? "OCR processing failed");
      }
    } catch (e) {
      print("❌ Error in OCR processing: $e");
      
      // Close progress dialog if it's open
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || !(route is DialogRoute));
      }
      
      // Only show error snackbar if we haven't already shown one above
      // (This is a fallback for unexpected errors)
      if (mounted) {
        String errorMessage = "לא ניתן לחלץ את הנתונים מהתמונה.";
        String details = "";
        
        // Provide more specific error message
        if (!eventController.isConnected.value) {
          errorMessage = "לא ניתן לחלץ את הנתונים מהתמונה.";
          details = "אנא נסה שוב או ודא שיש חיבור לאינטרנט לסריקה מתקדמת.";
        } else {
          errorMessage = "לא ניתן לחלץ את הנתונים מהתמונה.";
          details = "טיפים לשיפור: ודא שהתמונה ברורה, יש תאורה טובה, הטקסט לא מטושטש, והמסמך מלא במסגרת.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16
                  ),
                ),
                if (details.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      eventController.loading.value = false;
      // Reset loading message to default
      setState(() {
        _loadingMessage = 'סבלנות, זה יכול לקחת כמה דקות';
      });
    }
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
      // ✅ Now decode JSON properly (decoded but not used in this method)
      jsonDecode(response);
      //print("✅ Decoded JSON: $jsonData");
    } catch (e) {
      print("❌ JSON Decoding Error: $e");
    }
  }


  void addParticipant() {
    if (participantNumber.text.isNotEmpty) {
      final number = int.tryParse(participantNumber.text);
      if (number == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('מספר חולצה חייב להיות מספר'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final name = participantName.text.trim();
      
      // Check for duplicate shirt ID (number)
      if (participants.any((p) => p.number == number)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('מספר חולצה $number כבר קיים'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Check for duplicate name/ID (if name is provided)
      if (name.isNotEmpty && participants.any((p) => p.name == name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שם/ת.ז. "$name" כבר קיים'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() {
        participants.add(Participant(
            number: number,
            name: name
        ));
        participants.sort((a, b) => a.number.compareTo(b.number));
      });
      participantNumber.clear();
      participantName.clear();
    }
  }
  
  void editParticipant(Participant participant, int originalNumber) {
    final nameController = TextEditingController(text: participant.name);
    final numberController = TextEditingController(text: participant.number.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ערוך מתאמן'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'שם או ת.ז.',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'מספר חולצה',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                final newNumber = int.tryParse(numberController.text);
                if (newNumber == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('מספר חולצה חייב להיות מספר'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final newName = nameController.text.trim();
                
                // Check for duplicate shirt ID (number) - but allow if it's the same participant
                if (newNumber != originalNumber && participants.any((p) => p.number == newNumber)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('מספר חולצה $newNumber כבר קיים'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Check for duplicate name/ID (if name is provided) - but allow if it's the same participant
                if (newName.isNotEmpty && 
                    newName != participant.name && 
                    participants.any((p) => p.name == newName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('שם/ת.ז. "$newName" כבר קיים'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  final index = participants.indexWhere((p) => p.number == originalNumber);
                  if (index != -1) {
                    participants[index] = Participant(
                      number: newNumber,
                      name: newName,
                    );
                    participants.sort((a, b) => a.number.compareTo(b.number));
                  }
                });
                
                Navigator.of(context).pop();
              },
              child: Text('שמור'),
            ),
          ],
        );
      },
    );
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
            ),
            WifiSettingsButton(),
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
                          SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _loadingMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
                      Builder(
                        builder: (context) {
                          bool tablet = isTablet(context);
                          // Increase recruit number column width for tablet to hold 3 digits
                          final recruitNumberWidth = tablet ? 150.0 : 100.0;
                          // Increase name column width for tablet (30% larger: 200 * 1.3 = 260)
                          final nameColumnWidth = tablet ? 260.0 : 180.0;
                          // Increase list height for tablet (30% larger: 300 * 1.3 = 390)
                          final listHeight = tablet ? 390.0 : 300.0;
                          
                          return Container(
                            height: listHeight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: participants.isNotEmpty
                                    ? DataTable(
                                        columnSpacing: 12,
                                        columns: [
                                          DataColumn(
                                            label: SizedBox(
                                              width: 20,
                                              child: Text(
                                                '',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: SizedBox(
                                              width: nameColumnWidth,
                                              child: Text(
                                                'שם או ת.ז.',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: SizedBox(
                                              width: recruitNumberWidth,
                                              child: Text(
                                                'חולצה',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: SizedBox(
                                              width: 100,
                                              child: Text(
                                                'פעולות',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: participants.asMap().entries.map(
                                          (entry) => DataRow(
                                            cells: [
                                              DataCell(
                                                Container(
                                                  width: 30,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    (entry.key + 1).toString(),
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ), // ✅ Print index (1-based)
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth: nameColumnWidth,
                                                    maxWidth: nameColumnWidth,
                                                  ),
                                                  child: Text(
                                                    entry.value.name,
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ), // ✅ Contact Name
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth: recruitNumberWidth,
                                                    maxWidth: recruitNumberWidth,
                                                  ),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      entry.value.number.toString(),
                                                      textAlign: TextAlign.center,
                                                      softWrap: false,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.clip,
                                                    ),
                                                  ),
                                                ),
                                              ), // ✅ Contact Number
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit, size: 20),
                                                      onPressed: () {
                                                        editParticipant(entry.value, entry.value.number);
                                                      },
                                                      splashColor: Colors.blue,
                                                      tooltip: 'ערוך',
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete, size: 20),
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
                                                      tooltip: 'מחק',
                                                    ),
                                                  ],
                                                ),
                                              ), // ✅ Edit and Delete buttons
                                            ],
                                          ),
                                        ).toList(),
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ),
                          );
                        },
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
                                // Use offline-aware save method
                                await eventController.saveEventWithOfflineSupport(thisEvent);
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
                      // Info panel: Explain local scan and offer cloud retry (if ML Kit was used) - after save button
                      if (_showRetryOption && _imageFile != null && participants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50], // Light blue background for better contrast
                              border: Border.all(color: Colors.blue[300]!, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.red[700], size: 24), // Red icon for visibility
                                    SizedBox(width: 8),
                                    Text(
                                      "סריקה מקומית מהירה",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900], // Dark text for better contrast
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "הסריקה בוצעה במצב מקומי (ללא אינטרנט). אנא בדוק היטב את הנתונים שחולצו.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800], // Dark text for better contrast
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "אם יש שגיאות או נתונים חסרים, תוכל לנסות סריקה מתקדמת בענן (דורש אינטרנט) לתוצאות מדויקות יותר.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800], // Dark text for better contrast
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: eventController.isConnected.value
                                        ? () async {
                                            await _processImageOCR(_imageFile!, forceVertexAI: true);
                                          }
                                        : null,
                                    icon: Icon(Icons.cloud_upload, size: 20),
                                    label: Text(
                                      "נסה סריקה מתקדמת",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!eventController.isConnected.value)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "⚠️ אין חיבור לאינטרנט - סריקה מתקדמת לא זמינה",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 50,),
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

  @override
  void dispose() {
    _ocrService.dispose();
    groupNumber.dispose();
    instructorId.dispose();
    participantName.dispose();
    participantNumber.dispose();
    super.dispose();
  }
}
