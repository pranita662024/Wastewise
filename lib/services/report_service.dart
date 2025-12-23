import 'dart:io';
import 'dart:convert'; // Required for base64Encode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  /// Submit waste report to Firestore ONLY (No Storage needed)
  static Future<void> submitWasteReport({
    required File image,
    required String name,
    required String phone,
    required String address,
    required String landmark,
    required String note,
    required String locationText,
  }) async {
    try {
      print("📡 ReportService: Starting Firestore-only submission");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String uid = user.uid;

      // 1. Convert image to Base64 String
      print("📤 Converting image to Base64...");
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Safety Check: Firestore limit is 1MB per document
      // base64 strings are ~33% larger than binary files.
      if (base64Image.length > 1000000) {
        throw Exception("The image is too large for the database. Please reduce camera quality.");
      }

      // 3. Save to Firestore (Collection: waste_reports)
      await FirebaseFirestore.instance.collection("waste_reports").add({
        "userId": uid,
        "name": name,
        "phone": phone,
        "address": address,
        "landmark": landmark,
        "note": note,
        "locationText": locationText,
        "imageUrl": base64Image, // Actual image data saved as text
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("🎉 Firestore document created successfully!");
    } catch (e) {
      print("🚨 Firestore Error: $e");
      rethrow;
    }
  }

  /// Fetch reports for logged-in user (for History Page)
  static Stream<QuerySnapshot> getUserReports() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("waste_reports")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}