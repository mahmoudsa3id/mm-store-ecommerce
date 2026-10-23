import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';

/// Global local notification plugin.
/// Keep one instance for the whole application.
final FlutterLocalNotificationsPlugin adminLocalNotifications =
    FlutterLocalNotificationsPlugin();

/// Android notification channel.
///
/// IMPORTANT:
/// If this channel was already created on the device with different
/// sound settings, Android may keep the old settings.
/// In that case change the channel ID, e.g. v4.
final AndroidNotificationChannel adminOrderChannel = AndroidNotificationChannel(
  'new_orders',
  'New Orders',
  description: 'تنبيهات الطلبات الجديدة في MM Store Admin',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('new_order'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
  enableLights: true,
  showBadge: true,
);

/// Handles FCM messages when the app is in background.
///
/// IMPORTANT:
/// Do not manually call localNotifications.show() here when the FCM
/// message contains a `notification` payload.
///
/// Android will display the notification automatically.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? null
            : DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('========================================');
    debugPrint('FCM BACKGROUND MESSAGE');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('========================================');
  } catch (error, stackTrace) {
    debugPrint('FCM BACKGROUND HANDLER ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AdminFcmService {
  AdminFcmService(this.client);

  final SupabaseClient client;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final StreamController<RemoteMessage> _newOrderMessages =
      StreamController<RemoteMessage>.broadcast();
  String? _pendingOrderId;
  void Function(String orderId)? _onOrderNotification;

  Stream<RemoteMessage> get newOrderMessages => _newOrderMessages.stream;

  set onOrderNotification(void Function(String orderId)? callback) {
    _onOrderNotification = callback;
    final pendingOrderId = _pendingOrderId;
    if (callback != null && pendingOrderId != null) {
      _pendingOrderId = null;
      callback(pendingOrderId);
    }
  }

  Future<bool> requestPermission() => _requestPermission();

  Future<String?> getToken() => _messaging.getToken();

  /// Initialize FCM.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        await _initializeWeb();
      } else {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? null
                : DefaultFirebaseOptions.currentPlatform,
          );
        }

        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        await _initializeLocalNotifications();

        await _createAndroidNotificationChannel();

        await _requestPermission();

        await _registerToken();

        _listenToTokenRefresh();

        _listenToAuthChanges();

        _listenToForegroundMessages();

        _listenToNotificationOpenedApp();

        await _handleInitialMessage();
      }

      _initialized = true;

      debugPrint('MM Store Admin FCM initialized');
    } catch (error, stackTrace) {
      debugPrint('MM Store Admin FCM INITIALIZATION ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // WEB
  // ============================================================

  Future<void> _initializeWeb() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? null
              : DefaultFirebaseOptions.currentPlatform,
        );
      }

      await _requestPermission();

      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }

      _listenToTokenRefresh();

      _listenToForegroundMessages();

      _listenToNotificationOpenedApp();

      await _handleInitialMessage();
    } catch (error) {
      debugPrint('FCM WEB INITIALIZATION ERROR: $error');
    }
  }

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await adminLocalNotifications.initialize(
      settings: initializationSettings,

      /// Fired when user taps a LOCAL notification.
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb) return;

    final android = adminLocalNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    await android.createNotificationChannel(adminOrderChannel);
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('FCM AUTH STATUS: ${settings.authorizationStatus}');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final android = adminLocalNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM TOKEN IS NULL');
        return;
      }

      await _saveToken(token);
    } catch (error, stackTrace) {
      debugPrint('FCM GET TOKEN ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) {
        unawaited(_registerToken());
      }
    });
  }

  void _listenToTokenRefresh() {
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        if (token.isEmpty) return;

        debugPrint('FCM TOKEN REFRESHED: $token');

        await _saveToken(token);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM TOKEN REFRESH ERROR: $error');

        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  Future<void> _saveToken(String token) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        debugPrint('FCM TOKEN NOT SAVED: admin is not logged in.');
        return;
      }

      if (await client.rpc('is_admin') != true) {
        debugPrint('FCM TOKEN NOT SAVED: signed-in user is not an admin.');
        return;
      }

      await client.from('admin_device_tokens').upsert({
        'admin_user_id': user.id,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      debugPrint('FCM TOKEN SAVED SUCCESSFULLY');
    } catch (error, stackTrace) {
      debugPrint('SAVE FCM TOKEN ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Call this after admin logout.
  Future<void> deactivateCurrentToken() async {
    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) return;

      await client
          .from('admin_device_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('token', token);
    } catch (error) {
      debugPrint('DEACTIVATE FCM TOKEN ERROR: $error');
    }
  }

  // ============================================================
  // FOREGROUND
  // ============================================================

  void _listenToForegroundMessages() {
    _foregroundSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('FCM FOREGROUND MESSAGE: ${message.data}');

        if (message.data['type'] != 'new_order') return;

        _newOrderMessages.add(message);
        await _showForegroundNotification(message);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM FOREGROUND ERROR: $error');

        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'طلب جديد';

    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'لديك طلب جديد';

    final orderId = _orderIdFrom(message) ?? '';

    if (kIsWeb) {
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    final androidDetails = AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'تنبيهات الطلبات الجديدة في MM Store Admin',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      sound: const RawResourceAndroidNotificationSound('new_order'),
      enableLights: true,
      showWhen: true,
      tag: orderId,
      category: AndroidNotificationCategory.message,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await adminLocalNotifications.show(
      id: _notificationIdFor(orderId, id),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode({'type': 'new_order', 'orderId': orderId}),
    );
  }

  // ============================================================
  // BACKGROUND → USER TAPS NOTIFICATION
  // ============================================================

  void _listenToNotificationOpenedApp() {
    _openedAppSubscription?.cancel();

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint('FCM NOTIFICATION OPENED');

        _handleMessageTap(message);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM OPENED ERROR: $error');

        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  // ============================================================
  // APP WAS COMPLETELY CLOSED
  // ============================================================

  Future<void> _handleInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();

      if (message == null) return;

      debugPrint('FCM INITIAL MESSAGE');

      _handleMessageTap(message);
    } catch (error) {
      debugPrint('GET INITIAL FCM MESSAGE ERROR: $error');
    }
  }

  // ============================================================
  // MESSAGE TAP
  // ============================================================

  void _handleMessageTap(RemoteMessage message) {
    final orderId = _orderIdFrom(message);

    if (message.data['type'] != 'new_order' ||
        orderId == null ||
        orderId.isEmpty) {
      debugPrint('Notification is not a new order or has no orderId.');
      return;
    }

    debugPrint('OPEN ORDER FROM NOTIFICATION: $orderId');

    _dispatchOrderTap(orderId);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    String? orderId;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['type'] == 'new_order') {
        orderId = data['orderId']?.toString();
      }
    } on FormatException {
      orderId = payload;
    }

    if (orderId == null || orderId.isEmpty) {
      return;
    }

    debugPrint('OPEN LOCAL ORDER: $orderId');

    _dispatchOrderTap(orderId);
  }

  String? _orderIdFrom(RemoteMessage message) =>
      message.data['orderId']?.toString() ??
      message.data['order_id']?.toString();

  void _dispatchOrderTap(String orderId) {
    final callback = _onOrderNotification;
    if (callback == null) {
      _pendingOrderId = orderId;
      return;
    }
    callback(orderId);
  }

  int _notificationIdFor(String orderId, int fallback) {
    if (orderId.isEmpty) return fallback;
    var hash = 0x811c9dc5;
    for (final codeUnit in orderId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  // ============================================================
  // MANUAL TEST NOTIFICATION
  // ============================================================

  /// Use this only to test local notification.
  ///
  /// It does NOT test FCM/server push.
  Future<void> testLocalNotification() async {
    if (kIsWeb) return;

    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    final androidDetails = AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'تنبيهات الطلبات الجديدة في MM Store Admin',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      sound: RawResourceAndroidNotificationSound('new_order'),
      enableLights: true,
      showProgress: true,
      tag: 'new_order_test',
      category: AndroidNotificationCategory.message,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await adminLocalNotifications.show(
      id: id,
      title: '🔔 اختبار MM Store',
      body: 'الإشعارات والصوت يعملان بشكل صحيح.',
      notificationDetails: details,
      payload: '',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _authSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _authSubscription = null;

    await _newOrderMessages.close();
    _initialized = false;
  }
}
