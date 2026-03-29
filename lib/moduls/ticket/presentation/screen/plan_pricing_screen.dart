// import 'package:flutter/material.dart';

// import '../../../../core/constants/app_routes.dart';
// import '../widget/payment_method_dialog.dart';

// class PlanPricingScreen extends StatefulWidget {
//   const PlanPricingScreen({super.key});

//   @override
//   State<PlanPricingScreen> createState() => _PlanPricingScreenState();
// }

// class _PlanPricingScreenState extends State<PlanPricingScreen> {
//   bool _paypalSelected = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFC8C8C8),
//       body: Stack(
//         children: [
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Plan & Pricing',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     'Choose the Plan That Fits You Best',
//                     style: TextStyle(fontSize: 12, color: Colors.black38),
//                   ),
//                   const SizedBox(height: 40),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         const Text(
//                           'BASIC PLAN',
//                           style: TextStyle(
//                             color: Color(0xFF8DC6E9),
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 1.2,
//                           ),
//                         ),
//                         const SizedBox(height: 18),
//                         const _PlanBullet(text: 'What the user will get', dotColor: Color(0xFF9FE0F5)),
//                         const _PlanBullet(text: 'What the user will get', dotColor: Color(0xFF9FE0F5)),
//                         const _PlanBullet(text: 'What the user will not get', dotColor: Color(0xFFE3B6B6)),
//                         const _PlanBullet(text: 'What the user will not get', dotColor: Color(0xFFE3B6B6)),
//                         const SizedBox(height: 24),
//                         SizedBox(
//                           width: 160,
//                           child: OutlinedButton(
//                             onPressed: () {},
//                             style: OutlinedButton.styleFrom(
//                               side: const BorderSide(color: Color(0xFFB5B5B5)),
//                               foregroundColor: Colors.black38,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(18),
//                               ),
//                             ),
//                             child: const Text('Join with basic'),
//                           ),
//                         ),
//                         const Spacer(),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _Dot(isActive: true),
//                             _Dot(isActive: false),
//                             _Dot(isActive: false),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           PaymentMethodDialog(
//             isSelected: _paypalSelected,
//             onSelect: () => setState(() => _paypalSelected = !_paypalSelected),
//             onClose: () {},
//             onPay: () => Navigator.of(context).pushNamed(
//               AppRoutes.planPricingDetails,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PlanBullet extends StatelessWidget {
//   final String text;
//   final Color dotColor;

//   const _PlanBullet({
//     required this.text,
//     required this.dotColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 10),
//           Text(
//             text,
//             style: const TextStyle(color: Colors.black26),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Dot extends StatelessWidget {
//   final bool isActive;

//   const _Dot({required this.isActive});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       width: 6,
//       height: 6,
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF8DC6E9) : const Color(0xFFD7D7D7),
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }
