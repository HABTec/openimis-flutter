import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../api/dio_client.dart';
import '../../dto/enrollment/policy_dto.dart';
import '../../../../utils/api_response.dart';
import '../../../../utils/enhanced_database_helper.dart';
import '../../exceptions/dio_exceptions.dart';

class ContributionService {
  final DioClient dioClient;
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();
  final Uuid _uuid = const Uuid();

  ContributionService({required this.dioClient});

  /// Create contribution locally
  Future<ApiResponse> createContributionLocally({
    required String receipt,
    required String payDate,
    required String amount,
    required String policyUuid,
    String payType = 'B',
    bool isPhotoFee = false,
    String action = 'ENFORCE',
  }) async {
    try {
      final db = await _dbHelper.database;

      final contributionData = {
        'receipt': receipt,
        'pay_date': payDate,
        'pay_type': payType,
        'is_photo_fee': isPhotoFee ? 1 : 0,
        'action': action,
        'amount': amount,
        'policy_uuid': policyUuid,
        'sync_status': 0, // Pending sync
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final localId = await db.insert('contributions', contributionData);

      final contribution = ContributionDto(
        localId: localId,
        receipt: receipt,
        payDate: payDate,
        payType: payType,
        isPhotoFee: isPhotoFee,
        action: action,
        amount: amount,
        policyUuid: policyUuid,
        syncStatus: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      return ApiResponse.success(contribution,
          message: 'Contribution created locally');
    } catch (e) {
      return ApiResponse.failure('Failed to create contribution locally: $e');
    }
  }

  /// Create contribution online via GraphQL
  Future<ApiResponse> createContributionOnline(
      ContributionDto contribution) async {
    try {
      final clientMutationId = _uuid.v4();
      final clientMutationLabel = 'Create contribution';

      // Create direct GraphQL mutation without input types
      final mutation = '''
        mutation {
          createPremium(
            input: {
              clientMutationId: "$clientMutationId"
              clientMutationLabel: "$clientMutationLabel"
              receipt: "${contribution.receipt ?? ''}"
              payDate: "${contribution.payDate ?? ''}"
              payType: "${contribution.payType ?? 'B'}"
              isPhotoFee: ${contribution.isPhotoFee ?? false}
              action: "${contribution.action ?? 'ENFORCE'}"
              amount: "${contribution.amount ?? '0.00'}"
              policyUuid: "${contribution.policyUuid ?? ''}"
            }
          ) {
            clientMutationId
            internalId
          }
        }
      ''';

      final data = {
        'query': mutation,
        'variables': {},
      };

      final response = await dioClient.post('/api/graphql', data: data);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final result = response.data['data']['createPremium'];

        if (result != null) {
          final remoteContributionId =
              int.tryParse(result['internalId'] ?? '0') ?? 0;

          // Update local record with sync success
          await _updateContributionSyncStatus(contribution.localId!, 1,
              remoteContributionId: remoteContributionId);

          return ApiResponse.success(remoteContributionId,
              message: 'Contribution created successfully');
        }
      }

      final errorMessage =
          response.data['errors']?[0]?['message'] ?? 'Unknown error';
      await _updateContributionSyncStatus(contribution.localId!, 2,
          syncError: errorMessage);
      return ApiResponse.failure(errorMessage);
    } on DioError catch (e) {
      await _updateContributionSyncStatus(contribution.localId!, 2,
          syncError: DioExceptions.fromDioError(e).message);
      return ApiResponse.failure(DioExceptions.fromDioError(e).message);
    } catch (e) {
      await _updateContributionSyncStatus(contribution.localId!, 2,
          syncError: 'Failed to create contribution: $e');
      return ApiResponse.failure('Failed to create contribution: $e');
    }
  }

  /// Create contribution with offline-first support
  Future<ApiResponse> createContribution({
    required String receipt,
    required String payDate,
    required String amount,
    required String policyUuid,
    String payType = 'B',
    bool isPhotoFee = false,
    String action = 'ENFORCE',
    bool tryOnlineFirst = true,
  }) async {
    // First create locally
    final localResult = await createContributionLocally(
      receipt: receipt,
      payDate: payDate,
      amount: amount,
      policyUuid: policyUuid,
      payType: payType,
      isPhotoFee: isPhotoFee,
      action: action,
    );

    if (localResult.error) {
      return localResult;
    }

    final contribution = localResult.data as ContributionDto;

    // Try to sync online if requested
    if (tryOnlineFirst) {
      try {
        final onlineResult = await createContributionOnline(contribution);
        return onlineResult;
      } catch (e) {
        // Online creation failed, return local result
        return localResult;
      }
    }

    return localResult;
  }

  /// Get contributions by policy UUID
  Future<List<ContributionDto>> getContributionsByPolicyUuid(
      String policyUuid) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'contributions',
        where: 'policy_uuid = ?',
        whereArgs: [policyUuid],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => ContributionDto.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get contributions: $e');
    }
  }

  /// Get contribution by receipt number
  Future<ContributionDto?> getContributionByReceipt(String receipt) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'contributions',
        where: 'receipt = ?',
        whereArgs: [receipt],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return ContributionDto.fromJson(results.first);
    } catch (e) {
      throw Exception('Failed to get contribution: $e');
    }
  }

  /// Get unsynced contributions
  Future<List<ContributionDto>> getUnsyncedContributions() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'contributions',
        where: 'sync_status = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return results.map((map) => ContributionDto.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get unsynced contributions: $e');
    }
  }

  /// Sync pending contributions
  Future<void> syncPendingContributions() async {
    try {
      final unsyncedContributions = await getUnsyncedContributions();

      for (final contribution in unsyncedContributions) {
        try {
          await createContributionOnline(contribution);
        } catch (e) {
          print('Failed to sync contribution ${contribution.receipt}: $e');
        }
      }
    } catch (e) {
      print('Failed to sync pending contributions: $e');
    }
  }

  /// Update contribution sync status
  Future<void> _updateContributionSyncStatus(
    int localId,
    int syncStatus, {
    int? remoteContributionId,
    String? syncError,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updateData = {
        'sync_status': syncStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (remoteContributionId != null) {
        updateData['remote_contribution_id'] = remoteContributionId;
      }

      if (syncError != null) {
        updateData['sync_error'] = syncError;
      }

      await db.update(
        'contributions',
        updateData,
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw Exception('Failed to update contribution sync status: $e');
    }
  }

  /// Generate receipt number
  String generateReceiptNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return timestamp.toString().substring(5); // Use last 8 digits
  }
}
