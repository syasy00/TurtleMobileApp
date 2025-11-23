import 'dart:async';
import 'package:flutter/material.dart';
import 'account_menu_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.isDark,
    required this.firstName,
    required this.onManageAccount,
    required this.onToggleTheme,
    required this.onLogout,           // async
    this.onBack,                      // null on Home, non-null on List page
    this.avatarRadius = 24,
  });

  final bool isDark;
  final String firstName;
  final VoidCallback? onBack;
  final VoidCallback onManageAccount;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;   // <-- async type
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final hint = TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 13);
    final hey  = TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black87);
    final backFill = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final backIcon = isDark ? Colors.white : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (onBack != null)
          Material(
            color: backFill,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          )
        else
          const SizedBox(width: 8),

        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage Home', style: hint),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('Hey, $firstName', style: hey, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        AccountMenuButton(
          isDark: isDark,
          displayName: firstName,
          onManageAccount: onManageAccount,
          onToggleTheme: onToggleTheme,
          onLogout: onLogout,                // <-- now matches async type
          avatarRadius: avatarRadius,
        ),
      ],
    );
  }
}
