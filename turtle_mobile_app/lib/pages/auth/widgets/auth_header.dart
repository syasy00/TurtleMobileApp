import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final bool isLogin;
  const AuthHeader({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.00), Colors.black.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(isLogin),
          const SizedBox(height: 6),
          Text(
            isLogin
                ? "Hello again, you've been missed!"
                : 'Sign up now to get started with an account',
            style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13.5, height: 1.25),
          ),
        ],
      ),
    );
  }

  Widget _title(bool isLogin) {
    if (isLogin) {
      return const Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
          children: [TextSpan(text: 'Welcome Back '), TextSpan(text: '👋')],
        ),
        maxLines: 1, overflow: TextOverflow.ellipsis,
      );
    }
    return const Text.rich(
      TextSpan(
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
        children: [TextSpan(text: 'Create an Account '), TextSpan(text: '✨')],
      ),
      maxLines: 1, overflow: TextOverflow.ellipsis,
    );
  }
}
