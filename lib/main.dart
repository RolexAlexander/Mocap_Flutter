import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Retrieve available cameras
  final cameras = await availableCameras();

  // Select the front camera
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  runApp(MyApp(camera: frontCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Base64 Image Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({required this.camera});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  File? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();

    // Initialize the camera controller with the selected camera
    _controller = CameraController(widget.camera, ResolutionPreset.medium);

    // Initialize the camera controller asynchronously
    _initializeControllerFuture = _controller.initialize();

    startRequestTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getImageFromCamera() async {
    try {
      await _initializeControllerFuture;

      // Capture an image using the camera controller
      final image = await _controller.takePicture();

      setState(() {
        // Store the captured image file
        _selectedImage = File(image.path);
      });

      await _convertToBase64();
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _convertToBase64() async {
    if (_selectedImage != null) {
      // Read the image file as bytes
      final bytes = await _selectedImage!.readAsBytes();

      // Encode the image bytes to base64
      final base64Image = base64Encode(bytes);

      setState(() {
        // Store the base64-encoded image string
        _base64Image = base64Image;
      });

      await sendPostRequest();
    }
  }

  Future<void> sendPostRequest() async {
    try {
      var headers = {
        'Authorization':
            'token 2ef828b2935f311fdec9d6b1bed469e467dbf6b2b7538b63ee8f5320c8a47848',
        'Content-Type': 'application/json'
      };
      var url = Uri.parse('https://0ece-190-93-37-191.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/ca639c31-e3f3-4a1e-a6ad-ebc4da6c82cd?key=3a7fdc0069733f5e12e16f668f5da103');
      var body = jsonEncode({
        'name': 'interact',
        'ctx': {'image_data': _base64Image},
        '_req_ctx': {},
        'snt': 'urn:uuid:82cdbffa-bb03-42b6-a553-b775961eabc3'
      });

      var response = await http.post(url, headers: headers, body: body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error occurred during request: $e');
    }
  }

  void startRequestTimer() {
    const duration = Duration(seconds: 10);
    Timer.periodic(duration, (Timer timer) {
      if (_base64Image != null) {
        sendPostRequest();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Base64 Image Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Display the camera preview once the controller is initialized
                  return Container(
                    width: 300,
                    height: 300,
                    child: CameraPreview(_controller),
                  );
                } else {
                  // Show a loading indicator while the controller is being initialized
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getImageFromCamera,
              child: Text('Capture Image'),
            ),
            if (_base64Image != null) ...[
              SizedBox(height: 16),
              Text('Base64 Image'),
              SizedBox(height: 8),
              SelectableText(_base64Image!),
            ],
          ],
        ),
      ),
    );
  }
}
