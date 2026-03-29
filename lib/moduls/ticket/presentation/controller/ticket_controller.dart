import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../interface/ticket_interface.dart';
import '../../model/ticket_model.dart';

class TicketController {
  static final ValueNotifier<TicketResponse?> ticketsData = ValueNotifier<TicketResponse?>(null);
  static final ValueNotifier<List<TicketModel>> unpaidTickets = ValueNotifier<List<TicketModel>>([]);
  static final ValueNotifier<List<TicketModel>> paidTickets = ValueNotifier<List<TicketModel>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);
  static final ValueNotifier<bool> hasLoaded = ValueNotifier(false);

  static Future<void> loadTickets({SnackbarNotifier? snackbarNotifier}) async {
    try {
      isLoading.value = true;

      final ticketInterface = Get.find<TicketInterface>();

      // Fetch all tickets (without status filter to get summary data)
      final result = await ticketInterface.getMyTickets();

      result.fold(
        (failure) {
          snackbarNotifier?.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load tickets',
          );
        },
        (success) {
          if (success.data != null) {
            ticketsData.value = success.data;

            // Separate unpaid and paid tickets
            final allTickets = success.data!.tickets;
            unpaidTickets.value = allTickets.where((ticket) => !ticket.isPaid).toList();
            paidTickets.value = allTickets.where((ticket) => ticket.isPaid).toList();
          } else {
            // Reset to empty
            ticketsData.value = TicketResponse(
              summary: TicketSummary(openTickets: 0, totalDue: 0, overdue: 0),
              tickets: [],
            );
            unpaidTickets.value = [];
            paidTickets.value = [];
          }
        },
      );
    } catch (e) {
      snackbarNotifier?.notifyError(
        message: 'An error occurred while loading tickets',
      );
    } finally {
      isLoading.value = false;
      hasLoaded.value = true;
    }
  }
}
