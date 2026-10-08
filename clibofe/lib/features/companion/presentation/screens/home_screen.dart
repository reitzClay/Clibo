import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/repositories/auth/auth_repository.dart';
import 'package:clibofe/domain/user/user.dart';
import '../tabs/config_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/metrics_tab.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = locator<AuthRepository>();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authRepository.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.shareData("CLEAR_CHAT");
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Account & Data", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to permanently delete your account? All your chat history, usage data, and account records will be permanently erased. This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Permanently Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.shareData("CLEAR_CHAT");
          await FlutterOverlayWindow.closeOverlay();
        }
      } catch (_) {}

      final bool success = await _authRepository.deleteAccount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Your account and data have been permanently deleted."
                : "Account erased locally.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _toggleOverlay() async {
    final bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      final bool? status = await FlutterOverlayWindow.requestPermission();
      if (status != true) return;
    }

    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    } else {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Clibo Assistant",
        overlayContent: "Floating assistant is active",
        height: 200,
        width: 200,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        positionGravity: PositionGravity.auto,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final List<Widget> tabViews = [
      HistoryTab(tabController: _tabController),
      const ConfigTab(),
      const MetricsTab(),
    ];

    final userName = _currentUser?.name ?? "Developer Mode";
    final userEmail = _currentUser?.email ?? "clayton@clibo.ai";

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.card,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.foreground),
        title: Text(
          "Clibo Workspace",
          style: theme.textTheme.h4,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.card,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.mutedForeground,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Config'),
                Tab(text: 'Metrics'),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: theme.colorScheme.card,
        child: Column(
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              width: double.infinity,
              child: Row(
                children: [
                  if (_currentUser?.pictureUrl != null && _currentUser!.pictureUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        _currentUser!.pictureUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ShadAvatar(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            placeholder: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U'),
                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    ShadAvatar(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      placeholder: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U'),
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userEmail,
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(LucideIcons.layers, color: Colors.blueAccent),
              title: Text(
                "Toggle Floating Assistant",
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleOverlay();
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.messageSquare, color: theme.colorScheme.foreground),
              title: Text(
                "Clear Overlay Chat",
                style: theme.textTheme.p,
              ),
              onTap: () async {
                Navigator.pop(context);
                if (await FlutterOverlayWindow.isActive()) {
                  await FlutterOverlayWindow.shareData("CLEAR_CHAT");
                }
              },
            ),

            const Divider(indent: 16, endIndent: 16),

            ListTile(
              leading: Icon(LucideIcons.history, color: theme.colorScheme.foreground),
              title: Text(
                "Chat History",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.settings, color: theme.colorScheme.foreground),
              title: Text(
                "AI Provider Config",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activity, color: theme.colorScheme.foreground),
              title: Text(
                "Usage & Metrics",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),

            const Spacer(),
            const Divider(),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(LucideIcons.logOut, color: theme.colorScheme.destructive),
                      title: Text(
                        "Logout",
                        style: theme.textTheme.p.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      title: const Text(
                        "Delete Account & Data",
                        style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleDeleteAccount();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }
}
