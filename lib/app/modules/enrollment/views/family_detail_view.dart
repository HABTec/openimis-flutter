import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/enrollment_controller.dart';

class FamilyDetailView extends StatefulWidget {
  const FamilyDetailView({Key? key}) : super(key: key);

  @override
  State<FamilyDetailView> createState() => _FamilyDetailViewState();
}

class _FamilyDetailViewState extends State<FamilyDetailView> {
  final EnrollmentController controller = Get.find<EnrollmentController>();
  bool showRenewalBanner = true;
  bool showEnrollmentPeriodBanner = true;

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;
    final family = arguments['family'] as Map<String, dynamic>;
    final mode =
        arguments['mode'] as String; // 'view', 'edit', 'renew', 'amend'

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          _getTitle(mode),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF036273),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (mode != 'view')
            IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: () => _saveChanges(family, mode),
            ),
        ],
      ),
      body: Column(
        children: [
          if (mode == 'renew' && showRenewalBanner)
            _dismissibleBanner(_buildRenewalBanner(), () {
              setState(() => showRenewalBanner = false);
            }),
          if (mode == 'amend') _buildAmendmentBanner(),
          if (showEnrollmentPeriodBanner)
            _dismissibleBanner(_buildEnrollmentPeriodCheck(mode), () {
              setState(() => showEnrollmentPeriodBanner = false);
            }),
          Expanded(
            child: DefaultTabController(
              length: mode == 'renew' ? 3 : 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Color(0xFF036273),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF036273),
                    tabs: [
                      Tab(text: 'Family Info'),
                      Tab(text: 'Members'),
                      if (mode == 'renew') Tab(text: 'Payment'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFamilyInfoTab(family, mode),
                        _buildMembersTab(family, mode),
                        if (mode == 'renew') _buildPaymentTab(family),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(family, mode),
    );
  }

  String _getTitle(String mode) {
    switch (mode) {
      case 'view':
        return 'Family Details';
      case 'edit':
        return 'Edit Family';
      case 'renew':
        return 'Renew Membership';
      case 'amend':
        return 'Amend Family';
      default:
        return 'Family Details';
    }
  }

  Widget _buildRenewalBanner() {
    return Container(
      color: Colors.green.shade50,
      padding: EdgeInsets.all(16.w),
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, color: Colors.green),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Renewal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'Update family information and process payment for renewal',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmendmentBanner() {
    return Container(
      color: Colors.orange.shade50,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: Colors.orange),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Amendment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Make changes to family structure and member details',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentPeriodCheck(String mode) {
    if (mode == 'view') return SizedBox.shrink();

    final isEnrollmentPeriod = _isEnrollmentPeriodActive();
    if (isEnrollmentPeriod) return SizedBox.shrink();

    return Container(
      color: Colors.red.shade50,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enrollment Period Closed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  'Changes can only be made during enrollment period (Jan 1 - Mar 31)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dismissibleBanner(Widget child, VoidCallback onClose) {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      child: Stack(
        children: [
          child,
          Positioned(
            right: 8.w,
            top: 8.h,
            child: InkWell(
              onTap: onClose,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4.w),
                child: Icon(Icons.close, size: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoTab(Map<String, dynamic> family, String mode) {
    final familyData = family['family'] as Map<String, dynamic>;
    final members = family['members'] as List<dynamic>;
    final headMember = members.firstWhere((m) => m['is_head'] == true);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Basic Information',
            [
              _buildInfoRow('CBHI ID', familyData['uuid'], editable: false),
              _buildInfoRow('Family Type', familyData['family_type'],
                  editable: mode != 'view'),
              _buildInfoRow('Address', familyData['address_detail'],
                  editable: mode != 'view'),
              _buildInfoRow(
                  'Confirmation Type', familyData['confirmation_type'],
                  editable: mode != 'view'),
              _buildInfoRow(
                  'Confirmation Number', familyData['confirmation_number'],
                  editable: mode != 'view'),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSectionCard(
            'Location Information',
            [
              _buildInfoRow('Region', familyData['region_name'],
                  editable: mode != 'view'),
              _buildInfoRow('District', familyData['district_name'],
                  editable: mode != 'view'),
              _buildInfoRow('Municipality', familyData['municipality_name'],
                  editable: mode != 'view'),
              _buildInfoRow('Village', familyData['village_name'],
                  editable: mode != 'view'),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSectionCard(
            'Membership Details',
            [
              _buildInfoRow('Membership Type', familyData['membership_type'],
                  editable: mode == 'renew'),
              _buildInfoRow('Membership Level', familyData['membership_level'],
                  editable: mode == 'renew'),
              _buildInfoRow('Area Type', familyData['area_type'],
                  editable: mode == 'renew'),
              _buildInfoRow(
                  'Poverty Status', familyData['poverty_status'] ? 'Yes' : 'No',
                  editable: mode == 'renew'),
              _buildInfoRow('Calculated Contribution',
                  '${familyData['calculated_contribution']} ETB',
                  editable: false),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSectionCard(
            'Head of Family',
            [
              _buildInfoRow('Name', headMember['name'],
                  editable: mode != 'view'),
              _buildInfoRow('Gender', headMember['gender'],
                  editable: mode != 'view'),
              _buildInfoRow('Birth Date', headMember['birthdate'],
                  editable: mode != 'view'),
              _buildInfoRow('Phone', headMember['phone'],
                  editable: mode != 'view'),
              _buildInfoRow('Email', headMember['email'],
                  editable: mode != 'view'),
              _buildInfoRow('Marital Status', headMember['marital_status'],
                  editable: mode != 'view'),
              _buildInfoRow(
                  'Disability Status', headMember['disability_status'],
                  editable: mode != 'view'),
              _buildInfoRow('ID Number', headMember['identification_no'],
                  editable: mode != 'view'),
            ],
          ),
          if (mode != 'view')
            SizedBox(height: 100.h), // Space for bottom actions
        ],
      ),
    );
  }

  Widget _buildMembersTab(Map<String, dynamic> family, String mode) {
    final members = family['members'] as List<dynamic>;

    return Column(
      children: [
        if (mode != 'view')
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addNewMember(family),
                    icon: Icon(Icons.person_add),
                    label: Text('Add New Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF036273),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberCard(member, mode, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab(Map<String, dynamic> family) {
    final familyData = family['family'] as Map<String, dynamic>;
    final members = family['members'] as List<dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Recalculated contribution with breakdown (reusing display)
          _buildSectionCard(
            'Renewal Contribution Calculation',
            [
              _buildInfoRow('Number of Members', '${members.length}',
                  editable: false),
              _buildInfoRow('Membership Level', familyData['membership_level'],
                  editable: false),
              _buildInfoRow('Area Type', familyData['area_type'],
                  editable: false),
              _buildInfoRow('Base Rate per Member', '150 ETB', editable: false),
              Divider(),
              _buildInfoRow('Total Contribution',
                  '${familyData['calculated_contribution']} ETB',
                  editable: false, isTotal: true),
            ],
          ),
          SizedBox(height: 16.h),
          // 1. Online and Offline payment choices
          _buildSectionCard('Payment Options', [
            _buildPaymentOption(
                'Online Payment (ArifPay)', Icons.payment, true),
            _buildPaymentOption('Offline Payment', Icons.receipt_long, false),
          ]),
          SizedBox(height: 20.h),
          // 2. Manual transaction ID entry
          _buildSectionCard('Manual Transaction Entry', [
            _buildInfoRow('Transaction ID', '', editable: true),
          ]),
          SizedBox(height: 16.h),
          // 3. OCR ability placeholder
          _buildSectionCard('OCR Transaction Capture', [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFF036273)),
              title: Text('Capture receipt and extract txn id'),
              trailing: ElevatedButton(
                onPressed: () => controller.pickReceiptPhoto(),
                child: Text('Scan'),
              ),
            ),
          ]),
          SizedBox(height: 16.h),
          // 4. Show invoice and 5. Download membership card triggers
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.saveOfflinePaymentData(),
                  icon: Icon(Icons.receipt),
                  label: Text('Show Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.showMembershipCard(),
                  icon: Icon(Icons.card_membership),
                  label: Text('Download Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF036273),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // History tab removed per request

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF036273),
              ),
            ),
            SizedBox(height: 12.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool editable = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: editable
                ? TextFormField(
                    initialValue: value,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isTotal ? Color(0xFF036273) : Colors.black87,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, String mode, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25.r,
                  backgroundColor:
                      member['is_head'] ? Color(0xFF036273) : Colors.grey[300],
                  child: member['photo_path'] != null
                      ? ClipOval(
                          child: Image.asset(member['photo_path'],
                              fit: BoxFit.cover))
                      : Text(
                          member['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member['name'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (member['is_head'])
                            Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Color(0xFF036273),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'HEAD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'CBHI ID: ${member['chfid']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${member['gender']} • ${member['relationship']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (mode != 'view')
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMemberAction(value, member, index),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (mode == 'amend' || mode == 'renew')
                        PopupMenuItem(
                            value: 'photo', child: Text('Update Photo')),
                      if (mode == 'amend' && !member['is_head'])
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _buildMemberInfo(Icons.cake, member['birthdate']),
                SizedBox(width: 16.w),
                _buildMemberInfo(Icons.phone,
                    member['phone'].isNotEmpty ? member['phone'] : 'No phone'),
              ],
            ),
            if (member['disability_status'] != 'None')
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.accessibility,
                          size: 16.sp, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        'Disability: ${member['disability_status']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: Colors.grey[600]),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberActivationTile(Map<String, dynamic> member) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20.r,
        backgroundColor: Color(0xFF036273),
        child: Text(
          member['name'].toString().substring(0, 1).toUpperCase(),
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(member['name']),
      subtitle: Text('${member['relationship']} • ${member['gender']}'),
      trailing: Switch(
        value: true, // Default to active
        onChanged: (value) {
          // Handle activation/deactivation
          Get.snackbar(
            'Member ${value ? 'Activated' : 'Deactivated'}',
            '${member['name']} is now ${value ? 'active' : 'inactive'}',
          );
        },
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF036273).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? Color(0xFF036273) : Colors.grey[600],
        ),
      ),
      title: Text(title),
      trailing: Radio<bool>(
        value: isSelected,
        groupValue: true,
        onChanged: (value) {},
        activeColor: Color(0xFF036273),
      ),
    );
  }

  Widget _buildHistoryCard(String title, String description, String date,
      IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            SizedBox(height: 4.h),
            Text(
              date,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> family, String mode) {
    if (mode == 'view') return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isEnrollmentPeriodActive()
                  ? () => _saveChanges(family, mode)
                  : null,
              child: Text(_getSaveButtonText(mode)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF036273),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSaveButtonText(String mode) {
    switch (mode) {
      case 'edit':
        return 'Save Changes';
      case 'renew':
        return 'Process Renewal';
      case 'amend':
        return 'Save Amendment';
      default:
        return 'Save';
    }
  }

  bool _isEnrollmentPeriodActive() {
    final now = DateTime.now();
    // Enrollment period: January 1 - March 31
    return now.month >= 1 && now.month <= 3;
  }

  void _saveChanges(Map<String, dynamic> family, String mode) {
    if (!_isEnrollmentPeriodActive() && mode != 'view') {
      Get.snackbar(
        'Period Closed',
        'Changes can only be made during enrollment period',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    switch (mode) {
      case 'edit':
        _saveEdit(family);
        break;
      case 'renew':
        _processRenewal(family);
        break;
      case 'amend':
        _saveAmendment(family);
        break;
    }
  }

  void _saveEdit(Map<String, dynamic> family) {
    Get.dialog(
      AlertDialog(
        title: Text('Save Changes'),
        content:
            Text('Are you sure you want to save the changes to this family?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back();
              Get.snackbar(
                  'Success', 'Family information updated successfully');
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF036273)),
          ),
        ],
      ),
    );
  }

  void _processRenewal(Map<String, dynamic> family) {
    Get.dialog(
      AlertDialog(
        title: Text('Process Renewal'),
        content: Text(
            'This will renew the family membership and process payment. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back();
              Get.snackbar(
                  'Success', 'Membership renewal processed successfully');
            },
            child: Text('Renew'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _saveAmendment(Map<String, dynamic> family) {
    Get.dialog(
      AlertDialog(
        title: Text('Save Amendment'),
        content: Text(
            'Are you sure you want to save the amendments to this family?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back();
              Get.snackbar('Success', 'Family amendments saved successfully');
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _addNewMember(Map<String, dynamic> family) {
    Get.snackbar(
        'Info', 'Add new member functionality would be implemented here');
  }

  void _handleMemberAction(
      String action, Map<String, dynamic> member, int index) {
    switch (action) {
      case 'edit':
        Get.snackbar('Info', 'Edit member: ${member['name']}');
        break;
      case 'photo':
        Get.snackbar('Info', 'Update photo for: ${member['name']}');
        break;
      case 'remove':
        Get.dialog(
          AlertDialog(
            title: Text('Remove Member'),
            content: Text(
                'Are you sure you want to remove ${member['name']} from the family?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                      'Success', '${member['name']} removed from family');
                },
                child: Text('Remove'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _processRenewalPayment(Map<String, dynamic> family) {
    final familyData = family['family'] as Map<String, dynamic>;
    final amount = familyData['calculated_contribution'];

    Get.dialog(
      AlertDialog(
        title: Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Amount: $amount ETB'),
            SizedBox(height: 8.h),
            Text('Payment Method: Online (ArifPay)'),
            SizedBox(height: 8.h),
            Text('This will process the payment and activate the renewal.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Payment processed successfully');
            },
            child: Text('Pay $amount ETB'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}
