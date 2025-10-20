import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/daily_entry_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/payment_handling_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/bonus_screen.dart';
import '../screens/reset_app_screen.dart';
import '../services/role_auth_service.dart';
import '../models/user_role.dart';

class SimpleMainScreen extends StatefulWidget {
  const SimpleMainScreen({super.key});

  @override
  State<SimpleMainScreen> createState() => _SimpleMainScreenState();
}

class _SimpleMainScreenState extends State<SimpleMainScreen> {
  UserRole? _currentUserRole;
  String? _currentUserName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final role = await RoleAuthService.getCurrentUserRole();
    final name = await RoleAuthService.getCurrentUserName();
    print('🔍 Loaded user info - Role: $role, Name: $name');
    setState(() {
      _currentUserRole = role;
      _currentUserName = name;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Force staff users to start with Users screen instead of Dashboard
    if (_currentUserRole == UserRole.staff) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigationProvider = context.read<NavigationProvider>();
        navigationProvider.setInitialViewForStaff();
      });
    }
    
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getAppBarTitle(navigationProvider.currentView)),
                if (_currentUserRole != null && _currentUserName != null)
                  Text(
                    '${_currentUserName} (${_currentUserRole!.displayName})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
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
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
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
    // Check if staff is trying to access restricted screens
    if (_currentUserRole == UserRole.staff) {
      print('🔍 Staff user trying to access: $viewId');
      switch (viewId) {
        case ViewId.dashboard:
        case ViewId.reports:
        case ViewId.payments:
        case ViewId.notifications:
        case ViewId.bonus:
          // Redirect staff to Users screen if they try to access restricted screens
          print('🔍 Redirecting staff from $viewId to Users');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigationProvider = context.read<NavigationProvider>();
            navigationProvider.navigateTo(ViewId.users);
          });
          return const UserManagementScreen();
        case ViewId.users:
        case ViewId.entry:
          // Allow staff to access these screens
          print('🔍 Staff accessing allowed screen: $viewId');
          break;
      }
    }
    
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
            children: _buildNavigationItems(context, navigationProvider),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems(
    BuildContext context,
    NavigationProvider navigationProvider,
  ) {
    final items = <Widget>[];
    
    // If role is null, default to staff permissions (limited access)
    final userRole = _currentUserRole ?? UserRole.staff;

    // For staff: strictly show only Users and Entry
    if (userRole == UserRole.staff) {
      print('🔍 Building navigation for STAFF - showing only Users and Entry');
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.users,
        Icons.people_rounded,
        'Users',
      ));
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.entry,
        Icons.add_card_rounded,
        'Entry',
      ));
      return items;
    }

    // Admin and other roles get full navigation
    // Dashboard - Admin only
    if (userRole.canAccessDashboard) {
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.dashboard,
        Icons.dashboard_rounded,
        'Dashboard',
      ));
    }

    // Users - Both Admin and Staff
    if (userRole.canAccessUserManagement) {
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.users,
        Icons.people_rounded,
        'Users',
      ));
    }

    // Daily Entry - Both Admin and Staff
    if (userRole.canAccessDailyEntry) {
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.entry,
        Icons.add_card_rounded,
        'Entry',
      ));
    }

    // Reports - Admin only
    if (userRole.canAccessReports) {
      items.add(_buildNavItem(
        context,
        navigationProvider,
        ViewId.reports,
        Icons.analytics_rounded,
        'Reports',
      ));
    }

    // More button - Admin only
    if (userRole.canAccessDashboard) {
      items.add(_buildMoreButton(context, navigationProvider));
    }

    return items;
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
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
    final isSelected = navigationProvider.currentView == ViewId.notifications ||
        navigationProvider.currentView == ViewId.payments ||
        navigationProvider.currentView == ViewId.bonus;

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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'More Options',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Payment Handling - Admin only
            if ((_currentUserRole ?? UserRole.staff).canAccessPaymentHandling)
              _buildMoreOption(
                context,
                navigationProvider,
                ViewId.payments,
                Icons.payment_rounded,
                'Payment Handling',
                'Manage payment processing',
              ),
            // Notifications - Admin only
            if ((_currentUserRole ?? UserRole.staff).canAccessNotifications)
              _buildMoreOption(
                context,
                navigationProvider,
                ViewId.notifications,
                Icons.notifications_rounded,
                'Notifications',
                'Configure alerts and reminders',
              ),
            // Bonus Management - Admin only
            if ((_currentUserRole ?? UserRole.staff).canAccessBonusScreen)
              _buildMoreOption(
                context,
                navigationProvider,
                ViewId.bonus,
                Icons.card_giftcard_rounded,
                'Bonus Management',
                'Manage customer bonuses',
              ),
            // Reset App - Admin only
            if ((_currentUserRole ?? UserRole.staff).canAccessResetApp)
              _buildResetOption(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOption(
    BuildContext context,
    NavigationProvider navigationProvider,
    ViewId viewId,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        navigationProvider.navigateTo(viewId);
      },
    );
  }

  Widget _buildResetOption(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.refresh_rounded,
          color: Colors.red,
        ),
      ),
      title: const Text(
        'Reset App',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Clear all data and reset to default',
        style: TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ResetAppScreen(),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await RoleAuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

