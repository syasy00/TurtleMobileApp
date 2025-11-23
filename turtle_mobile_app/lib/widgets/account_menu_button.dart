import 'package:flutter/material.dart';


class AccountMenuButton extends StatefulWidget {
  final bool isDark;
  final String? displayName;

  final VoidCallback onManageAccount;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

 
  final double avatarRadius; // avatar R
  final double bubbleSize;   // bubble diameter
  final double haloSize;     // faint disc behind each bubble
  final double gapFromAvatar; // gap between avatar edge and first bubble
  final double verticalSpacing; // spacing between bubbles

  const AccountMenuButton({
    super.key,
    required this.isDark,
    required this.onManageAccount,
    required this.onToggleTheme,
    required this.onLogout,
    this.displayName,
    this.avatarRadius = 26,
    this.bubbleSize = 54,
    this.haloSize = 62,
    this.gapFromAvatar = 10,
    this.verticalSpacing = 64,
  });

  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton>
    with SingleTickerProviderStateMixin {
  final _avatarKey = GlobalKey();
  OverlayEntry? _entry;
  late final AnimationController _ctrl;

  String get _initial {
    final t = (widget.displayName ?? '').trim();
    return t.isEmpty ? 'A' : t.characters.first.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() => _entry == null ? _showOverlay() : _removeOverlay();

  void _removeOverlay() {
    _ctrl.reverse();
    _entry?.remove();
    _entry = null;
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final box = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final center = Offset(origin.dx + size.width / 2, origin.dy + size.height / 2);

    final media = MediaQuery.of(context);
    final safe = media.padding;
    final screen = media.size;

    _entry = OverlayEntry(
      builder: (_) => _ColumnOverlay(
        controller: _ctrl,
        center: center,
        isDark: widget.isDark,
        onDismiss: _removeOverlay,
        onManage: () { _removeOverlay(); widget.onManageAccount(); },
        onToggleTheme: () { _removeOverlay(); widget.onToggleTheme(); },
        onLogout: () async { _removeOverlay(); await widget.onLogout(); },

        // layout/visuals
        avatarRadius: widget.avatarRadius,
        bubbleSize: widget.bubbleSize,
        haloSize: widget.haloSize,
        gapFromAvatar: widget.gapFromAvatar,
        verticalSpacing: widget.verticalSpacing,
        safeLeft: 8 + safe.left,
        safeRight: screen.width - (8 + safe.right),
        safeTop: 8 + safe.top,
        safeBottom: screen.height - (8 + safe.bottom),
      ),
    );

    overlay.insert(_entry!);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _avatarKey,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: CircleAvatar(
          radius: widget.avatarRadius,
          backgroundColor: widget.isDark ? Colors.white10 : const Color(0xFFECEFF4),
          child: Text(
            _initial,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnOverlay extends StatelessWidget {
  final AnimationController controller;
  final Offset center;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onManage;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

  final double avatarRadius;
  final double bubbleSize;
  final double haloSize;
  final double gapFromAvatar;
  final double verticalSpacing;
  final double safeLeft, safeRight, safeTop, safeBottom;

  const _ColumnOverlay({
    required this.controller,
    required this.center,
    required this.isDark,
    required this.onDismiss,
    required this.onManage,
    required this.onToggleTheme,
    required this.onLogout,
    required this.avatarRadius,
    required this.bubbleSize,
    required this.haloSize,
    required this.gapFromAvatar,
    required this.verticalSpacing,
    required this.safeLeft,
    required this.safeRight,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    // Colors
    final Color bubbleBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final Color iconFg   = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final Color halo     = isDark ? Colors.white10 : Colors.black12;

    // Column X is centered to avatar, clamped to screen horizontally
    final x = center.dx.clamp(safeLeft + bubbleSize / 2, safeRight - bubbleSize / 2);

    // First bubble Y is just below avatar
    double firstY = center.dy + avatarRadius + gapFromAvatar + bubbleSize / 2;

    // Ensure entire column is visible within safe areas
    const count = 3;
    final bottomOfColumn = firstY + (count - 1) * verticalSpacing;
    if (bottomOfColumn > safeBottom) {
      // Shift upward so the last bubble is visible; keep at least under the avatar if possible.
      final overflow = bottomOfColumn - safeBottom;
      firstY = (firstY - overflow).clamp(
        center.dy + avatarRadius + 4, // never overlap the avatar
        safeBottom - (count - 1) * verticalSpacing,
      );
    }
    // Also ensure it doesn't go above safeTop (rare)
    if (firstY - bubbleSize / 2 < safeTop) {
      firstY = safeTop + bubbleSize / 2;
    }

    final items = <_Item>[
      _Item(Icons.manage_accounts_outlined, 'Manage', () async => onManage()),
      _Item(Icons.brightness_6_rounded,     'Dark/Light', () async => onToggleTheme()),
      _Item(Icons.logout_rounded,           'Logout', () async => onLogout()),
    ];

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onDismiss,
        child: Stack(
          children: List.generate(items.length, (i) {
            final target = Offset(x, firstY + i * verticalSpacing);
            final start  = center; // animate out from avatar center

            final anim = CurvedAnimation(
              parent: controller,
              curve: Interval(0.06 * i, 0.85, curve: Curves.easeOutCubic),
              reverseCurve: Curves.easeIn,
            );

            return AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                final pos = Offset.lerp(start, target, anim.value)!;
                final scale = Tween(begin: 0.85, end: 1.0).transform(anim.value);
                final opacity = Tween<double>(begin: 0, end: 1).transform(anim.value);

                return Positioned(
                  left: pos.dx - bubbleSize / 2,
                  top: pos.dy - bubbleSize / 2,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: _ActionBubble(
                        size: bubbleSize,
                        haloSize: haloSize,
                        bg: bubbleBg,
                        icon: items[i].icon,
                        iconColor: iconFg,
                        tooltip: items[i].tooltip,
                        onTap: items[i].onTap,
                        isDark: isDark,
                        haloColor: halo,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;
  _Item(this.icon, this.tooltip, this.onTap);
}

class _ActionBubble extends StatelessWidget {
  final double size;
  final double haloSize;
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool isDark;
  final Color haloColor;

  const _ActionBubble({
    required this.size,
    required this.haloSize,
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    required this.haloColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Container(
            width: haloSize,
            height: haloSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: haloColor),
          ),
        ),
        Tooltip(
          message: tooltip,
          preferBelow: true,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              customBorder: const CircleBorder(),
              radius: size / 2 + 10,
              onTap: onTap,
              splashColor: iconColor.withOpacity(0.12),
              highlightShape: BoxShape.circle,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
