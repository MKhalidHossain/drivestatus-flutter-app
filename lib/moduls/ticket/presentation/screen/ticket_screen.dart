import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/helpers/subscription_access.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../profile/model/profile_data.dart';
import '../controller/ticket_controller.dart';
import '../widget/payment_method_dialog.dart';
import '../widget/ticket_card.dart';
import '../widget/ticket_summary_card.dart';
import '../../model/ticket_model.dart';

class TicketScreen extends StatefulWidget {
  final bool showBackButton;

  const TicketScreen({super.key, this.showBackButton = false});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isPaypalselected = false;
  bool _isInitialized = false;
  late final SnackbarNotifier _snackbarNotifier;

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    return '$month $day,$year';
  }

  String _formatCurrency(int amount) {
    return r'$' + amount.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  Future<void> _loadTickets() async {
    await TicketController.loadTickets(
      snackbarNotifier: _isInitialized ? _snackbarNotifier : null,
    );
  }

  Future<bool> _ensureTicketAccess(String featureName) async {
    return SubscriptionAccess.ensureSubscribedAction(
      context: context,
      featureName: featureName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = ProfileData.instance.subscribed;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: const Color(0xFFF2F2F2),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Ticket',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: TicketController.isLoading,
          builder: (context, isLoading, _) {
            final hasLoaded = TicketController.hasLoaded.value;
            if (isLoading && !hasLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _loadTickets,
              child: ValueListenableBuilder<TicketResponse?>(
                valueListenable: TicketController.ticketsData,
                builder: (context, ticketsData, _) {
                  return ValueListenableBuilder<List<TicketModel>>(
                    valueListenable: TicketController.unpaidTickets,
                    builder: (context, unpaidTickets, _) {
                      return ValueListenableBuilder<List<TicketModel>>(
                        valueListenable: TicketController.paidTickets,
                        builder: (context, paidTickets, _) {
                          final summary =
                              ticketsData?.summary ??
                              TicketSummary(
                                openTickets: 0,
                                totalDue: 0,
                                overdue: 0,
                              );

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            children: [
                              if (!isSubscribed) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4DB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Ticket check and action buttons are locked for unsubscribed users.',
                                    style: TextStyle(
                                      color: Color(0xFF8A5B00),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (!widget.showBackButton) ...[
                                const SizedBox(height: 6),
                                const Center(
                                  child: Text(
                                    'Ticket',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              TicketSummaryCard(
                                openTickets: summary.openTickets,
                                totalDue: _formatCurrency(summary.totalDue),
                                overdue: summary.overdue,
                              ),
                              const SizedBox(height: 16),
                              if (unpaidTickets.isNotEmpty) ...[
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...unpaidTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TicketCard(
                                      ticketId: ticket.ticketNo,
                                      type: ticket.type,
                                      amount: _formatCurrency(ticket.amount),
                                      dueDate: _formatDateShort(ticket.dueAt),
                                      isPaid: false,
                                      onPayNow: () async {
                                        final canProceed =
                                            await _ensureTicketAccess(
                                              'Ticket payment',
                                            );
                                        if (!canProceed || !context.mounted) {
                                          return;
                                        }
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (dialogContext) {
                                            return StatefulBuilder(
                                              builder: (context, setDialogState) {
                                                return PaymentMethodDialog(
                                                  isSelected: _isPaypalselected,
                                                  onSelectChanged: (val) {
                                                    _isPaypalselected = val;
                                                    setState(
                                                      () => _isPaypalselected =
                                                          !_isPaypalselected,
                                                    );
                                                  },
                                                  onClose: () => Navigator.of(
                                                    context,
                                                  ).pop(dialogContext),
                                                  onPay: () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pushNamed(
                                                        AppRoutes
                                                            .planPricingDetails,
                                                      ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      onViewDetails: () async {
                                        final canProceed =
                                            await _ensureTicketAccess(
                                              'Ticket details',
                                            );
                                        if (!canProceed || !context.mounted) {
                                          return;
                                        }
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.ticketDetails,
                                          arguments: ticket.id,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (paidTickets.isNotEmpty) ...[
                                const Text(
                                  'Paid',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...paidTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TicketCard(
                                      ticketId: ticket.ticketNo,
                                      type: ticket.type,
                                      amount: _formatCurrency(ticket.amount),
                                      dueDate: _formatDateShort(ticket.dueAt),
                                      isPaid: true,
                                      onViewDetails: () async {
                                        final canProceed =
                                            await _ensureTicketAccess(
                                              'Ticket details',
                                            );
                                        if (!canProceed || !context.mounted) {
                                          return;
                                        }
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.ticketDetails,
                                          arguments: ticket.id,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              if (unpaidTickets.isEmpty && paidTickets.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'No tickets found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6C6C6C),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
