import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("About Us", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          "WasteWise is an eco-friendly recycling app that helps users manage "
          "their waste responsibly, earn rewards, and contribute to a cleaner environment. "
          "Our mission is to make recycling simple, rewarding, and sustainable.",
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
