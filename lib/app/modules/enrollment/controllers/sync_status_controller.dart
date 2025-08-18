import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/remote/services/enrollment/enhanced_insuree_service.dart';
import '../../../data/remote/services/enrollment/reference_data_service.dart';
import '../../../data/remote/dto/enrollment/insuree_dto.dart';
import '../../../utils/enhanced_database_helper.dart';
import '../../../di/locator.dart';
import '../../../widgets/snackbars.dart';

class SyncStatusController extends GetxController {
  final EnhancedInsureeService _insureeService =
      EnhancedInsureeService(dioClient: getIt());
  final ReferenceDataService _referenceService =
      ReferenceDataService(dioClient: getIt());
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = false.obs;
  final RxMap<String, int> stats = <String, int>{}.obs;
  final RxList<FamilyDto> pendingFamilies = <FamilyDto>[].obs;
  final RxList<InsureeDto> pendingInsurees = <InsureeDto>[].obs;
  final RxList<FamilyDto> syncedFamilies = <FamilyDto>[].obs;
  final RxList<InsureeDto> syncedInsurees = <InsureeDto>[].obs;
  final RxList<FamilyDto> failedFamilies = <FamilyDto>[].obs;
  final RxList<InsureeDto> failedInsurees = <InsureeDto>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivityListener();
    refreshData();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = result != ConnectivityResult.none;
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      isOnline.value = result != ConnectivityResult.none;
    });
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;

      // Load sync statistics
      final syncStats = await _dbHelper.getSyncStats();
      stats.assignAll(syncStats);

      // Load pending families
      final families = await _dbHelper.getUnsyncedFamilies();
      pendingFamilies.assignAll(families);

      // Load pending insurees
      final insurees = await _dbHelper.getUnsyncedInsurees();
      pendingInsurees.assignAll(insurees);

      // Load synced and failed lists
      syncedFamilies.assignAll(await _dbHelper.getFamiliesBySyncStatus(1));
      failedFamilies.assignAll(await _dbHelper.getFamiliesBySyncStatus(2));
      syncedInsurees.assignAll(await _dbHelper.getInsureesBySyncStatus(1));
      failedInsurees.assignAll(await _dbHelper.getInsureesBySyncStatus(2));
    } catch (e) {
      SnackBars.failure('Error', 'Failed to load sync data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncAll() async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      isSyncing.value = true;

      // First, sync reference data if needed
      final referenceResult = await _referenceService.syncIfNeeded();
      if (referenceResult.error) {
        SnackBars.warning('Warning',
            'Failed to sync reference data: ${referenceResult.message}');
      }

      // Then sync insurees and families
      final syncResult = await _insureeService.syncAllPending();

      if (syncResult.error) {
        SnackBars.failure('Sync Failed', syncResult.message);
      } else {
        SnackBars.success('Success', syncResult.message);
      }

      // Refresh data to show updated status
      await refreshData();
    } catch (e) {
      SnackBars.failure('Error', 'Sync failed: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncReferenceData() async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      isSyncing.value = true;

      final result = await _referenceService.syncAllReferenceData();

      if (result.error) {
        SnackBars.failure('Sync Failed', result.message);
      } else {
        SnackBars.success('Success', 'Reference data synced successfully');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Reference data sync failed: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> resyncReferenceData() async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      isSyncing.value = true;

      final result = await _referenceService.resyncAllReferenceData();

      if (result.error) {
        SnackBars.failure('Resync Failed', result.message);
      } else {
        SnackBars.success('Success', 'Reference data resynced successfully');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Reference data resync failed: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncFailedOperations() async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      isSyncing.value = true;

      // Get all failed families and insurees
      final failedFamilies =
          pendingFamilies.where((f) => f.syncStatus == 2).toList();
      final failedInsurees =
          pendingInsurees.where((i) => i.syncStatus == 2).toList();

      if (failedFamilies.isEmpty && failedInsurees.isEmpty) {
        SnackBars.info('Info', 'No failed operations to retry');
        return;
      }

      // Reset sync status to pending for all failed items
      for (final family in failedFamilies) {
        if (family.localId != null) {
          await _dbHelper.updateFamilySyncStatus(family.localId!, 0);
        }
      }

      for (final insuree in failedInsurees) {
        if (insuree.localId != null) {
          await _dbHelper.updateInsureeSyncStatus(insuree.localId!, 0);
        }
      }

      // Attempt sync for all items
      final result = await _insureeService.syncAllPending();

      final totalRetried = failedFamilies.length + failedInsurees.length;

      if (result.error) {
        SnackBars.failure('Retry Failed',
            'Failed to retry $totalRetried operations: ${result.message}');
      } else {
        SnackBars.success(
            'Success', 'Successfully retried $totalRetried failed operations');
      }

      // Refresh data to show updated status
      await refreshData();
    } catch (e) {
      SnackBars.failure('Error', 'Failed to retry operations: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> retrySyncFamily(int localId) async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      // Attempt direct resync of this family
      final result = await _insureeService.resyncFamily(localId);

      if (result.error) {
        SnackBars.failure('Retry Failed', result.message);
      } else {
        SnackBars.success('Success', result.message);
      }

      await refreshData();
    } catch (e) {
      SnackBars.failure('Error', 'Retry failed: $e');
    }
  }

  Future<void> retrySyncInsuree(int localId) async {
    if (!isOnline.value) {
      SnackBars.warning('Offline', 'Please check your internet connection');
      return;
    }

    try {
      // Attempt direct resync of this insuree
      final result = await _insureeService.resyncInsuree(localId);

      if (result.error) {
        SnackBars.failure('Retry Failed', result.message);
      } else {
        SnackBars.success('Success', result.message);
      }

      await refreshData();
    } catch (e) {
      SnackBars.failure('Error', 'Retry failed: $e');
    }
  }

  Future<void> deleteFamily(int localId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Family'),
          content: Text(
            'Are you sure you want to delete this family and all its members? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final result = await _insureeService.deleteFamily(localId);

        if (result.error) {
          SnackBars.failure('Delete Failed', result.message);
        } else {
          SnackBars.success('Success', 'Family deleted successfully');
          await refreshData();
        }
      }
    } catch (e) {
      SnackBars.failure('Error', 'Delete failed: $e');
    }
  }

  Future<void> deleteInsuree(int localId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Member'),
          content: Text(
            'Are you sure you want to delete this family member? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final result = await _insureeService.deleteInsuree(localId);

        if (result.error) {
          SnackBars.failure('Delete Failed', result.message);
        } else {
          SnackBars.success('Success', 'Member deleted successfully');
          await refreshData();
        }
      }
    } catch (e) {
      SnackBars.failure('Error', 'Delete failed: $e');
    }
  }

  // Helper methods for UI
  int get totalPendingItems {
    return (stats['families_pending'] ?? 0) + (stats['insurees_pending'] ?? 0);
  }

  int get totalSyncedItems {
    return (stats['families_synced'] ?? 0) + (stats['insurees_synced'] ?? 0);
  }

  int get totalFailedItems {
    return (stats['families_failed'] ?? 0) + (stats['insurees_failed'] ?? 0);
  }

  double get syncProgress {
    final total =
        (stats['families_total'] ?? 0) + (stats['insurees_total'] ?? 0);
    if (total == 0) return 1.0;
    return totalSyncedItems / total;
  }

  String get syncStatusText {
    if (!isOnline.value) {
      return 'Offline - Will sync when online';
    }
    if (isSyncing.value) {
      return 'Syncing...';
    }
    if (totalPendingItems == 0) {
      return 'All items synced';
    }
    return '$totalPendingItems items pending sync';
  }

  Color get syncStatusColor {
    if (!isOnline.value) {
      return Colors.orange;
    }
    if (totalFailedItems > 0) {
      return Colors.red;
    }
    if (totalPendingItems == 0) {
      return Colors.green;
    }
    return Colors.blue;
  }
}
