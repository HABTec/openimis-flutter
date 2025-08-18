import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/enhanced_database_helper.dart';

class SyncDetailView extends StatefulWidget {
  const SyncDetailView({Key? key}) : super(key: key);

  @override
  State<SyncDetailView> createState() => _SyncDetailViewState();
}

class _SyncDetailViewState extends State<SyncDetailView> {
  final _db = EnhancedDatabaseHelper();
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOps();
  }

  Future<void> _loadOps() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final entityType = args?['entityType'] as String?; // 'FAMILY' | 'INSUREE'
    final entity = args?['entity'];
    if (entityType == null || entity == null) {
      setState(() => _isLoading = false);
      return;
    }
    final localId = entity.localId as int?;
    if (localId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final ops = await _db.getSyncOperationsForEntity(entityType, localId);
    setState(() {
      _operations = ops;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final entityType = args?['entityType'] as String?;
    final entity = args?['entity'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Sync Detail'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(entityType, entity),
                  SizedBox(height: 16.h),
                  if ((entity?.syncStatus as int? ?? 0) == 2)
                    _buildResyncButton(entityType, entity),
                  if ((entity?.syncStatus as int? ?? 0) == 2)
                    SizedBox(height: 16.h),
                  _buildOperations(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String? entityType, dynamic entity) {
    final isFamily = entityType == 'FAMILY';
    final title = isFamily
        ? (entity.headInsuree?.otherNames != null &&
                entity.headInsuree?.lastName != null
            ? '${entity.headInsuree!.otherNames} ${entity.headInsuree!.lastName}'
            : 'Family ${entity.localId}')
        : (entity.otherNames != null && entity.lastName != null
            ? '${entity.otherNames} ${entity.lastName}'
            : 'Member ${entity.localId}');

    final subtitle = isFamily
        ? 'CHF ID: ${entity.headInsuree?.chfId ?? 'N/A'}'
        : 'CHF ID: ${entity.chfId ?? 'N/A'}';

    final status = entity.syncStatus == 1
        ? 'Synced'
        : entity.syncStatus == 2
            ? 'Failed'
            : 'Pending';

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entity.syncStatus == 1
              ? Colors.green
              : entity.syncStatus == 2
                  ? Colors.red
                  : Colors.orange,
          child: Icon(
            isFamily ? Icons.family_restroom : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (entity.syncError != null &&
                entity.syncError.toString().isNotEmpty)
              Text('Error: ${entity.syncError}',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(status,
              style: TextStyle(
                  color: entity.syncStatus == 1
                      ? Colors.green
                      : entity.syncStatus == 2
                          ? Colors.red
                          : Colors.orange)),
        ),
      ),
    );
  }

  Widget _buildOperations() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync Operations',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            if (_operations.isEmpty)
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text('No operations recorded.'),
              )
            else
              ..._operations.map((op) => _buildOperationTile(op)),
          ],
        ),
      ),
    );
  }

  Widget _buildResyncButton(String? entityType, dynamic entity) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Visualize the request by showing a dialog with the outgoing payload
          await Get.dialog(AlertDialog(
            title: Text('Attempting Resync'),
            content: Text(
                'This will try to resync ${entityType == 'FAMILY' ? 'family' : 'member'} #${entity.localId} to the backend.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('Close')),
            ],
          ));

          // Navigate back to status view which will handle resync via controller icon actions,
          // or call controller methods directly if desired.
          // Here we just direct user to use the retry buttons on the list/status pages
        },
        icon: Icon(Icons.refresh),
        label: Text('Resync Now'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      ),
    );
  }

  Widget _buildOperationTile(Map<String, dynamic> op) {
    final status = (op['status'] as String?) ?? 'PENDING';
    final color = status == 'SUCCESS'
        ? Colors.green
        : status == 'FAILED'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${op['operation_type']} ${op['entity_type']} (#${op['id']})',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(status,
                    style: TextStyle(color: color, fontSize: 12.sp)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text('Attempts: ${op['attempts']}/${op['max_attempts']}'),
          if ((op['error_message'] as String?) != null &&
              (op['error_message'] as String).isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text('Error: ${op['error_message']}',
                style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ],
          SizedBox(height: 6.h),
          Text('Created: ${op['created_at']}'),
          Text('Updated: ${op['updated_at']}'),
          SizedBox(height: 6.h),
          ExpansionTile(
            title: Text('Payload'),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text((op['data'] as String?) ?? '{}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12.sp)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
