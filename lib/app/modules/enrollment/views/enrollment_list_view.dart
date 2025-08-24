import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/enrollment_controller.dart';

class EnrollmentListView extends GetView<EnrollmentController> {
  final String? actionMode;

  const EnrollmentListView({Key? key, this.actionMode}) : super(key: key);

  String _getTitle() {
    switch (actionMode) {
      case 'enroll':
        return 'Family Enrollment';
      case 'amend':
        return 'Amend Family';
      case 'renew':
        return 'Renew Family';
      default:
        return 'Family Records';
    }
  }

  void _handleCardTap(Map<String, dynamic> family) {
    if (actionMode != null) {
      // If we're in a specific action mode, perform that action directly
      switch (actionMode) {
        case 'enroll':
          Get.toNamed('/enhanced-enrollment');
          break;
        case 'amend':
          _amendFamilyDetails(family);
          break;
        case 'renew':
          _renewFamilyDetails(family);
          break;
        default:
          _showFamilyOptions(family);
      }
    } else {
      // Default behavior - show options
      _showFamilyOptions(family);
    }
  }

  void _handleFloatingActionButton() {
    if (actionMode != null) {
      // If we're in a specific action mode, perform that action
      switch (actionMode) {
        case 'enroll':
          Get.toNamed('/enhanced-enrollment');
          break;
        case 'amend':
        case 'renew':
          // For amend/renew, we need to select a family first
          Get.snackbar('Info', 'Please select a family to ${actionMode}');
          break;
        default:
          Get.toNamed('/enhanced-enrollment');
      }
    } else {
      // Default behavior - go to enrollment
      Get.toNamed('/enhanced-enrollment');
    }
  }

  String _getEmptyStateTitle() {
    switch (actionMode) {
      case 'enroll':
        return 'No Families Found';
      case 'amend':
        return 'No Families to Amend';
      case 'renew':
        return 'No Families to Renew';
      default:
        return 'No Family Records';
    }
  }

  String _getEmptyStateMessage() {
    switch (actionMode) {
      case 'enroll':
        return 'No existing families found. Start by registering a new family.';
      case 'amend':
        return 'No families found that can be amended.';
      case 'renew':
        return 'No families found that need renewal.';
      default:
        return 'Start by registering a new family';
    }
  }

  String _getEmptyStateButtonText() {
    switch (actionMode) {
      case 'enroll':
        return 'Register New Family';
      case 'amend':
        return 'Search Families';
      case 'renew':
        return 'Search Families';
      default:
        return 'Register New Family';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          _getTitle(),
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
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => controller.applyFiltersManually(),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.white),
            onPressed: () => controller.resetAndReinitialize(),
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () => controller.syncPendingFamilies(),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _handleFloatingActionButton(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }

              if (controller.filteredEnrollments.isEmpty) {
                return _buildEmptyState();
              }

              return _buildFamilyList();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleFloatingActionButton(),
        backgroundColor: Color(0xFF036273),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: TextField(
        onChanged: (value) => controller.searchFamilies(value),
        decoration: InputDecoration(
          hintText: 'Search by CBHI ID, Name, or Phone',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.qr_code_scanner),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Color(0xFF036273), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', controller.selectedFilter.value == 'All'),
              SizedBox(width: 8.w),
              _buildFilterChip(
                  'Active', controller.selectedFilter.value == 'Active'),
              SizedBox(width: 8.w),
              _buildFilterChip('Pending Payment',
                  controller.selectedFilter.value == 'Pending Payment'),
              SizedBox(width: 8.w),
              _buildFilterChip(
                  'Expired', controller.selectedFilter.value == 'Expired'),
              SizedBox(width: 8.w),
              _buildFilterChip('Renewal Due',
                  controller.selectedFilter.value == 'Renewal Due'),
            ],
          )),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(0xFF036273),
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => controller.setFilter(label),
      selectedColor: Color(0xFF036273),
      backgroundColor: Colors.white,
      side: BorderSide(color: Color(0xFF036273)),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF036273)),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading families...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: controller.filteredEnrollments.length,
      itemBuilder: (context, index) {
        final family = controller.filteredEnrollments[index];
        return _buildFamilyCard(family);
      },
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> family) {
    final familyData = family['family'] as Map<String, dynamic>;
    final members = family['members'] as List<dynamic>;
    final headMember = members.isNotEmpty ? members.first : null;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _handleCardTap(family),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Color(0xFF036273),
                    child: headMember != null && headMember['name'] != null
                        ? Text(
                            headMember['name']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(Icons.person, color: Colors.white, size: 30.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headMember?['name'] ?? 'Unknown Family',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'CBHI ID: ${familyData['uuid'] ?? 'Not Available'}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${members.length} member(s)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(familyData),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _buildInfoChip(Icons.payment,
                      '${familyData['calculated_contribution'] ?? 0} ETB'),
                  SizedBox(width: 8.w),
                  _buildInfoChip(
                      Icons.calendar_today, _getExpiryStatus(familyData)),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> familyData) {
    String status = _getFamilyStatus(familyData);
    Color color = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.grey[600]),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getFamilyStatus(Map<String, dynamic> familyData) {
    final syncStatus = familyData['sync'] ?? 0;
    final paymentStatus = familyData['payment_status'] ?? 'PENDING';

    if (paymentStatus == 'PAID' && syncStatus == 1) {
      return 'Active';
    } else if (paymentStatus == 'PENDING') {
      return 'Pending Payment';
    } else if (syncStatus == 0) {
      return 'Pending Sync';
    } else {
      return 'Inactive';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending Payment':
        return Colors.orange;
      case 'Pending Sync':
        return Colors.blue;
      case 'Expired':
        return Colors.red;
      case 'Renewal Due':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getExpiryStatus(Map<String, dynamic> familyData) {
    // Mock expiry logic - in real app, calculate from enrollment date
    return 'Expires 2024-12-31';
  }

  void _showFamilyOptions(Map<String, dynamic> family) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Family Actions',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            _buildOptionTile(Icons.visibility, 'View Details',
                () => _viewFamilyDetails(family)),
            _buildOptionTile(
                Icons.edit, 'Edit Family', () => _editFamilyDetails(family)),
            _buildOptionTile(Icons.refresh, 'Renew Membership',
                () => _renewFamilyDetails(family)),
            _buildOptionTile(Icons.edit_note, 'Amend Family',
                () => _amendFamilyDetails(family)),
            _buildOptionTile(Icons.payment, 'Process Payment',
                () => _processPaymentDetails(family)),
            _buildOptionTile(
                Icons.print, 'Print Card', () => _printCardDetails(family)),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Color(0xFF036273).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: Color(0xFF036273)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  // Action methods for bottom sheet
  void _viewFamilyDetails(Map<String, dynamic> family) {
    Get.toNamed('/family-detail',
        arguments: {'family': family, 'mode': 'view'});
  }

  void _editFamilyDetails(Map<String, dynamic> family) {
    _amendFamilyDetails(family);
  }

  void _renewFamilyDetails(Map<String, dynamic> family) {
    Get.toNamed('/family-detail',
        arguments: {'family': family, 'mode': 'renew'});
  }

  void _amendFamilyDetails(Map<String, dynamic> family) {
    Get.toNamed('/family-detail',
        arguments: {'family': family, 'mode': 'amend'});
  }

  void _processPaymentDetails(Map<String, dynamic> family) {
    // TODO: Implement payment processing
    Get.snackbar('Info', 'Payment processing not yet implemented');
  }

  void _printCardDetails(Map<String, dynamic> family) {
    // TODO: Implement card printing
    Get.snackbar('Info', 'Card printing not yet implemented');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24.h),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () => _handleFloatingActionButton(),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              _getEmptyStateButtonText(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF036273),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
