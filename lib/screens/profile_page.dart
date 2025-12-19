import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'about_page.dart'; // we’ll create this next

class ProfilePage extends StatelessWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Profile Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.lightGreenAccent,
                    child: Icon(Icons.person, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? "User Name",
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.phoneNumber ?? user.email ?? "No Contact Info",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Edit",
                      style: TextStyle(color: Colors.lightGreenAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Updated List Options
            _buildListTile(Icons.stars, "Reward Points"),
            _buildListTile(Icons.history, "History"),
            _buildListTile(Icons.help_outline, "FAQ"),
            _buildListTile(Icons.info_outline, "About Us", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            }),
            _buildListTile(Icons.call, "Call Us", onTap: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '+918356983796');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            }),
            _buildListTile(Icons.share, "Share App", onTap: () {
              Share.share(
                'Check out WasteWise – the smart way to recycle responsibly! ♻️ Download now!',
              );
            }),
            _buildListTile(Icons.delete_outline, "Delete Account", onTap: () async {
              try {
                await user.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account deleted successfully.")),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting account: $e")),
                );
              }
            }),
            const SizedBox(height: 10),

            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.lightGreenAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightGreenAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.lightGreenAccent),
        onTap: onTap,
      ),
    );
  }
}
