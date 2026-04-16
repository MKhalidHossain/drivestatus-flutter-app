import 'package:flutter/material.dart';

import '../widget/payment_text_field.dart';
import '../widget/ticket_action_button.dart';

class PlanPricingDetailsScreen extends StatelessWidget {
  const PlanPricingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Payment Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text(
            'Compare plans and choose the one that best fits your hiring or job-seeking needs.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Summary',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recurring Payment Terms:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            '• Charges includes Applicable VAT/GST and/or Sale Taxes',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFBDBDBD)),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(r'$359.00', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Safe & secure payment',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'By clicking the Pay button, you are agreeing to our Terms of Service and Privacy Statement. You are also authorizing us to charge your credit/debit card at the price above now and before each new subscription term. For any questions please contact support@tipenko.com',
            style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A), height: 1.3),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              r'Total: $359.00',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCFCFCF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.flag, size: 14, color: Color(0xFF5A6472)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('United States', style: TextStyle(fontSize: 12)),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PaymentTextField(hintText: 'Email'),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCFCFCF)),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3F76F6)),
                  SizedBox(width: 6),
                  Text('PayPal', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const PaymentTextField(hintText: 'Name'),
          const SizedBox(height: 12),
          const PaymentTextField(hintText: 'Card Number'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: PaymentTextField(hintText: 'DD/MM/YYYY', isDense: true),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: PaymentTextField(hintText: 'CVC', isDense: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const PaymentTextField(hintText: 'Phone Number'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TicketActionButton(
              label: r'Pay $325.00',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
