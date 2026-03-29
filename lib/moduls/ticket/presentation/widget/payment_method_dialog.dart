// import 'package:flutter/material.dart';

// import 'ticket_action_button.dart';

// class PaymentMethodDialog extends StatefulWidget {
//   final bool? isSelected; // nullable support
//   final VoidCallback? onClose;
//   final ValueChanged<bool>? onSelectChanged;
//   final VoidCallback? onPay;

//   const PaymentMethodDialog({
//     super.key,
//     this.isSelected,
//     this.onClose,
//     this.onSelectChanged,
//     this.onPay,
//   });

//   @override
//   State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
// }

// class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
//   late bool selected;

//   @override
//   void initState() {
//     super.initState();
//     selected = widget.isSelected ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             InkWell(
//               onTap: () {
//                 setState(() => selected = !selected);
//                 widget.onSelectChanged?.call(selected);
//               },
//               child: Row(
//                 children: [
//                   const Text('PayPal'),
//                   const Spacer(),
//                   Icon(
//                     selected
//                         ? Icons.radio_button_checked
//                         : Icons.radio_button_off,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: TicketActionButton(
//                 label: 'Pay Now',
//                 onPressed: widget.onPay,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

import 'ticket_action_button.dart';

class PaymentMethodDialog extends StatefulWidget {
  final bool?isSelected;
  final VoidCallback? onClose;
  final ValueChanged<bool>? onSelectChanged;
  final VoidCallback? onPay;

  const PaymentMethodDialog({
    super.key,
    this.isSelected = true,
    this.onClose,
    this.onSelectChanged,
    this.onPay,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {


  late bool selected;

  @override
  void initState() {
    super.initState();
    selected = widget.isSelected ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:  Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onClose,
                  child: const Icon(Icons.close, size: 18, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
                  onTap: () {
                setState(() => selected = !selected);
                widget.onSelectChanged?.call(selected);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE3E3E3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF3F76F6)),
                    const SizedBox(width: 8),
                    const Text(
                      'PayPal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(
                      selected   ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: const Color(0xFF3F76F6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TicketActionButton(
                label: 'Pay Now',
                onPressed: widget.onPay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
