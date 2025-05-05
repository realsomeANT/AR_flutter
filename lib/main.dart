import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:permission_handler/permission_handler.dart';

// If you still get "Undefined class 'ARSessionManager'", do the following:
// 1. Make sure you have run `flutter pub get` after adding ar_flutter_plugin to pubspec.yaml.
// 2. Clean your build: run `flutter clean` then `flutter pub get`.
// 3. Restart your IDE/editor to refresh code analysis.
// 4. If you are using a custom IDE, ensure it is not using an old Dart analysis cache.
// 5. If the problem persists, try running `flutter pub upgrade` to update all dependencies.

// The class ARSessionManager is defined in ar_flutter_plugin >=0.7.0.
// If you still see this error, check your pubspec.yaml and pubspec.lock to confirm the correct version is installed.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter AR Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ARViewScreen(),
    );
  }
}

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({super.key});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Tap to Place Model')),
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontal,
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: true,
    );
    arObjectManager.onInitialize();
    arSessionManager.onPlaneOrPointTap = onPlaneTap;
  }

  Future<void> onPlaneTap(List<ARHitTestResult> hits) async {
    if (hits.isEmpty) return;
    final hit = hits.first;
    // Extract position from Matrix4
    final matrix = hit.worldTransform;
    final position = matrix.getTranslation();
    // Convert rotation Matrix3 to Quaternion, then to Vector4 (x, y, z, w)
    final rotationMatrix = matrix.getRotation();
    final quaternion = vector_math.Quaternion.fromRotation(rotationMatrix);
    final rotation = vector_math.Vector4(
      quaternion.x,
      quaternion.y,
      quaternion.z,
      quaternion.w,
    );

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/gundumhandfinish.gltf", // Change to your model path
      scale: vector_math.Vector3(0.5, 0.5, 0.5),
      position: position,
      rotation: rotation,
    );
    await arObjectManager?.addNode(node);
  }
}

// If you still get "Undefined class 'ARSessionManager'", it means:
// 1. The ar_flutter_plugin package is not installed or not the correct version.
// 2. Run `flutter pub get` in your project directory.
// 3. Ensure your pubspec.yaml contains:
/// 
/// dependencies:
///   ar_flutter_plugin: ^0.7.3
/// 
// 4. If you are using a different version, check the plugin documentation for class names and usage.
