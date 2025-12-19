import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateProfilePage extends StatefulWidget {
  final User user;
  const UpdateProfilePage({super.key, required this.user});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(widget.user.uid);

    final doc = await docRef.get();
    if (doc.exists) {
      _nameController.text = doc['name'] ?? '';
      _phoneController.text = doc['phone'] ?? '';
    }

    // Email always from FirebaseAuth
    _emailController.text = widget.user.email ?? '';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': widget.user.email, // store for easy access
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text(
          "Update Your Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Together we can simplify\nWaste Management.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Name field
              _buildInputField(
                icon: Icons.person_outline,
                controller: _nameController,
                label: "Name",
              ),
              const SizedBox(height: 16),

              // Phone field
              _buildInputField(
                icon: Icons.phone_outlined,
                controller: _phoneController,
                label: "Phone Number",
                suffix: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "change",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email field (read-only)
              _buildInputField(
                icon: Icons.email_outlined,
                controller: _emailController,
                label: "Email",
                readOnly: true,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA8C65D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightGreenAccent),
        title: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? "Enter $label" : null,
        ),
        trailing: suffix,
      ),
    );
  }
}
