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
import 'dart:async';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameracontroller;
  String output = "";
  late File _selectedImage;
  Timer? timer;
  var requestresponse;
  var count = 0;
  var selectedimage;
  String _base64Image = "";
  String imagedata = "";
  bool verified = false;
  bool newuser = false;

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
            count++;
            if (count % 100 == 0) {
              print("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxx");
              cameraImage = imageStream;
              runModel();
              // _getImageFromCamera();
            }
          });
        });
      }
    });
  }

runModel() async {
  if (cameraImage != null) {
    var predictions = await Tflite.runModelOnFrame(
      bytesList: cameraImage!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
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
      if (element['label'] == 'sad') {
        isFaceDetected = true;
        setState(() {
          output = element['label'];
        });
      }
    });

    if (!isFaceDetected) {
      setState(() {
        output = "No face detected";
      });
    }
  }
}

  void _getImageFromCamera() {
    print("zzzzzzzzzzzzzzzzsssssss");
    cameracontroller!.initialize().then((_) {
      print("zzzzzzzzzzzzzzzzpppppppp");
      // Capture an image using the camera controller
      cameracontroller!.takePicture().then((image) {
        print("zzzzzzzzzzzzzzzzttttttt");
        setState(() {
          // Store the captured image file
          _selectedImage = File(image.path);
          _convertToBase64();
        });
      }).catchError((error) {
        print('Error occurred: $error');
      });
    });
  }

  void _convertToBase64() {
    // if (_selectedImage != null) {
    // Read the image file as bytes
    _selectedImage.readAsBytes().then((bytes) {
      // Encode the image bytes to base64
      final base64Image = base64Encode(bytes);

      setState(() {
        // Store the base64-encoded image string
        _base64Image = base64Image;
      });

      // Send the POST request with the base64 image
      // sendPostRequest();
    }).catchError((error) {
      print('Error occurred: $error');
    });
    // }
  }

  Future<void> sendPostRequest() async {
    final url =
        'https://c90d-190-93-37-91.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/9b68ef56-f60f-4fc2-ad69-53e76e896c7a?key=3a7fdc0069733f5e12e16f668f5da103';
    final headers = {
      'Authorization':
          'token 48b6cea0bf64861b95eb948f97cd544866bc684ae3581628b4363ddbe48c3272',
      'Content-Type': 'application/json'
    };
    final body = jsonEncode({
      'name': 'interact',
      'ctx': {'image_data': _base64Image},
      '_req_ctx': {},
      'snt': 'urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5'
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      print('Response: ${response.body}');
    } catch (error) {
      print('Error: $error');
    }
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
