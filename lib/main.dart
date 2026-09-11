import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'screens/screens.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/app_state.dart';
import 'screens/screens.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/settings_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://trozbojbfgjpqkyuxtaz.supabase.co',
    anonKey: 'sb_publishable_OTzZAfBPAkmRpBq6J9qFgA_xWzy-J_M',
  );

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
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        canvasColor: const Color(0xFF121212),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: Colors.deepPurple.withValues(alpha: 0.3),
        ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final List<Widget> screens = [
          const ExploreScreen(),
          const FavoritesScreen(),
          const ProfileScreen(),
          if (state.currentUser?.role == 'author')
            const CreatorStudioScreen(),
          // CHỈ HIỂN THỊ ADMIN DASHBOARD TRÊN MÁY TÍNH / DESKTOP
          if (state.currentUser?.role == 'admin' && isDesktop)
            const AdminDashboardScreen(),
        ];

        final List<NavigationDestination> navDestinations = [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: state.t('nav_explore'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_outline),
            selectedIcon: const Icon(Icons.bookmark),
            label: state.t('nav_favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: state.t('nav_profile'),
          ),
          if (state.currentUser?.role == 'author')
            NavigationDestination(
              icon: const Icon(Icons.draw_outlined),
              selectedIcon: const Icon(Icons.draw),
              label: state.t('nav_studio'),
            ),
          // CHỈ HIỆN ICON QUẢN TRỊ KHI RỘNG >= 768px
          if (state.currentUser?.role == 'admin' && isDesktop)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: state.t('nav_admin'),
            ),
        ];

        final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories, color: Colors.deepPurpleAccent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    state.t('app_title'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            actions: [
              if (MediaQuery.of(context).size.width < 600) ...[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: state.t('settings'),
                  onSelected: (val) {
                    if (val == 'settings') {
                      showDialog(context: context, builder: (_) => const SettingsDialog());
                    } else if (val == 'theme') {
                      state.toggleTheme();
                    } else if (val == 'lang') {
                      state.toggleLanguage();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(state.t('settings')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'theme',
                      child: Row(
                        children: [
                          Icon(state.themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(state.themeMode == ThemeMode.light ? state.t('dark_mode') : state.t('light_mode')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'lang',
                      child: Row(
                        children: [
                          const Icon(Icons.language_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text('${state.t('lang_label')}: ${state.language.toUpperCase()}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: state.t('settings'),
                  onPressed: () => showDialog(context: context, builder: (_) => const SettingsDialog()),
                ),
                IconButton(
                  icon: Icon(state.themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                  tooltip: state.themeMode == ThemeMode.light ? state.t('dark_mode') : state.t('light_mode'),
                  onPressed: state.toggleTheme,
                ),
                TextButton(
                  onPressed: state.toggleLanguage,
                  child: Text(
                    state.language.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const VerticalDivider(width: 16, indent: 15, endIndent: 15),
              ],
              if (state.currentUser == null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AuthDialog(),
                    ),
                    icon: const Icon(Icons.login, size: 16),
                    label: Text(state.t('login'), style: const TextStyle(fontSize: 13)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PopupMenuButton<String>(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: state.currentUser!.role == 'admin' ? Colors.redAccent : Colors.deepPurple,
                            child: Text(state.currentUser!.username[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                          const SizedBox(width: 6),
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
                        child: Text('${state.t('role')}: ${state.currentUser!.role.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                ),
            ],
          ),
          body: screens[safeIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            destinations: navDestinations,
          ),
        );
      },
    );
  }
}