import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../../../network/presentation/screens/network_screen.dart';
import '../../../dns/presentation/screens/dns_screen.dart';
import '../../../sessions/presentation/screens/sessions_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../vpn/presentation/screens/vpn_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Define screens as a getter to ensure fresh instances
  List<Widget> get _screens => [
    const NetworkScreen(),
    const DnsScreen(),
    const SessionsScreen(),
    const VpnScreen(),  // This should be at index 3
    const SettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    print('Navigation: Selected index $index, showing ${_screens[index].runtimeType}');
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    print('Current index: $_currentIndex, showing ${_screens[_currentIndex].runtimeType}'); // Debug print

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications screen
            },
          ),
        ],
      ),
      body: _screens[_currentIndex], // Use direct indexing instead of IndexedStack
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wifi_outlined),
            selectedIcon: Icon(Icons.wifi),
            label: 'Network',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'DNS',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_lock_outlined),
            selectedIcon: Icon(Icons.vpn_lock),
            label: 'VPN',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (user?.name ?? 'U')[0].toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('My Devices'),
              onTap: () {
                // TODO: Implement devices screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Security Settings'),
              onTap: () {
                // TODO: Implement security settings screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                // TODO: Implement help & support screen
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
} 