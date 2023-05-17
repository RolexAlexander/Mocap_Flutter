import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "package:flutter_application_3/main.dart";
import 'package:flutter_tflite/flutter_tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameracontroller;
  String output = "";

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
            runModel();
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
          asynch: true);
      predictions!.forEach((element) {
        setState(() {
          output = element["label"];
        });
      });
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
