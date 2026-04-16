import 'package:flutter/material.dart';

class LicenseStatusCard extends StatelessWidget {
  final String status;
  final String validity;
  final String expiryDate;

  const LicenseStatusCard({
    super.key,
    required this.status,
    required this.validity,
    required this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF23A05A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Licence Status',
                  style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF0D8C3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FB35C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  validity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Expired: $expiryDate',
                style: const TextStyle(fontSize: 10, color: Color(0xFF7A7A7A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
