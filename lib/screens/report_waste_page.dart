import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReportWastePage extends StatefulWidget {
  const ReportWastePage({super.key});

  @override
  State<ReportWastePage> createState() => _ReportWastePageState();
}

class _ReportWastePageState extends State<ReportWastePage> {
  final picker = ImagePicker();
  File? imageFile;
  String location = "";
  bool isFetchingLocation = false;
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  final Color bgBlack = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF1A1A1A);
  final Color accentGreen = const Color(0xFF4CAF50);
  final Color textGrey = const Color(0xFFB3B3B3);

  Future<void> captureImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  // Improved: Faster location fetching
  Future<void> fetchLocation() async {
    setState(() => isFetchingLocation = true);
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isFetchingLocation = false);
        return;
      }
    }

    try {
      // Step 1: Try to get last known position first (instant)
      Position? pos = await Geolocator.getLastKnownPosition();
      
      // Step 2: If no last known or it's old, get current position with 'medium' accuracy for speed
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          location = "${place.subLocality}, ${place.locality}";
          addressCtrl.text = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
          isFetchingLocation = false;
        });
      }
    } catch (e) {
      setState(() => isFetchingLocation = false);
    }
  }

  // New: Image Preview Dialog
  void _showImagePreview() {
    if (imageFile == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(imageFile!, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void submitReport() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cardGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Success", style: TextStyle(color: accentGreen)),
          content: const Text("Waste report submitted successfully", style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: accentGreen)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: const Text("Report Waste", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: bgBlack,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: imageFile == null ? captureImage : _showImagePreview,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance_rounded, color: accentGreen, size: 40),
                            const SizedBox(height: 10),
                            Text("Capture Waste Image", style: TextStyle(color: textGrey)),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  onPressed: captureImage,
                                ),
                              ),
                            ),
                            const Center(child: Icon(Icons.fullscreen, color: Colors.white54, size: 40)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: isFetchingLocation ? null : fetchLocation,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accentGreen.withOpacity(0.2), cardGrey]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      isFetchingLocation 
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentGreen))
                        : Icon(Icons.location_on, color: accentGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location.isEmpty ? "Tap to fetch location" : location,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              Text("Details", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),

              _buildTextField("Full Name", nameCtrl, Icons.person, true),
              _buildTextField("Phone Number", phoneCtrl, Icons.phone, true, keyboardType: TextInputType.phone, isPhone: true),
              _buildTextField("Complete Address", addressCtrl, Icons.map, true),
              _buildTextField("Landmark / Area", landmarkCtrl, Icons.near_me, true),
              _buildTextField("Note (Optional)", noteCtrl, Icons.note_add, false),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, bool isRequired, {TextInputType keyboardType = TextInputType.text, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) return "Required field";
          if (isPhone && value != null) {
            if (!RegExp(r'^\d{10}$').hasMatch(value)) return "Enter a valid 10-digit number";
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: accentGreen, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: textGrey, fontSize: 14),
          filled: true,
          fillColor: cardGrey,
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(15)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentGreen), borderRadius: BorderRadius.circular(15)),
          errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(15)),
          focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}