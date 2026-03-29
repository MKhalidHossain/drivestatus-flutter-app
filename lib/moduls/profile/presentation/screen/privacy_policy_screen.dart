import 'package:flutter/material.dart';

import '../widget/policy_section.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color _background = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          PolicySection(
            number: '1',
            title: 'Introduction',
            body:
                'By using MIMI Stores Africa, you agree to these Terms and '
                'Conditions. Please read them carefully.',
          ),
          PolicySection(
            number: '2',
            title: 'Account Registration',
            body:
                'You must provide accurate and complete information during '
                'sign-up. You are responsible for maintaining the '
                'confidentiality of your login details.',
          ),
          PolicySection(
            number: '3',
            title: 'User Conduct',
            body:
                'You agree not to misuse the app or engage in fraudulent, '
                'harmful, or illegal activities. MIMI Stores Africa reserves '
                'the right to suspend or terminate accounts violating these '
                'rules.',
          ),
          PolicySection(
            number: '4',
            title: 'Orders & Payments',
            body:
                'All orders placed are subject to availability and '
                'confirmation. Payments are processed securely. In the case of '
                'refund or cancellation, conditions will apply as per our '
                'Refund Policy.',
          ),
          PolicySection(
            number: '5',
            title: 'Vendor Responsibilities',
            body:
                'Vendors must ensure all product/service information is '
                'accurate. They must comply with verification, subscription, '
                'and tax policies. Failure to comply may result in account '
                'suspension.',
          ),
          PolicySection(
            number: '6',
            title: 'Shipping & Delivery',
            body:
                'Shipping times and methods are displayed during checkout. '
                'Delays or failures due to incorrect information are not our '
                'responsibility.',
          ),
          PolicySection(
            number: '7',
            title: 'Returns & Refunds',
            body:
                'Refunds are available upon evaluation of the returned '
                'product. Users must initiate requests within the policy '
                'timeline. Vendors are expected to respond promptly.',
          ),   PolicySection(
            number: '8',
            title: 'Messaging & Communication',
            body:
                'All in-app communications must be'
                'professional. Abuse or harassment may lead to  '
                'a permanent ban.',
          ),   PolicySection(
            number: '9',
            title: 'Privacy',
            body:
                'Your personal data is protected under our '
                'Privacy Policy. By using the app, you consent to '
                'our data practices.',
          ),   PolicySection(
            number: '10',
            title: 'Modifications',
            body:
                'MIMI Stores Africa reserves the right to update'
                'these terms at any time. Continued use of the  '
                'app implies acceptance of the revised terms',
          ),   PolicySection(
            number: '11',
            title: 'Contact',
            body:
                'For support or queries, contact us through the '
                'product. Users must initiate requests within the policy '
                'timeline. Vendors are expected to respond promptly.',
          ),   PolicySection(
            number: '7',
            title: 'Returns & Refunds',
            body:
                'Refunds are available upon evaluation of the returned '
                'app or at support@mimistores.africa.'
          ),   
        ],
      ),
    );
  }
}
