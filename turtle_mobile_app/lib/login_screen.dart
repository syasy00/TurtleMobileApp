import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nest_selector.dart'; // Make ure the path is correct

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool rememberMe = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        emailController.text = savedEmail;
        rememberMe = true;
      });
    }
  }

  Future<void> _handleAuth() async {
    final auth = FirebaseAuth.instance;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        prefs.setString('saved_email', email);
      } else {
        prefs.remove('saved_email');
      }

      if (isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NestSelectorPage()),
        );
      } else {
        if (password != confirmPassword) {
          _showMessage("Passwords do not match");
          return;
        }
        await auth.createUserWithEmailAndPassword(email: email, password: password);
        _showMessage("Account created! You can now log in.");
        setState(() => isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Authentication error");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "Let's Get You ${isLogin ? "Sign In" : "Sign Up"}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access your account and explore new opportunities.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              _tabButton('Sign In', isLogin),
                              _tabButton('Sign Up', !isLogin),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          controller: emailController,
                          hintText: 'Email Address',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: passwordController,
                          hintText: 'Password',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          showVisibilityToggle: true,
                          isObscure: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        if (!isLogin)
                          _buildInputField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            showVisibilityToggle: true,
                            isObscure: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        if (!isLogin) const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (val) => setState(() => rememberMe = val ?? false),
                            ),
                            const Text("Remember me")
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(isLogin ? 'Login' : 'Sign Up'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => isLogin = !isLogin),
                            child: Text(
                              isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _tabButton(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = label == 'Sign In'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    bool showVisibilityToggle = false,
    bool isObscure = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}
