import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'auth_services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),

                    if (errorMessage != null)
                      Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)),

                    _textField(
                      emailController,
                      "Email",
                      Icons.email,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Email required";
                        }
                        if (!RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(v.trim().toLowerCase())) {
                          return "Enter valid email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    _textField(
                      passwordController,
                      "Password",
                      Icons.lock,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    _textField(
                      confirmPasswordController,
                      "Confirm Password",
                      Icons.lock,
                      isPassword: true,
                      validator: (v) {
                        if (v != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : _mainButton("Register", registerUser),

                    const SizedBox(height: 20),

                    _googleButton(),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()));
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.code == 'email-already-in-use'
            ? "Email already registered"
            : e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _textField(TextEditingController c, String hint, IconData icon,
      {bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      validator: validator,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _mainButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(text)),
    );
  }

  Widget _googleButton() {
    return OutlinedButton.icon(
      icon: Image.asset('assets/google_logo.png', height: 24),
      label: const Text("Sign up with Google"),
      onPressed: () async {
        final user = await AuthService().signInWithGoogle();
        if (user != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => HomePage(user: user)));
        }
      },
    );
  }
}
