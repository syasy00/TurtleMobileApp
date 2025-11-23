// lib/widgets/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/db.dart';
import '../widgets/bottom_bar.dart';
import '../pages/nest_selector_page.dart';

class NotificationsPage extends StatefulWidget {
  final bool isDarkMode;
  final String? nestId; // optional: show alerts for one shell

  const NotificationsPage({
    super.key,
    required this.isDarkMode,
    this.nestId,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final DatabaseReference _alertsRef;
  late final String _uid;

  // UI state
  int _tabIndex = 2; // Home(0), AI(1), Alerts(2)
  bool _showUnreadOnly = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _alertsRef = rtdb.ref('alerts/$_uid'); // alerts/<uid>/<autoId>
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---- helpers --------------------------------------------------------------

  String _formatAgo(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String _sectionFor(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yday = today.subtract(const Duration(days: 1));
    final target = DateTime(d.year, d.month, d.day);
    if (target == today) return "Today";
    if (target == yday) return "Yesterday";
    return "Earlier";
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    final Color bg      = dark ? const Color(0xFF0E0F12) : const Color(0xFFF5F7FA);
    final Color card    = dark ? const Color(0xFF1B1E24) : Colors.white;
    final Color border  = dark ? const Color(0xFF2A2E36) : const Color(0xFFE8EDF5);
    final Color text    = dark ? Colors.white : const Color(0xFF1E2430);
    final Color subtle  = dark ? Colors.white70 : const Color(0xFF6B7280);
    final Color primary = const Color(0xFF6D5DF6);

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppBar(
            backgroundColor: bg,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            automaticallyImplyLeading: false, // no back button
            title: Text(
              'Notifications',
              style: TextStyle(color: text, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search, color: subtle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search alerts…',
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: subtle,
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          // Filter chips + counts
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ChipsRow(
              dark: dark,
              onToggleUnread: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
              unreadOnly: _showUnreadOnly,
              alertsRef: _alertsRef,
              nestFilter: widget.nestId,
              text: text,
              subtle: subtle,
              border: border,
              card: card,
              primary: primary,
            ),
          ),

          const SizedBox(height: 6),

          // Stream list
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _alertsRef.orderByChild('createdAt').onValue,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final raw = (snap.data!.snapshot.value as Map?) ?? {};
                var items = raw.entries.map((e) {
                  final m = (e.value as Map).cast<String, dynamic>();
                  return _AlertItem(
                    id: e.key!,
                    nestId: (m['nestId'] ?? '') as String,
                    nestName: (m['nestName'] ?? 'Unknown') as String,
                    title: (m['title'] ?? '') as String,
                    body: (m['body'] ?? '') as String,
                    level: (m['level'] ?? 'info') as String, // info|warn|critical
                    createdAt: (m['createdAt'] ?? 0) as int,
                    read: (m['read'] ?? false) as bool,
                  );
                }).where((it) => widget.nestId == null || it.nestId == widget.nestId).toList();

                // search + unread filters
                final q = _searchCtrl.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  items = items.where((it) =>
                      it.title.toLowerCase().contains(q) ||
                      it.body.toLowerCase().contains(q) ||
                      it.nestName.toLowerCase().contains(q)).toList();
                }
                if (_showUnreadOnly) {
                  items = items.where((it) => !it.read).toList();
                }

                items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (items.isEmpty) {
                  return _EmptyState(dark: dark);
                }

                // Group into sections
                final sections = <String, List<_AlertItem>>{};
                for (final it in items) {
                  final sec = _sectionFor(
                      DateTime.fromMillisecondsSinceEpoch(it.createdAt).toLocal());
                  sections.putIfAbsent(sec, () => []).add(it);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: sections.entries.expand((entry) sync* {
                    yield Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: Text(entry.key,
                          style: TextStyle(
                              color: subtle,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .2)),
                    );
                    for (final it in entry.value) {
                      final Color badge = switch (it.level) {
                        'critical' => Colors.redAccent,
                        'warn'     => Colors.orangeAccent,
                        _          => primary,
                      };
                      yield Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(dark ? .35 : .06),
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: badge.withOpacity(.15),
                            child: Icon(
                              it.level == 'critical'
                                  ? Icons.warning_amber_rounded
                                  : it.level == 'warn'
                                      ? Icons.report_gmailerrorred_outlined
                                      : Icons.notifications_outlined,
                              color: badge,
                            ),
                          ),
                          title: Text(it.title,
                              style: TextStyle(
                                  color: text, fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${it.nestName} • ${_formatAgo(it.createdAt)}\n${it.body}',
                            style: TextStyle(color: subtle, height: 1.25),
                          ),
                          isThreeLine: true,
                          trailing: it.read
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF3B82F6), // blue dot
                                      shape: BoxShape.circle),
                                ),
                          onTap: () async {
                            await _alertsRef.child('${it.id}/read').set(true);
                          },
                        ),
                      );
                    }
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),

      // Keep the global bottom bar
      bottomNavigationBar: FancyBottomBar(
        currentIndex: _tabIndex,
        isDark: widget.isDarkMode,
        items: const [
          FancyItem(icon: Icons.home_outlined,          label: 'Home'),
          FancyItem(icon: Icons.auto_awesome_outlined,  label: 'AI'),
          FancyItem(icon: Icons.notifications_outlined, label: 'Alerts'),
        ],
        onTap: (i) {
          if (i == _tabIndex) return;
          setState(() => _tabIndex = i);
          if (i == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const NestSelectorPage()),
              (route) => false,
            );
          } else if (i == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const NestSelectorPage()),
              (route) => false,
            );
          }
          // i==2 stays here (Alerts)
        },
      ),
    );
  }
}

// ---- chips row (All / Unread with live counts) ------------------------------

class _ChipsRow extends StatelessWidget {
  final DatabaseReference alertsRef;
  final String? nestFilter;
  final VoidCallback onToggleUnread;
  final bool unreadOnly;
  final bool dark;
  final Color text, subtle, border, card, primary;

  const _ChipsRow({
    required this.alertsRef,
    required this.nestFilter,
    required this.onToggleUnread,
    required this.unreadOnly,
    required this.dark,
    required this.text,
    required this.subtle,
    required this.border,
    required this.card,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: alertsRef.onValue,
      builder: (context, snap) {
        int all = 0, unread = 0;
        final raw = (snap.data?.snapshot.value as Map?) ?? {};
        raw.forEach((_, v) {
          final m = (v as Map).cast<String, dynamic>();
          final matches = nestFilter == null || (m['nestId'] ?? '') == nestFilter;
          if (matches) {
            all += 1;
            if (!(m['read'] ?? false)) unread += 1;
          }
        });

        Widget chip({
          required String label,
          required int count,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? primary.withOpacity(.12) : card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? primary : border),
              ),
              child: Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? primary : text,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? primary : border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                          color: selected ? Colors.white : subtle,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Row(
          children: [
            chip(
              label: 'All',
              count: all,
              selected: !unreadOnly,
              onTap: () => onToggleUnread(),
            ),
            const SizedBox(width: 10),
            chip(
              label: 'Unread',
              count: unread,
              selected: unreadOnly,
              onTap: () => onToggleUnread(),
            ),
          ],
        );
      },
    );
  }
}

// ---- models & empty state ----------------------------------------------------

class _AlertItem {
  final String id, nestId, nestName, title, body, level;
  final int createdAt;
  final bool read;
  _AlertItem({
    required this.id,
    required this.nestId,
    required this.nestName,
    required this.title,
    required this.body,
    required this.level,
    required this.createdAt,
    required this.read,
  });
}

class _EmptyState extends StatelessWidget {
  final bool dark;
  const _EmptyState({required this.dark});

  @override
  Widget build(BuildContext context) {
    final Color text = dark ? Colors.white70 : const Color(0xFF6B7280);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: text),
            const SizedBox(height: 12),
            Text(
              "No alerts yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
            ),
            const SizedBox(height: 6),
            Text(
              "You’ll see temperature / humidity warnings here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: text),
            ),
          ],
        ),
      ),
    );
  }
}
