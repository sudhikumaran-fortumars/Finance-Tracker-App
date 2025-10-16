import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/data_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/simple_auth_screen.dart';
import 'services/simple_auth_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/daily_entry_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/payment_handling_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/bonus_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Finance Tracker',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppBarTitle(navigationProvider.currentView)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    onPressed: () => themeProvider.toggleTheme(),
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await _logout(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.account_circle_rounded),
              ),
            ],
          ),
          body: _getCurrentScreen(navigationProvider.currentView),
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            navigationProvider,
          ),
        );
      },
    );
  }

  String _getAppBarTitle(ViewId viewId) {
    switch (viewId) {
      case ViewId.dashboard:
        return 'Dashboard';
      case ViewId.users:
        return 'User Management';
      case ViewId.entry:
        return 'Daily Entry';
      case ViewId.reports:
        return 'Reports';
      case ViewId.payments:
        return 'Payment Handling';
      case ViewId.notifications:
        return 'Notifications';
      case ViewId.bonus:
        return 'Bonus Management';
    }
  }

  Widget _getCurrentScreen(ViewId viewId) {
    switch (viewId) {
      case ViewId.dashboard:
        return const DashboardScreen();
      case ViewId.users:
        return const UserManagementScreen();
      case ViewId.entry:
        return const DailyEntryScreen();
      case ViewId.reports:
        return const ReportsScreen();
      case ViewId.payments:
        return const PaymentHandlingScreen();
      case ViewId.notifications:
        return const NotificationsScreen();
      case ViewId.bonus:
        return const BonusScreen();
    }
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    NavigationProvider navigationProvider,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                navigationProvider,
                ViewId.dashboard,
                Icons.dashboard_rounded,
                'Dashboard',
              ),
              _buildNavItem(
                context,
                navigationProvider,
                ViewId.users,
                Icons.people_rounded,
                'Users',
              ),
              _buildNavItem(
                context,
                navigationProvider,
                ViewId.entry,
                Icons.add_card_rounded,
                'Entry',
              ),
              _buildNavItem(
                context,
                navigationProvider,
                ViewId.reports,
                Icons.analytics_rounded,
                'Reports',
              ),
              _buildMoreButton(context, navigationProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavigationProvider navigationProvider,
    ViewId viewId,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = navigationProvider.currentView == viewId;

    return Expanded(
      child: GestureDetector(
        onTap: () => navigationProvider.navigateTo(viewId),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(
    BuildContext context,
    NavigationProvider navigationProvider,
  ) {
    final theme = Theme.of(context);
    final isSelected =
        navigationProvider.currentView == ViewId.notifications;

    return Expanded(
      child: GestureDetector(
        onTap: () => _showMoreOptions(context, navigationProvider),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  'More',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(
    BuildContext context,
    NavigationProvider navigationProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'More Options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                  _buildMoreOption(
                    context,
                    'Payment Handling',
                    Icons.payment_rounded,
                    () {
                      Navigator.pop(context);
                      navigationProvider.navigateTo(ViewId.payments);
                    },
                  ),
                  _buildMoreOption(
                    context,
                    'Notifications',
                    Icons.notifications_rounded,
                    () {
                      Navigator.pop(context);
                      navigationProvider.navigateTo(ViewId.notifications);
                    },
                  ),
                  _buildMoreOption(
                    context,
                    'Bonus Management',
                    Icons.stars_rounded,
                    () {
                      Navigator.pop(context);
                      navigationProvider.navigateTo(ViewId.bonus);
                    },
                  ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      SimpleAuthService.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SimpleAuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

