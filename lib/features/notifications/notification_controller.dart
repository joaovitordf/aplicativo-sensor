import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/features/auth/auth_controller.dart';

class NotificationController extends ChangeNotifier {
  final AuthController _authController;
  final PpeService _ppeService;

  List<PpeEvent> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollingTimer;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _lastReadId = 0;
  static const String _lastReadIdKey = 'notifications_last_read_event_id';

  NotificationController(this._authController, this._ppeService) {
    _init();
  }

  List<PpeEvent> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> _init() async {
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotificationsPlugin.initialize(initSettings);

    final prefs = await SharedPreferences.getInstance();
    _lastReadId = prefs.getInt(_lastReadIdKey) ?? 0;

    _authController.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (_authController.isAuthenticated && _authController.clientId != null) {
      if (!_isInitialized) {
        _isInitialized = true;
        _fetchNotifications();
        _startPolling();
      }
    } else {
      _stopPolling();
      _isInitialized = false;
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 2 minutes
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _fetchNotifications();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchNotifications() async {
    final clientId = _authController.clientId;
    if (clientId == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final events = await _ppeService.getEvents(
        clientId: clientId,
        page: 1,
        start: todayStr,
        end: todayStr,
      );

      if (events.isNotEmpty) {
        // Check if there are new alerts
        if (_notifications.isNotEmpty) {
          final lastKnownId = _notifications.first.id;
          final latestNewId = events.first.id;

          if (latestNewId > lastKnownId && events.first.isNonCompliant) {
            _showLocalNotification(events.first);
          }
        }

        _notifications = events;

        int newUnread = 0;
        for (var item in _notifications) {
          if (item.id > _lastReadId) {
            newUnread++;
          }
        }

        _unreadCount = newUnread;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationController] Error polling notifications: $e');
      }
    }
  }

  Future<void> _showLocalNotification(PpeEvent item) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'alertas_epi_channel',
        'Alertas EPI',
        channelDescription: 'Notificações de infrações de EPI',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        item.id,
        'Novo Alerta de EPI',
        'Câmera ${item.cameraId ?? '-'}: ${item.translatedMissingPpe}',
        platformDetails,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationController] Error showing notification: $e');
      }
    }
  }

  void markAsRead() async {
    if (_notifications.isNotEmpty) {
      _lastReadId = _notifications.first.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadIdKey, _lastReadId);
    }
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}
