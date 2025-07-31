import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../api/dio_client.dart';
import '../../dto/enrollment/policy_dto.dart';
import '../../../../utils/api_response.dart';
import '../../../../utils/enhanced_database_helper.dart';
import '../../exceptions/dio_exceptions.dart';

class PolicyService {
  final DioClient dioClient;
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();
  final Uuid _uuid = const Uuid();

  PolicyService({required this.dioClient});

  /// Create policy locally
  Future<ApiResponse> createPolicyLocally({
    required String enrollDate,
    required String startDate,
    required String expiryDate,
    required String value,
    required int productId,
    required int familyId,
    int officerId = 1,
  }) async {
    try {
      final db = await _dbHelper.database;
      final uuid = _uuid.v4();

      final policyData = {
        'enroll_date': enrollDate,
        'start_date': startDate,
        'expiry_date': expiryDate,
        'value': value,
        'product_id': productId,
        'family_id': familyId,
        'officer_id': officerId,
        'uuid': uuid,
        'sync_status': 0, // Pending sync
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final localId = await db.insert('policies', policyData);

      final policy = PolicyDto(
        localId: localId,
        enrollDate: enrollDate,
        startDate: startDate,
        expiryDate: expiryDate,
        value: value,
        productId: productId,
        familyId: familyId,
        officerId: officerId,
        uuid: uuid,
        syncStatus: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      return ApiResponse.success(policy, message: 'Policy created locally');
    } catch (e) {
      return ApiResponse.failure('Failed to create policy locally: $e');
    }
  }

  /// Create policy online via GraphQL
  Future<ApiResponse> createPolicyOnline(PolicyDto policy) async {
    try {
      const String mutation = '''
        mutation CreatePolicy(\$input: CreatePolicyInputType!) {
          createPolicy(input: \$input) {
            clientMutationId
            internalId
          }
        }
      ''';

      final clientMutationId = _uuid.v4();
      final clientMutationLabel =
          'Create Policy ${policy.familyId} - ${policy.startDate} : ${policy.expiryDate}';

      final input =
          policy.toGraphQLInput(clientMutationId, clientMutationLabel);

      final data = {
        'query': mutation,
        'variables': {'input': input},
      };

      final response = await dioClient.post('/api/graphql', data: data);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final result = response.data['data']['createPolicy'];

        if (result != null) {
          final remotePolicyId = int.tryParse(result['internalId'] ?? '0') ?? 0;

          // Update local record with sync success
          await _updatePolicySyncStatus(policy.localId!, 1,
              remotePolicyId: remotePolicyId);

          return ApiResponse.success(remotePolicyId,
              message: 'Policy created successfully');
        }
      }

      final errorMessage =
          response.data['errors']?[0]?['message'] ?? 'Unknown error';
      await _updatePolicySyncStatus(policy.localId!, 2,
          syncError: errorMessage);
      return ApiResponse.failure(errorMessage);
    } on DioError catch (e) {
      await _updatePolicySyncStatus(policy.localId!, 2,
          syncError: DioExceptions.fromDioError(e).message);
      return ApiResponse.failure(DioExceptions.fromDioError(e).message);
    } catch (e) {
      await _updatePolicySyncStatus(policy.localId!, 2,
          syncError: 'Failed to create policy: $e');
      return ApiResponse.failure('Failed to create policy: $e');
    }
  }

  /// Create policy with offline-first support
  Future<ApiResponse> createPolicy({
    required String enrollDate,
    required String startDate,
    required String expiryDate,
    required String value,
    required int productId,
    required int familyId,
    int officerId = 1,
    bool tryOnlineFirst = true,
  }) async {
    // First create locally
    final localResult = await createPolicyLocally(
      enrollDate: enrollDate,
      startDate: startDate,
      expiryDate: expiryDate,
      value: value,
      productId: productId,
      familyId: familyId,
      officerId: officerId,
    );

    if (localResult.error) {
      return localResult;
    }

    final policy = localResult.data as PolicyDto;

    // Try to sync online if requested
    if (tryOnlineFirst) {
      try {
        final onlineResult = await createPolicyOnline(policy);
        return onlineResult;
      } catch (e) {
        // Online creation failed, return local result
        return localResult;
      }
    }

    return localResult;
  }

  /// Get policy by UUID
  Future<PolicyDto?> getPolicyByUuid(String uuid) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'policies',
        where: 'uuid = ?',
        whereArgs: [uuid],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return PolicyDto.fromJson(results.first);
    } catch (e) {
      throw Exception('Failed to get policy: $e');
    }
  }

  /// Get policies by family ID
  Future<List<PolicyDto>> getPoliciesByFamilyId(int familyId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'policies',
        where: 'family_id = ?',
        whereArgs: [familyId],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => PolicyDto.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get policies: $e');
    }
  }

  /// Get unsynced policies
  Future<List<PolicyDto>> getUnsyncedPolicies() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'policies',
        where: 'sync_status = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return results.map((map) => PolicyDto.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get unsynced policies: $e');
    }
  }

  /// Sync pending policies
  Future<void> syncPendingPolicies() async {
    try {
      final unsyncedPolicies = await getUnsyncedPolicies();

      for (final policy in unsyncedPolicies) {
        try {
          await createPolicyOnline(policy);
        } catch (e) {
          print('Failed to sync policy ${policy.uuid}: $e');
        }
      }
    } catch (e) {
      print('Failed to sync pending policies: $e');
    }
  }

  /// Update policy sync status
  Future<void> _updatePolicySyncStatus(
    int localId,
    int syncStatus, {
    int? remotePolicyId,
    String? syncError,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updateData = {
        'sync_status': syncStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (remotePolicyId != null) {
        updateData['remote_policy_id'] = remotePolicyId;
      }

      if (syncError != null) {
        updateData['sync_error'] = syncError;
      }

      await db.update(
        'policies',
        updateData,
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw Exception('Failed to update policy sync status: $e');
    }
  }

  /// Helper method to calculate expiry date
  String calculateExpiryDate(String? enrollmentPeriodEndDate) {
    if (enrollmentPeriodEndDate != null && enrollmentPeriodEndDate.isNotEmpty) {
      return enrollmentPeriodEndDate;
    }

    // Default to one year from now
    final oneYearFromNow = DateTime.now().add(const Duration(days: 365));
    return oneYearFromNow.toIso8601String().split('T')[0];
  }
}
