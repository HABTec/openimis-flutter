import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controller/enhanced_enrollment_controller.dart';

class EnhancedEnrollmentView extends StatelessWidget {
  const EnhancedEnrollmentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EnhancedEnrollmentController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Family Registration'),
        backgroundColor: Color(0xFF036273),
        foregroundColor: Colors.white,
        actions: [
          Obx(() => IconButton(
                onPressed: controller.isSyncing.value
                    ? null
                    : () async {
                        await controller.syncReferenceData();
                      },
                icon: controller.isSyncing.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync Reference Data',
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('Loading reference data...'),
              ],
            ),
          );
        }

        if (!controller.isReferenceDataReady.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 64.sp, color: Colors.orange),
                SizedBox(height: 16.h),
                Text(
                  'Reference data not available',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please sync reference data before creating families',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () async {
                    await controller.syncReferenceData();
                  },
                  child: Text('Sync Now'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(controller),

            // Form content
            Expanded(
              child: _buildStepContent(controller),
            ),

            // Navigation buttons
            _buildNavigationButtons(controller),
          ],
        );
      }),
    );
  }

  Widget _buildProgressIndicator(EnhancedEnrollmentController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color(0xFF036273),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Step ${controller.currentStep.value} of ${controller.totalSteps}',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: controller.currentStep.value / controller.totalSteps,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB7D3D7)),
          ),
          SizedBox(height: 8.h),
          Text(
            controller.getStepTitle(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(EnhancedEnrollmentController controller) {
    return Obx(() {
      switch (controller.currentStep.value) {
        case 1:
          return _buildFamilyHeadForm(controller);
        case 2:
          return _buildLocationAndFamilyForm(controller);
        case 3:
          return _buildMembersForm(controller);
        case 4:
          return _buildPaymentForm(controller);
        case 5:
          return _buildReviewForm(controller);
        default:
          return _buildFamilyHeadForm(controller);
      }
    });
  }

  Widget _buildFamilyHeadForm(EnhancedEnrollmentController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: controller.familyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Head Information',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),

            // CHF ID Format Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHF ID Format',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8.h),
                    Obx(() => Column(
                          children: controller.chfIdFormatOptions.map((option) {
                            return RadioListTile<int>(
                              title: Text(option['label']!),
                              value: int.parse(option['value']!),
                              groupValue: controller.chfIdFormat.value,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.chfIdFormat.value = value;
                                }
                              },
                            );
                          }).toList(),
                        )),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Personal Information
            TextFormField(
              controller: controller.headFirstNameController,
              decoration: InputDecoration(
                labelText: 'First Name (Other Names)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  controller.validateRequired(value, 'First Name'),
            ),

            SizedBox(height: 12.h),

            TextFormField(
              controller: controller.headLastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  controller.validateRequired(value, 'Last Name'),
            ),

            SizedBox(height: 12.h),

            // Gender Selection
            Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  value: controller.headGender.value.isEmpty
                      ? null
                      : controller.headGender.value,
                  items: controller.genderOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.headGender.value = value;
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select gender' : null,
                )),

            SizedBox(height: 12.h),

            // Date of Birth
            TextFormField(
              controller: controller.headDobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_month),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate:
                          DateTime.now().subtract(Duration(days: 365 * 25)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.headDobController.text =
                          date.toString().split(' ')[0];
                    }
                  },
                ),
              ),
              validator: controller.validateDate,
            ),

            SizedBox(height: 12.h),

            // Phone Number
            TextFormField(
              controller: controller.headPhoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: controller.validatePhone,
            ),

            SizedBox(height: 12.h),

            // Email (Optional)
            TextFormField(
              controller: controller.headEmailController,
              decoration: InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
            ),

            SizedBox(height: 12.h),

            // Marital Status
            Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Marital Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  value: controller.headMaritalStatus.value,
                  items: controller.maritalStatusOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.headMaritalStatus.value = value;
                    }
                  },
                )),

            SizedBox(height: 12.h),

            // ID Type
            Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'ID Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  value: controller.headIdType.value,
                  items: controller.idTypeOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.headIdType.value = value;
                    }
                  },
                )),

            SizedBox(height: 12.h),

            // Passport/ID Number
            TextFormField(
              controller: controller.headPassportController,
              decoration: InputDecoration(
                labelText: 'ID/Passport Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),

            SizedBox(height: 12.h),

            // Profession
            Obx(() => DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Profession',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  value: controller.headProfessionId.value == 0
                      ? null
                      : controller.headProfessionId.value,
                  items: controller.professions.map((profession) {
                    return DropdownMenuItem<int>(
                      value: profession.id,
                      child: Text(profession.profession ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.headProfessionId.value = value;
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select profession' : null,
                )),

            SizedBox(height: 12.h),

            // Education
            Obx(() => DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Education Level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  value: controller.headEducationId.value == 0
                      ? null
                      : controller.headEducationId.value,
                  items: controller.educations.map((education) {
                    return DropdownMenuItem<int>(
                      value: education.id,
                      child: Text(education.education ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.headEducationId.value = value;
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select education level' : null,
                )),

            SizedBox(height: 16.h),

            // Photo Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8.h),
                    Obx(() {
                      if (controller.headPhoto.value != null) {
                        return Column(
                          children: [
                            Container(
                              width: 150.w,
                              height: 150.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(
                                  File(controller.headPhoto.value!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextButton(
                              onPressed: controller.pickHeadPhoto,
                              child: Text('Retake Photo'),
                            ),
                          ],
                        );
                      } else {
                        return ElevatedButton.icon(
                          onPressed: controller.pickHeadPhoto,
                          icon: Icon(Icons.camera_alt),
                          label: Text('Take Photo'),
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndFamilyForm(EnhancedEnrollmentController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location & Family Details',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Location Selection
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),

                  // Temporary debug button

                  SizedBox(height: 12.h),

                  // Region dropdown
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Region',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        value: controller.selectedRegionId.value.isEmpty
                            ? null
                            : controller.selectedRegionId.value,
                        items: controller.regions
                            .where((location) =>
                                location.id != null && location.id!.isNotEmpty)
                            .map((location) {
                          return DropdownMenuItem<String>(
                            value: location.id!,
                            child: Text(location.name ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedRegionId.value = value;
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select region' : null,
                      )),

                  SizedBox(height: 12.h),
                  // District dropdown
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select District',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        value: controller.selectedDistrictId.value.isEmpty
                            ? null
                            : controller.selectedDistrictId.value,
                        items: controller.filteredDistricts
                            .where((location) =>
                                location.id != null && location.id!.isNotEmpty)
                            .map((location) {
                          return DropdownMenuItem<String>(
                            value: location.id!,
                            child: Text(location.name ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedDistrictId.value = value;
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select district' : null,
                      )),
                  SizedBox(height: 12.h),

                  // Municipality dropdown
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Municipality',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        value: controller.selectedMunicipalityId.value.isEmpty
                            ? null
                            : controller.selectedMunicipalityId.value,
                        items: controller.filteredMunicipalities
                            .where((location) =>
                                location.id != null && location.id!.isNotEmpty)
                            .map((location) {
                          return DropdownMenuItem<String>(
                            value: location.id!,
                            child: Text(location.name ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedMunicipalityId.value = value;
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select municipality' : null,
                      )),
                  SizedBox(height: 12.h),

                  // Village dropdown
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Village',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        value: controller.selectedVillageId.value.isEmpty
                            ? null
                            : controller.selectedVillageId.value,
                        items: controller.filteredVillages
                            .where((location) =>
                                location.id != null && location.id!.isNotEmpty)
                            .map((location) {
                          return DropdownMenuItem<String>(
                            value: location.id!,
                            child: Text(location.name ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedVillageId.value = value;
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select village' : null,
                      )),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Family Details
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Details',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12.h),

                  // Address
                  TextFormField(
                    controller: controller.addressController,
                    decoration: InputDecoration(
                      labelText: 'Address Details',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                  ),

                  SizedBox(height: 12.h),

                  // Family Type
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Family Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        value: controller.familyTypeId.value,
                        items: controller.familyTypes.map((familyType) {
                          return DropdownMenuItem<String>(
                            value: familyType.code,
                            child: Text(familyType.type ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.familyTypeId.value = value;
                          }
                        },
                      )),

                  SizedBox(height: 12.h),

                  // Confirmation Type
                  Obx(() => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Confirmation Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.verified),
                        ),
                        value: controller.confirmationTypeId.value,
                        items: controller.confirmationTypes
                            .map((confirmationType) {
                          return DropdownMenuItem<String>(
                            value: confirmationType.code,
                            child: Text(confirmationType.confirmationtype ??
                                confirmationType.code ??
                                ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.confirmationTypeId.value = value;
                          }
                        },
                      )),

                  SizedBox(height: 12.h),

                  // Confirmation Number (if required)
                  Obx(() {
                    final selectedConfirmationType =
                        controller.confirmationTypes.firstWhereOrNull((ct) =>
                            ct.code == controller.confirmationTypeId.value);

                    if (selectedConfirmationType
                            ?.isConfirmationNumberRequired ==
                        true) {
                      return TextFormField(
                        controller: controller.confirmationNumberController,
                        decoration: InputDecoration(
                          labelText: 'Confirmation Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (value) => controller.validateRequired(
                            value, 'Confirmation Number'),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Membership Configuration
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Configuration',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12.h),

                  // Area Type (Level Type)
                  Obx(() {
                    final levelTypes = controller.availableMembershipTypes
                        .map((mt) => mt.levelType)
                        .where((lt) => lt != null)
                        .toSet()
                        .toList();

                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Area Type',
                        border: OutlineInputBorder(),
                      ),
                      value: controller.selectedAreaType.value.isEmpty
                          ? null
                          : controller.selectedAreaType.value,
                      items: levelTypes.map((levelType) {
                        return DropdownMenuItem(
                          value: levelType,
                          child: Text(levelType!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedAreaType.value = value;
                        }
                      },
                    );
                  }),

                  SizedBox(height: 12.h),

                  // Membership Level (Level Index)
                  Obx(() {
                    final filteredTypes = controller.availableMembershipTypes
                        .where((mt) =>
                            mt.levelType == controller.selectedAreaType.value)
                        .toList();

                    if (filteredTypes.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Please select an area type first',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Membership Level',
                        border: OutlineInputBorder(),
                      ),
                      value: controller.selectedMembershipTypeId.value.isEmpty
                          ? null
                          : controller.selectedMembershipTypeId.value,
                      items: filteredTypes.map((membershipType) {
                        final displayName =
                            'Level ${membershipType.levelIndex} - ${membershipType.price} ETB';
                        return DropdownMenuItem(
                          value: membershipType.id,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedMembershipType.value = controller
                              .availableMembershipTypes
                              .firstWhere((mt) => mt.id == value);
                        }
                      },
                    );
                  }),

                  SizedBox(height: 12.h),

                  // Enhanced Contribution Display
                  Obx(() {
                    if (controller.currentContributionBreakdown.value != null) {
                      final breakdown =
                          controller.currentContributionBreakdown.value!;
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contribution Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                                'Members: ${breakdown.memberContributions.toStringAsFixed(2)} ETB'),
                            Text(
                                'Registration: ${breakdown.registrationFee.toStringAsFixed(2)} ETB'),
                            Text(
                                'Lump Sum: ${breakdown.lumpSum.toStringAsFixed(2)} ETB'),
                            Divider(),
                            Text(
                              'Total: ${breakdown.totalAmount.toStringAsFixed(2)} ETB',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersForm(EnhancedEnrollmentController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Members',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add additional family members (optional)',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 16.h),

          // Existing Members List
          Obx(() {
            if (controller.familyMembers.isEmpty) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: Text(
                      'No family members added yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'Added Members (${controller.familyMembers.length})',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                  ...controller.familyMembers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text('${member.otherNames} ${member.lastName}'),
                      subtitle:
                          Text('${member.genderId} | CHF ID: ${member.chfId}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.removeFamilyMember(index),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }),

          SizedBox(height: 16.h),

          // Add Member Form
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: controller.memberFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Member',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12.h),

                    // Member Name Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.memberFirstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => controller.validateRequired(
                                value, 'First Name'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextFormField(
                            controller: controller.memberLastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                controller.validateRequired(value, 'Last Name'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Gender and Date of Birth
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(),
                                ),
                                value: controller.memberGender.value.isEmpty
                                    ? null
                                    : controller.memberGender.value,
                                items: controller.genderOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option['value'],
                                    child: Text(option['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.memberGender.value = value;
                                  }
                                },
                                validator: (value) => value == null
                                    ? 'Please select gender'
                                    : null,
                              )),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextFormField(
                            controller: controller.memberDobController,
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_month),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: Get.context!,
                                    initialDate: DateTime.now()
                                        .subtract(Duration(days: 365 * 25)),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    controller.memberDobController.text =
                                        date.toString().split(' ')[0];
                                  }
                                },
                              ),
                            ),
                            validator: controller.validateDate,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Relationship
                    Obx(() => DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Relationship to Head',
                            border: OutlineInputBorder(),
                          ),
                          value: controller.memberRelationshipId.value == 0
                              ? null
                              : controller.memberRelationshipId.value,
                          items: controller.relations.map((relation) {
                            return DropdownMenuItem<int>(
                              value: relation.id,
                              child: Text(relation.relation ?? ''),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.memberRelationshipId.value = value;
                            }
                          },
                          validator: (value) => value == null
                              ? 'Please select relationship'
                              : null,
                        )),

                    SizedBox(height: 12.h),

                    // Phone and Email
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.memberPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextFormField(
                            controller: controller.memberEmailController,
                            decoration: InputDecoration(
                              labelText: 'Email (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: controller.validateEmail,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Profession and Education
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Profession',
                                  border: OutlineInputBorder(),
                                ),
                                value: controller.memberProfessionId.value == 0
                                    ? null
                                    : controller.memberProfessionId.value,
                                items: controller.professions.map((profession) {
                                  return DropdownMenuItem<int>(
                                    value: profession.id,
                                    child: Text(profession.profession ?? ''),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.memberProfessionId.value = value;
                                  }
                                },
                                validator: (value) => value == null
                                    ? 'Please select profession'
                                    : null,
                              )),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Obx(() => DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Education',
                                  border: OutlineInputBorder(),
                                ),
                                value: controller.memberEducationId.value == 0
                                    ? null
                                    : controller.memberEducationId.value,
                                items: controller.educations.map((education) {
                                  return DropdownMenuItem<int>(
                                    value: education.id,
                                    child: Text(education.education ?? ''),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.memberEducationId.value = value;
                                  }
                                },
                                validator: (value) => value == null
                                    ? 'Please select education'
                                    : null,
                              )),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Member Photo
                    Obx(() {
                      if (controller.memberPhoto.value != null) {
                        return Column(
                          children: [
                            Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(
                                  File(controller.memberPhoto.value!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextButton(
                              onPressed: controller.pickMemberPhoto,
                              child: Text('Retake Photo'),
                            ),
                          ],
                        );
                      } else {
                        return ElevatedButton.icon(
                          onPressed: controller.pickMemberPhoto,
                          icon: Icon(Icons.camera_alt),
                          label: Text('Take Photo'),
                        );
                      }
                    }),

                    SizedBox(height: 16.h),

                    // Add Member Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.addFamilyMember,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Add Member'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(EnhancedEnrollmentController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment & Contribution',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Contribution Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribution Summary',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Family Head:'),
                      Text('1 member'),
                    ],
                  ),
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Additional Members:'),
                          Text('${controller.familyMembers.length} members'),
                        ],
                      )),
                  Divider(),
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Members:'),
                          Text(
                              '${controller.familyMembers.length + 1} members'),
                        ],
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Membership Type:'),
                      Obx(() => Text(controller.membershipType.value)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Membership Level:'),
                      Obx(() => Text(controller.membershipLevel.value)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Area Type:'),
                      Obx(() => Text(controller.areaType.value)),
                    ],
                  ),
                  Obx(() {
                    if (controller.povertyStatus.value) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Poverty Discount:'),
                          Text('50% Applied',
                              style: TextStyle(color: Colors.green)),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  }),
                  Divider(),
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Contribution:',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ETB ${controller.calculatedContribution.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Payment Method Selection
          Obx(() {
            if (controller.calculatedContribution.value > 0) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 12.h),
                      RadioListTile<String>(
                        title: Text('Online Payment'),
                        subtitle:
                            Text('Pay using mobile money or bank transfer'),
                        value: 'online',
                        groupValue: controller.paymentMethod.value,
                        onChanged: (value) {
                          if (value != null) {
                            controller.paymentMethod.value = value;
                            controller.isOfflinePayment.value = false;
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text('Offline Payment'),
                        subtitle: Text(
                            'Pay later at office or record manual payment'),
                        value: 'offline',
                        groupValue: controller.paymentMethod.value,
                        onChanged: (value) {
                          if (value != null) {
                            controller.paymentMethod.value = value;
                            controller.isOfflinePayment.value = true;
                          }
                        },
                      ),

                      // Show transaction ID section for offline payment
                      Obx(() {
                        if (controller.isOfflinePayment.value) {
                          return Column(
                            children: [
                              SizedBox(height: 16.h),

                              // Transaction ID entry button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    controller.showTransactionIdDialog();
                                  },
                                  icon: Icon(Icons.receipt_long, size: 20.w),
                                  label: Text(
                                    controller.transactionId.value.isEmpty
                                        ? 'Enter Transaction ID'
                                        : 'Update Transaction ID',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: BorderSide(color: Colors.orange),
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                              ),

                              // Show transaction ID when entered
                              if (controller
                                  .transactionId.value.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 16.w),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Transaction ID',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        controller.transactionId.value,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 12.h),

                                // Mark as Paid button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      controller.processOfflinePayment();
                                    },
                                    icon: Icon(Icons.payment, size: 20.w),
                                    label: Text(
                                      'Mark as Paid',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              );
            } else {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Icon(Icons.free_breakfast,
                          size: 48.sp, color: Colors.green),
                      SizedBox(height: 8.h),
                      Text(
                        'No Payment Required',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        'This family qualifies for free registration',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildReviewForm(EnhancedEnrollmentController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Family Head Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Head',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                      'Name: ${controller.headFirstNameController.text} ${controller.headLastNameController.text}'),
                  Obx(() => Text('Gender: ${controller.headGender.value}')),
                  Text('DOB: ${controller.headDobController.text}'),
                  Text('Phone: ${controller.headPhoneController.text}'),
                  if (controller.headEmailController.text.isNotEmpty)
                    Text('Email: ${controller.headEmailController.text}'),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Family Members Summary
          Obx(() {
            if (controller.familyMembers.isNotEmpty) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Members (${controller.familyMembers.length})',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8.h),
                      ...controller.familyMembers.map((member) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                              '• ${member.otherNames} ${member.lastName} (${member.genderId})'),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),

          SizedBox(height: 12.h),

          // Location Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location & Details',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() {
                    String locationText = 'Location: ';
                    if (controller.selectedRegionId.value.isNotEmpty) {
                      final region = controller.regions.firstWhereOrNull(
                          (loc) => loc.id == controller.selectedRegionId.value);
                      locationText += region?.name ?? '';
                    }
                    if (controller.selectedDistrictId.value.isNotEmpty) {
                      final district = controller.filteredDistricts
                          .firstWhereOrNull((loc) =>
                              loc.id == controller.selectedDistrictId.value);
                      locationText += ' > ${district?.name ?? ''}';
                    }
                    if (controller.selectedMunicipalityId.value.isNotEmpty) {
                      final municipality = controller.filteredMunicipalities
                          .firstWhereOrNull((loc) =>
                              loc.id ==
                              controller.selectedMunicipalityId.value);
                      locationText += ' > ${municipality?.name ?? ''}';
                    }
                    if (controller.selectedVillageId.value.isNotEmpty) {
                      final village = controller.filteredVillages
                          .firstWhereOrNull((loc) =>
                              loc.id == controller.selectedVillageId.value);
                      locationText += ' > ${village?.name ?? ''}';
                    }
                    if (locationText == 'Location: ') {
                      locationText = 'Location: Not selected';
                    }
                    return Text(locationText);
                  }),
                  Text('Address: ${controller.addressController.text}'),
                  Obx(() =>
                      Text('Family Type: ${controller.familyTypeId.value}')),
                  Obx(() => Text(
                      'Poverty Status: ${controller.povertyStatus.value ? 'Below poverty line' : 'Above poverty line'}')),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Payment Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() => Text(
                      'Total Contribution: ETB ${controller.calculatedContribution.value.toStringAsFixed(2)}')),
                  Obx(() {
                    if (controller.calculatedContribution.value > 0) {
                      return Text(
                          'Payment Method: ${controller.paymentMethod.value}');
                    } else {
                      return Text('Payment: Not required');
                    }
                  }),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitFamilyRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF036273),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text('Registering...'),
                          ],
                        )
                      : Text(
                          'Submit Registration',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(EnhancedEnrollmentController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              if (controller.currentStep.value > 1)
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Previous'),
                  ),
                ),
              if (controller.currentStep.value > 1) SizedBox(width: 12.w),
              if (controller.currentStep.value < controller.totalSteps)
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF036273),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Next'),
                  ),
                ),
            ],
          )),
    );
  }
}
