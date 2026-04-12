import 'package:dartz/dartz.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/ticket_interface.dart';
import '../model/ticket_model.dart';

final class TicketInterfaceImpl extends TicketInterface {
  final AppPigeon appPigeon;

  TicketInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<TicketResponse>>> getMyTickets({
    String? status,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getMyTickets(status: status),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];

        if (responseData == null) {
          return Success(
            message: responseBody['message']?.toString() ?? 'No tickets found',
            data: TicketResponse(
              summary: TicketSummary(openTickets: 0, overdue: 0),
              tickets: [],
            ),
          );
        }

        final ticketResponse = TicketResponse.fromJson(
          Map<String, dynamic>.from(responseData),
        );

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Tickets fetched successfully',
          data: ticketResponse,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<TicketModel>>> getTicketById(
    String ticketId,
  ) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getTicketById(ticketId),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];

        if (responseData == null) {
          return Success(
            message: responseBody['message']?.toString() ?? 'No ticket found',
            data: TicketModel(
              id: '',
              userId: '',
              ticketNo: '',
              status: '',
              amount: 0,
              country: '',
              type: '',
              speed: '',
              location: '',
              officerBadge: '',
              city: '',
              issuedAt: DateTime.now(),
              dueAt: DateTime.now(),
              warnings: '',
              pointsOnLicense: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              v: 0,
              isClosed: false,
            ),
          );
        }

        final ticket = TicketModel.fromJson(
          Map<String, dynamic>.from(responseData),
        );

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Ticket fetched successfully',
          data: ticket,
        );
      },
    );
  }
}
