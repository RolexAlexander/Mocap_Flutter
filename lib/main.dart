import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
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
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getImageFromCamera() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _convertToBase64() async {
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        _base64Image = base64Image;
      });
    }
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
                  return Container(
                    width: 300,
                    height: 300,
                    child: CameraPreview(_controller),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getImageFromCamera,
              child: Text('Capture Image'),
            ),
            ElevatedButton(
              onPressed: _convertToBase64,
              child: Text('Convert to Base64'),
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