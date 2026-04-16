import 'package:flutter/material.dart';

import '../widget/notification_list_item.dart';

class TicketNotificationScreen extends StatelessWidget {
  const TicketNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      const _NotificationData(
        message: 'Your license status just updated — please check the latest details.',
        time: '2 hours ago',
        isHighlighted: true,
      ),
      const _NotificationData(
        message: 'Suspension risk detected! View your license alerts now.',
        time: '2 hours ago',
        isHighlighted: true,
      ),
      const _NotificationData(
        message: 'Your fine is due in 3 days. Pay now to avoid penalties.',
        time: '2 hours ago',
        isHighlighted: true,
      ),
      const _NotificationData(
        message: 'Ticket payment confirmed! Keep driving safely.',
        time: '3 hours ago',
      ),
      const _NotificationData(
        message: 'New quiz available in the Learning Center.',
        time: '3 hours ago',
      ),
      const _NotificationData(
        message: 'Suspension risk detected! View your license alerts now.',
        time: '3 hours ago',
      ),
      const _NotificationData(
        message: 'Your fine is due in 3 days. Pay now to avoid penalties.',
        time: '3 hours ago',
      ),
      const _NotificationData(
        message: 'Suspension risk detected! View your license alerts now.',
        time: '3 hours ago',
      ),
      const _NotificationData(
        message: 'Your fine is due in 3 days. Pay now to avoid penalties.',
        time: '3 hours ago',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Notification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7D7D7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notification',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F76F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFD9D9D9)),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return NotificationListItem(
                            message: item.message,
                            time: item.time,
                            isHighlighted: item.isHighlighted,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NotificationData {
  final String message;
  final String time;
  final bool isHighlighted;

  const _NotificationData({
    required this.message,
    required this.time,
    this.isHighlighted = false,
  });
}
