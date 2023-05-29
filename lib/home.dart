import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  Timer? timer;
  String output = "";
  late File selectedImage;
  String base64Image = "";

  @override
  void initState() {
    super.initState();
    setupCamera();
    startRequestTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> setupCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await cameraController.initialize();
    setState(() {});
  }

  void startRequestTimer() {
    timer = Timer.periodic(Duration(seconds: 10), (_) {
      if (cameraController.value.isInitialized) {
        _getImageFromCamera();
      }
    });
  }

  Future<void> _getImageFromCamera() async {
    try {
      await cameraController.initialize();
      final image = await cameraController.takePicture();

      setState(() {
        selectedImage = File(image.path);
      });

      await _convertToBase64();
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _convertToBase64() async {
    if (selectedImage != null) {
      try {
        final bytes = await selectedImage.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          this.base64Image = base64Image;
        });

        await sendPostRequest();
      } catch (e) {
        print('Error occurred: $e');
      }
    }
  }

  Future<void> sendPostRequest() async {
    try {
      var headers = {
        'Authorization':
            'token 2ef828b2935f311fdec9d6b1bed469e467dbf6b2b7538b63ee8f5320c8a47848',
        'Content-Type': 'application/json'
      };
      var url = Uri.parse(
          'https://0ece-190-93-37-191.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/ca639c31-e3f3-4a1e-a6ad-ebc4da6c82cd?key=3a7fdc0069733f5e12e16f668f5da103');
      var body = jsonEncode({
        'name': 'interact',
        'ctx': {'image_data': base64Image},
        '_req_ctx': {},
        'snt': 'urn:uuid:82cdbffa-bb03-42b6-a553-b775961eabc3'
      });

      var response = await http.post(url, body: body, headers: headers);
      print('Request response: ${response.body}');
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Live Emotion Detection App")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
          Text(output, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        ],
      ),
    );
  }
}
