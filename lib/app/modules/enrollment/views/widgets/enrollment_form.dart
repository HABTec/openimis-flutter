import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';
import 'package:openimis_app/app/modules/enrollment/controller/LocationDto.dart';
import '../../controller/enrollment_controller.dart';
import 'offline_payment_view.dart';

class EnrollmentForm extends StatelessWidget {
  final int? enrollmentId;
  final String? chfid;
  final EnrollmentController controller = Get.put(EnrollmentController());

  EnrollmentForm({this.enrollmentId, this.chfid});

  @override
  Widget build(BuildContext context) {
    // Initialize test data when form loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeTestData();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(enrollmentId == null
            ? 'New Family Registration'
            : 'Add Family Member'),
        backgroundColor: Color(0xFF036273),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.syncConfiguration(),
                icon: controller.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sync Rates',
              )),
          SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // Progress Indicator
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF036273),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Step ${controller.currentStep.value} of 5',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.currentStep.value / 5,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFB7D3D7)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    controller.getStepTitle(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: controller.enrollmentFormKey,
                  child: _buildStepContent(context),
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _buildBottomButtons(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (controller.currentStep.value) {
      case 1:
        return _buildPersonalInfoStep(context);
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildFamilyStep();
      case 4:
        return _buildPaymentMethodStep();
      case 5:
        return _buildReviewStep();
      default:
        return _buildPersonalInfoStep(context);
    }
  }

  Widget _buildPersonalInfoStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF036273)),
        ),
        SizedBox(height: 20),

        // Photo Section
        Center(
          child: Column(
            children: [
              Obx(() {
                return GestureDetector(
                  onTap: controller.pickAndCropPhoto,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFB7D3D7).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Color(0xFF036273), width: 2),
                    ),
                    child: controller.photo.value == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  size: 40, color: Color(0xFF036273)),
                              Text('Add Photo',
                                  style: TextStyle(color: Color(0xFF036273))),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              File(controller.photo.value!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                );
              }),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: controller.pickAndCropPhoto,
                icon: Icon(Icons.edit, color: Color(0xFF036273)),
                label: Text('Change Photo',
                    style: TextStyle(color: Color(0xFF036273))),
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        // Form Fields
        Row(
          children: [
            Expanded(
              child: buildTextFormField(
                controller.chfidController,
                'CHFID *',
                TextInputType.number,
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'CHFID is required';
                  }
                  if (value.length != 10) {
                    return 'CHFID must be exactly 10 digits';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: buildTextFormField(
                controller.identificationNoController,
                'National ID',
                TextInputType.text,
                null,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildTextFormField(
                controller.lastNameController,
                'Last Name *',
                TextInputType.text,
                (value) => value == null || value.isEmpty
                    ? 'Last name is required'
                    : null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: buildTextFormField(
                controller.givenNameController,
                'Given Name *',
                TextInputType.text,
                (value) => value == null || value.isEmpty
                    ? 'Given name is required'
                    : null,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildDropdownFormField(
                controller.gender,
                'Gender *',
                ['Male', 'Female', 'Other'],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: buildTextFormField(
                controller.phoneController,
                'Phone Number',
                TextInputType.phone,
                null,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildTextFormField(
                controller.emailController,
                'Email',
                TextInputType.emailAddress,
                null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: buildDateFormField(
                context,
                controller.birthdateController,
                'Birth Date *',
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildDropdownFormField(
                controller.maritalStatus,
                'Marital Status',
                ['Single', 'Married', 'Divorced', 'Widowed'],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: buildDropdownFormField(
                controller.relationShip,
                'Relation to Head',
                [
                  'Head',
                  'Spouse',
                  'Son/Daughter',
                  'Father/Mother',
                  'Brother/Sister',
                  'Uncle/Aunt',
                  'Grandparent',
                  'Employee',
                  'Other'
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        buildDropdownFormField(
          controller.disabilityStatus,
          'Disability Status *',
          ['None', 'Physical', 'Visual', 'Hearing', 'Mental', 'Other'],
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Information',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF036273)),
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                buildLocationDropdown('Region', controller.selectedRegion,
                    controller.stepRegions),
                SizedBox(height: 16),
                buildLocationDropdown('District', controller.selectedDistrict,
                    controller.stepDistricts),
                SizedBox(height: 16),
                buildLocationDropdown(
                    'Municipality',
                    controller.selectedMunicipality,
                    controller.stepMunicipalities),
                SizedBox(height: 16),
                buildLocationDropdown('Village', controller.selectedVillage,
                    controller.stepVillages),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Type & Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF036273),
                  ),
                ),
                SizedBox(height: 16),
                buildDropdownFormField(
                  controller.membershipType,
                  'Membership Type *',
                  ['Paying', 'Indigent'],
                ),
                SizedBox(height: 16),
                buildDropdownFormField(
                  controller.membershipLevel,
                  'Membership Level *',
                  ['Level 1', 'Level 2', 'Level 3'],
                ),
                SizedBox(height: 16),
                buildDropdownFormField(
                  controller.areaType,
                  'Area Type *',
                  ['Rural', 'City'],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF036273).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Color(0xFF036273).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF036273), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contribution will be calculated based on membership type, level, area, and number of members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF036273),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Information',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF036273)),
        ),
        SizedBox(height: 20),

        if (enrollmentId == null) ...[
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Setup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('New Family Registration'),
                      Switch(
                        value: controller.newEnrollment.value,
                        onChanged: (value) {
                          controller.newEnrollment.value = value;
                          if (value) {
                            controller.isHead.value = true;
                            controller.relationShip.value = 'Head';
                          }
                        },
                        activeColor: Color(0xFF036273),
                      ),
                    ],
                  ),
                  if (controller.newEnrollment.value) ...[
                    Row(
                      children: [
                        Text('Family Head'),
                        Switch(
                          value: controller.isHead.value,
                          onChanged: (value) {
                            controller.isHead.value = value;
                            controller.relationShip.value = value ? 'Head' : '';
                          },
                          activeColor: Color(0xFF036273),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        SizedBox(height: 20),

        // Family Members List
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Family Members',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => controller.addFamilyMember(),
                      icon: Icon(Icons.add),
                      label: Text('Add Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF036273),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Current member being added preview
                if (controller.givenNameController.text.isNotEmpty ||
                    controller.lastNameController.text.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFB7D3D7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF036273)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFF036273),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.givenNameController.text} ${controller.lastNameController.text}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('CHFID: ${controller.chfidController.text}'),
                              Text(
                                  'Relation: ${controller.relationShip.value}'),
                              Text(
                                  'Disability: ${controller.disabilityStatus.value}'),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text('Ready to Add',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Color(0xFF036273),
                        ),
                      ],
                    ),
                  ),

                // Added family members
                Obx(() => Column(
                      children:
                          controller.familyMembers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: member.isHead
                                ? Color(0xFF036273).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: member.isHead
                                    ? Color(0xFF036273)
                                    : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: member.isHead
                                    ? Color(0xFF036273)
                                    : Colors.grey.shade400,
                                child: Icon(
                                    member.isHead ? Icons.star : Icons.person,
                                    color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          member.fullName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (member.isHead) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF036273),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'HEAD',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('CHFID: ${member.chfid}'),
                                    Text(
                                        '${member.gender} • ${member.relationship}'),
                                    if (member.disabilityStatus != 'None')
                                      Text(
                                          'Disability: ${member.disabilityStatus}'),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      controller.editFamilyMember(index);
                                      break;
                                    case 'set_head':
                                      controller.setFamilyHead(index);
                                      break;
                                    case 'delete':
                                      controller.deleteFamilyMember(index);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit,
                                            color: Color(0xFF036273)),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  if (!member.isHead)
                                    PopupMenuItem(
                                      value: 'set_head',
                                      child: Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Set as Head'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: Icon(Icons.more_vert,
                                    color: Color(0xFF036273)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )),

                // Summary
                Obx(() => controller.familyMembers.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF036273).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Members: ${controller.familyMembers.length}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Head: ${controller.familyHead?.fullName ?? "Not Set"}',
                              style: TextStyle(
                                color: Color(0xFF036273),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF036273)),
        ),
        SizedBox(height: 20),

        Text(
          'Choose how you would like to pay for your membership:',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 24),

        // Payment method selection cards
        Obx(() => Column(
              children: [
                // Online Payment Card
                GestureDetector(
                  onTap: () {
                    controller.isOfflinePayment.value = false;
                    controller.paymentMethod.value = 'online';
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: !controller.isOfflinePayment.value
                          ? Color(0xFF036273).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !controller.isOfflinePayment.value
                            ? Color(0xFF036273)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: !controller.isOfflinePayment.value
                              ? Color(0xFF036273)
                              : Colors.grey[600],
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Online Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: !controller.isOfflinePayment.value
                                      ? Color(0xFF036273)
                                      : Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay instantly using ArifPay gateway',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!controller.isOfflinePayment.value)
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF036273),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Offline Payment Card
                GestureDetector(
                  onTap: () {
                    controller.isOfflinePayment.value = true;
                    controller.paymentMethod.value = 'offline_manual';
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: controller.isOfflinePayment.value
                          ? Color(0xFF036273).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.isOfflinePayment.value
                            ? Color(0xFF036273)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: controller.isOfflinePayment.value
                              ? Color(0xFF036273)
                              : Colors.grey[600],
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: controller.isOfflinePayment.value
                                      ? Color(0xFF036273)
                                      : Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay using PoS machine and enter transaction ID',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.isOfflinePayment.value)
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF036273),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),

                // Show offline payment details if selected
                if (controller.isOfflinePayment.value) ...[
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Payment Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Complete payment using your PoS machine\n'
                          '2. Get the transaction receipt\n'
                          '3. Enter transaction ID manually or scan receipt\n'
                          '4. Your payment will be verified later',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )),

        SizedBox(height: 24),

        // Payment amount display
        FutureBuilder<double>(
          future: controller.calculateTotalContribution(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final contribution = snapshot.data ?? 0.0;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF036273).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF036273),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Amount to Pay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF036273),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${contribution.toStringAsFixed(2)} ETB',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF036273),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF036273)),
        ),
        SizedBox(height: 20),

        // Summary Cards
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(),
                _buildReviewRow('Name',
                    '${controller.givenNameController.text} ${controller.lastNameController.text}'),
                _buildReviewRow('CHFID', controller.chfidController.text),
                _buildReviewRow('Gender', controller.gender.value),
                _buildReviewRow('Phone', controller.phoneController.text),
                _buildReviewRow(
                    'Disability Status', controller.disabilityStatus.value),
              ],
            ),
          ),
        ),

        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(),
                _buildReviewRow('Region',
                    controller.selectedRegion.value?.name ?? 'Not selected'),
                _buildReviewRow('District',
                    controller.selectedDistrict.value?.name ?? 'Not selected'),
                _buildReviewRow(
                    'Membership Type', controller.membershipType.value),
                _buildReviewRow(
                    'Membership Level', controller.membershipLevel.value),
                _buildReviewRow('Area Type', controller.areaType.value),
              ],
            ),
          ),
        ),

        // Family Members Summary
        Obx(() => controller.familyMembers.isNotEmpty
            ? Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Members',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      ...controller.familyMembers
                          .map((member) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      member.isHead ? Icons.star : Icons.person,
                                      size: 16,
                                      color: member.isHead
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${member.fullName} (${member.relationship})',
                                        style: TextStyle(
                                          fontWeight: member.isHead
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      if (controller.familyMembers.isEmpty)
                        Text(
                          'No family members added yet',
                          style: TextStyle(
                              color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink()),

        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contribution Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(),
                _buildReviewRow(
                    'Membership Type', controller.membershipType.value),
                _buildReviewRow(
                    'Membership Level', controller.membershipLevel.value),
                _buildReviewRow('Area Type', controller.areaType.value),
                Obx(() => _buildReviewRow(
                    'Total Members', '${controller.familyMembers.length}')),

                // Payment Method Information
                Obx(() => _buildReviewRow(
                    'Payment Method',
                    controller.isOfflinePayment.value
                        ? 'Offline Payment'
                        : 'Online Payment')),
                Obx(() => controller.isOfflinePayment.value &&
                        controller.transactionId.value.isNotEmpty
                    ? _buildReviewRow(
                        'Transaction ID', controller.transactionId.value)
                    : Container()),

                Divider(),
                Obx(() => controller.isCalculatingContribution.value
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Calculating contribution...'),
                          ],
                        ),
                      )
                    : FutureBuilder<double>(
                        future: controller.calculateTotalContribution(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildReviewRow(
                                'Total Contribution', 'Calculating...',
                                isTotal: true);
                          }
                          final contribution = snapshot.data ?? 0.0;
                          return _buildReviewRow('Total Contribution',
                              '${contribution.toStringAsFixed(2)} ETB',
                              isTotal: true);
                        },
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Color(0xFF036273) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        if (controller.currentStep.value > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.previousStep,
              child: Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF036273),
                side: BorderSide(color: Color(0xFF036273)),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (controller.currentStep.value > 1) SizedBox(width: 16),
        Expanded(
          flex: controller.currentStep.value == 1 ? 1 : 2,
          child: controller.currentStep.value < 4
              ? ElevatedButton(
                  onPressed: controller.nextStep,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF036273),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              : controller.currentStep.value == 4
                  ? ElevatedButton(
                      onPressed: controller.nextStep,
                      child: Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF036273),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : Obx(() => controller.isOfflinePayment.value
                      ? Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Show offline payment dialog
                                Get.bottomSheet(
                                  Container(
                                    height: Get.height * 0.8,
                                    child: OfflinePaymentView(),
                                  ),
                                  isScrollControlled: true,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long),
                                  SizedBox(width: 8),
                                  Text('Enter Transaction ID'),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: controller.onEnrollmentSubmitOffline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text('Save for Later'),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: controller.onEnrollmentSubmitOnline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment),
                                  SizedBox(width: 8),
                                  Text('Proceed to Payment'),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF036273),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: controller.onEnrollmentSubmitOffline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text('Save for Later'),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        )),
        ),
      ],
    );
  }

  Widget buildLocationDropdown(String label, Rxn selectedValue, RxList items) {
    return Obx(() {
      return DropdownButtonFormField(
        value: selectedValue.value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF036273)),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF036273), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        style: TextStyle(color: Colors.black87),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF036273)),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item?.name ?? 'Unknown',
              style: TextStyle(color: Colors.black87),
            ),
          );
        }).toList(),
        onChanged: (value) {
          selectedValue.value = value;
          controller.onLocationChanged(label, value);
        },
      );
    });
  }

  Widget buildTextFormField(
    TextEditingController textController,
    String labelText,
    TextInputType keyboardType,
    String? Function(String?)? validator,
  ) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Color(0xFF036273)),
        border: OutlineInputBorder(),
        errorStyle: TextStyle(color: Colors.red),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF036273), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: keyboardType == TextInputType.multiline ? 3 : 1,
      style: TextStyle(color: Colors.black87),
    );
  }

  Widget buildDropdownFormField(
    RxString controllerValue,
    String labelText,
    List<String> items,
  ) {
    return Obx(() {
      return DropdownButtonFormField<String>(
        value: controllerValue.value.isEmpty ? null : controllerValue.value,
        onChanged: (newValue) {
          controllerValue.value = newValue ?? '';
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Color(0xFF036273)),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF036273), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        style: TextStyle(color: Colors.black87),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF036273)),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget buildDateFormField(
    BuildContext context,
    TextEditingController textController,
    String labelText,
  ) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Color(0xFF036273)),
        border: OutlineInputBorder(),
        errorStyle: TextStyle(color: Colors.red),
        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF036273)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF036273), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF036273),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          textController.text = "${pickedDate.toLocal()}".split(' ')[0];
        }
      },
    );
  }
}
