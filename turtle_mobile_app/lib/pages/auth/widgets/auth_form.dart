import 'package:flutter/material.dart';
import '../../../theme/ app_colors.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final TextEditingController emailCtl;
  final TextEditingController passwordCtl;
  final TextEditingController confirmCtl;

  // first + last name (signup only)
  final TextEditingController firstNameCtl;
  final TextEditingController lastNameCtl;

  final bool rememberMe;
  final bool loading;
  final ValueChanged<bool> onRememberChanged;
  final ValueChanged<bool> onSwitchTab;
  final VoidCallback onSubmit;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.emailCtl,
    required this.passwordCtl,
    required this.confirmCtl,
    required this.firstNameCtl,
    required this.lastNameCtl,
    required this.rememberMe,
    required this.loading,
    required this.onRememberChanged,
    required this.onSwitchTab,
    required this.onSubmit,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.isLogin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0x18FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _tabButton('Sign In', isLogin),
              _tabButton('Sign Up', !isLogin),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // First/Last Name (Sign Up only)
        if (!isLogin) ...[
          Row(
            children: [
              Expanded(child: _label('First Name')),
              const SizedBox(width: 12),
              Expanded(child: _label('Last Name')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _field(controller: widget.firstNameCtl, hint: 'Enter first name')),
              const SizedBox(width: 12),
              Expanded(child: _field(controller: widget.lastNameCtl,  hint: 'Enter last name')),
            ],
          ),
          const SizedBox(height: 14),
        ],

        _label(isLogin ? 'Username' : 'Email'),
        _field(controller: widget.emailCtl, hint: isLogin ? 'Input username' : 'Input email'),
        const SizedBox(height: 14),

        _label('Password'),
        _field(
          controller: widget.passwordCtl,
          hint: 'Input password',
          obscure: _obscurePass,
          suffix: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),

        if (!isLogin) ...[
          const SizedBox(height: 14),
          _label('Confirm Password'),
          _field(
            controller: widget.confirmCtl,
            hint: 'Confirm password',
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ],

        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: widget.rememberMe,
              onChanged: widget.loading ? null : (v) => widget.onRememberChanged(v ?? false),
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.55)),
            ),
            Text('Remember me', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13.5)),
          ],
        ),

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.loading
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isLogin ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.loading ? null : () => widget.onSwitchTab(!isLogin),
            child: Text(
              isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
              style: const TextStyle(color: Color(0xFF8FB3FF), fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }

  // ----- helpers -----
  Expanded _tabButton(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.loading ? null : () => widget.onSwitchTab(label == 'Sign In'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
          filled: true,
          fillColor: const Color(0x1FFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF4C6BFF), width: 1.2),
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
