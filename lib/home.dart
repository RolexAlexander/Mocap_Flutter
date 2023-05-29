import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  CameraImage? cameraImage;
  CameraController? cameraController;
  Timer? timer;
  String output = "";
  late File _selectedImage;
  String _base64Image = "";

  @override
  void initState() {
    super.initState();
    loadCamera();
    startRequestTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  void loadCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
          });
        });
      }
    });
  }

  void startRequestTimer() {
    timer = Timer.periodic(Duration(seconds: 10), (_) {
      if (cameraImage != null) {
        _getImageFromCamera();
      }
    });
  }

  void _getImageFromCamera() async {
    try {
      await cameraController!.initialize();
      final image = await cameraController!.takePicture();

      setState(() {
        _selectedImage = File(image.path);
        _convertToBase64();
      });
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _convertToBase64() async {
    if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _base64Image = base64Image;
        });

        sendPostRequest();
      } catch (e) {
        print('Error occurred: $e');
      }
    }
  }

  void sendPostRequest() async {
    try {
      var headers = {
        'Authorization':
            'Token 2ef828b2935f311fdec9d6b1bed469e467dbf6b2b7538b63ee8f5320c8a47848',
        'Content-Type': 'application/json'
      };
      var url = Uri.parse(
          'https://0ece-190-93-37-191.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/ca639c31-e3f3-4a1e-a6ad-ebc4da6c82cd?key=3a7fdc0069733f5e12e16f668f5da103');
      var body = jsonEncode({
        "name": "interact",
        "ctx": {"image_data": _base64Image},
        "_req_ctx": {},
        "snt": "urn:uuid:82cdbffa-bb03-42b6-a553-b775961eabc3"
      });
      var response = await http.post(url, body: body, headers: headers);
      print('Request response: $response');
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Emotion Detection App")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
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
          Text(output,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        ],
      ),
    );
  }
}
