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

  // เพิ่มตัวแปรสำหรับเก็บ path ของโมเดลที่เลือก
  String selectedModel = "assets/gundumhandfinish.gltf";

  // รายชื่อโมเดลที่เลือกได้
  final List<String> modelList = [
    "assets/Giant.gltf",
    "assets/MagicStaff.gltf",
    "assets/Chest.gltf",
    "assets/Boat.gltf",
    "assets/Car.gltf",
    "assets/gundumhandfinish.gltf",
  ];

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
      floatingActionButton: FloatingActionButton(
        onPressed: _showModelSelectionDialog,
        child: const Icon(Icons.view_in_ar),
      ),
    );
  }

  void _showModelSelectionDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('เลือกโมเดล 3D'),
          children: modelList.map((model) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, model),
              child: Text(model.split('/').last),
            );
          }).toList(),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedModel = result;
      });
    }
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
      uri: selectedModel, // ใช้โมเดลที่เลือก
      scale: vector_math.Vector3(0.35, 0.35, 0.35),
      position: position,
      rotation: rotation,
    );
    await arObjectManager?.addNode(node);
  }
}
