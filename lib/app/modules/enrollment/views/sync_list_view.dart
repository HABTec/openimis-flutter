import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/sync_status_controller.dart';

class SyncListView extends StatelessWidget {
  const SyncListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final entity = (args?['entity'] as String?) ?? 'FAMILY'; // FAMILY | INSUREE
    final status =
        (args?['status'] as int?) ?? 0; // 0 pending, 1 synced, 2 failed
    final controller = Get.put(SyncStatusController());

    final title = '${entity == 'FAMILY' ? 'Families' : 'Members'} '
        '${status == 0 ? 'Pending' : status == 1 ? 'Synced' : 'Failed'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final items = _getItems(controller, entity, status);
        if (items.isEmpty) {
          return Center(child: Text('No items'));
        }
        return ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return _buildTile(entity, item, controller);
          },
        );
      }),
    );
  }

  List<dynamic> _getItems(SyncStatusController c, String entity, int status) {
    if (entity == 'FAMILY') {
      if (status == 0) return c.pendingFamilies;
      if (status == 1) return c.syncedFamilies;
      return c.failedFamilies;
    } else {
      if (status == 0) return c.pendingInsurees;
      if (status == 1) return c.syncedInsurees;
      return c.failedInsurees;
    }
  }

  Widget _buildTile(
      String entity, dynamic item, SyncStatusController controller) {
    final isFamily = entity == 'FAMILY';
    final title = isFamily
        ? (item.headInsuree?.otherNames != null &&
                item.headInsuree?.lastName != null
            ? '${item.headInsuree!.otherNames} ${item.headInsuree!.lastName}'
            : 'Family ${item.localId}')
        : (item.otherNames != null && item.lastName != null
            ? '${item.otherNames} ${item.lastName}'
            : 'Member ${item.localId}');

    final subtitle = isFamily
        ? 'CHF ID: ${item.headInsuree?.chfId ?? 'N/A'}'
        : 'CHF ID: ${item.chfId ?? 'N/A'}';

    final color = item.syncStatus == 1
        ? Colors.green
        : item.syncStatus == 2
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(isFamily ? Icons.family_restroom : Icons.person,
              color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if ((item.syncError as String?) != null &&
                (item.syncError as String).isNotEmpty)
              Text('Error: ${item.syncError}',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((item.syncStatus as int? ?? 0) == 2)
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.orange),
                onPressed: () async {
                  if (entity == 'FAMILY') {
                    await controller.retrySyncFamily(item.localId);
                  } else {
                    await controller.retrySyncInsuree(item.localId);
                  }
                },
              ),
            IconButton(
              icon: Icon(Icons.info_outline, color: Colors.blueGrey),
              onPressed: () => Get.toNamed('/sync-detail', arguments: {
                'entityType': entity,
                'entity': item,
              }),
            ),
          ],
        ),
        onTap: () => Get.toNamed('/sync-detail',
            arguments: {'entityType': entity, 'entity': item}),
      ),
    );
  }
}
