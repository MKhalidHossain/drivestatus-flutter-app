import 'package:dartz/dartz.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../model/payment_response_model.dart';
import '../model/plan_model.dart';

abstract base class PlanInterface extends BaseRepository {
  Future<Either<DataCRUDFailure, Success<List<PlanModel>>>> getPlans();

  Future<Either<DataCRUDFailure, Success<PlanModel>>> getPlanById(
    String planId,
  );

  Future<Either<DataCRUDFailure, Success<PlanModel>>> createPlan({
    required String name,
    required double price,
    String? currency,
    bool? recurring,
    String? interval,
    List<String>? features,
  });

  Future<Either<DataCRUDFailure, Success<PlanModel>>> updatePlan({
    required String planId,
    String? name,
    double? price,
    String? currency,
    bool? recurring,
    String? interval,
    List<String>? features,
  });

  Future<Either<DataCRUDFailure, Success<PlanModel>>> deletePlan(String planId);

  Future<Either<DataCRUDFailure, Success<PlanPaymentCreateResponse>>>
  createPlanPayment({
    required String planId,
    required String provider,
    String? email,
    String? name,
  });

  Future<Either<DataCRUDFailure, Success<PlanPaymentModel>>>
  confirmPlanPayment({required String paymentId, String? providerPaymentId});
}
