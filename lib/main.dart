import 'package:flutter/material.dart';
import 'package:flutter_application_3/home.dart';
import "package:camera/camera.dart";

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: Home(camera: cameras![0]), // Pass the camera description here
    );
  }
}
