enum UserRole {
  admin,
  staff,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full access to all features';
      case UserRole.staff:
        return 'Limited access - User management and daily entry only';
    }
  }

  bool get canAccessDashboard => this == UserRole.admin;
  bool get canAccessReports => this == UserRole.admin;
  bool get canAccessUserManagement => true; // Both roles can access
  bool get canAccessDailyEntry => true; // Both roles can access
  bool get canAccessPaymentHandling => this == UserRole.admin;
  bool get canAccessBonusScreen => this == UserRole.admin;
  bool get canAccessNotifications => this == UserRole.admin;
  bool get canAccessResetApp => this == UserRole.admin;
}