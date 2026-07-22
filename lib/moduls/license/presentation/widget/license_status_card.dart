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

  _LicenseStatusStyle _statusStyle(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();

    if (normalized == 'pending' ||
        normalized == 'processing' ||
        normalized == 'in_review') {
      return const _LicenseStatusStyle(
        textColor: Color(0xFFC08A0A),
        iconColor: Color(0xFFC08A0A),
        iconBackground: Color(0xFFFFF4DB),
        badgeColor: Color(0xFFC08A0A),
      );
    }

    if (normalized == 'complete' ||
        normalized == 'completed' ||
        normalized == 'ok' ||
        normalized == 'okay' ||
        normalized == 'active' ||
        normalized == 'verified' ||
        normalized == 'valid') {
      return const _LicenseStatusStyle(
        textColor: Color(0xFF1B8E3E),
        iconColor: Color(0xFF1B8E3E),
        iconBackground: Color(0xFFE8F7ED),
        badgeColor: Color(0xFF1B8E3E),
      );
    }

    if (normalized == 'expired' ||
        normalized == 'rejected' ||
        normalized == 'inactive' ||
        normalized == 'suspended') {
      return const _LicenseStatusStyle(
        textColor: Color(0xFFD64545),
        iconColor: Color(0xFFD64545),
        iconBackground: Color(0xFFFBEFE8),
        badgeColor: Color(0xFFD64545),
      );
    }

    return const _LicenseStatusStyle(
      textColor: Color(0xFF5C6BF2),
      iconColor: Color(0xFF5C6BF2),
      iconBackground: Color(0xFFEFF2FF),
      badgeColor: Color(0xFF5C6BF2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

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
              color: style.iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shield_outlined, color: style.iconColor),
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
                  style: TextStyle(
                    color: style.textColor,
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
                  color: style.badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
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

class _LicenseStatusStyle {
  final Color textColor;
  final Color iconColor;
  final Color iconBackground;
  final Color badgeColor;

  const _LicenseStatusStyle({
    required this.textColor,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeColor,
  });
}
