import 'package:dio/src/response.dart';

abstract class IEnrollmentService<T> {

  Future<Response> enrollment({required T dto});
  Future<Response> locations();
  Future<Response> hospitals();
  Future<Response> membership_card({required String uuid});
}
