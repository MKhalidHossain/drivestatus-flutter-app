import 'package:flutter/material.dart';

class TicketSummaryCard extends StatelessWidget {
  final int openTickets;
  final String totalDue;
  final int overdue;

  const TicketSummaryCard({
    super.key,
    required this.openTickets,
    required this.totalDue,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Your Summary',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Open Tickets:', value: '$openTickets'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Total Due:', value: totalDue),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Overdue:', value: '$overdue'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6C6C6C)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
