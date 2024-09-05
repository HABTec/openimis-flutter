import 'package:dio/dio.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/i_enrollment_service.dart';
import 'package:openimis_app/app/utils/api_response.dart';

import '../../../../modules/enrollment/controller/HospitalDto.dart';
import '../../../../modules/enrollment/controller/LocationDto.dart';
import '../../../../modules/enrollment/controller/MembershipDto.dart';
import '../../base/idto.dart';
import '../../base/status.dart';

import '../../dto/enrollment/enrollment_in_dto.dart';
import '../../exceptions/dio_exceptions.dart';
import 'i_enrollment_repository.dart';

class EnrollmentRepository implements IEnrollmentRepository<EnrollmentInDto> {
  final IEnrollmentService service;

  EnrollmentRepository({required this.service});

  @override
  Future<ApiResponse<bool>> create({required IDto dto}) async {
    try {
      final response = await service.enrollment(dto: dto);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true, message: "Enrollment successful.");
      }
      return ApiResponse.failure(response.data['message']);
    } on DioError catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.failure(e.response!.data['message']);
      }
      return ApiResponse.failure(e.message);
    }
  }


  @override
  Future<bool?> delete({required String uuid}) async {

  }

  @override
  Future<Status<EnrollmentInDto>> get({required String uuid}) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<Status<List<EnrollmentInDto>>?> getAll({int? limit, int? offset, bool? isFeatured, String? position, String? companyId}) {
    // TODO: implement getAll
    throw UnimplementedError();
  }

  @override
  Future<bool?> update({required String uuid, required IDto dto}) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override

  Future<Status<List<LocationDto>>> getLocations() async {
    try {

      final response = await service.locations();

      // Ensure the data is properly typed as List<dynamic>
      final data = response.data['data'] as List<dynamic>;

      // Convert the List<dynamic> to List<LocationDto>
      final locations = data.map((e) => LocationDto.fromJson(e)).toList();

      if (response.statusCode == 200) {
        return Status.success(data: locations);
      }

      return const Status.failure(reason: "Something went wrong!");
    } on DioError catch (e) {
      final errMsg = DioExceptions.fromDioError(e).toString();
      return Status.failure(reason: errMsg);
    }
  }



  @override
  Future<Status<List<HealthServiceProvider>>> getHospitals() async {
    try {
      final response = await service.hospitals();

      // Check if the response status code is 200
      if (response.statusCode == 200) {
        // Extract the data list from the 'data' key
        final resp = response.data as Map<String, dynamic>;

        final hospitals = Hospital.fromJson(resp);

        return Status.success(data: hospitals.data);
      } else {
        return const Status.failure(reason: "Something went wrong!");
      }
    } on DioError catch (e) {
      final errMsg = DioExceptions.fromDioError(e).toString();
      return Status.failure(reason: errMsg);
    }
  }

  @override
  Future<Status<MemberShipCard>> getMembershipCard({required String uuid}) async{
    // TODO: implement getMembershipCard
    try {
      final response = await service.membership_card(uuid: 'feb656f8-b9ea-4c88-bdb8-00d2a1aa2fa2');
      //feb656f8-b9ea-4c88-bdb8-00d2a1aa2fa2
      // Check if the response status code is 200
      if (response.statusCode == 200) {
        // Extract the data list from the 'data' key
        final resp = response.data as Map<String, dynamic>;

        final card = MemberShipCard.fromJson(resp);

        return Status.success(data: card);
      } else {
        return const Status.failure(reason: "Something went wrong!");
      }
    } on DioError catch (e) {
      final errMsg = DioExceptions.fromDioError(e).toString();
      return Status.failure(reason: errMsg);
    }
  }




}

