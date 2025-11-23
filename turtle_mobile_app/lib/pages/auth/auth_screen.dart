import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../nest_selector_page.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_form.dart';
import '../../theme/ app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _svc = AuthService();

  bool isLogin = true;
  bool rememberMe = false;
  bool _loading = false;

  // controllers shared with the form
  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  final firstNameCtl = TextEditingController(); // signup only
  final lastNameCtl  = TextEditingController(); // signup only

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    emailCtl.dispose();
    passwordCtl.dispose();
    confirmCtl.dispose();
    firstNameCtl.dispose();
    lastNameCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await _svc.loadSavedEmail();
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        emailCtl.text = saved;
        rememberMe = true;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_loading) return;
    final email = emailCtl.text.trim();
    final pass  = passwordCtl.text.trim();
    final pass2 = confirmCtl.text.trim();
    final first = firstNameCtl.text.trim();
    final last  = lastNameCtl.text.trim();

    setState(() => _loading = true);
    try {
      if (rememberMe) {
        await _svc.saveEmail(email);
      } else {
        await _svc.clearSavedEmail();
      }

      if (isLogin) {
        await _svc.signIn(email: email, password: pass);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NestSelectorPage()),
        );
      } else {
        if (pass != pass2) {
          _toast("Passwords do not match");
          return;
        }
        await _svc.signUp(
          email: email,
          password: pass,
          firstName: first,
          lastName: last,
        );
        _toast("Account created! You can now log in.");
        setState(() => isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? "Authentication error");
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    const bgTop = AppColors.bgTop;       // Color(0xFF0E1A2F)
    const bgBottom = AppColors.bgBottom; // Color(0xFF0B1426)

    final w = MediaQuery.of(context).size.width;
    final heroSize = w.clamp(320.0, 440.0) * 0.52;
    final headerReserve = heroSize * 0.56;
    final heroTop = headerReserve - heroSize * 0.34;
    final heroRight = -heroSize * 0.14;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
            ),
          ),

          // soft blob
          Positioned(
            top: -90, right: -60,
            child: IgnorePointer(
              child: Container(
                width: heroSize * 1.7, height: heroSize * 1.7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x332F66F5), Color(0x112F66F5), Colors.transparent],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // hero image
          Positioned(
            top: heroTop, right: heroRight,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.035,
                child: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 28, offset: Offset(0, 14))],
                  ),
                  child: Image.asset(
                    'assets/turtle_batik.png',
                    width: heroSize, height: heroSize, fit: BoxFit.contain, filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: headerReserve),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: AuthHeader(isLogin: isLogin),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                    child: _GlassCard(
                      child: AuthForm(
                        isLogin: isLogin,
                        emailCtl: emailCtl,
                        passwordCtl: passwordCtl,
                        confirmCtl: confirmCtl,
                        firstNameCtl: firstNameCtl, // shown on Sign Up
                        lastNameCtl: lastNameCtl,   // shown on Sign Up
                        rememberMe: rememberMe,
                        loading: _loading,
                        onRememberChanged: (v) => setState(() => rememberMe = v),
                        onSwitchTab: (login) => setState(() => isLogin = login),
                        onSubmit: _handleSubmit,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
