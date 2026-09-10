import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'screens/screens.dart';
import 'widgets/auth_dialog.dart';

void main() {
  runApp(const NovelPlatformApp());
}

class NovelPlatformApp extends StatefulWidget {
  const NovelPlatformApp({super.key});

  @override
  State<NovelPlatformApp> createState() => _NovelPlatformAppState();
}

class _NovelPlatformAppState extends State<NovelPlatformApp> {
  @override
  void initState() {
    super.initState();
    globalAppState.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kho Truyện Web',
      debugShowCheckedModeBanner: false,
      themeMode: globalAppState.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: const CardThemeData(elevation: 2),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardThemeData(elevation: 2),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final List<Widget> screens = [
      const ExploreScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
      if (state.currentUser?.role == 'admin') const AdminDashboardScreen(),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: Colors.deepPurpleAccent),
            const SizedBox(width: 8),
            Text(state.t('app_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(state.themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            tooltip: 'Đổi nền Sáng / Tối',
            onPressed: state.toggleTheme,
          ),
          TextButton(
            onPressed: state.toggleLanguage,
            child: Text(
              state.language.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          if (state.currentUser == null)
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AuthDialog(),
              ),
              icon: const Icon(Icons.login, size: 18),
              label: Text(state.t('login')),
            )
          else
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: state.currentUser!.role == 'admin' ? Colors.redAccent : Colors.deepPurple,
                      child: Text(state.currentUser!.username[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(state.currentUser!.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              onSelected: (val) {
                if (val == 'logout') state.logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text('Vai trò: ${state.currentUser!.role.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(state.t('logout'), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: state.t('nav_explore')),
          NavigationDestination(icon: const Icon(Icons.bookmark_outline), selectedIcon: const Icon(Icons.bookmark), label: state.t('nav_favorites')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: state.t('nav_profile')),
          if (state.currentUser?.role == 'admin')
            NavigationDestination(icon: const Icon(Icons.admin_panel_settings_outlined), selectedIcon: const Icon(Icons.admin_panel_settings), label: state.t('nav_admin')),
        ],
      ),
    );
  }
}