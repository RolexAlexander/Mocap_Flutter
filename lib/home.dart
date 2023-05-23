import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "package:flutter_application_3/main.dart";
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameracontroller;
  String output = "";
  var requestresponse;
  var count = 0;

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadmodel();
    // sendPostRequest();
    print('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
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

  // sendPostRequest() async {
  //   print(
  //       "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
  //   // if (cameraImage != null) {
  //   print('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  //   // List imageBytes = cameraImage!.planes.map((plane) {
  //   //   return plane.bytes;
  //   // }).toList();

  //   // // Convert bytes to base64
  //   // List<String> base64Images = imageBytes.map((bytes) {
  //   //   return base64Encode(bytes);
  //   // }).toList();
  //   var headers = {
  //     'Authorization':
  //         "Token 681abcae51894ac84558c653954f1d887ba6f3e9dd5b0395c44ddd178deea3ef",
  //     'Content-Type': 'application/json'
  //   };
  //   var url = Uri.parse(
  //       'https://e00f-190-93-37-193.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/3280bb4b-22e9-4973-ba75-0f1ba6e18404?key=3a7fdc0069733f5e12e16f668f5da103');
  //   var body = jsonEncode({
  //     "name": "talker",
  //     "ctx": {
  //       "image_data": {"image": "base64Images"}
  //     },
  //     "_req_ctx": {},
  //     "snt": "urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5"
  //   });
  //   var response = await http.post(url, body: body, headers: headers);
  //   print(
  //       'Request xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx response: ${response}');
  //   setState(() {
  //     requestresponse = response;
  //   });
  //   // }
  // }

  sendPostRequest() async {
    print(
        "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
    // if (cameraImage != null) {
    print('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    // List imageBytes = cameraImage!.planes.map((plane) {
    //   return plane.bytes;
    // }).toList();

    // Convert bytes to base64
    // String base64Images = base64Encode(imageBytes);
    List<List<int>> imageBytes = cameraImage!.planes.map((plane) {
      return plane.bytes.toList();
    }).toList();
    // Convert bytes to base64
    String base64Images = base64.encode(concatenateByteArrays(imageBytes));
    print(base64Images.length);
    var headers = {
      'Authorization':
          "Token 6f20aa57cc2ada063004e8b13737c398a69cd20b5fb0b856eebd033229474833",
      'Content-Type': 'application/json'
    };
    var url = Uri.parse(
        'https://a56e-190-93-37-193.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/d33d678c-799c-4f14-b8c3-d3281afce776?key=3a7fdc0069733f5e12e16f668f5da103');
    var body = jsonEncode({
      "name": "talker",
      "ctx": {
        "image_data": {"image": base64Images}
      },
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

  List<int> concatenateByteArrays(List<List<int>> byteArrays) {
    List<int> result = [];
    for (var byteArray in byteArrays) {
      result.addAll(byteArray);
    }
    return result;
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
