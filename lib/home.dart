import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";
  late File selectedImage;
  String base64Image = "";

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  void loadCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await cameraController!.initialize();
    cameraController!.startImageStream((imageStream) {
      setState(() {
        cameraImage = imageStream;
      });
      runModel();
    });
  }

  void runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        threshold: 0.1,
        asynch: true,
      );

      bool isFaceDetected = false;
      predictions!.forEach((element) {
        if (element['label'] == '1 sad') {
          isFaceDetected = true;
          setState(() {
            output = element['label'];
            base64Image = ""; // Clear the base64Image when a face is detected
          });
          _convertToBase64();
          _sendPostRequest();
        }
      });

      if (!isFaceDetected) {
        setState(() {
          output = "No face detected";
          base64Image = ""; // Clear the base64Image when no face is detected
        });
      }
    }
  }

  Future<void> _convertToBase64() async {
    final imageBytes = await cameraImage!.planes[0].bytes;
    final base64Image = base64Encode(imageBytes);
    setState(() {
      this.base64Image = base64Image;
    });
    _copyToClipboard(base64Image); // Copy base64Image to clipboard
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
  }

  Future<void> _sendPostRequest() async {
    final url =
        'https://c90d-190-93-37-91.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/9b68ef56-f60f-4fc2-ad69-53e76e896c7a?key=3a7fdc0069733f5e12e16f668f5da103';
    final headers = {
      'Authorization': 'token 48b6cea0bf64861b95eb948f97cd544866bc684ae3581628b4363ddbe48c3272',
      'Content-Type': 'application/json'
    };
    final body = jsonEncode({
      'name': 'interact',
      'ctx': {
        'image_data': base64Image,
        'expression': output,
      },
      '_req_ctx': {},
      'snt': 'urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5',
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      print('Response: ${response.body}');
    } catch (error) {
      print('Error: $error');
    }
  }

  void loadModel() async {
    await Tflite.loadModel(model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  @override
  void dispose() {
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Emotion Detection App")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(output, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
          if (base64Image.isNotEmpty) SelectableText(base64Image), // Display base64Image if not empty
        ],
      ),
    );
  }
}
