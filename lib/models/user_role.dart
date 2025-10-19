enum UserRole {
  owner,
  staff,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.staff:
        return 'Staff';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'Full access to all features';
      case UserRole.staff:
        return 'Limited access to core features';
    }
  }

  bool get canManageUsers {
    switch (this) {
      case UserRole.owner:
        return true;
      case UserRole.staff:
        return false;
    }
  }

  bool get canViewReports {
    switch (this) {
      case UserRole.owner:
        return true;
      case UserRole.staff:
        return true;
    }
  }

  bool get canManageSchemes {
    switch (this) {
      case UserRole.owner:
        return true;
      case UserRole.staff:
        return false;
    }
  }

  bool get canSendWhatsApp {
    switch (this) {
      case UserRole.owner:
        return true;
      case UserRole.staff:
        return true;
    }
  }

  bool get canViewAnalytics {
    switch (this) {
      case UserRole.owner:
        return true;
      case UserRole.staff:
        return false;
    }
  }
}

