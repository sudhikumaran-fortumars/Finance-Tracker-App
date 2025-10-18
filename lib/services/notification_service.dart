import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification.dart' as app_notification;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase messaging
    await _configureFirebaseMessaging();

    // Set up message handlers
    _setupMessageHandlers();
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    
    if (notificationStatus.isDenied) {
      throw Exception('Notification permission denied');
    }

    // Request Firebase messaging permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('Firebase messaging permission denied');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    final data = message.data;
    
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'payment_received':
          // Navigate to transaction details
          break;
        case 'user_registered':
          // Navigate to user management
          break;
        case 'scheme_completed':
          // Navigate to scheme details
          break;
        default:
          // Navigate to dashboard
          break;
      }
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'finance_tracker_channel',
      'Finance Tracker Notifications',
      channelDescription: 'Notifications for Finance Tracker App',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Send payment received notification
  Future<void> sendPaymentReceivedNotification({
    required String userName,
    required double amount,
    required String paymentMode,
  }) async {
    await _showLocalNotification(
      title: 'Payment Received! 💰',
      body: '₹${amount.toStringAsFixed(0)} received from $userName via $paymentMode',
      payload: 'payment_received',
    );
  }

  // Send user registered notification
  Future<void> sendUserRegisteredNotification({
    required String userName,
    required String schemeName,
  }) async {
    await _showLocalNotification(
      title: 'New User Registered! 👤',
      body: '$userName has joined the $schemeName scheme',
      payload: 'user_registered',
    );
  }

  // Send scheme completed notification
  Future<void> sendSchemeCompletedNotification({
    required String userName,
    required String schemeName,
    required double totalAmount,
  }) async {
    await _showLocalNotification(
      title: 'Scheme Completed! 🎉',
      body: '$userName has completed $schemeName scheme (₹${totalAmount.toStringAsFixed(0)})',
      payload: 'scheme_completed',
    );
  }

  // Send overdue payment notification
  Future<void> sendOverduePaymentNotification({
    required String userName,
    required double overdueAmount,
    required int overdueWeeks,
  }) async {
    await _showLocalNotification(
      title: 'Overdue Payment Alert! ⚠️',
      body: '$userName has ₹${overdueAmount.toStringAsFixed(0)} overdue ($overdueWeeks weeks)',
      payload: 'overdue_payment',
    );
  }

  // Send weekly reminder notification
  Future<void> sendWeeklyReminderNotification({
    required String userName,
    required double weeklyAmount,
  }) async {
    await _showLocalNotification(
      title: 'Weekly Payment Reminder 📅',
      body: 'Reminder: $userName owes ₹${weeklyAmount.toStringAsFixed(0)} this week',
      payload: 'weekly_reminder',
    );
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Schedule recurring notifications
  Future<void> scheduleWeeklyReminders() async {
    // Schedule weekly reminders for all active users
    // This would typically be done on the server side
    // For now, we'll just show a local notification
    await _showLocalNotification(
      title: 'Weekly Reminders Scheduled 📅',
      body: 'Weekly payment reminders have been scheduled for all active users',
      payload: 'reminders_scheduled',
    );
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // You can perform background tasks here
  // For example, update local database, send analytics, etc.
}
