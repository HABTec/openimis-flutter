import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openimis_app/app/modules/enrollment/controller/enrollment_controller.dart';
import 'enrollment_form.dart';

class EnrollmentListPage extends StatelessWidget {
  final EnrollmentController controller = Get.put(EnrollmentController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Obx(() {
                return Checkbox(
                  value: controller.isAllSelected.value,
                  onChanged: (value) {
                    controller.toggleSelectAll(value!);
                  },
                );
              }),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by CHFID',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    controller.searchText.value = value;
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final enrollments = controller.filteredEnrollments;
            return enrollments.isEmpty
                ? Center(child: Text('No enrollments found'))
                : ListView.builder(
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      final enrollment = enrollments[index];
                      final photoBase64 = enrollment['photo'] as String?;
                      final imageProvider = (photoBase64 != null &&
                              photoBase64.isNotEmpty)
                          ? Image.memory(base64Decode(photoBase64)).image
                          : AssetImage(
                              'assets/openimis-logo.png'); // Replace with actual avatar path or URL

                      return Dismissible(
                        key: Key(enrollment['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text(
                                    'Do you want to delete this enrollment?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .pop(false), // User cancels
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .pop(true), // User confirms
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          final enrollmentId = enrollment['family']['id'];

                          // Call the delete method to handle backend removal or state change
                          controller.deleteEnrollment(enrollmentId);

                          // Update the local list to reflect the removal in the UI
                          controller.filteredEnrollments.removeAt(index);

                          // Optionally, show a Snackbar to confirm deletion
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Enrollment deleted')),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          margin: EdgeInsets.all(10.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: imageProvider,
                            ),
                            title: Text(
                                'chfid - ${enrollment['family']['chfid']} - Status: ${enrollment['family']['sync'] == 0 ? 'synced' : 'not synced'}'),
                            subtitle: Text(
                                'CHFID: ${enrollment['family']['chfid']}\nTotal Members: ${enrollment['members'].length ?? 0}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Obx(() {
                                //   return Checkbox(
                                //     value: controller.selectedEnrollments
                                //         .contains(enrollment['id']),
                                //     onChanged: (value) {
                                //       controller.toggleEnrollmentSelection(
                                //           enrollment['id'], value!);
                                //     },
                                //   );
                                // }),
                                // IconButton(
                                //   icon: Icon(Icons.edit),
                                //   onPressed: () {
                                //     controller.editEnrollment(enrollment);
                                //     showDialog(
                                //       context: context,
                                //       builder: (_) => EditEnrollmentDialog(
                                //           controller: controller,
                                //           enrollment: enrollment),
                                //     );
                                //   },
                                // ),
                                IconButton(
                                  icon: Icon(Icons.add_box_outlined),
                                  onPressed: () {
                                    var k = enrollment['family']['id'];
                                    controller.familyId.value =
                                        enrollment['family']['id'];
                                    // Navigate to enrollment form to add new member
                                    Get.to(() => EnrollmentForm(
                                          enrollmentId: enrollment['family']
                                              ['id'],
                                          chfid: enrollment['family']['chfid'],
                                        ));
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // Handle the tap event
                            },
                          ),
                        ),
                      );
                    },
                  );
          }),
        ),
      ],
    );
  }
}

class EditEnrollmentDialog extends StatelessWidget {
  final EnrollmentController controller;
  final enrollment;

  EditEnrollmentDialog({required this.controller, this.enrollment});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(2), // Rounded corners for the dialog
      ),
      content: Container(
        width: 700.w, // Set a fixed width for the dialog
        padding: EdgeInsets.all(2.w), // Add padding inside the dialog
        child: SingleChildScrollView(
          child: Form(
            key: controller.enrollmentFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Enrollment',
                  style: Theme.of(context).textTheme.headline6?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 20.h), // Gap between title and input fields

                _buildTextField(
                  controller: controller.givenNameController,
                  label: 'Given Name',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.lastNameController,
                  label: 'Last Name',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.chfidController,
                  label: 'CHFID',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.phoneController,
                  label: 'Phone',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.emailController,
                  label: 'Email',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.identificationNoController,
                  label: 'Identification No',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.birthdateController,
                  label: 'Birthdate',
                  keyboardType: TextInputType.datetime,
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildDropdownField(
                  value: controller.gender.value,
                  label: 'Gender',
                  items: ['Male', 'Female', 'Other'],
                  onChanged: (value) => controller.gender.value = value!,
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildDropdownField(
                  value: controller.maritalStatus.value,
                  label: 'Marital Status',
                  items: ['Single', 'Married', 'Divorced', 'Widowed'],
                  onChanged: (value) => controller.maritalStatus.value = value!,
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildTextField(
                  controller: controller.headChfidController,
                  label: 'Head CHFID',
                ),
                SizedBox(height: 16.h), // Gap between input fields

                _buildSwitchField(
                  value: controller.isHead.value,
                  label: 'Is Head',
                  onChanged: (value) => controller.isHead.value = value,
                ),
                SizedBox(height: 16.h), // Gap before action buttons

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 10.w), // Gap between buttons
                    TextButton(
                      onPressed: () async {
                        await controller.updateEnrollment(enrollment);
                        Get.back();
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value)
          ? value
          : null, // Ensure the value exists in items
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchField({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
