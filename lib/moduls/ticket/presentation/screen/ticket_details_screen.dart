import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../interface/ticket_interface.dart';
import '../../model/ticket_model.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  TicketModel? _ticket;
  bool _isLoading = true;
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
    return '$month $day, $year';
  }

  int _calculateDaysLeft(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  String _parseWarnings(String warnings) {
    return warnings;
  }

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  Future<void> _loadTicketDetails() async {
    if (widget.ticketId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final ticketInterface = Get.find<TicketInterface>();
      final result = await ticketInterface.getTicketById(widget.ticketId);

      result.fold(
        (failure) {
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load ticket details',
          );
        },
        (success) {
          if (success.data != null) {
            setState(() {
              _ticket = success.data;
            });
          }
        },
      );
    } catch (e) {
      _snackbarNotifier.notifyError(
        message: 'An error occurred while loading ticket details',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Ticket Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
          ? const Center(
              child: Text(
                'No ticket details found',
                style: TextStyle(fontSize: 16, color: Color(0xFF6C6C6C)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTicketDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF2F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_outlined,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _ticket!.ticketNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'State',
                            style: TextStyle(
                              color: Color(0xFF6C6C6C),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _ticket!.isClosed
                                  ? const Color(0xFF2CC56F)
                                  : const Color(0xFFB7791F),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _ticket!.isClosed ? 'Closed' : 'Open',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Important Dates',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Issued:',
                        value: _formatDateShort(_ticket!.issuedAt),
                      ),
                      const SizedBox(height: 6),
                      _DetailLine(
                        label: 'Due:',
                        value: _formatDateShort(_ticket!.dueAt),
                      ),
                      const SizedBox(height: 6),
                      _DetailLine(
                        label: 'Days Left:',
                        value: '${_calculateDaysLeft(_ticket!.dueAt)} days',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Violation Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(label: 'Type:', value: _ticket!.type),
                      const SizedBox(height: 6),
                      _DetailLine(label: 'Speed:', value: _ticket!.speed),
                      const SizedBox(height: 6),
                      _DetailLine(label: 'Location:', value: _ticket!.location),
                      const SizedBox(height: 6),
                      _DetailLine(
                        label: 'Officer:',
                        value: 'Badge ${_ticket!.officerBadge}',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Warnings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._parseWarnings(_ticket!.warnings)
                          .split(',')
                          .map(
                            (warning) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _DetailLine(
                                label: warning.trim(),
                                value: '',
                              ),
                            ),
                          ),
                      const SizedBox(height: 6),
                      _DetailLine(
                        label: 'Point on license:',
                        value: '${_ticket!.pointsOnLicense}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6C6C6C), fontSize: 16),
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ],
    );
  }
}
