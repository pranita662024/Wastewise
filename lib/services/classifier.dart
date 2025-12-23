import 'package:tflite_v2/tflite_v2.dart';

class WasteClassifier {
  static bool _isModelLoaded = false;

  static Future<void> loadModel() async {
    if (_isModelLoaded) {
      print("ℹ️ Model already loaded");
      return;
    }

    try {
      final res = await Tflite.loadModel(
        model: "assets/model/wastewise_model.tflite",
        labels: "assets/model/labels.txt",
      );

      print("📦 TFLite load response: $res");

      _isModelLoaded = true;
      print("✅ Model loaded successfully");
    } catch (e) {
      print("❌ MODEL LOAD FAILED: $e");
      rethrow;
    }
  }

  static Future<List?> predictImage(String imagePath) async {
    if (!_isModelLoaded) {
      throw Exception("Model is yet not loaded");
    }

    return await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 2,
      threshold: 0.2,
      imageMean: 127.5,
      imageStd: 127.5,
    );
  }

  static void dispose() {
    Tflite.close();
    _isModelLoaded = false;
  }
}
