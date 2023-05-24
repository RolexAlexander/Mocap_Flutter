import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "package:flutter_application_3/main.dart";
import 'package:flutter_tflite/flutter_tflite.dart';
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
  CameraController? cameracontroller;
  String output = "";
  File? _selectedImage;
  var requestresponse;
  var count = 0;
  var selectedimage;
  String? _base64Image;
  String imagedata = "";

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadmodel();
  }

  loadCamera() {
    cameracontroller = CameraController(cameras![0], ResolutionPreset.medium);
    cameracontroller!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameracontroller!.startImageStream((imageStream) {
            cameraImage = imageStream;
            // sendPostRequest;
            runModel();
          });
        });
      }
    });
  }

  runModel() async {
    if (cameraImage != null) {
      // var predictions = await Tflite.runModelOnFrame(
      //     bytesList: cameraImage!.planes.map((plane) {
      //       return plane.bytes;
      //     }).toList(),
      //     imageHeight: cameraImage!.height,
      //     imageWidth: cameraImage!.width,
      //     imageMean: 127.5,
      //     imageStd: 127.5,
      //     rotation: 90,
      //     threshold: 0.1,
      //     asynch: true);
      // predictions!.forEach((element) {
      //   setState(() {
      //     output = element["label"];
      //   });
      // });
      count = count + 1;
      if (count % 10 == 0) {
        sendPostRequest();
      }
    }
  }

  sendPostRequest() async {
    // Convert bytes to base64

    try {
      // Capture an image using the camera controller
      final image = await cameracontroller?.takePicture();

      setState(() {
        // Store the captured image file
        _selectedImage = File(image!.path);
      });
    } catch (e) {
      print('Error occurred: $e');
    }
    if (_selectedImage != null) {
      // Read the image file as bytes
      final bytes = await _selectedImage!.readAsBytes();
      print("bytes");
      print(bytes);
      // Encode the image bytes to base64
      final base64Image = base64Encode(bytes);

      setState(() {
        // Store the base64-encoded image string
        _base64Image = base64Image;
      });
    }

    var headers = {
      'Authorization':
          "Token 392f1eb645b5695c7932aec4ef6b1c1f8c00d77f3879829acf38eef20458e879",
      'Content-Type': 'application/json'
    };
    var url = Uri.parse(
        'https://5ed4-190-93-37-91.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/fa709d99-9366-49ca-8b77-f6ffeaefea17?key=3a7fdc0069733f5e12e16f668f5da103');
    var body = jsonEncode({
      "name": "interact",
      "ctx": {"image_data": _base64Image},
      "_req_ctx": {},
      "snt": "urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5"
    });
    var response = await http.post(url, body: body, headers: headers);
    print(
        'Request xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx response: ${response}');

    // }
  }

  loadmodel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
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
                child: !cameracontroller!.value.isInitialized
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameracontroller!.value.aspectRatio,
                        child: CameraPreview(cameracontroller!),
                      ),
              ),
            ),
            Text(output,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30))
          ],
        ));
  }
}
