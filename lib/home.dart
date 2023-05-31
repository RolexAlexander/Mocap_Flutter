import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  String updatedOutput =
      "something"; // Create a new variable to store the updated output
  late File _selectedImage;
  Timer? timer;
  var requestresponse;
  var count = 0;
  var selectedimage;
  String _base64Image =
      "This is just a test. I will win all chess games this friday!";
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
              List<Uint8List> imagedata = imageStream.planes.map((plane) {
                return plane.bytes;
              }).toList();
              runModel(imagedata);
              // _getImageFromCamera();
            }
          });
        });
      }
    });
  }

  List<int> convertListOfUint8List(List<Uint8List> list) {
    List<int> newlist = [];
    for (final item in list) {
      newlist.addAll(item);
    }
    return newlist;
  }

  Uint8List concatenatePlanes(List<Uint8List> planes) {
    final planeBytes = planes.map((plane) => plane).toList();
    return Uint8List.fromList(planeBytes.expand((element) => element).toList());
  }

  runModel(List<Uint8List> imagedata) async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: imagedata,
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        threshold: 0.1,
        asynch: true,
      );

      bool isFaceDetected = false;
      print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
      predictions!.forEach((element) {
        if (element['label'] == '1 sad') {
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
      // try {
      if (output == "No face detected") {
        print("No user infront of camera");
        verified = false;
        newuser = false;
      } else {
        newuser = true;
        if (newuser == true && verified == true) {
          print("User already verified");
        } else {
          verified = true;
          print("new user we have to verify");
          print("TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT");

          String base64Image = base64Encode(concatenatePlanes(imagedata));
          print("base64Imagexxxxxxxxxxxxxxxxxx");
          print(base64Image);
          sendPostRequest(base64Image);
        }
      }
    }
  }

  Future<void> sendPostRequest(String base64Image) async {
    final url =
        'https://e0da-190-93-37-93.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/37d9b3fc-9437-4b6b-9891-759733d69d2f?key=3a7fdc0069733f5e12e16f668f5da103';
    final headers = {
      'Authorization':
          'token 70c78e859cc1bd1b2a8c270b3ccbceadd8db2c313c0788232ceae52a3e4e9430',
      'Content-Type': 'application/json'
    };
    final body = jsonEncode({
      'name': 'interact',
      'ctx': {'image_data': base64Image},
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
