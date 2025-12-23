import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wastewise/services/report_service.dart';

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
  bool isSubmitting = false; 
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

  void _clearForm() {
    setState(() {
      imageFile = null;
      location = "";
      nameCtrl.clear();
      phoneCtrl.clear();
      addressCtrl.clear();
      landmarkCtrl.clear();
      noteCtrl.clear();
    });
  }

  Future<void> captureImage() async {
    // Quality is set low to ensure the resulting Base64 string fits in Firestore
    final picked = await picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 20, 
      maxWidth: 600,
    );
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

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
      Position? pos = await Geolocator.getLastKnownPosition();
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
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      setState(() => isFetchingLocation = false);
    }
  }

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

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture an image")),
      );
      return;
    }

    setState(() => isSubmitting = true); 

    try {
      await ReportService.submitWasteReport(
        image: imageFile!,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        landmark: landmarkCtrl.text.trim(),
        note: noteCtrl.text.trim(),
        locationText: location,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false, 
        builder: (_) => AlertDialog(
          backgroundColor: cardGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Success", style: TextStyle(color: accentGreen)),
          content: const Text(
            "Waste report submitted successfully",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearForm(); 
              },
              child: Text("OK", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission Failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false); 
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
              // Image Upload Section
              GestureDetector(
                onTap: (isSubmitting) ? null : (imageFile == null ? captureImage : _showImagePreview),
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
                            if (!isSubmitting)
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

              // Location Section
              InkWell(
                onTap: isFetchingLocation || isSubmitting ? null : fetchLocation,
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
                onPressed: isSubmitting ? null : submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: accentGreen.withOpacity(0.3),
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        enabled: !isSubmitting, 
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) return "Required field";
          if (isPhone && value != null && value.isNotEmpty) {
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