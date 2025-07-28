import 'package:dio/src/response.dart';

import '../../../local/config/app_config.dart';
import '../../api/api_routes.dart';
import '../../api/dio_client.dart';
import '../../dto/auth/graphql_auth_dto.dart';
import 'i_auth_service.dart';
import '../../base/idto.dart';

class AuthService implements IAuthService<IDto> {
  final DioClient dioClient;

  AuthService({required this.dioClient});

  @override
  Future<Response> login({required IDto dto}) async {
    try {
      return await dioClient.post(ApiRoutes.LOGIN, data: dto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> registerCustomer({required IDto dto}) {
    // TODO: implement registerCustomer
    throw UnimplementedError();
  }

  @override
  Future<Response> insureeValidation(data) async {
    try {
      return await dioClient.post(ApiRoutes.INSUREE_VALIDATION, data: data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> insureeOtpValidation(data) async {
    try {
      return await dioClient.post(ApiRoutes.INSUREE_OTP_VALIDATION, data: data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> insureeOtpResend(data) async {
    try {
      return await dioClient.post(ApiRoutes.INSUREE_OTP_RESEND, data: data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> userNameVerify(data) async {
    try {
      return await dioClient.post(ApiRoutes.USERNAME_VERIFY, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // New GraphQL authentication methods
  Future<Response> graphqlAuth(
      {required String username, required String password}) async {
    try {
      final request =
          GraphQLAuthRequest(username: username, password: password);
      return await dioClient.post(ApiRoutes.GRAPHQL, data: request.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getCurrentUser() async {
    try {
      return await dioClient.get(ApiRoutes.CURRENT_USER);
    } catch (e) {
      rethrow;
    }
  }
}
