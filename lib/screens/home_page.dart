import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wastewise/screens/profile_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  Uint8List? _webImageBytes;
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
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
          _locationChip(),
          const SizedBox(height: 16),
          _userCard(username),
          const SizedBox(height: 30),

          /// 🔁 ORDER FIXED: Recycle → Schedule → Tips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _showRecycleOptions,
                child: _actionCard(Icons.recycling, "Recycle"),
              ),
              _actionCard(Icons.schedule, "Report"),
              _actionCard(Icons.lightbulb_outline, "Tips"),
            ],
          ),

          const SizedBox(height: 30),
          _recyclePointsSection(),
        ]),
      ),
    );
  }

  Widget _userCard(String username) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2E), Color(0xFF1C7C54)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Let's Recycle, $username!",
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Reward Points: $rewardPoints",
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text("Status: $status",
            style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold)),
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
        const Icon(Icons.location_on,
            size: 16, color: Colors.lightGreenAccent),
        const SizedBox(width: 6),
        Text(userLocation,
            style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _actionCard(IconData icon, String label) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.lightGreenAccent, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ]),
    );
  }

  /// ---------------- RECYCLE POINTS ----------------
  Widget _recyclePointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recycle Points",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: const [
            _RecyclePointCard(
                title: "Biodegradable",
                points: "+50 Points",
                icon: Icons.eco,
                color: Color(0xFF2ECC71)),
            _RecyclePointCard(
                title: "Non-Biodegradable",
                points: "+70 Points",
                icon: Icons.delete_outline,
                color: Color(0xFFE67E22)),
            _RecyclePointCard(
                title: "Recyclable",
                points: "+100 Points",
                icon: Icons.recycling,
                color: Color(0xFF1ABC9C)),
            _RecyclePointCard(
                title: "E-Waste",
                points: "+150 Points",
                icon: Icons.bolt,
                color: Color(0xFF9B59B6)),
          ],
        ),
      ],
    );
  }

  /// ---------------- IMAGE FLOW ----------------
  void _showRecycleOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading:
              const Icon(Icons.camera_alt, color: Colors.lightGreenAccent),
          title:
              const Text("Capture Image", style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo, color: Colors.lightGreenAccent),
          title: const Text("Upload from Gallery",
              style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          },
        ),
      ]),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (kIsWeb) {
      _webImageBytes = await image.readAsBytes();
    } else {
      _mobileImage = io.File(image.path);
    }

    _detectWasteType(image.name);
    _showImagePreview();
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          kIsWeb
              ? Image.memory(_webImageBytes!, height: 250)
              : Image.file(_mobileImage!, height: 250),
          const SizedBox(height: 10),
          Text("Detected Waste: $wasteType",
              style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadImage();
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.lightGreenAccent)),
          ),
        ],
      ),
    );
  }

  void _detectWasteType(String name) {
    name = name.toLowerCase();
    if (name.contains("plastic")) {
      wasteType = "Plastic";
    } else if (name.contains("paper")) {
      wasteType = "Paper";
    } else if (name.contains("metal")) {
      wasteType = "Metal";
    } else if (name.contains("glass")) {
      wasteType = "Glass";
    } else {
      wasteType = "Mixed Waste";
    }
  }

  Future<void> _uploadImage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref("recycle_images/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg");

    if (kIsWeb) {
      await ref.putData(_webImageBytes!);
    } else {
      await ref.putFile(_mobileImage!);
    }

    final imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("recycles").add({
      "userId": uid,
      "imageUrl": imageUrl,
      "location": userLocation,
      "wasteType": wasteType,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image uploaded successfully")),
    );
  }
}

/// ---------------- POINT CARD ----------------
class _RecyclePointCard extends StatelessWidget {
  final String title;
  final String points;
  final IconData icon;
  final Color color;

  const _RecyclePointCard({
    required this.title,
    required this.points,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(points,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
