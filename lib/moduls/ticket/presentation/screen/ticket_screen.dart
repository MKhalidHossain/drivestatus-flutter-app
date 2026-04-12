import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../controller/ticket_controller.dart';
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

  @override
  Widget build(BuildContext context) {
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
                    valueListenable: TicketController.openTickets,
                    builder: (context, openTickets, _) {
                      return ValueListenableBuilder<List<TicketModel>>(
                        valueListenable: TicketController.closedTickets,
                        builder: (context, closedTickets, _) {
                          final summary =
                              ticketsData?.summary ??
                              TicketSummary(openTickets: 0, overdue: 0);

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            children: [
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
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD4E4FF),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF1F6FEB),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Track your ticket records, review deadlines, and check status updates here.',
                                        style: TextStyle(
                                          color: Color(0xFF33527B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TicketSummaryCard(
                                openRecords: openTickets.length,
                                closedRecords: closedTickets.length,
                                needsAttention: summary.overdue > 0
                                    ? summary.overdue
                                    : summary.openTickets,
                              ),
                              const SizedBox(height: 16),
                              if (openTickets.isNotEmpty) ...[
                                const Text(
                                  'Open Records',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...openTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TicketCard(
                                      ticketId: ticket.ticketNo,
                                      type: ticket.type,
                                      dueDate: _formatDateShort(ticket.dueAt),
                                      isClosed: false,
                                      onViewDetails: () {
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
                              if (closedTickets.isNotEmpty) ...[
                                const Text(
                                  'Closed Records',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...closedTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TicketCard(
                                      ticketId: ticket.ticketNo,
                                      type: ticket.type,
                                      dueDate: _formatDateShort(ticket.dueAt),
                                      isClosed: true,
                                      onViewDetails: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.ticketDetails,
                                          arguments: ticket.id,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              if (openTickets.isEmpty && closedTickets.isEmpty)
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
