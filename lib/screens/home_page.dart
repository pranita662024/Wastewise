import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastewise/screens/profile_page.dart';
import 'package:wastewise/screens/report_waste_page.dart'; 
import 'package:wastewise/screens/prediction_page.dart'; // ✅ Added for AI Prediction
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String userLocation = "Fetching location...";
  int rewardPoints = 150;
  String status = "Excellent";

  final ImagePicker _picker = ImagePicker();
  io.File? _mobileImage;
  String wasteType = "Unknown";

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// ---------------- LOCATION ----------------
  Future<void> _getUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => userLocation = "Location disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => userLocation = "Permission denied");
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

    setState(() {
      userLocation =
          "${placemarks.first.subLocality}, ${placemarks.first.locality}";
    });
  }

  /// ---------------- PAGE SWITCH ----------------
  Widget _getCurrentPage() {
    if (_selectedIndex == 0) {
      return _buildHomeUI();
    }
    return ProfilePage(user: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.lightGreenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  /// ---------------- HOME UI ----------------
  Widget _buildHomeUI() {
    final username = widget.user.email!.split('@')[0];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _locationChip(),
              Image.asset('assets/wastewise_logo.png', height: 40, width: 40),
            ],
          ),
          const SizedBox(height: 16),
          _userCard(username),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _showRecycleOptions,
                child: _actionCard(Icons.recycling, "Recycle"),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportWastePage()),
                  );
                },
                child: _actionCard(Icons.schedule, "Report"),
              ),
              _actionCard(Icons.lightbulb_outline, "Tips"),
            ],
          ),
          const SizedBox(height: 30),
          _recyclePointsSection(),
        ]),
      ),
    );
  }

  /// ---------------- RECYCLE / AI FLOW ----------------
  void _showRecycleOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt, color: Colors.lightGreenAccent),
          title: const Text("Capture Image", style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _pickAndPredict(ImageSource.camera);
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo, color: Colors.lightGreenAccent),
          title: const Text("Upload from Gallery", style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _pickAndPredict(ImageSource.gallery);
          },
        ),
      ]),
    );
  }

  Future<void> _pickAndPredict(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
    source: source,
    maxWidth: 500,  // ✅ Reduces pixels to process
    maxHeight: 500, // ✅ Speeds up the math significantly
    imageQuality: 85 // ✅ Reduces file size
    );
    if (image == null) return;

    final selectedFile = io.File(image.path);

    // ✅ Move to Prediction Page and wait for the AI result
    final String? resultLabel = await Navigator.push(
      context,
      MaterialPageRoute(
        // ✅ Correct: using 'imagePath' and passing the string path
            builder: (context) => PredictionPage(imagePath: selectedFile.path),
      ),
    );

    // ✅ Update UI and Points if a result was returned
    if (resultLabel != null) {
      setState(() {
        _mobileImage = selectedFile;
        // Removes the leading number if present (e.g., "0 Bio-degradable" -> "Bio-degradable")
        wasteType = resultLabel.contains(' ') 
            ? resultLabel.split(' ').sublist(1).join(' ') 
            : resultLabel;
        
        _addPointsForWaste(wasteType);
      });

      _saveRecycleToFirestore();
    }
  }

  void _addPointsForWaste(String type) {
    String lowerType = type.toLowerCase();
    if (lowerType.contains("bio")) {
      rewardPoints += 50;
    } else if (lowerType.contains("non")) {
      rewardPoints += 70;
    } else if (lowerType.contains("recyclable")) {
      rewardPoints += 100;
    } else if (lowerType.contains("e-waste")) {
      rewardPoints += 150;
    }
  }

  Future<void> _saveRecycleToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection("recycles").add({
        "userId": widget.user.uid,
        "wasteType": wasteType,
        "location": userLocation,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! $wasteType identified.")),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  /// ---------------- UI COMPONENTS ----------------
  Widget _userCard(String username) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF0F3D2E), Color(0xFF1C7C54)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Let's Recycle, $username!",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("Reward Points: $rewardPoints", style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text("Status: $status",
            style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _locationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.lightGreenAccent),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on, size: 16, color: Colors.lightGreenAccent),
        const SizedBox(width: 6),
        Text(userLocation, style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _actionCard(IconData icon, String label) {
    return Container(
      width: 95, height: 95,
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.lightGreenAccent, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ]),
    );
  }

  Widget _recyclePointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recycle Points",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14, mainAxisSpacing: 14,
          children: const [
            _RecyclePointCard(title: "Biodegradable", points: "+50", icon: Icons.eco, color: Color(0xFF2ECC71)),
            _RecyclePointCard(title: "Non-Biodegradable", points: "+70", icon: Icons.delete_outline, color: Color(0xFFE67E22)),
            _RecyclePointCard(title: "Recyclable", points: "+100", icon: Icons.recycling, color: Color(0xFF1ABC9C)),
            _RecyclePointCard(title: "E-Waste", points: "+150", icon: Icons.bolt, color: Color(0xFF9B59B6)),
          ],
        ),
      ],
    );
  }
}

class _RecyclePointCard extends StatelessWidget {
  final String title, points; final IconData icon; final Color color;
  const _RecyclePointCard({required this.title, required this.points, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(points, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}