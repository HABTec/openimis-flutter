import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../api/dio_client.dart';
import '../../dto/enrollment/insuree_dto.dart';
import '../../../../utils/enhanced_database_helper.dart';
import '../../../../utils/api_response.dart';
import '../../../../modules/auth/controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class EnhancedInsureeService {
  final DioClient dioClient;
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();
  final Uuid _uuid = const Uuid();

  EnhancedInsureeService({required this.dioClient});

  // Check if online
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Get current user's officer ID
  int _getOfficerId() {
    final user = AuthController.to.currentUser;
    // For now, use a default officer ID of 1
    // TODO: Implement proper officer ID retrieval when available
    return 1; // Default officer ID
  }

  // Get current user's health facility ID
  int _getHealthFacilityId() {
    final user = AuthController.to.currentUser;
    // For now, use a default health facility ID of 17
    // TODO: Implement proper health facility ID retrieval when available
    return 17; // Default health facility ID
  }

  /// Create family with head insuree (offline-first)
  Future<ApiResponse> createFamily(FamilyDto family) async {
    try {
      // Always save locally first
      final localId = await _dbHelper.insertFamily(family);
      final isOnline = await _isOnline();
      if (isOnline) {
        // Try to sync immediately if online
        final syncResult = await _syncFamilyToServer(localId);
        if (!syncResult.error) {
          return ApiResponse.success(localId,
              message: 'Family created and synced successfully');
        } else {
          return ApiResponse.success(localId,
              message: 'Family created offline. Will sync when online.');
        }
      } else {
        return ApiResponse.success(localId,
            message: 'Family created offline. Will sync when online.');
      }
    } catch (e) {
      return ApiResponse.failure('Failed to create family: $e');
    }
  }

  /// Create additional family member (offline-first)
  Future<ApiResponse> createInsuree(InsureeDto insuree) async {
    try {
      // Always save locally first
      final localId = await _dbHelper.insertInsuree(insuree);

      if (await _isOnline()) {
        // Try to sync immediately if online
        final syncResult = await _syncInsureeToServer(localId);
        if (!syncResult.error) {
          return ApiResponse.success(localId,
              message: 'Insuree created and synced successfully');
        } else {
          return ApiResponse.success(localId,
              message: 'Insuree created offline. Will sync when online.');
        }
      } else {
        return ApiResponse.success(localId,
            message: 'Insuree created offline. Will sync when online.');
      }
    } catch (e) {
      return ApiResponse.failure('Failed to create insuree: $e');
    }
  }

  /// Sync all pending operations
  Future<ApiResponse> syncAllPending() async {
    try {
      if (!await _isOnline()) {
        return ApiResponse.failure('No internet connection');
      }

      // Get all unsynced families and insurees
      final unsyncedFamilies = await _dbHelper.getUnsyncedFamilies();
      final unsyncedInsurees = await _dbHelper.getUnsyncedInsurees();

      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];

      // Sync families first (since insurees depend on family IDs)
      for (final family in unsyncedFamilies) {
        final result = await _syncFamilyToServer(family.localId!);
        if (result.error) {
          failCount++;
          errors.add('Family ${family.localId}: ${result.message}');
        } else {
          successCount++;
        }
      }

      // Then sync individual insurees
      for (final insuree in unsyncedInsurees) {
        final result = await _syncInsureeToServer(insuree.localId!);
        if (result.error) {
          failCount++;
          errors.add('Insuree ${insuree.localId}: ${result.message}');
        } else {
          successCount++;
        }
      }

      if (failCount == 0) {
        return ApiResponse.success(null,
            message: 'All $successCount items synced successfully');
      } else {
        return ApiResponse.failure(
            '$successCount synced, $failCount failed: ${errors.join('; ')}');
      }
    } catch (e) {
      return ApiResponse.failure('Sync failed: $e');
    }
  }

  /// Sync individual family to server
  Future<ApiResponse> _syncFamilyToServer(int localId) async {
    try {
      // Get the family from local database
      final families = await _dbHelper.getUnsyncedFamilies();
      final family = families.firstWhereOrNull((f) => f.localId == localId);

      if (family == null) {
        return ApiResponse.failure('Family not found');
      }

      final clientMutationId = _uuid.v4();
      final clientMutationLabel =
          'Create family - ${family.headInsuree?.otherNames ?? ''} ${family.headInsuree?.lastName ?? ''} (${family.headInsuree?.chfId ?? ''})';

      // Create direct GraphQL mutation without input types
      final mutation = '''
        mutation {
          createFamily(
            input: {
              clientMutationId: "$clientMutationId"
              clientMutationLabel: "$clientMutationLabel"
              id: $localId
              
              headInsuree: {
                chfId: "${family.headInsuree?.chfId ?? ''}"
                lastName: "${family.headInsuree?.lastName ?? ''}"
                otherNames: "${family.headInsuree?.otherNames ?? ''}"
                genderId: "${family.headInsuree?.genderId ?? 'M'}"
                dob: "${family.headInsuree?.dob ?? ''}"
                head: ${family.headInsuree?.head ?? true}
                marital: "${family.headInsuree?.marital ?? 'N'}"
                passport: "${family.headInsuree?.passport ?? ''}"
                phone: "${family.headInsuree?.phone ?? ''}"
                email: "${family.headInsuree?.email ?? ''}"
                ${family.headInsuree?.photo != null ? '''
                photo: {
                  officerId: ${_getOfficerId()}
                  date: "${family.headInsuree!.photo!.date}"
                }
                ''' : ''}
                cardIssued: ${family.headInsuree?.cardIssued ?? true}
                professionId: ${family.headInsuree?.professionId ?? 1}
                educationId: ${family.headInsuree?.educationId ?? 1}
                typeOfIdId: "${family.headInsuree?.typeOfIdId ?? 'N'}"
                status: "${family.headInsuree?.status ?? 'AC'}"
                healthFacilityId: ${_getHealthFacilityId()}
              }

              locationId: ${family.locationId ?? 0}
              poverty: ${family.poverty ?? false}
              familyTypeId: "${family.familyTypeId ?? 'H'}"
              address: "${family.address ?? ''}"
              confirmationTypeId: "${family.confirmationTypeId ?? 'C'}"
              confirmationNo: "${family.confirmationNo ?? ''}"
              jsonExt: "${family.jsonExt ?? '{}'}"
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
      print("create family response: ${response.data}");
      if (response.statusCode == 200 &&
          response.data['data']['createFamily'] != null) {
        final result = response.data['data']['createFamily'];
        final remoteFamilyId = localId;

        // Update local record with sync success
        await _dbHelper.updateFamilySyncStatus(localId, 1,
            remoteFamilyId: remoteFamilyId);

        // Also update the head insuree if it exists
        if (family.headInsuree != null) {
          await _dbHelper.updateInsureeSyncStatus(
            family.headInsuree!.localId!,
            1,
            remoteId: result['internalId'],
          );
        }

        return ApiResponse.success(remoteFamilyId,
            message: 'Family synced successfully');
      } else {
        final errorMessage =
            response.data['errors']?[0]?['message'] ?? 'Unknown error';
        await _dbHelper.updateFamilySyncStatus(localId, 2,
            syncError: errorMessage);
        return ApiResponse.failure(errorMessage);
      }
    } catch (e) {
      await _dbHelper.updateFamilySyncStatus(localId, 2,
          syncError: e.toString());
      print("Failed to sync family: $e");
      return ApiResponse.failure('Failed to sync family: $e');
    }
  }

  /// Sync individual insuree to server
  Future<ApiResponse> _syncInsureeToServer(int localId) async {
    try {
      // Get the insuree from local database
      final insurees = await _dbHelper.getUnsyncedInsurees();
      final insuree = insurees.firstWhereOrNull((i) => i.localId == localId);

      if (insuree == null) {
        return ApiResponse.failure('Insuree not found');
      }

      final clientMutationId = _uuid.v4();
      final clientMutationLabel = 'Create insuree - ${insuree.chfId}';

      // Create direct GraphQL mutation without input types
      final mutation = '''
        mutation {
          createInsuree(
            input: {
              clientMutationId: "$clientMutationId"
              clientMutationLabel: "$clientMutationLabel"
              chfId: "${insuree.chfId ?? ''}"
              lastName: "${insuree.lastName ?? ''}"
              otherNames: "${insuree.otherNames ?? ''}"
              genderId: "${insuree.genderId ?? 'M'}"
              dob: "${insuree.dob ?? ''}"
              head: ${insuree.head ?? false}
              marital: "${insuree.marital ?? 'N'}"
              passport: "${insuree.passport ?? ''}"
              phone: "${insuree.phone ?? ''}"
              email: "${insuree.email ?? ''}"
              ${insuree.photo != null ? '''
              photo: {
                officerId: ${insuree.photo!.officerId ?? _getOfficerId()}
                date: "${insuree.photo!.date ?? DateTime.now().toIso8601String().split('T')[0]}"
                photo: "${insuree.photo!.photo ?? ''}"
              }
              ''' : ''}
              cardIssued: ${insuree.cardIssued ?? true}
              professionId: ${insuree.professionId ?? 1}
              educationId: ${insuree.educationId ?? 1}
              typeOfIdId: "${insuree.typeOfIdId ?? 'D'}"
              familyId: ${insuree.familyId ?? 0}
              relationshipId: ${insuree.relationshipId ?? 1}
              status: "${insuree.status ?? 'AC'}"
              jsonExt: "${insuree.jsonExt ?? '{}'}"
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

      if (response.statusCode == 200 &&
          response.data['data']['createInsuree'] != null) {
        final result = response.data['data']['createInsuree'];

        // Update local record with sync success
        await _dbHelper.updateInsureeSyncStatus(
          localId,
          1,
          remoteId: result['internalId'],
        );

        return ApiResponse.success(result['internalId'],
            message: 'Insuree synced successfully');
      } else {
        final errorMessage =
            response.data['errors']?[0]?['message'] ?? 'Unknown error';
        await _dbHelper.updateInsureeSyncStatus(localId, 2,
            syncError: errorMessage);
        return ApiResponse.failure(errorMessage);
      }
    } catch (e) {
      await _dbHelper.updateInsureeSyncStatus(localId, 2,
          syncError: e.toString());
      return ApiResponse.failure('Failed to sync insuree: $e');
    }
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    return await _dbHelper.getSyncStats();
  }

  /// Get all families (both synced and unsynced)
  Future<List<FamilyDto>> getAllFamilies() async {
    // This would need to be implemented to get both synced and unsynced families
    // For now, return unsynced ones
    return await _dbHelper.getUnsyncedFamilies();
  }

  /// Get family members by family ID
  Future<List<InsureeDto>> getFamilyMembers(int localFamilyId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'insurees',
      where: 'local_family_id = ?',
      whereArgs: [localFamilyId],
      orderBy: 'head DESC, created_at ASC', // Head first, then by creation time
    );

    return results
        .map((map) => InsureeDto(
              localId: map['local_id'] as int?,
              chfId: map['chf_id'] as String?,
              lastName: map['last_name'] as String?,
              otherNames: map['other_names'] as String?,
              genderId: map['gender_id'] as String?,
              dob: map['dob'] as String?,
              head: (map['head'] as int?) == 1,
              marital: map['marital'] as String?,
              passport: map['passport'] as String?,
              phone: map['phone'] as String?,
              email: map['email'] as String?,
              photo: map['photo_data'] != null
                  ? PhotoDto(
                      photo: map['photo_data'] as String?,
                      officerId: map['photo_officer_id'] as int?,
                      date: map['photo_date'] as String?,
                    )
                  : null,
              cardIssued: (map['card_issued'] as int?) == 1,
              professionId: map['profession_id'] as int?,
              educationId: map['education_id'] as int?,
              typeOfIdId: map['type_of_id_id'] as String?,
              localFamilyId: map['local_family_id'] as int?,
              familyId: map['remote_family_id'] as int?,
              relationshipId: map['relationship_id'] as int?,
              status: map['status'] as String?,
              jsonExt: map['json_ext'] as String?,
              syncStatus: map['sync_status'] as int?,
              createdAt: map['created_at'] as String?,
              updatedAt: map['updated_at'] as String?,
            ))
        .toList();
  }

  /// Delete family and all its members
  Future<ApiResponse> deleteFamily(int localFamilyId) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Delete all insurees in the family
        await txn.delete(
          'insurees',
          where: 'local_family_id = ?',
          whereArgs: [localFamilyId],
        );

        // Delete the family
        await txn.delete(
          'families',
          where: 'local_id = ?',
          whereArgs: [localFamilyId],
        );

        // Delete related sync operations
        await txn.delete(
          'sync_operations',
          where: '(entity_type = ? OR entity_type = ?) AND local_id = ?',
          whereArgs: ['FAMILY', 'INSUREE', localFamilyId],
        );
      });

      return ApiResponse.success(null, message: 'Family deleted successfully');
    } catch (e) {
      return ApiResponse.failure('Failed to delete family: $e');
    }
  }

  /// Delete individual insuree (not head)
  Future<ApiResponse> deleteInsuree(int localInsureeId) async {
    try {
      final db = await _dbHelper.database;

      // Check if this is a head insuree
      final result = await db.query(
        'insurees',
        where: 'local_id = ? AND head = 1',
        whereArgs: [localInsureeId],
      );

      if (result.isNotEmpty) {
        return ApiResponse.failure(
            'Cannot delete head insuree. Delete the entire family instead.');
      }

      await db.transaction((txn) async {
        // Delete the insuree
        await txn.delete(
          'insurees',
          where: 'local_id = ?',
          whereArgs: [localInsureeId],
        );

        // Delete related sync operations
        await txn.delete(
          'sync_operations',
          where: 'entity_type = ? AND local_id = ?',
          whereArgs: ['INSUREE', localInsureeId],
        );
      });

      return ApiResponse.success(null, message: 'Insuree deleted successfully');
    } catch (e) {
      return ApiResponse.failure('Failed to delete insuree: $e');
    }
  }
}
