import 'dart:io';
import 'package:flutter/material.dart';
import '../services/classifier.dart';

class PredictionPage extends StatefulWidget {
  final String imagePath;
  const PredictionPage({super.key, required this.imagePath});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  bool _isLoading = true;
  String _result = "Analyzing...";
  String _errorText = "";

  @override
  void initState() {
    super.initState();
    _initAndRun(); // ✅ SAFE ENTRY POINT
  }

  /// 🔥 Ensures model is loaded before inference
  Future<void> _initAndRun() async {
    try {
      await WasteClassifier.loadModel(); // SAFE: loads once
      await _runInference();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = "Model initialization failed: $e";
      });
    }
  }

  Future<void> _runInference() async {
    try {
      final results = await WasteClassifier
          .predictImage(widget.imagePath)
          .timeout(const Duration(seconds: 15));

      if (results != null && results.isNotEmpty) {
        setState(() {
          _result = results[0]['label'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = "Could not identify waste";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = "Inference error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analysis")),

      // ✅ Prevents overflow on small screens
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.file(
                  File(widget.imagePath),
                  height: 300,
                ),

                const SizedBox(height: 20),

                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text("AI is thinking... (Max 15s)"),
                ]
                else if (_errorText.isNotEmpty) ...[
                  Text(
                    _errorText,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back"),
                  )
                ]
                else ...[
                  Text(
                    "Result: $_result",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _result),
                    child: const Text("Confirm & Collect Points"),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
