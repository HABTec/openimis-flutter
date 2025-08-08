import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openimis_app/app/utils/api_response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/remote/services/enrollment/reference_data_service.dart';
import '../../../data/remote/services/enrollment/enhanced_insuree_service.dart';
import '../../../data/remote/services/enrollment/product_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/remote/services/enrollment/policy_service.dart';
import '../../../data/remote/services/enrollment/contribution_service.dart';
import '../../../data/local/services/enhanced_contribution_service.dart';
import '../../../data/remote/dto/enrollment/insuree_dto.dart';
import '../../../data/remote/dto/enrollment/product_dto.dart';
import '../../../data/remote/dto/enrollment/policy_dto.dart';
import '../../../data/remote/dto/enrollment/profession_dto.dart';
import '../../../data/remote/dto/enrollment/education_dto.dart';
import '../../../data/remote/dto/enrollment/relation_dto.dart';
import '../../../data/remote/dto/enrollment/family_type_dto.dart';
import '../../../data/remote/dto/enrollment/confirmation_type_dto.dart';
import '../../../data/remote/dto/enrollment/location_hierarchy_dto.dart';
import '../../../utils/enhanced_database_helper.dart';
import '../../../di/locator.dart';
import '../../../widgets/snackbars.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../views/widgets/qr_card_view.dart';

class EnhancedEnrollmentController extends GetxController {
  // Services
  final ReferenceDataService _referenceService = getIt<ReferenceDataService>();
  final EnhancedInsureeService _insureeService =
      getIt<EnhancedInsureeService>();
  final PolicyService _policyService = getIt<PolicyService>();
  final ContributionService _contributionService = getIt<ContributionService>();
  final EnhancedContributionService _enhancedContributionService =
      getIt<EnhancedContributionService>();
  final EnhancedDatabaseHelper _dbHelper = getIt<EnhancedDatabaseHelper>();
  final Uuid _uuid = const Uuid();

  // Form keys
  final GlobalKey<FormState> familyFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> memberFormKey = GlobalKey<FormState>();

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = true.obs;
  final RxBool isReferenceDataReady = false.obs;

  // Current step in multi-step form
  final RxInt currentStep = 1.obs;
  final int totalSteps = 5;

  // CHF ID Format Selection
  final RxInt chfIdFormat =
      1.obs; // 1=region+district+auto, 2=district+auto, 3=auto only

  // Family Head Form Controllers
  final TextEditingController headFirstNameController = TextEditingController();
  final TextEditingController headLastNameController = TextEditingController();
  final TextEditingController headPhoneController = TextEditingController();
  final TextEditingController headEmailController = TextEditingController();
  final TextEditingController headPassportController = TextEditingController();
  final TextEditingController headDobController = TextEditingController();

  // Family Details Controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController confirmationNumberController =
      TextEditingController();

  // Member Form Controllers
  final TextEditingController memberFirstNameController =
      TextEditingController();
  final TextEditingController memberLastNameController =
      TextEditingController();
  final TextEditingController memberPhoneController = TextEditingController();
  final TextEditingController memberEmailController = TextEditingController();
  final TextEditingController memberPassportController =
      TextEditingController();
  final TextEditingController memberDobController = TextEditingController();

  // Observable form fields
  final RxString headGender = ''.obs;
  final RxString headMaritalStatus = 'N'.obs;
  final RxString headIdType = 'D'.obs;
  final RxInt headProfessionId = 0.obs;
  final RxInt headEducationId = 0.obs;
  final RxBool povertyStatus = false.obs;
  final RxString familyTypeId = 'H'.obs;
  final RxString confirmationTypeId = 'A'.obs;
  // Location selection (cascading)
  final RxString selectedRegionId = ''.obs;
  final RxString selectedDistrictId = ''.obs;
  final RxString selectedMunicipalityId = ''.obs;
  final RxString selectedVillageId = ''.obs;

  // Filtered location lists (based on parent selection)
  final RxList<FlatLocationDto> filteredDistricts = <FlatLocationDto>[].obs;
  final RxList<FlatLocationDto> filteredMunicipalities =
      <FlatLocationDto>[].obs;
  final RxList<FlatLocationDto> filteredVillages = <FlatLocationDto>[].obs;

  // Member form fields
  final RxString memberGender = ''.obs;
  final RxString memberMaritalStatus = 'N'.obs;
  final RxString memberIdType = 'D'.obs;
  final RxInt memberProfessionId = 0.obs;
  final RxInt memberEducationId = 0.obs;
  final RxInt memberRelationshipId = 0.obs;

  // Photo handling
  final Rx<XFile?> headPhoto = Rx<XFile?>(null);
  final Rx<XFile?> memberPhoto = Rx<XFile?>(null);

  // Reference data
  final RxList<ProfessionDto> professions = <ProfessionDto>[].obs;
  final RxList<EducationDto> educations = <EducationDto>[].obs;
  final RxList<RelationDto> relations = <RelationDto>[].obs;
  final RxList<FamilyTypeDto> familyTypes = <FamilyTypeDto>[].obs;
  final RxList<ConfirmationTypeDto> confirmationTypes =
      <ConfirmationTypeDto>[].obs;
  final RxList<FlatLocationDto> regions = <FlatLocationDto>[].obs;
  final RxList<FlatLocationDto> districts = <FlatLocationDto>[].obs;
  final RxList<FlatLocationDto> municipalities = <FlatLocationDto>[].obs;
  final RxList<FlatLocationDto> villages = <FlatLocationDto>[].obs;

  // Current family data
  final Rx<FamilyDto?> currentFamily = Rx<FamilyDto?>(null);
  final RxList<InsureeDto> familyMembers = <InsureeDto>[].obs;

  // Current policy and contribution
  final Rx<PolicyDto?> currentPolicy = Rx<PolicyDto?>(null);

  // Product and membership selection
  final RxList<ProductDto> availableProducts = <ProductDto>[].obs;
  final RxList<MembershipTypeDto> availableMembershipTypes =
      <MembershipTypeDto>[].obs;
  final Rx<String> selectedProductId = ''.obs;
  final Rx<ProductDto?> selectedProduct = Rx<ProductDto?>(null);
  final Rx<String> selectedMembershipTypeId = ''.obs;
  final Rx<MembershipTypeDto?> selectedMembershipType =
      Rx<MembershipTypeDto?>(null);

  // Enhanced contribution calculation
  final Rx<ContributionBreakdown?> currentContributionBreakdown =
      Rx<ContributionBreakdown?>(null);

  // Dynamic membership type selection
  final Rx<String> selectedAreaType = ''.obs;

  // Payment related observables
  final RxBool showPaymentSection = false.obs;
  final RxString paymentMethod = 'online'.obs;
  final RxBool isOfflinePayment = false.obs;

  // Transaction ID and OCR related properties
  final RxString transactionId = ''.obs;
  final TextEditingController transactionIdController = TextEditingController();
  final RxString ocrText = ''.obs;
  final RxString extractedTransactionId = ''.obs;
  final RxBool isProcessingOCR = false.obs;
  final Rxn<XFile> receiptPhoto = Rxn<XFile>();

  // Contribution calculation
  final RxDouble calculatedContribution = 0.0.obs;
  final RxString membershipType = 'Paying'.obs;
  final RxString membershipLevel = 'Level 1'.obs;
  final RxString areaType = 'Urban'.obs;

  // Gender options
  final List<Map<String, String>> genderOptions = [
    {'value': 'M', 'label': 'Male'},
    {'value': 'F', 'label': 'Female'},
  ];

  // Marital status options
  final List<Map<String, String>> maritalStatusOptions = [
    {'value': 'N', 'label': 'Not Specified'},
    {'value': 'S', 'label': 'Single'},
    {'value': 'M', 'label': 'Married'},
    {'value': 'D', 'label': 'Divorced'},
    {'value': 'W', 'label': 'Widowed'},
  ];

  // ID type options (License)
  final List<Map<String, String>> idTypeOptions = [
    {'value': 'D', 'label': "Driver's License"},
    {'value': 'N', 'label': 'National ID'},
    {'value': 'P', 'label': 'Passport'},
    {'value': 'V', 'label': 'Voter Card'},
  ];

  // CHF ID format options
  final List<Map<String, String>> chfIdFormatOptions = [
    {'value': '1', 'label': 'Region/District/Auto/Member/Admin/Year'},
    {'value': '2', 'label': 'Auto/District/Member/Admin/Year'},
    {'value': '3', 'label': 'Auto/Member/Admin/Year'},
  ];

  @override
  void onInit() {
    super.onInit();
    _initConnectivityListener();
    _checkReferenceDataAndInit();
    // _setupLocationListeners();
    _setDefaultTestValues();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = result != ConnectivityResult.none;
    });

    Connectivity().checkConnectivity().then((result) {
      isOnline.value = result != ConnectivityResult.none;
    });
  }

  void _setupLocationListeners() {
    // Listen for region changes
    ever(selectedRegionId, (regionId) {
      if (regionId.isNotEmpty) {
        _filterDistrictsByRegion(regionId);
        // Clear dependent selections
        selectedDistrictId.value = '';
        selectedMunicipalityId.value = '';
        selectedVillageId.value = '';
        filteredMunicipalities.clear();
        filteredVillages.clear();
      }
    });

    // Listen for district changes
    ever(selectedDistrictId, (districtId) {
      if (districtId.isNotEmpty) {
        _filterMunicipalitiesByDistrict(districtId);
        // Clear dependent selections
        selectedMunicipalityId.value = '';
        selectedVillageId.value = '';
        filteredVillages.clear();
      }
    });

    // Listen for municipality changes
    ever(selectedMunicipalityId, (municipalityId) {
      if (municipalityId.isNotEmpty) {
        _filterVillagesByMunicipality(municipalityId);
        // Clear dependent selections
        selectedVillageId.value = '';
      }
    });
  }

  /// Sets default test values for easier testing
  void _setDefaultTestValues() {
    // Family Head Information
    headFirstNameController.text = 'Abebe';
    headLastNameController.text = 'Kebede';
    headPhoneController.text = '+251911123456';
    headEmailController.text = 'abebe.kebede@email.com';
    headPassportController.text = 'ET123456789';
    headDobController.text = '1985-03-15';

    // Set default observable values
    headGender.value = 'M';
    headMaritalStatus.value = 'M'; // Married
    headIdType.value = 'D'; // Default ID type
    headProfessionId.value = 1; // Will be set to first available profession
    headEducationId.value = 1; // Will be set to first available education

    // Family Details
    addressController.text = 'Kebele 01, House No. 123, Addis Ababa';
    familyTypeId.value = 'H'; // Household
    confirmationTypeId.value = 'A'; // Default confirmation type
    confirmationNumberController.text = 'CONF123456';

    // Member form defaults (for when adding members)
    memberFirstNameController.text = 'Sara';
    memberLastNameController.text = 'Kebede';
    memberPhoneController.text = '+251922654321';
    memberEmailController.text = 'sara.kebede@email.com';
    memberPassportController.text = 'ET987654321';
    memberDobController.text = '1990-07-20';

    memberGender.value = 'F';
    memberMaritalStatus.value = 'S'; // Single
    memberIdType.value = 'D';
    memberProfessionId.value = 1;
    memberEducationId.value = 1;
    memberRelationshipId.value = 1; // Will be set to first available relation

    // CHF ID Format
    chfIdFormat.value = 1;

    // Payment defaults
    paymentMethod.value = 'offline';
    isOfflinePayment.value = true;
    transactionId.value = 'TXN123456789';

    // Poverty status
    povertyStatus.value = false;
  }

  /// Calculate contribution using the enhanced formula
  void calculateEnhancedContribution() async {
    if (selectedMembershipType.value == null) return;

    try {
      // Prepare family members for calculation
      final List<FamilyMemberForCalculation> members = [];

      // Add head
      final headAge = _calculateAge(headDobController.text);
      members.add(FamilyMemberForCalculation(
        name: '${headFirstNameController.text} ${headLastNameController.text}',
        disabled: false,
        age: headAge,
        isHead: true, // Could be determined from form data
      ));

      // Add family members
      for (final member in familyMembers) {
        final memberAge = _calculateAge(member.dob ?? '');
        members.add(FamilyMemberForCalculation(
          name: '${member.lastName}',
          age: memberAge,
          isHead: false,
          disabled: false, // Could be determined from member data
        ));
      }

      final breakdown =
          await _enhancedContributionService.calculateContribution(
        familyMembers: members,
        membershipTypeId: selectedMembershipType.value!.id!,
      );

      currentContributionBreakdown.value = breakdown.breakdown;
      calculatedContribution.value = breakdown.breakdown!.totalAmount;
    } catch (e) {
      print('Error calculating enhanced contribution: $e');
    }
  }

  /// Calculate age from date of birth string
  int _calculateAge(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  void _filterDistrictsByRegion(String regionId) {
    print("=== FILTERING DISTRICTS BY REGION: $regionId ===");
    print("Total districts available: ${districts.length}");

    // Show all districts and their parent IDs
    for (var district in districts) {
      print(
          "District: ${district.name} (${district.id}) -> parentId: ${district.parentId}");
    }

    final filteredList =
        districts.where((district) => district.parentId == regionId).toList();

    print("Filtered districts found: ${filteredList.length}");
    for (var district in filteredList) {
      print("Filtered: ${district.name} -> parentId: ${district.parentId}");
    }

    filteredDistricts.assignAll(filteredList);
    print("=== END FILTERING ===");
  }

  void _filterMunicipalitiesByDistrict(String districtId) {
    final filteredList = municipalities
        .where((municipality) => municipality.parentId == districtId)
        .toList();
    filteredMunicipalities.assignAll(filteredList);
  }

  void _filterVillagesByMunicipality(String municipalityId) {
    final filteredList = villages
        .where((village) => village.parentId == municipalityId)
        .toList();
    filteredVillages.assignAll(filteredList);
  }

  Future<void> _checkReferenceDataAndInit() async {
    try {
      isLoading.value = true;

      // Check if reference data is already cached
      final needsSync = await _dbHelper.needsReferenceDataSync();

      if (needsSync && isOnline.value) {
        // Show dialog to sync reference data
        final shouldSync = await Get.dialog<bool>(
          AlertDialog(
            title: Text('Sync Required'),
            content: Text(
                'Reference data needs to be synchronized before creating families. This includes locations, professions, education levels, and other required data.\n\nWould you like to sync now?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Sync Now'),
              ),
            ],
          ),
        );

        if (shouldSync == true) {
          await syncReferenceData();
        } else {
          // Don't allow form access without reference data
          Get.back();
          SnackBars.warning('Sync Required',
              'Please sync reference data before creating families');
          return;
        }
      }

      // Load cached reference data
      await _loadReferenceData();
      isReferenceDataReady.value = true;
    } catch (e) {
      SnackBars.failure('Error', 'Failed to initialize: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncReferenceData() async {
    try {
      isSyncing.value = true;

      final result = await _referenceService.syncAllReferenceData();

      if (result.error) {
        SnackBars.failure('Sync Failed', result.message);
        throw Exception(result.message);
      } else {
        SnackBars.success('Success', 'Reference data synced successfully');
      }
    } catch (e) {
      rethrow;
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _loadReferenceData() async {
    try {
      // Load all reference data in parallel
      final futures = [
        _referenceService.getProfessions(),
        _referenceService.getEducations(),
        _referenceService.getRelations(),
        _referenceService.getFamilyTypes(),
        _referenceService.getConfirmationTypes(),
        _referenceService.getLocationsByType('R'), // Regions
        _referenceService.getLocationsByType('D'), // Districts
        _referenceService.getLocationsByType('W'), // Municipalities
        _referenceService.getLocationsByType('V'), // Villages
        _referenceService.getProducts(),
      ];

      final results = await Future.wait(futures);

      professions.assignAll(results[0] as List<ProfessionDto>);
      educations.assignAll(results[1] as List<EducationDto>);
      relations.assignAll(results[2] as List<RelationDto>);
      familyTypes.assignAll(results[3] as List<FamilyTypeDto>);
      confirmationTypes.assignAll(results[4] as List<ConfirmationTypeDto>);
      regions.assignAll(results[5] as List<FlatLocationDto>);
      districts.assignAll(results[6] as List<FlatLocationDto>);
      municipalities.assignAll(results[7] as List<FlatLocationDto>);
      villages.assignAll(results[8] as List<FlatLocationDto>);
      availableProducts.assignAll(results[9] as List<ProductDto>);
      availableMembershipTypes.assignAll((results[9] as List<ProductDto>)
          .expand((product) => product.membershipTypes ?? [])
          .toList()
          .fold<Map<String, MembershipTypeDto>>({}, (map, type) {
            map[type.id] = type;
            return map;
          })
          .values
          .toList());
      selectedProductId.value = availableProducts.first.id ?? '';
      selectedProduct.value = availableProducts.first;
      print("Loaded locations:");
      print("Regions: ${regions.length}");
      print("Districts: ${districts.length}");
      print("Municipalities: ${municipalities.length}");
      print("Villages: ${villages.length}");

      if (districts.isNotEmpty) {
        print("First district: ${districts.first.toJson()}");
      }

      // Set default values if available
      if (professions.isNotEmpty)
        headProfessionId.value = professions.first.id ?? 0;
      if (educations.isNotEmpty)
        headEducationId.value = educations.first.id ?? 0;
      if (familyTypes.isNotEmpty)
        familyTypeId.value = familyTypes.first.code ?? 'H';
      if (confirmationTypes.isNotEmpty)
        confirmationTypeId.value = confirmationTypes.first.code ?? 'A';
    } catch (e) {
      SnackBars.failure('Error', 'Failed to load reference data: $e');
    }
  }

  // Manual resync of reference data
  Future<void> resyncReferenceData() async {
    try {
      isLoading.value = true;
      final result = await _referenceService.resyncAllReferenceData();

      if (result.error == null) {
        // Reload reference data after successful sync
        await _loadReferenceData();
        SnackBars.success('Success', 'Reference data synced successfully');
      } else {
        SnackBars.failure(
            'Error', 'Failed to resync reference data: ${result.error}');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to resync reference data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // CHF ID Generation Logic
  String _generateChfId(int autoId, int memberNo) {
    final currentYear = DateTime.now().year;
    final adminId = _getAdminId();

    // Get location codes for formats 1 and 2
    String? regionCode;
    String? districtCode;

    if (selectedVillageId.value.isNotEmpty) {
      // Find the selected location (should be a village)
      final selectedLocation =
          villages.firstWhereOrNull((loc) => loc.id == selectedVillageId.value);

      if (selectedLocation != null) {
        // Extract district from full path
        final pathParts = selectedLocation.fullPath?.split(' > ') ?? [];
        if (pathParts.length >= 2) {
          regionCode = _abbreviate(pathParts[0]);
          districtCode = _abbreviate(pathParts[1]);
        }
      }
    }

    // Generate CHF ID based on selected format
    switch (chfIdFormat.value) {
      case 1: // region/district/auto/member/admin/year
        // if (regionCode == null || districtCode == null) {
        //   throw Exception('Location required for this CHF ID format');
        // }
        // return '$regionCode/$districtCode/${autoId.toString().padLeft(4, '0')}/$memberNo/$adminId/$currentYear';
        return 'AA/KK/${autoId.toString().padLeft(4, '0')}/$memberNo/$adminId/$currentYear';

      case 2: // auto/district/member/admin/year
        if (districtCode == null) {
          throw Exception('District location required for this CHF ID format');
        }
        return '${autoId.toString().padLeft(4, '0')}/$districtCode/$memberNo/$adminId/$currentYear';

      case 3: // auto/member/admin/year
      default:
        return '${autoId.toString().padLeft(4, '0')}/$memberNo/$adminId/$currentYear';
    }
  }

  String _abbreviate(String locationName) {
    final words = locationName.trim().split(' ');
    if (words.length == 1) {
      final word = words[0];
      if (word.length == 3) return word.toUpperCase();
      if (word.length > 3) return word.substring(0, 2).toUpperCase();
      return word.toUpperCase();
    }
    // Multiple words -> first char of each word
    return words
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
  }

  int _getAdminId() {
    // TODO: Get actual admin/officer ID from auth
    return 1; // Default admin ID
  }

  // Step Navigation
  void nextStep() {
    if (currentStep.value < totalSteps) {
      if (_validateCurrentStep()) {
        currentStep.value++;
        if (currentStep.value == 4) {
          // Payment step
          calculateEnhancedContribution();
          showPaymentSection.value = true;
        }
      }
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 1: // Family Head Information
        return familyFormKey.currentState?.validate() ?? false;
      case 2: // Location & Family Details
        return true;
      case 3: // Family Members (optional)
        return true; // Members are optional
      case 4: // Payment Method
        return true; // Validation handled in payment section
      default:
        return true;
    }
  }

  String getStepTitle() {
    switch (currentStep.value) {
      case 1:
        return 'Family Head Information';
      case 2:
        return 'Location & Family Details';
      case 3:
        return 'Family Members';
      case 4:
        return 'Payment & Contribution';
      case 5:
        return 'Review & Submit';
      default:
        return 'Family Registration';
    }
  }

  // Photo handling
  Future<void> pickHeadPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        headPhoto.value = image;
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to capture photo: $e');
    }
  }

  Future<void> pickMemberPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        memberPhoto.value = image;
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to capture photo: $e');
    }
  }

  // Add family member
  Future<void> addFamilyMember() async {
    if (!(memberFormKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      // Convert photo to base64 if available
      String? photoBase64;
      if (memberPhoto.value != null) {
        final bytes = await File(memberPhoto.value!.path).readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      // Generate CHF ID for member
      final memberNo =
          familyMembers.length + 2; // +1 for head, +1 for this member
      final chfId =
          _generateChfId(DateTime.now().millisecondsSinceEpoch, memberNo);

      final member = InsureeDto(
        chfId: chfId,
        lastName: memberLastNameController.text.trim(),
        otherNames: memberFirstNameController.text.trim(),
        genderId: memberGender.value,
        dob: memberDobController.text,
        head: false,
        marital: memberMaritalStatus.value,
        passport: memberPassportController.text.trim(),
        phone: memberPhoneController.text.trim(),
        email: memberEmailController.text.trim(),
        photo: photoBase64 != null
            ? PhotoDto(
                photo: photoBase64,
                officerId: _getAdminId(),
                date: DateTime.now().toIso8601String().split('T')[0],
              )
            : null,
        cardIssued: true,
        professionId: memberProfessionId.value,
        educationId: memberEducationId.value,
        typeOfIdId: memberIdType.value,
        relationshipId: memberRelationshipId.value,
        status: 'AC',
        jsonExt: '{}',
        syncStatus: 0,
      );

      familyMembers.add(member);
      _clearMemberForm();

      // Recalculate contribution
      calculateEnhancedContribution();

      SnackBars.success('Success', 'Family member added successfully');
    } catch (e) {
      SnackBars.failure('Error', 'Failed to add family member: $e');
    }
  }

  // Remove family member
  void removeFamilyMember(int index) {
    if (index >= 0 && index < familyMembers.length) {
      familyMembers.removeAt(index);
      calculateEnhancedContribution();
      SnackBars.success('Success', 'Family member removed');
    }
  }

  // Clear member form
  void _clearMemberForm() {
    memberFirstNameController.clear();
    memberLastNameController.clear();
    memberPhoneController.clear();
    memberEmailController.clear();
    memberPassportController.clear();
    memberDobController.clear();
    memberGender.value = '';
    memberMaritalStatus.value = 'N';
    memberIdType.value = 'D';
    memberProfessionId.value =
        professions.isNotEmpty ? professions.first.id ?? 0 : 0;
    memberEducationId.value =
        educations.isNotEmpty ? educations.first.id ?? 0 : 0;
    memberRelationshipId.value =
        relations.isNotEmpty ? relations.first.id ?? 0 : 0;
    memberPhoto.value = null;
  }

  // Submit family registration
  Future<void> submitFamilyRegistration() async {
    try {
      isLoading.value = true;

      // Generate CHF ID for head
      final headChfId =
          _generateChfId(DateTime.now().millisecondsSinceEpoch, 1);

      // Convert head photo to base64 if available
      String? headPhotoBase64;
      if (headPhoto.value != null) {
        final bytes = await File(headPhoto.value!.path).readAsBytes();
        headPhotoBase64 = base64Encode(bytes);
      }

      // Create head insuree
      final headInsuree = InsureeDto(
        chfId: headChfId,
        lastName: headLastNameController.text.trim(),
        otherNames: headFirstNameController.text.trim(),
        genderId: headGender.value,
        dob: headDobController.text,
        head: true,
        marital: headMaritalStatus.value,
        passport: headPassportController.text.trim(),
        phone: headPhoneController.text.trim(),
        email: headEmailController.text.trim(),
        photo: headPhotoBase64 != null
            ? PhotoDto(
                photo: headPhotoBase64,
                officerId: _getAdminId(),
                date: DateTime.now().toIso8601String().split('T')[0],
              )
            : null,
        cardIssued: true,
        professionId: headProfessionId.value,
        educationId: headEducationId.value,
        typeOfIdId: headIdType.value,
        status: 'AC',
        jsonExt: '{}',
        syncStatus: 0,
      );

      // Create family
      final family = FamilyDto(
        headInsuree: headInsuree,
        locationId: int.tryParse(selectedVillageId.value) ?? 0,
        poverty: povertyStatus.value,
        familyTypeId: familyTypeId.value,
        address: addressController.text.trim(),
        confirmationTypeId: confirmationTypeId.value,
        confirmationNo: confirmationNumberController.text.trim(),
        jsonExt: '{}',
        syncStatus: 0,
      );

      // Create family in database
      final result = await _insureeService.createFamily(family);

      if (result.error) {
        SnackBars.failure('Registration Failed', result.message);
        return;
      }

      final localFamilyId = result.data as int;
      currentFamily.value = family.copyWith(localId: localFamilyId);

      // Add family members
      for (final member in familyMembers) {
        member.localFamilyId = localFamilyId;
        member.familyId = localFamilyId;
        final memberResult = await _insureeService.createInsuree(member);
        if (memberResult.error) {
          SnackBars.warning(
              'Warning', 'Failed to add member: ${memberResult.message}');
        }
      }

      // Create policy after family creation
      await _createPolicyForFamily(localFamilyId);

      // Handle payment and contribution creation
      if (currentContributionBreakdown.value != null &&
          currentContributionBreakdown.value!.totalAmount > 0) {
        if (!isOfflinePayment.value) {
          // Handle online payment and contribution
          await _handleOnlinePaymentAndContribution();
        } else {
          // Handle offline payment and contribution
          await _handleOfflinePaymentAndContribution();
        }
      } else {
        // No payment required
        _showSuccessPage();
      }
    } catch (e) {
      SnackBars.failure('Error', 'Registration failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleOnlinePayment() async {
    // TODO: Implement online payment integration
    SnackBars.info('Info', 'Online payment integration coming soon');
    _showSuccessPage();
  }

  Future<void> _handleOfflinePayment() async {
    // For offline payment, show invoice and mark as pending
    _showOfflineInvoice();
  }

  // Create policy for the family
  Future<void> _createPolicyForFamily(int familyId) async {
    if (selectedProductId.value.isEmpty) {
      SnackBars.warning('Warning', 'No product selected for policy creation');
      return;
    }

    try {
      final now = DateTime.now();
      final enrollDate = now.toIso8601String().split('T')[0];
      final startDate = enrollDate;

      // Calculate expiry date using product's enrolment period or default

      final expiryDate = _policyService
          .calculateExpiryDate(selectedProduct.value?.enrolmentPeriodEndDate);

      // final policyResult = await _policyService.createPolicy(
      //   enrollDate: enrollDate,
      //   startDate: startDate,
      //   expiryDate: expiryDate,
      //   value: currentContributionBreakdown.value?.totalAmount
      //           .toStringAsFixed(2) ??
      //       '0.00',
      //   productId: int.parse(selectedProductId.value),
      //   familyId: familyId,
      //   officerId: _getAdminId(),
      //   tryOnlineFirst: isOnline.value,
      // );
      final policyResult = ApiResponse(
        error: false,
        message: 'Policy created successfully offline',
        data: PolicyDto(
          uuid: '0',
          enrollDate: '0',
          startDate: '0',
          expiryDate: '0',
          value: '',
        ),
      );

      if (!policyResult.error) {
        currentPolicy.value = policyResult.data as PolicyDto;
        SnackBars.success('Success', 'Policy created successfully');
      } else {
        //TODO: improve
        currentPolicy.value = PolicyDto(
          uuid: '0',
          enrollDate: '0',
          startDate: '0',
          expiryDate: '0',
          value: '',
        );
        SnackBars.warning('Warning',
            'Policy creation failed: ${policyResult.message}. Will be created when online');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to create policy: $e');
    }
  }

  // Handle online payment and contribution creation
  Future<void> _handleOnlinePaymentAndContribution() async {
    if (currentPolicy.value == null) {
      SnackBars.failure('Error', 'Policy must be created before payment');
      return;
    }

    try {
      // Generate receipt number
      final receiptNumber = _contributionService.generateReceiptNumber();
      final payDate = DateTime.now().toIso8601String().split('T')[0];
      final totalAmount =
          currentContributionBreakdown.value!.totalAmount.toStringAsFixed(2);

      // Create contribution
      final contributionResult = await _contributionService.createContribution(
        receipt: receiptNumber,
        payDate: payDate,
        amount: totalAmount,
        policyUuid: currentPolicy.value!.uuid!,
        tryOnlineFirst: true,
      );

      if (!contributionResult.error) {
        SnackBars.success('Success', 'Payment processed successfully');
        _showSuccessPage();
      } else {
        SnackBars.failure('Payment Failed', contributionResult.message);
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to process payment: $e');
    }
  }

  // Handle offline payment and contribution creation
  Future<void> _handleOfflinePaymentAndContribution() async {
    if (currentPolicy.value == null) {
      SnackBars.failure('Error', 'Policy must be created before payment');
      return;
    }

    try {
      // Create offline contribution record
      final receiptNumber = _contributionService.generateReceiptNumber();
      final payDate = DateTime.now().toIso8601String().split('T')[0];
      final totalAmount =
          currentContributionBreakdown.value!.totalAmount.toStringAsFixed(2);

      // Create contribution locally (will sync later)
      final contributionResult = await _contributionService.createContribution(
        receipt: receiptNumber,
        payDate: payDate,
        amount: totalAmount,
        policyUuid: currentPolicy.value!.uuid!,
        tryOnlineFirst: false, // Force offline
      );

      if (!contributionResult.error) {
        _showOfflineInvoice();
      } else {
        SnackBars.failure('Error',
            'Failed to create offline payment record: ${contributionResult.message}');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to process offline payment: $e');
    }
  }

  void _showOfflineInvoice() {
    Get.to(() => OfflinePaymentInvoiceView(
          family: currentFamily.value!,
          amount: calculatedContribution.value,
          onPaymentRecorded: () => _showSuccessPage(),
        ));
  }

  void _showSuccessPage() {
    if (currentFamily.value == null) {
      SnackBars.failure(
          'Error', 'Family data is missing. Please try registering again.');
      return;
    }

    Get.to(() => FamilyRegistrationSuccessView(
          family: currentFamily.value!,
          memberCount: familyMembers.length + 1,
        ));
  }

  // Validation helpers
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[\d\s-()]+$').hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!GetUtils.isEmail(value.trim())) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }
  }

  // Temporary debug method to test location syncing
  Future<void> debugTestLocationSync() async {
    try {
      isLoading.value = true;
      print("Starting debug location sync...");

      // Manually call the location sync
      final result = await _referenceService.syncAllReferenceData();

      if (!result.error) {
        print("Location sync successful, reloading data...");
        await _loadReferenceData();
        SnackBars.success(
            'Debug', 'Location sync completed - check console logs');
      } else {
        print("Location sync failed: ${result.error}");
        SnackBars.failure('Debug', 'Location sync failed: ${result.error}');
      }
    } catch (e) {
      print("Debug location sync error: $e");
      SnackBars.failure('Debug', 'Location sync error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Transaction ID and Payment Methods (Simplified version)

  // Validate transaction ID
  bool validateTransactionId(String id) {
    return id.trim().length >= 8;
  }

  // Manual transaction ID entry
  void setManualTransactionId(String id) {
    transactionId.value = id.trim();
    paymentMethod.value = 'offline_manual';
    isOfflinePayment.value = true;
  }

  // Show transaction ID input dialog
  void showTransactionIdDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text(
              'Enter Transaction ID',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter the transaction ID from your PoS receipt:',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 16.h),

            // Manual entry section
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.keyboard, color: Colors.blue, size: 20.w),
                      SizedBox(width: 8.w),
                      Text(
                        'Manual Entry',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: transactionIdController,
                    decoration: InputDecoration(
                      labelText: 'Transaction ID',
                      hintText: 'e.g., TXN123456789',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      transactionId.value = value.trim();
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // OCR placeholder section
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.grey, size: 20.w),
                      SizedBox(width: 8.w),
                      Text(
                        'Scan Receipt (Coming Soon)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'OCR scanning feature will be available in a future update',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Obx(() => ElevatedButton(
                onPressed: transactionId.value.length >= 8
                    ? () {
                        if (validateTransactionId(transactionId.value)) {
                          setManualTransactionId(transactionId.value);
                          Get.back();
                          SnackBars.success(
                            'Success',
                            'Transaction ID saved successfully',
                          );
                        } else {
                          SnackBars.failure(
                            'Invalid ID',
                            'Please enter a valid transaction ID (minimum 8 characters)',
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Save'),
              )),
        ],
      ),
    );
  }

  // Handle offline payment process
  Future<void> processOfflinePayment(
      {bool fromRegistrationFlow = false}) async {
    if (transactionId.value.isEmpty) {
      SnackBars.warning(
          'Missing Information', 'Please enter a transaction ID first');
      showTransactionIdDialog();
      return;
    }

    try {
      isLoading.value = true;

      // Create a simple offline payment record
      final paymentData = {
        'family_id': currentFamily.value?.localId ?? 0,
        'transaction_id': transactionId.value,
        'payment_method': paymentMethod.value,
        'payment_date': DateTime.now().toIso8601String(),
        'amount': calculatedContribution.value,
        'sync_status': 'PENDING',
      };

      // For now, just show success - actual database implementation will be added later
      SnackBars.success(
          'Payment Recorded', 'Offline payment has been recorded successfully');

      // Only show success page if called from registration flow and family data exists
      if (fromRegistrationFlow && currentFamily.value != null) {
        _showSuccessPage();
      } else if (!fromRegistrationFlow) {
        // When called from UI button, just mark payment as recorded
        SnackBars.info('Payment Recorded',
            'Payment has been marked as paid. Continue with registration.');
      }
    } catch (e) {
      SnackBars.failure('Error', 'Failed to process offline payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle payment method
  void togglePaymentMethod() {
    isOfflinePayment.toggle();
    if (isOfflinePayment.value) {
      paymentMethod.value = 'offline_manual';
    } else {
      paymentMethod.value = 'online';
      transactionId.value = '';
      transactionIdController.clear();
      receiptPhoto.value = null;
    }
  }

  // Clear payment data
  void clearPaymentData() {
    transactionId.value = '';
    transactionIdController.clear();
    ocrText.value = '';
    extractedTransactionId.value = '';
    receiptPhoto.value = null;
    paymentMethod.value = 'online';
    isOfflinePayment.value = false;
  }

  // Pick receipt photo for OCR with enhanced options
  Future<void> pickReceiptPhoto() async {
    try {
      // Show dialog to choose source
      final source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: Text('Select Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Request appropriate permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw Exception('Camera permission not granted');
        }
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission not granted');
        }
      }

      final XFile? photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        // Compress image before processing
        final compressedFile = await compressImage(photo);
        if (compressedFile != null) {
          receiptPhoto.value = XFile(compressedFile.path);
          await extractTextFromReceipt(receiptPhoto.value!);
        } else {
          receiptPhoto.value = photo;
          await extractTextFromReceipt(photo);
        }
      }
    } catch (e) {
      showSnackBar(
        'Error',
        'Failed to capture receipt: $e',
        isError: true,
      );
    }
  }

  void showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor:
          isError ? const Color(0xFFFF5252) : const Color(0xFF4CAF50),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Compress image to reduce processing time
  Future<XFile?> compressImage(XFile image) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result;
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }

  // Extract text from receipt using enhanced OCR
  Future<void> extractTextFromReceipt(XFile photo) async {
    try {
      isProcessingOCR.value = true;
      ocrText.value = '';
      extractedTransactionId.value = '';

      // Show processing dialog
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(width: 16),
              Text('Processing Receipt'),
            ],
          ),
          content: Text('Extracting text from image...'),
        ),
        barrierDismissible: false,
      );

      final inputImage = InputImage.fromFilePath(photo.path);
      var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String fullText = '';
      List<String> potentialTransactionIds = [];

      // Process each text block
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          fullText += '${line.text}\n';

          // Look for potential transaction IDs in each line
          final candidates = _findPotentialTransactionIds(line.text);
          potentialTransactionIds.addAll(candidates);
        }
      }

      ocrText.value = fullText;

      // Close processing dialog
      Get.back();

      if (potentialTransactionIds.isNotEmpty) {
        // If multiple candidates found, show selection dialog
        if (potentialTransactionIds.length > 1) {
          final selectedId =
              await _showTransactionIdSelectionDialog(potentialTransactionIds);
          if (selectedId != null) {
            _setTransactionId(selectedId);
          }
        } else {
          // If single candidate found, use it directly
          _setTransactionId(potentialTransactionIds.first);
        }
      } else {
        showSnackBar(
          'OCR Complete',
          'No transaction ID found. Please enter manually.',
        );
      }
    } catch (e) {
      Get.back(); // Close processing dialog if error occurs
      showSnackBar(
        'OCR Error',
        'Failed to extract text: $e',
        isError: true,
      );
    } finally {
      isProcessingOCR.value = false;
    }
  }

  // Helper method to set transaction ID
  void _setTransactionId(String id) {
    extractedTransactionId.value = id;
    transactionIdController.text = id;
    transactionId.value = id;
    paymentMethod.value = 'offline_ocr';
    showSnackBar(
      'Success',
      'Transaction ID extracted: $id',
    );
  }

  // Show dialog for selecting transaction ID from multiple candidates
  Future<String?> _showTransactionIdSelectionDialog(
      List<String> candidates) async {
    return await Get.dialog<String>(
      AlertDialog(
        title: Text('Select Transaction ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Multiple potential transaction IDs found. Please select the correct one:'),
            SizedBox(height: 16),
            ...candidates
                .map((id) => ListTile(
                      title: Text(id),
                      onTap: () => Get.back(result: id),
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Find potential transaction IDs in text
  List<String> _findPotentialTransactionIds(String text) {
    final List<String> candidates = [];

    // Common patterns for transaction IDs
    final patterns = [
      // Exact patterns with labels
      r'(?:Transaction|Trans|TXN|ID|REF)[\s:]*([A-Z0-9]{8,20})',
      r'(?:Receipt|Ref|Reference)[\s:]*([A-Z0-9]{8,20})',
      r'(?:Payment|Pay)[\s:]*([A-Z0-9]{8,20})',

      // Generic patterns for numbers and alphanumeric strings
      r'\b\d{6,15}\b', // Pure numeric
      r'\b[A-Z0-9]{8,20}\b', // Alphanumeric

      // Date-like patterns to exclude
      r'\b\d{2}[/-]\d{2}[/-]\d{2,4}\b',
      r'\b\d{4}[/-]\d{2}[/-]\d{2}\b',
    ];

    for (String pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);

      for (Match match in matches) {
        final candidate = match.group(1) ?? match.group(0) ?? '';
        if (candidate.isNotEmpty &&
            !_isDateFormat(candidate) &&
            !_isCommonNumber(candidate)) {
          candidates.add(candidate);
        }
      }
    }

    return candidates.toSet().toList(); // Remove duplicates
  }

  // Helper to check if string is a date format
  bool _isDateFormat(String text) {
    return RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{2,4}\b').hasMatch(text) ||
        RegExp(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b').hasMatch(text);
  }

  // Helper to check if string is a common number (amount, phone, etc.)
  bool _isCommonNumber(String text) {
    // Check for currency amounts
    if (RegExp(r'^\d+\.\d{2}$').hasMatch(text)) return true;

    // Check for phone numbers
    if (RegExp(r'^\+?\d{10,12}$').hasMatch(text)) return true;

    return false;
  }

  @override
  void onClose() {
    // Dispose controllers
    headFirstNameController.dispose();
    headLastNameController.dispose();
    headPhoneController.dispose();
    headEmailController.dispose();
    headPassportController.dispose();
    headDobController.dispose();
    addressController.dispose();
    confirmationNumberController.dispose();
    memberFirstNameController.dispose();
    memberLastNameController.dispose();
    memberPhoneController.dispose();
    memberEmailController.dispose();
    memberPassportController.dispose();
    memberDobController.dispose();
    super.onClose();
  }
}

// Success Page Widget
class FamilyRegistrationSuccessView extends StatelessWidget {
  final FamilyDto family;
  final int memberCount;

  const FamilyRegistrationSuccessView({
    Key? key,
    required this.family,
    required this.memberCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Additional safety check
    if (family.headInsuree == null) {
      return Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: Text('Registration Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 100, color: Colors.red),
              SizedBox(height: 24),
              Text(
                'Registration Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Family data is incomplete. Please try registering again.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text('Registration Complete'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
              SizedBox(height: 24),
              Text(
                'Family Registered Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Family Head: ${family.headInsuree?.otherNames ?? 'N/A'} ${family.headInsuree?.lastName ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'CHF ID: ${family.headInsuree?.chfId ?? 'Pending'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Total Members: $memberCount',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    SizedBox(height: 8),
                    Text(
                      'If you are offline, your family has been registered offline and will be synced to the server when internet connection is available.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // QR Card and Membership Actions
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    // Generate QR Code & Membership Card Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showQRCard(),
                        icon: Icon(Icons.qr_code, size: 24),
                        label: Text(
                          'Generate QR Card & Membership Card',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Go to Home Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.offAllNamed('/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Go to Home',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Get.toNamed('/sync-status');
                },
                child: Text(
                  'View Sync Status',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCard() {
    final chfId = family.headInsuree?.chfId ?? 'PENDING';
    final memberName =
        '${family.headInsuree?.otherNames ?? ''} ${family.headInsuree?.lastName ?? ''}'
            .trim();

    if (chfId.isEmpty || chfId == 'PENDING') {
      Get.snackbar(
        'Information',
        'CHF ID is not yet available. Please wait for the family to be processed.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading dialog while generating QR card
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
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
            chfid: chfId,
            memberName: memberName,
            receiptData: null, // Will be null for offline registrations
          ));
    });
  }
}

// Offline Payment Invoice View
class OfflinePaymentInvoiceView extends StatelessWidget {
  final FamilyDto family;
  final double amount;
  final VoidCallback onPaymentRecorded;

  const OfflinePaymentInvoiceView({
    Key? key,
    required this.family,
    required this.amount,
    required this.onPaymentRecorded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Invoice'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT INVOICE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                      'Invoice Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Family details
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Head: ${family.headInsuree?.otherNames} ${family.headInsuree?.lastName}'),
                    Text('CHF ID: ${family.headInsuree?.chfId}'),
                    Text('Phone: ${family.headInsuree?.phone}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Payment details
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Family Registration Fee:'),
                        Text('ETB ${amount.toStringAsFixed(2)}'),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ETB ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPaymentRecorded,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Mark as Paid (Offline)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Note: This registration will be synced to the server when internet connection is available.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
