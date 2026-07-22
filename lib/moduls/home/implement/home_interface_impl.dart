import 'package:dartz/dartz.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/home_interface.dart';
import '../model/home_response_model.dart';

final class HomeInterfaceImpl extends HomeInterface {
  final AppPigeon appPigeon;

  HomeInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<HomeResponseModel>>> getHomeData() {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getHome);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final homeData = HomeResponseModel.fromJson(payload);
        return Success(
          message: responseBody['message']?.toString() ?? 'Home data fetched',
          data: homeData,
        );
      },
    );
  }
}
