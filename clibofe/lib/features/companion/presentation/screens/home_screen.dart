import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../../../../domain/user/user.dart';
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
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
      Center(child: Text("Chat Log History List View (Placeholder)", style: theme.textTheme.muted)),
      Center(child: Text("Lottie Behaviour Settings View (Placeholder)", style: theme.textTheme.muted)),
      Center(child: Text("Token Calculations & Metrics View (Placeholder)", style: theme.textTheme.muted)),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
              color: theme.colorScheme.primary.withOpacity(0.05),
              width: double.infinity,
              child: Row(
                children: [
                  ShadAvatar(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    placeholder: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U'),
                    backgroundColor: const Color.fromARGB(50, 45, 23, 255),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.large,
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

            ListTile(
              leading: Icon(LucideIcons.layers, color: theme.colorScheme.foreground),
              title: Text(
                "Toggle Floating Overlay",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleOverlay();
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activitySquare200, color: theme.colorScheme.foreground),
              title: Text(
                "Enter API key",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activitySquare200, color: theme.colorScheme.foreground),
              title: Text(
                "New Chat",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activitySquare200, color: theme.colorScheme.foreground),
              title: Text(
                "Search Chat History",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activitySquare200, color: theme.colorScheme.foreground),
              title: Text(
                "Library",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(LucideIcons.activitySquare200, color: theme.colorScheme.foreground),
              title: Text(
                "Recent",
                style: theme.textTheme.p,
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),
            const Divider(),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
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
