import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/sync_status_controller.dart';

class SyncStatusView extends StatelessWidget {
  const SyncStatusView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SyncStatusController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Sync Status'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sync Statistics Card
                _buildStatsCard(controller),

                SizedBox(height: 20.h),

                // Sync All Button
                _buildSyncAllButton(controller),

                SizedBox(height: 20.h),

                // Reference Data Resync Button
                _buildReferenceDataResyncButton(controller),

                SizedBox(height: 20.h),

                // Sync Failed Operations Button
                _buildSyncFailedOperationsButton(controller),

                SizedBox(height: 20.h),

                // Pending Families Section
                _buildPendingFamiliesSection(controller),

                SizedBox(height: 20.h),

                // Pending Insurees Section
                _buildPendingInsureesSection(controller),

                SizedBox(height: 20.h),

                // Failed Operations Section
                _buildFailedOperationsSection(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard(SyncStatusController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Statistics',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Families',
                    controller.stats['families_pending']?.toString() ?? '0',
                    controller.stats['families_total']?.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Members',
                    controller.stats['insurees_pending']?.toString() ?? '0',
                    controller.stats['insurees_total']?.toString() ?? '0',
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Synced',
                    '${(controller.stats['families_synced'] ?? 0) + (controller.stats['insurees_synced'] ?? 0)}',
                    '${(controller.stats['families_total'] ?? 0) + (controller.stats['insurees_total'] ?? 0)}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Failed',
                    '${(controller.stats['families_failed'] ?? 0) + (controller.stats['insurees_failed'] ?? 0)}',
                    '${(controller.stats['families_total'] ?? 0) + (controller.stats['insurees_total'] ?? 0)}',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String total, Color color) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30.w),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'of $total',
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncAllButton(SyncStatusController controller) {
    final pendingCount = (controller.stats['families_pending'] ?? 0) +
        (controller.stats['insurees_pending'] ?? 0);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: pendingCount > 0 &&
                controller.isOnline.value &&
                !controller.isSyncing.value
            ? () => controller.syncAll()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: controller.isSyncing.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Syncing...'),
                ],
              )
            : Text(
                pendingCount > 0
                    ? 'Sync All ($pendingCount items)'
                    : controller.isOnline.value
                        ? 'All Synced'
                        : 'Offline - Will sync when online',
                style: TextStyle(fontSize: 16.sp),
              ),
      ),
    );
  }

  Widget _buildReferenceDataResyncButton(SyncStatusController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isOnline.value && !controller.isSyncing.value
            ? () => controller.resyncReferenceData()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: controller.isSyncing.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Resyncing...'),
                ],
              )
            : Text(
                'Resync Reference Data',
                style: TextStyle(fontSize: 16.sp),
              ),
      ),
    );
  }

  Widget _buildSyncFailedOperationsButton(SyncStatusController controller) {
    final failedFamilies =
        controller.pendingFamilies.where((f) => f.syncStatus == 2).length;
    final failedInsurees =
        controller.pendingInsurees.where((i) => i.syncStatus == 2).length;
    final totalFailed = failedFamilies + failedInsurees;

    if (totalFailed == 0) {
      return SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isOnline.value && !controller.isSyncing.value
            ? () => controller.syncFailedOperations()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: controller.isSyncing.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Retrying...'),
                ],
              )
            : Text(
                'Sync Failed Operations ($totalFailed)',
                style: TextStyle(fontSize: 16.sp),
              ),
      ),
    );
  }

  Widget _buildPendingFamiliesSection(SyncStatusController controller) {
    if (controller.pendingFamilies.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Families (${controller.pendingFamilies.length})',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ...controller.pendingFamilies
            .map((family) => _buildFamilyCard(family, controller)),
      ],
    );
  }

  Widget _buildPendingInsureesSection(SyncStatusController controller) {
    if (controller.pendingInsurees.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Members (${controller.pendingInsurees.length})',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ...controller.pendingInsurees
            .map((insuree) => _buildInsureeCard(insuree, controller)),
      ],
    );
  }

  Widget _buildFailedOperationsSection(SyncStatusController controller) {
    final failedFamilies =
        controller.pendingFamilies.where((f) => f.syncStatus == 2).toList();
    final failedInsurees =
        controller.pendingInsurees.where((i) => i.syncStatus == 2).toList();

    if (failedFamilies.isEmpty && failedInsurees.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Failed Operations (${failedFamilies.length + failedInsurees.length})',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 12.h),
        ...failedFamilies.map(
            (family) => _buildFamilyCard(family, controller, isError: true)),
        ...failedInsurees.map(
            (insuree) => _buildInsureeCard(insuree, controller, isError: true)),
      ],
    );
  }

  Widget _buildFamilyCard(dynamic family, SyncStatusController controller,
      {bool isError = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: isError ? Colors.red.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isError ? Colors.red : Colors.blue,
          child: Icon(
            Icons.family_restroom,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        title: Text(
          family.headInsuree?.otherNames != null &&
                  family.headInsuree?.lastName != null
              ? '${family.headInsuree!.otherNames} ${family.headInsuree!.lastName}'
              : 'Family ${family.localId}',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHF ID: ${family.headInsuree?.chfId ?? 'N/A'}'),
            Text('Location: ${family.locationId ?? 'N/A'}'),
            if (isError && family.syncError != null)
              Text(
                'Error: ${family.syncError}',
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError)
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                onPressed: () => controller.retrySyncFamily(family.localId!),
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => controller.deleteFamily(family.localId!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsureeCard(dynamic insuree, SyncStatusController controller,
      {bool isError = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: isError ? Colors.red.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isError ? Colors.red : Colors.green,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        title: Text(
          insuree.otherNames != null && insuree.lastName != null
              ? '${insuree.otherNames} ${insuree.lastName}'
              : 'Member ${insuree.localId}',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHF ID: ${insuree.chfId ?? 'N/A'}'),
            Text('Family: ${insuree.localFamilyId ?? 'N/A'}'),
            if (isError && insuree.syncError != null)
              Text(
                'Error: ${insuree.syncError}',
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError)
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                onPressed: () => controller.retrySyncInsuree(insuree.localId!),
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => controller.deleteInsuree(insuree.localId!),
            ),
          ],
        ),
      ),
    );
  }
}
