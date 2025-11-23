import 'package:flutter/material.dart';
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
    // OUTER padding around the whole pill
    const outerPad = EdgeInsets.fromLTRB(16, 4, 16, 12);

    // INNER padding inside the pill
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
                  // Pill background + icons/labels
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
                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onTap(i),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  it.icon,
                                  color: active
                                      ? AppColors.primary
                                      : iconIdle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  it.label.isEmpty ? " " : it.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? AppColors.primary
                                        : textIdle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Blue indicator
                  Positioned(
                    top: 0,
                    left: indicatorLeft.clamp(
                        pillHPad, outerWidth - pillHPad - indicatorWidth),
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

                  // Bottom track (decorative)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 140,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white12 : AppColors.gray200,
                        borderRadius: BorderRadius.circular(6),
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
