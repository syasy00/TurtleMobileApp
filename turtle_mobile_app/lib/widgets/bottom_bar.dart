// lib/widgets/bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/db.dart'; // 👈 add this
import '../theme/ app_colors.dart';

class FancyItem {
  final IconData icon;
  final String label;
  const FancyItem({required this.icon, required this.label});
}

class FancyBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<FancyItem> items;
  final ValueChanged<int> onTap;
  final bool isDark;

  const FancyBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    const outerPad = EdgeInsets.fromLTRB(16, 4, 16, 12);
    const double pillHPad = 18.0;
    const double pillVPadTop = 14.0;
    const double pillVPadBottom = 14.0;
    const double indicatorWidth = 46.0;
    const double indicatorHeight = 4.0;

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final iconIdle = isDark ? Colors.white70 : AppColors.gray500;
    final textIdle = iconIdle;

    return SafeArea(
      top: false,
      child: Padding(
        padding: outerPad,
        child: SizedBox(
          height: 86,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final outerWidth = constraints.maxWidth;
              final innerWidth = outerWidth - (pillHPad * 2);
              final segWidth =
                  (items.isEmpty ? innerWidth : innerWidth / items.length);
              final double indicatorLeft = pillHPad +
                  (segWidth * currentIndex) +
                  (segWidth - indicatorWidth) / 2;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // pill background
                  Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(
                        pillHPad, pillVPadTop, pillHPad, pillVPadBottom),
                    child: Row(
                      children: List.generate(items.length, (i) {
                        final it = items[i];
                        final active = i == currentIndex;

                        final labelLower = it.label.toLowerCase();
                        final isNotificationItem =
                            labelLower.contains("alert") ||
                                labelLower.contains("notif");

                        Widget iconWidget = Icon(
                          it.icon,
                          color: active ? AppColors.primary : iconIdle,
                        );

                        if (isNotificationItem) {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            iconWidget = StreamBuilder<DatabaseEvent>(
                              stream: rtdb // 👈 use rtdb
                                  .ref('alerts/$uid')
                                  .limitToLast(10)
                                  .onValue,
                              builder: (context, snapshot) {
                                bool hasUnread = false;

                                if (snapshot.hasData &&
                                    snapshot.data!.snapshot.value != null) {
                                  final data = snapshot.data!.snapshot.value;

                                  try {
                                    if (data is Map) {
                                      for (final v in data.values) {
                                        if (v is Map && v['read'] == false) {
                                          hasUnread = true;
                                          break;
                                        }
                                      }
                                    } else if (data is List) {
                                      for (final v in data) {
                                        if (v is Map && v['read'] == false) {
                                          hasUnread = true;
                                          break;
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    print("Error parsing badge data: $e");
                                  }
                                }

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      it.icon,
                                      color:
                                          active ? AppColors.primary : iconIdle,
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: bg,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          }
                        }

                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onTap(i),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                iconWidget,
                                const SizedBox(height: 6),
                                Text(
                                  it.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        active ? AppColors.primary : textIdle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // indicator
                  Positioned(
                    top: 0,
                    left: indicatorLeft.clamp(
                      pillHPad,
                      outerWidth - pillHPad - indicatorWidth,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
