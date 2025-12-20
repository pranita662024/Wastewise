import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportService {

  static Future<void> submitWasteReport({
    required File image,
    required String name,
    required String phone,
    required String address,
    required String landmark,
    required String note,
    required String locationText,
  }) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final uid = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 🔹 Upload image
    final imageRef = FirebaseStorage.instance
        .ref()
        .child("report_images/$uid/$timestamp.jpg");

    await imageRef.putFile(image);
    final imageUrl = await imageRef.getDownloadURL();

    // 🔹 Save Firestore document
    await FirebaseFirestore.instance
        .collection("waste_reports")
        .add({
      "userId": uid,
      "name": name,
      "phone": phone,
      "address": address,
      "landmark": landmark,
      "note": note,
      "location": locationText,
      "imageUrl": imageUrl,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
