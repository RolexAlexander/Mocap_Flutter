import 'dart:convert';
import 'dart:io';
// import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Emotion Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(camera: camera),
    );
  }
}

class Home extends StatefulWidget {
  final CameraDescription camera;

  const Home({required this.camera});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";
  String base64Image = "";

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> runModel() async {
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
          //_convertToBase64();
          _sendPostRequest();
          _getImageFromCamera();
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

  Future<void> _getImageFromCamera() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();

      setState(() {
        final selectedImage = File(image.path);
        _convertToBase64(selectedImage);
      });
    } catch (e) {
      print('Error occurred: $e');
    }
  }

    void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
  }

  Future<void> _convertToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    setState(() {
      this.base64Image = base64Image;
    });
    _copyToClipboard(base64Image);
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
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
          ),
          Text(output, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
          if (base64Image.isNotEmpty) SelectableText(base64Image), // Display base64Image if not empty
          ElevatedButton(
            onPressed: _getImageFromCamera,
            child: Text('Capture Image'),
          ),
        ],
      ),
    );
  }
}