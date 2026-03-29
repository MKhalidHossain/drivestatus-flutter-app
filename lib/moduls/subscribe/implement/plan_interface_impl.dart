import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/plan_interface.dart';
import '../model/payment_response_model.dart';
import '../model/plan_model.dart';

final class PlanInterfaceImpl extends PlanInterface {
  final AppPigeon appPigeon;

  PlanInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<List<PlanModel>>>> getPlans() async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getPlans);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        if (responseData == null) {
          return Success(
            message: responseBody['message']?.toString() ?? 'No plans found',
            data: <PlanModel>[],
          );
        }

        final plans = _extractPlans(responseData);

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Plans fetched successfully',
          data: plans,
        );
      },
    );
  }

  List<PlanModel> _extractPlans(dynamic responseData) {
    final plans = <PlanModel>[];
    if (responseData is List) {
      for (final item in responseData) {
        if (item is Map) {
          plans.add(PlanModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return plans;
    }

    if (responseData is! Map) {
      return plans;
    }

    final dataMap = Map<String, dynamic>.from(responseData);
    final candidates = <dynamic>[
      dataMap['plans'],
      dataMap['items'],
      dataMap['list'],
      dataMap['results'],
      dataMap['data'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map) {
            plans.add(PlanModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (plans.isNotEmpty) {
          break;
        }
      }
    }

    final currentPlanCandidate =
        dataMap['currentPlan'] ?? dataMap['activePlan'] ?? dataMap['myPlan'];
    final currentPlan = _readCurrentPlan(currentPlanCandidate);
    if (currentPlan != null) {
      final existingIndex = plans.indexWhere(
        (plan) => plan.id == currentPlan.id,
      );
      if (existingIndex >= 0) {
        plans[existingIndex] = plans[existingIndex].copyWith(isCurrent: true);
      } else {
        plans.insert(0, currentPlan);
      }
    }

    if (plans.isEmpty && dataMap.isNotEmpty) {
      plans.add(PlanModel.fromJson(dataMap));
    }
    return plans;
  }

  PlanModel? _readCurrentPlan(dynamic currentPlanCandidate) {
    if (currentPlanCandidate is! Map) {
      return null;
    }
    final currentMap = Map<String, dynamic>.from(currentPlanCandidate);
    return PlanModel.fromJson(currentMap).copyWith(isCurrent: true);
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanModel>>> getPlanById(
    String planId,
  ) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getPlanById(planId));
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        if (responseData is Map) {
          return Success(
            message: responseBody['message']?.toString() ?? 'Plan fetched',
            data: PlanModel.fromJson(Map<String, dynamic>.from(responseData)),
          );
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Plan fetched',
          data: PlanModel.fromJson(<String, dynamic>{}),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanModel>>> createPlan({
    required String name,
    required double price,
    String? currency,
    bool? recurring,
    String? interval,
    List<String>? features,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final data = <String, dynamic>{
          'name': name,
          'price': price,
          if (currency != null) 'currency': currency,
          if (recurring != null) 'recurring': recurring,
          if (interval != null) 'interval': interval,
          if (features != null) 'features': features,
        };

        final response = await appPigeon.post(
          ApiEndpoints.createPlan,
          data: data,
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        if (responseData is Map) {
          return Success(
            message: responseBody['message']?.toString() ?? 'Plan created',
            data: PlanModel.fromJson(Map<String, dynamic>.from(responseData)),
          );
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Plan created',
          data: PlanModel.fromJson(<String, dynamic>{}),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanModel>>> updatePlan({
    required String planId,
    String? name,
    double? price,
    String? currency,
    bool? recurring,
    String? interval,
    List<String>? features,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final data = <String, dynamic>{
          if (name != null) 'name': name,
          if (price != null) 'price': price,
          if (currency != null) 'currency': currency,
          if (recurring != null) 'recurring': recurring,
          if (interval != null) 'interval': interval,
          if (features != null) 'features': features,
        };

        final response = await appPigeon.patch(
          ApiEndpoints.updatePlan(planId),
          data: data,
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        if (responseData is Map) {
          return Success(
            message: responseBody['message']?.toString() ?? 'Plan updated',
            data: PlanModel.fromJson(Map<String, dynamic>.from(responseData)),
          );
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Plan updated',
          data: PlanModel.fromJson(<String, dynamic>{}),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanModel>>> deletePlan(
    String planId,
  ) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.delete(
          ApiEndpoints.deletePlan(planId),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        if (responseData is Map) {
          return Success(
            message: responseBody['message']?.toString() ?? 'Plan deleted',
            data: PlanModel.fromJson(Map<String, dynamic>.from(responseData)),
          );
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Plan deleted',
          data: PlanModel.fromJson(<String, dynamic>{}),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanPaymentCreateResponse>>>
  createPlanPayment({
    required String planId,
    // required String provider,
    String? email,
    String? name,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        debugPrint('API: createPlanPayment start \n planId=$planId ');
        final response = await appPigeon.post(
          ApiEndpoints.createPlanPayment,
          data: {
            'planId': planId,
            // 'provider': provider,
            'email': email,
            'name': name,
          },
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        debugPrint(
          'API: createPlanPayment ok message=${responseBody['message']} '
          'hasData=${responseData != null}',
        );

        if (responseData is Map) {
          return Success(
            message:
                responseBody['message']?.toString() ??
                'Plan payment created successfully',
            data: PlanPaymentCreateResponse.fromJson(
              Map<String, dynamic>.from(responseData),
            ),
          );
        }

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Plan payment created successfully',
          data: const PlanPaymentCreateResponse(
            paymentId: '',
            amount: 0,
            currency: 'USD',
          ),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<PlanPaymentModel>>>
  confirmPlanPayment({
    required String paymentId,
    String? providerPaymentId,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final effectiveProviderId = providerPaymentId ?? 'SIMULATED';
        final usePaymentId = paymentId.isNotEmpty;
        final path = usePaymentId
            ? ApiEndpoints.confirmPlanPayment(paymentId)
            : ApiEndpoints.confirmPlanPaymentNoId;
        debugPrint(
          'API: confirmPlanPayment start paymentId=$paymentId providerPaymentId=$providerPaymentId path=$path',
        );
        final response = await appPigeon.post(
          path,
          data: {
            'providerPaymentId': effectiveProviderId,
            'paymentIntentId': effectiveProviderId,
            'transactionId': effectiveProviderId,
          },
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];

        debugPrint(
          'API: confirmPlanPayment ok message=${responseBody['message']} '
          'hasData=${responseData != null}',
        );

        if (responseData is Map) {
          return Success(
            message: responseBody['message']?.toString() ?? 'Payment confirmed',
            data: PlanPaymentModel.fromJson(
              Map<String, dynamic>.from(responseData),
            ),
          );
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Payment confirmed',
          data: const PlanPaymentModel(
            id: '',
            planId: '',
            provider: '',
            amount: 0,
            currency: 'USD',
            status: '',
            providerPaymentId: '',
          ),
        );
      },
    );
  }
}
