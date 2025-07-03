import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:openimis_app/app/data/remote/repositories/enrollment/enrollment_repository.dart';
import 'package:openimis_app/app/modules/enrollment/controller/LocationDto.dart';
import 'package:openimis_app/app/modules/enrollment/controller/MembershipDto.dart';
import 'package:openimis_app/app/modules/policy/views/widgets/qr_view.dart';
import 'package:openimis_app/app/data/remote/services/payment/arifpay_service.dart';
import 'package:openimis_app/app/data/local/services/contribution_config_service.dart';
import 'package:uuid/uuid.dart';

import '../../../data/remote/base/status.dart';
import '../../../di/locator.dart';
import '../../../utils/database_helper.dart';
import '../../../utils/functions.dart';
import '../../../widgets/snackbars.dart';
import '../views/widgets/enrollment_form.dart';
import '../views/widgets/enrollment_members.dart';
import '../views/widgets/qr_view.dart';
import '../views/widgets/submit_botton_sheet.dart';
import '../views/widgets/payment_view.dart';
import '../views/widgets/receipt_view.dart';
import '../views/widgets/qr_card_view.dart';
import 'DropdownDto.dart';
import 'EnrollmentDto.dart';
import 'HospitalDto.dart';

// Family Member Model
class FamilyMember {
  String chfid;
  String firstName;
  String lastName;
  String gender;
  String birthdate;
  String phone;
  String email;
  String identificationNo;
  String maritalStatus;
  String relationship;
  String disabilityStatus;
  bool isHead;
  String? photoPath;

  FamilyMember({
    required this.chfid,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthdate,
    required this.phone,
    required this.email,
    required this.identificationNo,
    required this.maritalStatus,
    required this.relationship,
    required this.disabilityStatus,
    required this.isHead,
    this.photoPath,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'chfid': chfid,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthdate': birthdate,
      'phone': phone,
      'email': email,
      'identificationNo': identificationNo,
      'maritalStatus': maritalStatus,
      'relationship': relationship,
      'disabilityStatus': disabilityStatus,
      'isHead': isHead,
      'photoPath': photoPath,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      chfid: json['chfid'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      birthdate: json['birthdate'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      identificationNo: json['identificationNo'] ?? '',
      maritalStatus: json['maritalStatus'] ?? '',
      relationship: json['relationship'] ?? '',
      disabilityStatus: json['disabilityStatus'] ?? '',
      isHead: json['isHead'] ?? false,
      photoPath: json['photoPath'],
    );
  }
}

class EnrollmentController extends GetxController
    with SingleGetTickerProviderMixin {
  final GlobalKey<FormState> enrollmentFormKey = GlobalKey<FormState>();
  final GetStorage _storage = GetStorage();

  final _enrollmentRepository = getIt.get<EnrollmentRepository>();
  final _arifpayService = ArifPayService();
  final _contributionConfigService = ContributionConfigService();

  // Form controllers
  final chfidController = TextEditingController();
  final eaCodeController = TextEditingController();
  final lastNameController = TextEditingController();
  final givenNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final identificationNoController = TextEditingController();
  final birthdateController = TextEditingController();
  final headChfidController = TextEditingController();

  // Form observable variables
  var gender = ''.obs;
  var maritalStatus = ''.obs;
  var relationShip = ''.obs;
  var disabilityStatus = ''.obs; // New disability status field
  var isHead = false.obs;
  var povertyStatus = false.obs;
  var newEnrollment = true.obs;
  var photo = Rx<XFile?>(null);
  var selectedTabIndex = 0.obs;

  // Health facility fields - Kept for backward compatibility
  var selectedHealthFacilityLevel = ''.obs;
  var selectedHealthFacility = ''.obs;

  // Membership Type & Level fields - Story 3 requirement
  var membershipType = ''.obs; // 'Paying' or 'Indigent'
  var membershipLevel = ''.obs; // 'Level 1', 'Level 2', or 'Level 3'
  var areaType = ''.obs; // 'Rural' or 'City'

  var selectedFamilyType = ''.obs;
  var selectedConfirmationType = ''.obs;
  final confirmationNumber = TextEditingController();
  final addressDetail = TextEditingController();
  var familyId = 0.obs;

  // Member listing
  var family = {}.obs;
  var members = <Map<String, dynamic>>[].obs;
  var familyMembers = <FamilyMember>[].obs; // Enhanced family member list
  var voucherNumber = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Payment related
  var currentPaymentSession = Rxn<PaymentInitiationResponse>();
  var paymentStatus = ''.obs;
  var paymentAmount = 150.0.obs; // Mock contribution amount
  var receiptData = Rxn<PaymentVerificationResponse>();

  // Sync status
  var syncStatus = 0.obs; // 0 = not synced, 1 = synced

  // Disability options
  final List<String> disabilityOptions = [
    'None',
    'Physical',
    'Visual',
    'Hearing',
    'Mental',
    'Other'
  ];

  final _enrollmentScrollController = ScrollController();
  final Rx<Status<EnrollmentDto>> _rxEnrollmentState = Rx(const Status.idle());
  final Rx<Status<MemberShipCard>> _rxMemberShipCard = Rx(const Status.idle());

  Status<EnrollmentDto> get enrollmentState => _rxEnrollmentState.value;
  Status<MemberShipCard> get membershipState => _rxMemberShipCard.value;

  ScrollController get enrollmentScrollController =>
      _enrollmentScrollController;

  final ImagePicker _picker = ImagePicker();
  var shouldHide = false.obs;
  bool dev = true;

  var filteredEnrollments = <Map<String, dynamic>>[].obs;
  var searchText = ''.obs;
  var enrollments = <Map<String, dynamic>>[].obs;
  var selectedEnrollments = <int>[].obs;
  var isAllSelected = false.obs;

  void toggleSelectAll(bool selectAll) {
    isAllSelected.value = selectAll;
    selectedEnrollments.clear();
    if (selectAll) {
      selectedEnrollments.addAll(
        filteredEnrollments.map<int>((enrollment) => enrollment['id'] as int),
      );
    }
  }

  Future<void> fetchEnrollmentDetails(int enrollmentId) async {
    try {
      isLoading(true);
      var data = await DatabaseHelper().getFamilyAndMembers(enrollmentId);
      if (data != null) {
        family.value = data['family'];
        members.value = List<Map<String, dynamic>>.from(data['members']);
      } else {
        errorMessage.value = 'No data found';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  void toggleEnrollmentSelection(int id, bool isSelected) {
    if (isSelected) {
      selectedEnrollments.add(id);
    } else {
      selectedEnrollments.remove(id);
    }
    isAllSelected.value =
        selectedEnrollments.length == filteredEnrollments.length;
  }

  // Location dropdowns
  final Rx<Status<List<LocationDto>>> _rxLocationState =
      Rx(const Status.idle());
  final Rx<Status<List<HealthServiceProvider>>> _rxHospitalState =
      Rx(const Status.idle());

  Status<List<LocationDto>> get locationState => _rxLocationState.value;
  Status<List<HealthServiceProvider>> get hospitalState =>
      _rxHospitalState.value;

  var selectedRegion = Rxn<LocationDto>();
  var selectedDistrict = Rxn<District>();
  var selectedMunicipality = Rxn<Municipality>();
  var selectedVillage = Rxn<Village>();

  var districts = <District>[].obs;
  var municipalities = <Municipality>[].obs;
  var villages = <Village>[].obs;
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    fetchEnrollments();
    fetchLocations();
    fetchHospitals();
  }

  Future<void> fetchEnrollments() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getAllFamiliesWithMembers();
    enrollments.value = data;
    filteredEnrollments.value = data;
  }

  Future<void> fetchLocations() async {
    _rxLocationState.value = Status.loading();
    try {
      await Future.delayed(Duration(seconds: 1));
      // Mock location data - you can replace with actual API call
      final mockLocations = [
        LocationDto(
          id: 1,
          name: 'Addis Ababa',
          district: District(
            id: 1,
            name: 'Addis Ketema',
          ),
          municipality: Municipality(
            id: 1,
            name: 'Kebele 01',
          ),
          village: Village(
            id: 1,
            name: 'Village A',
          ),
        ),
        LocationDto(
          id: 2,
          name: 'Oromia',
          district: District(
            id: 2,
            name: 'Bole',
          ),
          municipality: Municipality(
            id: 2,
            name: 'Kebele 02',
          ),
          village: Village(
            id: 2,
            name: 'Village B',
          ),
        ),
      ];
      _rxLocationState.value = Status.success(data: mockLocations);
    } catch (e) {
      _rxLocationState.value = Status.failure(reason: e.toString());
    }
  }

  Future<void> fetchHospitals() async {
    _rxHospitalState.value = Status.loading();
    try {
      await Future.delayed(Duration(seconds: 1));
      // Mock hospital data
      final mockHospitals = [
        HealthServiceProvider(
            id: 1, name: 'General Hospital', level: 'Level 1'),
        HealthServiceProvider(
            id: 2, name: 'Specialized Hospital', level: 'Level 2'),
      ];
      _rxHospitalState.value = Status.success(data: mockHospitals);
    } catch (e) {
      _rxHospitalState.value = Status.failure(reason: e.toString());
    }
  }

  Future<void> updateEnrollment(enrollment) async {
    final dbHelper = DatabaseHelper();
    // Implementation for updating enrollment
    // TODO: Add update logic with disability status
  }

  // Offline save
  Future<void> onEnrollmentSubmitOffline() async {
    if (!_validateForm()) return;

    final db = await DatabaseHelper().database;
    String? photoBase64;
    if (photo.value != null) {
      photoBase64 = await _encodePhotoToBase64(photo.value!);
    }

    final enrollmentData = {
      'phone': phoneController.text,
      'birthdate': birthdateController.text,
      'chfid': chfidController.text,
      'eaCode': eaCodeController.text,
      'email': emailController.text,
      'gender': gender.value,
      'givenName': givenNameController.text,
      'identificationNo': identificationNoController.text,
      'isHead': isHead.value ? 1 : 0,
      'lastName': lastNameController.text,
      'maritalStatus': maritalStatus.value,
      'headChfid': headChfidController.text,
      'newEnrollment': newEnrollment.value ? 1 : 0,
      'photo': photoBase64 ?? "",
      'remarks': "",
      'membershipType': membershipType.value,
      'membershipLevel': membershipLevel.value,
      'familyType': selectedFamilyType.value,
      'confirmationType': selectedConfirmationType.value,
      'confirmationNumber': confirmationNumber.text,
      'addressDetail': addressDetail.text,
      'relationShip': relationShip.value,
      'disabilityStatus': disabilityStatus.value,
      'syncStatus': 0,
    };

    try {
      // Save to local database
      await _saveToLocalDatabase(enrollmentData);
      SnackBars.success("Success", "Member saved offline successfully!");
      resetForm();
      fetchEnrollments();
    } catch (e) {
      SnackBars.failure("Error", "Failed to save member: $e");
    }
  }

  // Online save with payment
  Future<void> onEnrollmentSubmitOnline() async {
    if (!_validateForm()) return;

    try {
      isLoading(true);

      // First save the enrollment data
      await onEnrollmentSubmitOffline();

      // Then proceed to payment
      await _initiatePayment();
    } catch (e) {
      SnackBars.failure("Error", "Failed to process enrollment: $e");
    } finally {
      isLoading(false);
    }
  }

  // Payment flow
  Future<void> _initiatePayment() async {
    try {
      // Show processing dialog
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF036273)),
              ),
              SizedBox(width: 16),
              Text('Processing Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${calculateTotalContribution()} ETB'),
              Text('Currency: ETB'),
              Text('Description: CBHI Membership Payment'),
              SizedBox(height: 16),
              Text('Initiating ArifPay payment gateway...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Simulate payment processing
      await Future.delayed(Duration(seconds: 2));

      final response = await _arifpayService.initiatePayment(
        amount: calculateTotalContribution(),
        currency: 'ETB',
        orderId: _generateOrderId(),
        description: 'CBHI Membership Payment',
        customerEmail: emailController.text.isEmpty
            ? 'member@cbhi.et'
            : emailController.text,
        customerPhone:
            phoneController.text.isEmpty ? '0911000000' : phoneController.text,
      );

      currentPaymentSession.value = response;

      // Close processing dialog
      Get.back();

      // Navigate to payment view
      Get.to(() => PaymentView(
            paymentUrl: response.checkoutUrl,
            onPaymentComplete: _handlePaymentComplete,
            onPaymentFailed: _handlePaymentFailed,
          ));
    } catch (e) {
      Get.back(); // Close any open dialogs
      SnackBars.failure("Payment Error", "Failed to initiate payment: $e");
    }
  }

  void _handlePaymentComplete(String transactionId) async {
    try {
      // Verify payment
      final verification = await _arifpayService.verifyPayment(transactionId);

      if (verification.verified) {
        receiptData.value = verification;

        // Update sync status
        syncStatus.value = 1;

        // Show receipt
        Get.to(() => ReceiptView(
              receiptData: verification,
              onDownloadQR: _showQRCard,
            ));

        SnackBars.success("Success", "Payment completed successfully!");
      } else {
        SnackBars.failure("Error", "Payment verification failed");
      }
    } catch (e) {
      SnackBars.failure("Error", "Payment verification error: $e");
    }
  }

  void _handlePaymentFailed(String error) {
    SnackBars.failure("Payment Failed", error);
  }

  void _showQRCard() {
    // Show loading dialog while generating QR card
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF036273)),
            ),
            SizedBox(width: 16),
            Text('Generating QR Card'),
          ],
        ),
        content: Text('Creating your CBHI membership card...'),
      ),
      barrierDismissible: false,
    );

    // Simulate QR generation delay
    Future.delayed(Duration(seconds: 2), () {
      Get.back(); // Close loading dialog

      // Navigate to QR card view
      Get.to(() => QRCardView(
            chfid: chfidController.text,
            memberName:
                '${givenNameController.text} ${lastNameController.text}',
            receiptData: receiptData.value,
          ));
    });
  }

  // Sync to backend
  Future<void> syncToBackend(List<int> enrollmentIds) async {
    try {
      isLoading(true);

      for (int id in enrollmentIds) {
        // Mock sync - simulate API call
        await Future.delayed(Duration(seconds: 1));

        // Update sync status in database
        // TODO: Implement actual sync logic
      }

      SnackBars.success("Success", "Records synced successfully!");
      fetchEnrollments();
    } catch (e) {
      SnackBars.failure("Sync Error", "Failed to sync records: $e");
    } finally {
      isLoading(false);
    }
  }

  bool _validateForm() {
    if (!enrollmentFormKey.currentState!.validate()) {
      return false;
    }

    if (disabilityStatus.value.isEmpty) {
      SnackBars.failure("Validation Error", "Please select disability status");
      return false;
    }

    return true;
  }

  Future<int?> _saveToLocalDatabase(Map<String, dynamic> enrollmentData) async {
    try {
      final dbHelper = DatabaseHelper();
      
      // Auto-generate CHFID if empty or not provided
      String chfid = chfidController.text.trim();
      if (chfid.isEmpty) {
        chfid = await dbHelper.generateUniqueChfid();
        chfidController.text = chfid; // Update the UI
        SnackBars.success("Auto-Generated", "CBHI ID generated: $chfid");
      }
      
      // Prepare family data with all form fields
      Map<String, dynamic> familyData = {
        'uuid': DatabaseHelper.generateMemberUUID(),
        'chfid': chfid,
        'familyType': selectedFamilyType.value,
        'confirmationType': selectedConfirmationType.value,
        'confirmationNumber': confirmationNumber.text,
        'addressDetail': addressDetail.text,
        'povertyStatus': povertyStatus.value,
        
        // Location data
        'regionId': selectedRegion.value?.id,
        'regionName': selectedRegion.value?.name ?? '',
        'districtId': selectedDistrict.value?.id,
        'districtName': selectedDistrict.value?.name ?? '',
        'municipalityId': selectedMunicipality.value?.id,
        'municipalityName': selectedMunicipality.value?.name ?? '',
        'villageId': selectedVillage.value?.id,
        'villageName': selectedVillage.value?.name ?? '',
      };

      // Prepare head member data
      Map<String, dynamic> headMemberData = {
        'firstName': givenNameController.text,
        'lastName': lastNameController.text,
        'gender': gender.value,
        'phone': phoneController.text,
        'email': emailController.text,
        'birthdate': birthdateController.text,
        'maritalStatus': maritalStatus.value,
        'disabilityStatus': disabilityStatus.value,
        'identificationNo': identificationNoController.text,
        'photo': photo.value != null ? await _encodePhotoToBase64(photo.value!) : '',
      };
      
      // Calculate contribution before saving
      final contribution = await calculateTotalContribution();

      if (newEnrollment.value && isHead.value) {
        // Insert new family with comprehensive data
        final familyId = await dbHelper.insertCompleteFamilyWithHead(
          familyData: familyData,
          headMemberData: headMemberData,
          membershipType: membershipType.value,
          membershipLevel: membershipLevel.value,
          areaType: areaType.value,
          calculatedContribution: contribution,
        );

        // Save all additional family members
        for (final member in familyMembers) {
          if (!member.isHead) {
            await dbHelper.insertFamilyMember(
              familyId: familyId,
              familyUuid: familyData['uuid'],
              memberData: {
                'chfid': member.chfid.isEmpty ? await dbHelper.generateUniqueChfid() : member.chfid,
                'firstName': member.firstName,
                'lastName': member.lastName,
                'gender': member.gender,
                'phone': member.phone,
                'email': member.email,
                'birthdate': member.birthdate,
                'maritalStatus': member.maritalStatus,
                'relationship': member.relationship,
                'disabilityStatus': member.disabilityStatus,
                'identificationNo': member.identificationNo,
                'photo': member.photoPath ?? '',
              },
            );
          }
        }

        return familyId;
      } else {
        // Insert as family member to existing family
        final existingFamilyId = this.familyId.value;
        
        // Get existing family UUID
        final familyData = await dbHelper.getFamilyById(existingFamilyId);
        final familyUuid = familyData?['uuid'] ?? DatabaseHelper.generateMemberUUID();
        
        await dbHelper.insertFamilyMember(
          familyId: existingFamilyId,
          familyUuid: familyUuid,
          memberData: {
            'chfid': chfid,
            'firstName': givenNameController.text,
            'lastName': lastNameController.text,
            'gender': gender.value,
            'phone': phoneController.text,
            'email': emailController.text,
            'birthdate': birthdateController.text,
            'maritalStatus': maritalStatus.value,
            'relationship': relationShip.value,
            'disabilityStatus': disabilityStatus.value,
            'identificationNo': identificationNoController.text,
            'photo': photo.value != null ? await _encodePhotoToBase64(photo.value!) : '',
          },
        );
        
        // Update family contribution after adding member
        await dbHelper.updateFamilyContribution(existingFamilyId, contribution);
        return existingFamilyId;
      }
    } catch (e) {
      print('Error saving to local database: $e');
      SnackBars.failure("Save Error", "Failed to save enrollment data: $e");
      rethrow;
    }
  }

  String _generateOrderId() {
    return 'ORD_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _encodePhotoToBase64(XFile photo) async {
    final bytes = await File(photo.path).readAsBytes();
    return base64Encode(bytes);
  }

  // Voucher image handling
  var voucherImage = Rxn<XFile>();

  // Premium and contribution data
  var premiumAmount = 500.0.obs; // Default premium amount
  var currency = 'ETB'.obs; // Default currency
  var perMember = 50.0.obs; // Per member cost
  var validity = '1 Year'.obs; // Default validity period

  // Missing methods for enrollment operations
  Future<void> deleteEnrollment(int enrollmentId) async {
    try {
      isLoading(true);

      // Remove from local database
      final db = await DatabaseHelper().database;
      await db.delete('families', where: 'id = ?', whereArgs: [enrollmentId]);
      await db
          .delete('members', where: 'family_id = ?', whereArgs: [enrollmentId]);

      // Refresh the enrollments list
      fetchEnrollments();

      SnackBars.success("Success", "Enrollment deleted successfully!");
    } catch (e) {
      SnackBars.failure("Error", "Failed to delete enrollment: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> pickVoucherImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        voucherImage.value = pickedFile;
        SnackBars.success("Success", "Voucher image selected!");
      }
    } catch (e) {
      SnackBars.failure("Error", "Failed to pick voucher image: $e");
    }
  }

  void clearVoucherImage() {
    voucherImage.value = null;
    SnackBars.success("Success", "Voucher image cleared!");
  }

  Future<void> onEnrollmentOnline(int familyId) async {
    try {
      isLoading(true);

      // Process online enrollment for the family
      await _processOnlineEnrollment(familyId);

      // Proceed to payment
      await _initiatePayment();

      SnackBars.success("Success", "Online enrollment initiated!");
    } catch (e) {
      SnackBars.failure("Error", "Failed to process online enrollment: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> _processOnlineEnrollment(int familyId) async {
    // Mock online enrollment processing
    await Future.delayed(Duration(seconds: 2));

    // Update sync status to indicate online processing
    final db = await DatabaseHelper().database;
    await db.update(
      'families',
      {'sync': 1},
      where: 'id = ?',
      whereArgs: [familyId],
    );
  }

  // Step navigation for new form
  var currentStep = 1.obs;
  var stepRegions = <LocationDto>[].obs;
  var stepDistricts = <District>[].obs;
  var stepMunicipalities = <Municipality>[].obs;
  var stepVillages = <Village>[].obs;

  String getStepTitle() {
    switch (currentStep.value) {
      case 1:
        return 'Personal Information';
      case 2:
        return 'Location & Services';
      case 3:
        return 'Family Details';
      case 4:
        return 'Review & Submit';
      default:
        return 'Personal Information';
    }
  }

  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  void initializeTestData() {
    // Don't populate CHFID - let it auto-generate
    // chfidController.text = ''; // Leave empty to trigger auto-generation
    identificationNoController.text = '123456';
    lastNameController.text = 'Doe';
    givenNameController.text = 'John';
    gender.value = 'Male';
    phoneController.text = '0961186323';
    emailController.text = 'john.doe@example.com';
    birthdateController.text = '1999-05-04';
    maritalStatus.value = 'Single';
    relationShip.value = 'Head';
    disabilityStatus.value = 'None';
    membershipType.value = 'Paying';
    membershipLevel.value = 'Level 1';
    areaType.value = 'Rural';
    
    // Initialize location data
    _initializeLocationData();
  }

  void _initializeLocationData() {
    // Mock location data
    stepRegions.value = [
      LocationDto(id: 1, name: 'Addis Ababa'),
      LocationDto(id: 2, name: 'Oromia'),
      LocationDto(id: 3, name: 'Amhara'),
    ];

    stepDistricts.value = [
      District(id: 1, name: 'Addis Ketema'),
      District(id: 2, name: 'Bole'),
      District(id: 3, name: 'Kirkos'),
    ];

    stepMunicipalities.value = [
      Municipality(id: 1, name: 'Kebele 01'),
      Municipality(id: 2, name: 'Kebele 02'),
      Municipality(id: 3, name: 'Kebele 03'),
    ];

    stepVillages.value = [
      Village(id: 1, name: 'Village A'),
      Village(id: 2, name: 'Village B'),
      Village(id: 3, name: 'Village C'),
    ];

    // Set default selections using existing variables
    selectedRegion.value = stepRegions.first;
    selectedDistrict.value = stepDistricts.first;
    selectedMunicipality.value = stepMunicipalities.first;
    selectedVillage.value = stepVillages.first;
  }

  void onLocationChanged(String locationType, dynamic selectedLocation) {
    // Handle location hierarchy changes
    switch (locationType) {
      case 'Region':
        selectedDistrict.value = null;
        selectedMunicipality.value = null;
        selectedVillage.value = null;
        // Load districts for selected region
        _loadDistrictsForRegion(selectedLocation?.id);
        break;
      case 'District':
        selectedMunicipality.value = null;
        selectedVillage.value = null;
        // Load municipalities for selected district
        _loadMunicipalitiesForDistrict(selectedLocation?.id);
        break;
      case 'Municipality':
        selectedVillage.value = null;
        // Load villages for selected municipality
        _loadVillagesForMunicipality(selectedLocation?.id);
        break;
    }
  }

  void _loadDistrictsForRegion(int? regionId) {
    // Mock data - replace with actual API call
    stepDistricts.value = [
      District(id: 1, name: 'District 1'),
      District(id: 2, name: 'District 2'),
    ];
  }

  void _loadMunicipalitiesForDistrict(int? districtId) {
    // Mock data - replace with actual API call
    stepMunicipalities.value = [
      Municipality(id: 1, name: 'Municipality 1'),
      Municipality(id: 2, name: 'Municipality 2'),
    ];
  }

  void _loadVillagesForMunicipality(int? municipalityId) {
    // Mock data - replace with actual API call
    stepVillages.value = [
      Village(id: 1, name: 'Village 1'),
      Village(id: 2, name: 'Village 2'),
    ];
  }

  Future<void> scanQRCode(TextEditingController controller) async {
    try {
      final result =
          await Get.to(() => QRViewEnrollment(controller: controller));
      if (result != null) {
        controller.text = result;
      } else {
        SnackBars.failure("Failed", "QR code scan was unsuccessful.");
      }
    } catch (e) {
      SnackBars.failure(
          "Error", "An error occurred while scanning the QR code.");
    }
  }

  void resetForm() {
    chfidController.clear();
    eaCodeController.clear();
    lastNameController.clear();
    givenNameController.clear();
    phoneController.clear();
    emailController.clear();
    identificationNoController.clear();
    birthdateController.clear();
    gender.value = '';
    maritalStatus.value = '';
    disabilityStatus.value = '';
    isHead.value = false;
    photo.value = null;
    newEnrollment.value = true;
    enrollmentFormKey.currentState?.reset();
  }

  Future<void> pickAndCropPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: false,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final croppedFileAsFile = File(croppedFile.path);
        photo.value = XFile(croppedFileAsFile.path);
      }
    }
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      birthdateController.text = "${picked.toLocal()}".split(' ')[0];
    }
  }

  void handleNewEnrollmentChange(bool value) {
    if (value) {
      isHead.value = true;
      headChfidController.text = chfidController.text;
    } else {
      isHead.value = false;
      headChfidController.clear();
    }
  }

  void showSnackBarOnFailure(String? err) {
    Get.closeAllSnackbars();
    SnackBars.failure("Oops!", err.toString());
    _rxEnrollmentState.value = Status.idle();
  }

  // Family Member Management Methods
  void addFamilyMember() async {
    // Validate current form
    if (givenNameController.text.isEmpty || lastNameController.text.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill in the member details before adding',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Auto-generate CHFID if empty
    String memberChfid = chfidController.text.trim();
    if (memberChfid.isEmpty) {
      final dbHelper = DatabaseHelper();
      memberChfid = await dbHelper.generateUniqueChfid();
      chfidController.text = memberChfid; // Update the UI
    }

    // Create new family member from current form data
    final newMember = FamilyMember(
      chfid: memberChfid,
      firstName: givenNameController.text,
      lastName: lastNameController.text,
      gender: gender.value,
      birthdate: birthdateController.text,
      phone: phoneController.text,
      email: emailController.text,
      identificationNo: identificationNoController.text,
      maritalStatus: maritalStatus.value,
      relationship: relationShip.value,
      disabilityStatus: disabilityStatus.value,
      isHead: isHead.value,
      photoPath: photo.value?.path,
    );

    // If this member is set as head, remove head status from others
    if (newMember.isHead) {
      for (var member in familyMembers) {
        member.isHead = false;
      }
    }

    // Add to family members list
    familyMembers.add(newMember);

    // Clear form for next member
    _clearFormForNextMember();

    Get.snackbar(
      'Success',
      'Family member added successfully',
      backgroundColor: Color(0xFF036273),
      colorText: Colors.white,
    );
  }

  void deleteFamilyMember(int index) {
    if (index >= 0 && index < familyMembers.length) {
      final member = familyMembers[index];

      Get.defaultDialog(
        title: 'Delete Member',
        middleText:
            'Are you sure you want to remove ${member.fullName} from the family?',
        textCancel: 'Cancel',
        textConfirm: 'Delete',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () {
          familyMembers.removeAt(index);
          Get.back();
          Get.snackbar(
            'Success',
            'Family member removed successfully',
            backgroundColor: Color(0xFF036273),
            colorText: Colors.white,
          );
        },
      );
    }
  }

  void setFamilyHead(int index) {
    if (index >= 0 && index < familyMembers.length) {
      // Remove head status from all members
      for (var member in familyMembers) {
        member.isHead = false;
      }

      // Set selected member as head
      familyMembers[index].isHead = true;
      familyMembers.refresh(); // Trigger UI update

      Get.snackbar(
        'Success',
        '${familyMembers[index].fullName} is now the family head',
        backgroundColor: Color(0xFF036273),
        colorText: Colors.white,
      );
    }
  }

  void editFamilyMember(int index) {
    if (index >= 0 && index < familyMembers.length) {
      final member = familyMembers[index];

      // Populate form with member data
      chfidController.text = member.chfid;
      givenNameController.text = member.firstName;
      lastNameController.text = member.lastName;
      gender.value = member.gender;
      birthdateController.text = member.birthdate;
      phoneController.text = member.phone;
      emailController.text = member.email;
      identificationNoController.text = member.identificationNo;
      maritalStatus.value = member.maritalStatus;
      relationShip.value = member.relationship;
      disabilityStatus.value = member.disabilityStatus;
      isHead.value = member.isHead;

      if (member.photoPath != null) {
        photo.value = XFile(member.photoPath!);
      }

      // Remove member from list (will be re-added when form is submitted)
      familyMembers.removeAt(index);
    }
  }

  String _generateChfid() {
    // Generate a simple CHFID (in real app, this would be more sophisticated)
    return 'CHF${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  void _clearFormForNextMember() {
    // Clear form but keep some family-level data
    chfidController.clear();
    givenNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    emailController.clear();
    identificationNoController.clear();
    birthdateController.clear();
    gender.value = '';
    maritalStatus.value = '';
    relationShip.value = '';
    disabilityStatus.value = 'None';
    isHead.value = false;
    photo.value = null;
  }

  // Get family head
  FamilyMember? get familyHead {
    try {
      return familyMembers.firstWhere((member) => member.isHead);
    } catch (e) {
      return null;
    }
  }

  // Calculate total contribution based on configuration
  var calculatedContribution = 0.0.obs;
  var isCalculatingContribution = false.obs;

  Future<double> calculateTotalContribution() async {
    if (familyMembers.isEmpty || 
        membershipType.value.isEmpty || 
        membershipLevel.value.isEmpty || 
        areaType.value.isEmpty) {
      return 0.0;
    }

    try {
      isCalculatingContribution(true);
      
      final contribution = await _contributionConfigService.calculateContribution(
        membershipLevel: membershipLevel.value,
        membershipType: membershipType.value,
        areaType: areaType.value,
        numberOfMembers: familyMembers.length,
      );
      
      calculatedContribution.value = contribution;
      return contribution;
    } catch (e) {
      print('Error calculating contribution: $e');
      // Fallback to default calculation
      return _getDefaultContribution();
    } finally {
      isCalculatingContribution(false);
    }
  }

  // Default fallback calculation
  double _getDefaultContribution() {
    if (familyMembers.isEmpty) return 0.0;
    
    double baseRate = 0.0;
    switch (membershipLevel.value) {
      case 'Level 1':
        baseRate = membershipType.value == 'Paying' ? 100.0 : 50.0;
        break;
      case 'Level 2':
        baseRate = membershipType.value == 'Paying' ? 150.0 : 75.0;
        break;
      case 'Level 3':
        baseRate = membershipType.value == 'Paying' ? 200.0 : 100.0;
        break;
    }
    return baseRate * familyMembers.length;
  }

  // Recalculate contribution when relevant fields change
  void _onMembershipDetailsChanged() {
    if (membershipType.value.isNotEmpty && 
        membershipLevel.value.isNotEmpty && 
        areaType.value.isNotEmpty && 
        familyMembers.isNotEmpty) {
      calculateTotalContribution();
    }
  }

  // Initialize configuration sync on controller start
  @override
  void onInit() {
    super.onInit();
    _initializeConfigSync();
    
    // Set up reactive listeners for membership details changes
    ever(membershipType, (_) => _onMembershipDetailsChanged());
    ever(membershipLevel, (_) => _onMembershipDetailsChanged());
    ever(areaType, (_) => _onMembershipDetailsChanged());
    ever(familyMembers, (_) => _onMembershipDetailsChanged());
  }

  Future<void> _initializeConfigSync() async {
    try {
      // Check if we need to sync configuration
      if (await _contributionConfigService.shouldSyncConfig()) {
        final syncSuccess = await _contributionConfigService.syncConfigFromBackend();
        if (syncSuccess) {
          print('Configuration synced successfully');
        } else {
          print('Configuration sync failed - using local data');
        }
      }
    } catch (e) {
      print('Error initializing config sync: $e');
    }
  }

  // Force sync configuration manually
  Future<void> syncConfiguration() async {
    try {
      isLoading(true);
      final success = await _contributionConfigService.syncConfigFromBackend();
      if (success) {
        SnackBars.success("Success", "Configuration updated successfully!");
        // Recalculate contribution with new config
        await calculateTotalContribution();
      } else {
        SnackBars.failure("Sync Failed", "Unable to update configuration. Using local data.");
      }
    } catch (e) {
      SnackBars.failure("Error", "Failed to sync configuration: $e");
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    chfidController.dispose();
    eaCodeController.dispose();
    lastNameController.dispose();
    givenNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    identificationNoController.dispose();
    birthdateController.dispose();
    super.onClose();
  }
}

