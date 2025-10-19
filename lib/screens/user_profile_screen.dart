import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_auth_service.dart';
import '../models/user_role.dart';
import '../widgets/common/card_widget.dart';
import '../widgets/common/button_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AppAuthService _authService = AppAuthService.instance;
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            CardWidget(
              title: 'User Information',
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Name',
                    value: _authService.getUserDisplayName(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'Role',
                    value: _authService.getUserRoleDisplayName(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: _authService.currentUser?.email ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: _authService.currentUser?.phoneNumber ?? 'N/A',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role Information Card
            CardWidget(
              title: 'Role Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _authService.currentUser?.role.description ?? 'No role assigned',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Permissions:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildPermissionList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions Card
            CardWidget(
              title: 'Quick Actions',
              child: Column(
                children: [
                  if (_authService.canPerformAction('manage_users'))
                    SizedBox(
                      width: double.infinity,
                      child: ButtonWidget(
                        text: 'Manage Users',
                        icon: Icons.people,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User management feature coming soon!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  if (_authService.canPerformAction('manage_users'))
                    const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ButtonWidget(
                      text: 'Change Password',
                      icon: Icons.lock,
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // System Information Card
            CardWidget(
              title: 'System Information',
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.login,
                    label: 'Last Login',
                    value: _authService.currentUser?.lastLoginAt != null
                        ? _formatDateTime(_authService.currentUser!.lastLoginAt!)
                        : 'Never',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Account Created',
                    value: _formatDateTime(_authService.currentUser?.createdAt ?? DateTime.now()),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.verified,
                    label: 'Status',
                    value: _authService.currentUser?.isActive == true ? 'Active' : 'Inactive',
                    valueColor: _authService.currentUser?.isActive == true ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPermissionList() {
    final permissions = _authService.getUserPermissions();
    final permissionLabels = {
      'manage_users': 'Manage Users',
      'view_reports': 'View Reports',
      'manage_schemes': 'Manage Schemes',
      'send_whatsapp': 'Send WhatsApp Messages',
      'view_analytics': 'View Analytics',
    };

    return permissions.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              entry.value ? Icons.check_circle : Icons.cancel,
              color: entry.value ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              permissionLabels[entry.key] ?? entry.key,
              style: TextStyle(
                color: entry.value ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await _authService.updatePassword(
                _authService.currentUser!.id,
                oldPasswordController.text,
                newPasswordController.text,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update password'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

