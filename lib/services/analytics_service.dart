import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static AnalyticsService get instance => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Initialize analytics
  Future<void> initialize() async {
    // Initialize Firebase Analytics
    await _analytics.setAnalyticsCollectionEnabled(true);

    // Initialize Crashlytics
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    // Set user properties
    await _setUserProperties();
  }

  // Set user properties
  Future<void> _setUserProperties() async {
    await _analytics.setUserProperty(
      name: 'app_version',
      value: '1.0.0', // You can get this from package_info_plus
    );
  }

  // ==================== USER EVENTS ====================

  /// Track user registration
  Future<void> trackUserRegistration({
    required String userId,
    required String schemeName,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'user_registration',
      parameters: {
        'user_id': userId,
        'scheme_name': schemeName,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track user login
  Future<void> trackUserLogin({
    required String loginMethod,
  }) async {
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'login_method': loginMethod,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track user logout
  Future<void> trackUserLogout() async {
    await _analytics.logEvent(
      name: 'user_logout',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ==================== PAYMENT EVENTS ====================

  /// Track payment received
  Future<void> trackPaymentReceived({
    required String userId,
    required double amount,
    required String paymentMode,
    required bool isOverdue,
  }) async {
    await _analytics.logEvent(
      name: 'payment_received',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'payment_mode': paymentMode,
        'is_overdue': isOverdue,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track payment failed
  Future<void> trackPaymentFailed({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'payment_failed',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'failure_reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track overdue payment
  Future<void> trackOverduePayment({
    required String userId,
    required double overdueAmount,
    required int overdueWeeks,
  }) async {
    await _analytics.logEvent(
      name: 'overdue_payment',
      parameters: {
        'user_id': userId,
        'overdue_amount': overdueAmount,
        'overdue_weeks': overdueWeeks,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ==================== SCHEME EVENTS ====================

  /// Track scheme creation
  Future<void> trackSchemeCreated({
    required String schemeId,
    required String schemeName,
    required double totalAmount,
    required int durationWeeks,
  }) async {
    await _analytics.logEvent(
      name: 'scheme_created',
      parameters: {
        'scheme_id': schemeId,
        'scheme_name': schemeName,
        'total_amount': totalAmount,
        'duration_weeks': durationWeeks,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track scheme completed
  Future<void> trackSchemeCompleted({
    required String schemeId,
    required String userId,
    required double totalAmount,
    required int completionWeeks,
  }) async {
    await _analytics.logEvent(
      name: 'scheme_completed',
      parameters: {
        'scheme_id': schemeId,
        'user_id': userId,
        'total_amount': totalAmount,
        'completion_weeks': completionWeeks,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track scheme cancelled
  Future<void> trackSchemeCancelled({
    required String schemeId,
    required String userId,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'scheme_cancelled',
      parameters: {
        'scheme_id': schemeId,
        'user_id': userId,
        'cancellation_reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ==================== SCREEN EVENTS ====================

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Track dashboard view
  Future<void> trackDashboardView() async {
    await trackScreenView(screenName: 'dashboard');
  }

  /// Track user management view
  Future<void> trackUserManagementView() async {
    await trackScreenView(screenName: 'user_management');
  }

  /// Track daily entry view
  Future<void> trackDailyEntryView() async {
    await trackScreenView(screenName: 'daily_entry');
  }

  /// Track reports view
  Future<void> trackReportsView() async {
    await trackScreenView(screenName: 'reports');
  }

  // ==================== SEARCH EVENTS ====================

  /// Track search performed
  Future<void> trackSearchPerformed({
    required String searchTerm,
    required String searchType,
    required int resultCount,
  }) async {
    await _analytics.logEvent(
      name: 'search_performed',
      parameters: {
        'search_term': searchTerm,
        'search_type': 'user_search',
        'result_count': resultCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ==================== ERROR TRACKING ====================

  /// Track error
  Future<void> trackError({
    required String errorMessage,
    required String errorType,
    String? stackTrace,
  }) async {
    await _crashlytics.recordError(
      errorMessage,
      stackTrace != null ? StackTrace.fromString(stackTrace) : null,
      fatal: false,
    );

    await _analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'error_message': errorMessage,
        'error_type': errorType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track crash
  Future<void> trackCrash({
    required String errorMessage,
    required String stackTrace,
  }) async {
    await _crashlytics.recordError(
      errorMessage,
      StackTrace.fromString(stackTrace),
      fatal: true,
    );
  }

  // ==================== BUSINESS METRICS ====================

  /// Track revenue metrics
  Future<void> trackRevenueMetrics({
    required double totalRevenue,
    required double monthlyRevenue,
    required int activeUsers,
    required int completedSchemes,
  }) async {
    await _analytics.logEvent(
      name: 'revenue_metrics',
      parameters: {
        'total_revenue': totalRevenue,
        'monthly_revenue': monthlyRevenue,
        'active_users': activeUsers,
        'completed_schemes': completedSchemes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track user engagement
  Future<void> trackUserEngagement({
    required String userId,
    required String action,
    required int sessionDuration,
  }) async {
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'user_id': userId,
        'action': action,
        'session_duration': sessionDuration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ==================== CUSTOM EVENTS ====================

  /// Track custom event
  Future<void> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  // ==================== USER IDENTIFICATION ====================

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ==================== CONVERSION TRACKING ====================

  /// Track conversion events
  Future<void> trackConversion({
    required String conversionType,
    required double value,
    String? currency,
  }) async {
    await _analytics.logEvent(
      name: 'conversion',
      parameters: {
        'conversion_type': conversionType,
        'value': value,
        'currency': currency ?? 'INR',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
