import 'package:dio/dio.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/i_enrollment_service.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/family_service.dart';
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
  final FamilyService? familyService;

  EnrollmentRepository({
    required this.service,
    this.familyService,
  });

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
      return ApiResponse.failure(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<bool?> delete({required String uuid}) async {
    // TODO: Implement delete functionality if needed
    return null;
  }

  @override
  Future<Status<EnrollmentInDto>> get({required String uuid}) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<Status<List<EnrollmentInDto>>?> getAll(
      {int? limit,
      int? offset,
      bool? isFeatured,
      String? position,
      String? companyId}) {
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
  Future<Status<MemberShipCard>> getMembershipCard(
      {required String uuid}) async {
    // TODO: implement getMembershipCard
    try {
      final response = await service.membership_card(
          uuid: 'feb656f8-b9ea-4c88-bdb8-00d2a1aa2fa2');
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

  @override
  Future<ApiResponse> enrollmentSubmit(data) async {
    try {
      final response = await service.enrollmentR(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true, message: "Enrollment successful.");
      }
      return ApiResponse.failure(response.data['message']);
    } on DioError catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.failure(e.response!.data['message']);
      }
      return ApiResponse.failure(e.message ?? 'Unknown error');
    }
  }

  /// Create family using GraphQL with form data mapping
  Future<ApiResponse> createFamilyFromForm({
    required String chfId,
    required String lastName,
    required String otherNames,
    required String gender,
    required String dob,
    required String phone,
    required String email,
    required String identificationNo,
    required String maritalStatus,
    String? photoBase64,
    int? locationId,
    bool poverty = false,
    String familyTypeId = 'H',
    String? address,
    String confirmationTypeId = 'C',
    String? confirmationNo,
    int? healthFacilityId,
  }) async {
    try {
      if (familyService == null) {
        return ApiResponse.failure('Family service not available');
      }

      final input = familyService!.mapEnrollmentToGraphQLInput(
        chfId: chfId,
        lastName: lastName,
        otherNames: otherNames,
        gender: gender,
        dob: dob,
        phone: phone,
        email: email,
        identificationNo: identificationNo,
        maritalStatus: maritalStatus,
        photoBase64: photoBase64,
        locationId: locationId,
        poverty: poverty,
        familyTypeId: familyTypeId,
        address: address,
        confirmationTypeId: confirmationTypeId,
        confirmationNo: confirmationNo,
        healthFacilityId: healthFacilityId,
      );

      return await familyService!.createFamilyWithOfflineSupport(input);
    } catch (e) {
      return ApiResponse.failure('Failed to create family: $e');
    }
  }

  /// Create a family using GraphQL
  Future<ApiResponse> createFamily(
      {required Map<String, dynamic> input}) async {
    try {
      final response = await service.createFamily(input: input);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true,
            message: "Family created successfully.");
      }
      return ApiResponse.failure(response.data['message'] ?? 'Unknown error');
    } on DioError catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.failure(e.response!.data['message']);
      }
      return ApiResponse.failure(e.message ?? 'Network error');
    }
  }

  /// List families using GraphQL
  Future<ApiResponse> listFamilies(
      {required Map<String, dynamic> filters}) async {
    try {
      final response = await service.listFamilies(filters: filters);
      if (response.statusCode == 200) {
        return ApiResponse.success(response.data['data']['families']);
      }
      return ApiResponse.failure(response.data['message'] ?? 'Unknown error');
    } on DioError catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.failure(e.response!.data['message']);
      }
      return ApiResponse.failure(e.message ?? 'Network error');
    }
  }

  /// Sync pending families
  Future<void> syncPendingFamilies() async {
    if (familyService != null) {
      await familyService!.syncPendingFamilies();
    }
  }

  // Sync family data with server
  Future<ApiResponse> syncFamilyData(Map<String, dynamic> data) async {
    try {
      final response = await service.enrollmentR(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true, message: "Sync successful.");
      }
      return ApiResponse.failure(response.data['message']);
    } on DioError catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.failure(e.response!.data['message']);
      }
      return ApiResponse.failure(
          e.message != null ? e.message! : 'Sync failed');
    }
  }
}
