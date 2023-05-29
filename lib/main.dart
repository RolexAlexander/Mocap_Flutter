import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(PostRequestApp());
}

class PostRequestApp extends StatefulWidget {
  @override
  _PostRequestAppState createState() => _PostRequestAppState();
}

class _PostRequestAppState extends State<PostRequestApp> {
  Timer? _timer;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  File? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeCamera();
  }

  void _startTimer() {
    const duration = Duration(seconds: 5);
    _timer = Timer.periodic(duration, (timer) async {
      await _takePictureAndSendRequest();
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _takePictureAndSendRequest() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final imageFile = File(image.path);

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64Image;
      });

      await _sendPostRequest(base64Image);
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _sendPostRequest(String base64Image) async {
    final url =
        'https://0ece-190-93-37-191.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/ca639c31-e3f3-4a1e-a6ad-ebc4da6c82cd?key=3a7fdc0069733f5e12e16f668f5da103';
    final headers = {
      'Authorization': 'token 2ef828b2935f311fdec9d6b1bed469e467dbf6b2b7538b63ee8f5320c8a47848',
      'Content-Type': 'application/json'
    };
    final body = jsonEncode({
      'name': 'interact',
      'ctx': {'image_data': base64Image},
      '_req_ctx': {},
      'snt': 'urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5'
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      print('Response: ${response.body}');
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Post Request App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_selectedImage != null) ...[
                Container(
                  width: 300,
                  height: 300,
                  child: Image.file(_selectedImage!),
                ),
                SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _takePictureAndSendRequest,
                child: Text('Capture Image and Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}