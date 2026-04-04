import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/services/app_pigeon/app_pigeon.dart';
import '../../interface/notification_interface.dart';
import '../../model/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final SnackbarNotifier _snackbarNotifier;
  bool _isLoading = false;
  bool _isInitialized = false;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _justMarkedAllAsRead = false; // Track if we just marked all as read

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
      _loadNotifications();
    }
  }

  Future<String?> _getUserId() async {
    try {
      final appPigeon = Get.find<AppPigeon>();
      final authStatus = await appPigeon.currentAuth();
      if (authStatus is Authenticated) {
        final auth = authStatus.auth;
        final userId =
            auth.data['_id'] ??
            auth.data['userId'] ??
            auth.data['user']?['_id'] ??
            auth.data['user']?['id'];
        if (userId != null) {
          return userId.toString();
        }
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  Future<void> _loadNotifications() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      _snackbarNotifier.notifyError(
        message: 'Unable to get user information. Please login again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notificationInterface = Get.find<NotificationInterface>();

      // Debug: Print API URL and user ID
      final apiUrl = ApiEndpoints.getUserNotifications(userId);
      debugPrint('📡 Notification API Call:');
      debugPrint('   URL: $apiUrl');
      debugPrint('   User ID: $userId');
      debugPrint('   Method: GET');
      debugPrint('   Token: Applied automatically via AuthService interceptor');

      final result = await notificationInterface.getNotifications(
        userId: userId,
      );

      result.fold(
        (failure) {
          debugPrint('❌ API Error: ${failure.uiMessage}');
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load notifications',
          );
        },
        (success) {
          debugPrint('✅ API Success: ${success.message}');
          debugPrint('   Notifications count: ${success.data?.length ?? 0}');

          final loadedNotifications = success.data ?? [];

          // If we just marked all as read, preserve the read state
          // This prevents server delay from overwriting our local state
          if (_justMarkedAllAsRead) {
            // Merge: keep read state from local if we just marked them
            final localNotificationMap = {
              for (var n in _notifications) n.id: n,
            };

            setState(() {
              _notifications = loadedNotifications.map((loaded) {
                // If we have this notification locally and it was marked as read, keep it read
                final local = localNotificationMap[loaded.id];
                if (local != null && local.isRead) {
                  return NotificationModel(
                    id: loaded.id,
                    userId: loaded.userId,
                    title: loaded.title,
                    message: loaded.message,
                    type: loaded.type,
                    isRead: true, // Preserve read state
                    createdAt: loaded.createdAt,
                    updatedAt: loaded.updatedAt,
                  );
                }
                return loaded;
              }).toList();
              _unreadCount = _notifications
                  .where((notification) => !notification.isRead)
                  .length;
              _justMarkedAllAsRead = false; // Reset flag
            });

            debugPrint('✅ Preserved read state after mark all as read');
          } else {
            // Normal load - use server data as is
            setState(() {
              _notifications = loadedNotifications;
              _unreadCount = _notifications
                  .where((notification) => !notification.isRead)
                  .length;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Exception: $e');
      _snackbarNotifier.notifyError(
        message: 'An error occurred while loading notifications',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final appPigeon = Get.find<AppPigeon>();

      // Use the markNotificationAsRead endpoint
      final apiUrl = ApiEndpoints.markNotificationAsRead(
        notificationId: notificationId,
      );
      debugPrint('📡 Mark as Read API Call:');
      debugPrint('   URL: $apiUrl');
      debugPrint('   Method: PATCH');
      debugPrint('   Token: Applied automatically via AuthService interceptor');

      await appPigeon.patch(apiUrl);

      // Update local state
      setState(() {
        _notifications = _notifications.map((notification) {
          if (notification.id == notificationId) {
            return NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              isRead: true,
              createdAt: notification.createdAt,
              updatedAt: notification.updatedAt,
            );
          }
          return notification;
        }).toList();
        _unreadCount = _notifications
            .where((notification) => !notification.isRead)
            .length;
      });

      debugPrint('✅ Notification marked as read: $notificationId');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final responseMessage = responseData is Map
          ? responseData['message']?.toString() ?? ''
          : '';
      final isMissingSingleReadEndpoint =
          (e.response?.statusCode == 400 || e.response?.statusCode == 404) &&
          responseMessage.toLowerCase().contains('api not found');

      if (isMissingSingleReadEndpoint) {
        final userId = await _getUserId();
        if (userId != null && userId.isNotEmpty) {
          final fallbackAppPigeon = Get.find<AppPigeon>();
          debugPrint(
            '⚠️ mark-as-read endpoint missing, fallback to mark-all-as-read',
          );
          await fallbackAppPigeon.patch(
            ApiEndpoints.markAllNotificationsAsRead(userId),
          );

          if (!mounted) return;
          setState(() {
            _notifications = _notifications.map((notification) {
              return NotificationModel(
                id: notification.id,
                userId: notification.userId,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                isRead: true,
                createdAt: notification.createdAt,
                updatedAt: notification.updatedAt,
              );
            }).toList();
            _unreadCount = 0;
          });
          return;
        }
      }

      debugPrint('❌ Error marking notification as read: $e');
      _snackbarNotifier.notifyError(
        message: 'Failed to mark notification as read',
      );
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      _snackbarNotifier.notifyError(
        message: 'Failed to mark notification as read',
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      _snackbarNotifier.notifyError(
        message: 'Unable to get user information. Please login again.',
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationInterface = Get.find<NotificationInterface>();

      debugPrint('📡 Mark All As Read API Call:');
      debugPrint('   User ID: $userId');
      debugPrint('   Method: PATCH');
      debugPrint('   Token: Applied automatically via AuthService interceptor');

      final result = await notificationInterface.markAllAsRead(userId: userId);

      result.fold(
        (failure) {
          debugPrint('❌ Mark All As Read Error: ${failure.uiMessage}');
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to mark all as read',
          );
          setState(() {
            _isLoading = false;
          });
        },
        (success) {
          debugPrint('✅ Mark All As Read Success: ${success.message}');

          // Set flag to preserve read state during reload
          _justMarkedAllAsRead = true;

          // Update local state immediately - mark all as read
          // This ensures UI updates instantly before server sync
          setState(() {
            _notifications = _notifications.map((notification) {
              return NotificationModel(
                id: notification.id,
                userId: notification.userId,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                isRead: true, // Mark all as read
                createdAt: notification.createdAt,
                updatedAt: notification.updatedAt,
              );
            }).toList();
            _unreadCount = 0; // Reset unread count
            _isLoading = false;
          });

          _snackbarNotifier.notifySuccess(
            message: success.message.isNotEmpty
                ? success.message
                : 'All notifications marked as read',
          );

          debugPrint('✅ UI Updated:');
          debugPrint('   Total notifications: ${_notifications.length}');
          debugPrint('   Unread count: $_unreadCount');
          debugPrint(
            '   All notifications isRead: ${_notifications.every((n) => n.isRead)}',
          );

          // Reload from server after a delay to sync with backend
          // The flag will preserve read state during reload
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _loadNotifications();
            }
          });
        },
      );
    } catch (e) {
      debugPrint('❌ Exception in markAllAsRead: $e');
      _snackbarNotifier.notifyError(
        message: 'An error occurred while marking notifications as read',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'license':
        return Icons.credit_card;
      case 'ticket':
        return Icons.receipt;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'license':
        return const Color(0xFF1976F3);
      case 'ticket':
        return const Color(0xFFF57C00);
      case 'alert':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF1976F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: Color(0xFF1976F3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header with unread count
                        if (_unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Notification',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976F3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Notifications list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              final isUnread = !notification.isRead;

                              return InkWell(
                                onTap: () {
                                  if (isUnread) {
                                    _markNotificationAsRead(notification.id);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? const Color(0xFFEAF5FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isUnread
                                        ? Border.all(
                                            color: const Color(
                                              0xFF1976F3,
                                            ).withValues(alpha: 0.3),
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Unread indicator dot
                                      if (isUnread)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 6,
                                            right: 12,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1976F3),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      // Icon
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getNotificationColor(
                                            notification.type,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getNotificationIcon(
                                            notification.type,
                                          ),
                                          size: 24,
                                          color: _getNotificationColor(
                                            notification.type,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title
                                            if (notification.title.isNotEmpty)
                                              Text(
                                                notification.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isUnread
                                                      ? const Color(0xFF1976F3)
                                                      : Colors.black87,
                                                ),
                                              ),
                                            if (notification.title.isNotEmpty)
                                              const SizedBox(height: 4),
                                            // Message
                                            Text(
                                              notification.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            // Time and Type
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  notification.timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getNotificationColor(
                                                          notification.type,
                                                        ).withValues(
                                                          alpha: 0.1,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    notification.type
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          _getNotificationColor(
                                                            notification.type,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
