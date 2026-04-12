import 'package:flutter/material.dart';

import '../widget/policy_section.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

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
          'Terms & Condition',
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
            title: 'Acceptance of Terms',
            body:
                'By registering or using MIMI Stores Africa, you agree to '
                'comply with and be legally bound by these Terms & Conditions.',
          ),
          PolicySection(
            number: '2',
            title: 'User Eligibility',
            body:
                'Users must be 18+ and provide accurate information during '
                'sign-up. False data may result in suspension.',
          ),
          PolicySection(
            number: '3',
            title: 'Account Responsibility',
            body:
                'You are responsible for maintaining the confidentiality of '
                'your login credentials and for all activities under your '
                'account.',
          ),
          PolicySection(
            number: '4',
            title: 'Usage Restrictions',
            body:
                'You agree not to:\n- Misuse the platform\n- Upload harmful or '
                'illegal content\n- Impersonate others\n- Violate any '
                'applicable laws',
          ),
          PolicySection(
            number: '5',
            title: 'Service Access',
            body:
                'Features, records, and related content are provided based on '
                'service availability. Access and presentation may change as '
                'the app is updated over time.',
          ),
          PolicySection(
            number: '6',
            title: 'Product Listings',
            body:
                'Vendors must list genuine items/services with accurate '
                'descriptions. Fraudulent or misleading listings will be '
                'removed and accounts penalized.',
          ),
          PolicySection(
            number: '7',
            title: 'Intellectual Property',
            body:
                'All content on MIMI Stores Africa is protected. You may not '
                'reuse, reproduce, or distribute content without permission.',
          ),
          PolicySection(
            number: '8',
            title: 'Messaging & Communication',
            body:
                'The platform enables in-app messaging. Abuse, harassment, '
                'or spam will result in account action.',
          ),
          PolicySection(
            number: '9',
            title: 'Termination',
            body:
                'The platform enables in-app messaging. Abuse, harassment, '
                'or spam will result in account action.',
          ),
          PolicySection(
            number: '10',
            title: 'Changes to Terms',
            body:
                'The platform enables in-app messaging. Abuse, harassment, '
                'or spam will result in account action.',
          ),
          PolicySection(
            number: '11',
            title: 'Governing Law',
            body:
                'The platform enables in-app messaging. Abuse, harassment, '
                'or spam will result in account action.',
          ),
          PolicySection(
            number: '12',
            title: 'Contact Us',
            body:
                'The platform enables in-app messaging. Abuse, harassment, '
                'or spam will result in account action.',
          ),
        ],
      ),
    );
  }
}
