import 'package:dio/src/response.dart';

abstract class IEnrollmentService<T> {
  Future<Response> enrollment({required T dto});
  Future<Response> enrollmentR(data);
  Future<Response> locations();
  Future<Response> hospitals();
  Future<Response> membership_card({required String uuid});

  // GraphQL methods
  Future<Response> createFamily({required Map<String, dynamic> input});
  Future<Response> listFamilies({required Map<String, dynamic> filters});
}
