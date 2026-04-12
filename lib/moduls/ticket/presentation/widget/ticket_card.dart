import 'package:flutter/material.dart';

import 'ticket_action_button.dart';

class TicketCard extends StatelessWidget {
  final String ticketId;
  final String type;
  final String dueDate;
  final bool isClosed;
  final VoidCallback? onViewDetails;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.type,
    required this.dueDate,
    this.isClosed = false,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isClosed
        ? const Color(0xFF2CC56F)
        : const Color(0xFFB7791F);
    final String statusLabel = isClosed ? 'Closed' : 'Open';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number_outlined, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                ticketId,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Type:', value: type),
          const SizedBox(height: 6),
          _InfoRow(label: 'Deadline:', value: dueDate),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TicketActionButton(
                  label: 'Open Details',
                  isPrimary: true,
                  onPressed: onViewDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6C6C6C))),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
