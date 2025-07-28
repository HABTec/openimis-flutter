import 'dart:async';

import 'package:country_codes/country_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:openimis_app/app/data/local/config/app_config.dart';
import 'package:local_auth/local_auth.dart';

import '../../../data/local/entities/app_config_entity.dart';
import '../../../data/local/entities/user_entity.dart';
import '../../../data/remote/base/status.dart';
import '../../../data/remote/dto/auth/login_in_dto.dart';
import '../../../data/remote/dto/auth/login_out_dto.dart';
import '../../../data/remote/dto/auth/register_company_dto.dart';
import '../../../data/remote/dto/auth/register_company_out_dto.dart';
import '../../../data/remote/dto/auth/register_customer_dto.dart';
import '../../../data/remote/dto/auth/register_customer_out_dto.dart';
import '../../../data/remote/dto/auth/graphql_auth_dto.dart';
import '../../../data/remote/repositories/auth/auth_repository.dart';
import '../../../data/remote/api/dio_client.dart';
import '../../../di/locator.dart';
import '../../../domain/enums/user_type.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/functions.dart';
import '../../../widgets/snackbars.dart';
import '../../enrollment/views/widgets/submit_botton_sheet.dart';
import '../views/login/widgets/choose_bottom_sheet.dart';

class AuthController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  final GetStorage storage = GetStorage();

  var isFirstTime = true.obs;

  var isBiometricEnabled = false.obs;

  var isCheckingUsername = false.obs;
  var usernameExists = false.obs;

  static AuthController get to => Get.find();
  final _authRepository = getIt.get<AuthRepository>();
  final CountryDetails details = CountryCodes.detailsForLocale();

  /*
  * Customer Form Fields.
  * */
  final GlobalKey<FormState> customerFormKey = GlobalKey<FormState>();
  final customerFullNameController = TextEditingController();
  final customerChfidController = TextEditingController(text: '045802525');
  final customerUsernameController = TextEditingController();
  final customerHeadChfidController = TextEditingController(text: '048651094');
  final customerPhoneNumberController =
      TextEditingController(text: '9843317526');
  final customerConfirmPasswordController =
      TextEditingController(text: 'Apple@12345');
  final customerEmailController =
      TextEditingController(text: 'kadl.invoker@gmail.com');
  final customerPasswordController = TextEditingController(text: 'Apple@12345');
  dynamic customerOTPController = TextEditingController();

  /*
  * Company Form Fields
  * */
  final GlobalKey<FormState> companyFormKey = GlobalKey<FormState>();
  final companyNameController = TextEditingController();
  final companyBusinessNumberController = TextEditingController();
  final companyBusinessEmailController = TextEditingController();
  final companyAddressController = TextEditingController();
  final companyCountryController = TextEditingController();
  final companyPasswordController = TextEditingController();

  final Rx<Status> _configStatus = Rx(const Status.idle());

  Status get configStatus => _configStatus.value;
  final RxBool isFormValid = false.obs;

  /*
  * Login Form Fields
  * */
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  /*
  * Rx
  * */

  late final RxString _rxCountry;

  String get country => _rxCountry.value;

  final Rxn<UserEntity> _rxnCurrentUser = Rxn<UserEntity>();

  UserEntity? get currentUser => _rxnCurrentUser.value;

  final Rxn<AppConfigEntity> _rxnAppConfig = Rxn<AppConfigEntity>();

  AppConfigEntity? get appConfig => _rxnAppConfig.value;

  final Rx<Status<RegisterCustomerOutDto>> _rxRegisterCustomerState =
      Rx(const Status.idle());

  Status<RegisterCustomerOutDto> get registerCustomerState =>
      _rxRegisterCustomerState.value;

  final Rx<Status<RegisterCompanyOutDto>> _rxRegisterCompanyState =
      Rx(const Status.idle());

  Status<RegisterCompanyOutDto> get registerCompanyState =>
      _rxRegisterCompanyState.value;

  final Rx<Status<AppConfig>> _rxConfigState = Rx(const Status.idle());

  Status<AppConfig> get ConfigState => _rxConfigState.value;

  final Rx<Status<LoginOutDto>> _rxLoginState = Rx(const Status.idle());

  Status<LoginOutDto> get loginState => _rxLoginState.value;

  final Rx<Status> _rxCustomerRegisterState = Rx(const Status.idle());

  Status get registerState => _rxCustomerRegisterState.value;

  final Rx<Status> _rxcustomerOtpVerifyState = Rx(const Status.idle());

  Status get otpVerifyState => _rxcustomerOtpVerifyState.value;

  final RxBool _rxIsObscure = RxBool(true);

  bool get isObscure => _rxIsObscure.value;

  final Rx<RegisterType> _rxRegisterType = Rx(RegisterType.NOTSELECTED);

  RegisterType get registerType => _rxRegisterType.value;

  final Rx<Status> _rxUsernameVerify = Rx(const Status.idle());

  Status get usernameVerify => _rxUsernameVerify.value;

  // OTP
  var isVerified = false.obs;
  var canResend = false.obs;
  var timeLeft = 60.obs;
  var isResend = false.obs;

  void updateIsFirstTime(bool value) {
    isFirstTime.value = value;
    storage.write('isFirstTime', value); // Save to storage
  }

  Future<void> verifyOtp() async {
    _rxcustomerOtpVerifyState.value = Status.loading();
    Map<String, dynamic> data = {
      "phone": customerPhoneNumberController.value.text,
      "otp": customerOTPController.value.text,
      "username": customerUsernameController.value.text,
      "password": customerConfirmPasswordController.value.text,
      "email": customerEmailController.value.text ?? "test-gmail@g.com",
    };

    final response = await _authRepository.insureeOTPValidation(data);
    if (!response.error) {
      _rxcustomerOtpVerifyState.value = Status.success(data: response.data);
      FocusManager.instance.primaryFocus?.unfocus();
      resetData();
      popupBottomSheet(
        bottomSheetBody: await Get.bottomSheet(
          SubmitBottomSheet(
            titleText: "Registration Completed",
            descriptionText: "You can view the details on the dashboard.",
            buttonText: "Login",
            onTap: () async {
              // Custom async logic
              await Get.offAllNamed(Routes.LOGIN);
            },
          ),
          isScrollControlled: true,
          backgroundColor: Colors.white, // Set background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.0), // Add rounded corners to the top
            ),
          ),
          isDismissible: false, // Prevent dismiss by tapping outside
          enableDrag: true,
        ),
      );
    } else {
      _rxcustomerOtpVerifyState.value = Status.failure(reason: "reason");
      SnackBars.failure("Oops!", response.message);
    }
  }

  Future<void> resendOtpForVerify() async {
    _rxcustomerOtpVerifyState.value = Status.loading();
    Map<String, dynamic> data = {
      "phone": customerPhoneNumberController.value.text,
    };
    final response = await _authRepository.insureeOTPResend(data);
    if (!response.error) {
      isResend.value = true;
      SnackBars.success("Success!", response.message);
    } else {
      SnackBars.failure("Oops!", response.message);
    }
  }

  void validateForm() {
    isFormValid.value = customerFormKey.currentState?.validate() ?? false;
  }

  void verifyInsuree() async {
    _rxCustomerRegisterState.value = Status.loading();
    Map<String, dynamic> data = {
      "chfid": customerChfidController.value.text,
      "head_chfid": customerHeadChfidController.value.text,
      "dob": "2024-03-24",
      "phone": customerPhoneNumberController.value.text,
      "email": customerEmailController.value.text ?? "test-gmail@g.com",
    };
    final response = await _authRepository.insureeValidation(data);
    if (!response.error) {
      _rxCustomerRegisterState.value = Status.success(data: response.data);
      FocusManager.instance.primaryFocus?.unfocus();
      //Get.back();
      //Get.offAllNamed(Routes.OTP);
      //popupBottomSheet(bottomSheetBody: const SubmitBottomSheet());
    } else {
      _rxCustomerRegisterState.value = Status.failure(reason: "reason");
      SnackBars.failure("Oops!", response.message);
    }
  }

  Future<void> verifyUsername(data) async {
    _rxUsernameVerify.value = Status.loading();
    Map<String, dynamic> data = {
      "username": customerUsernameController.value.text,
    };
    final response = await _authRepository.usernameVerify(data);
    if (!response.error) {
      usernameExists.value = false;
      _rxUsernameVerify.value = Status.success(data: response.data);
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _rxUsernameVerify.value = Status.failure(reason: "reason");
      usernameExists.value = true;
      SnackBars.failure("Oops!", response.message);
    }
  }

  void startTimer() {
    canResend.value = false;
    timeLeft.value = 10;

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void resendOtp() async {
    startTimer();
    isResend.value = true;
    //await verifyOtp();
    resendOtpForVerify();
  }

  //
  @override
  void onInit() {
    super.onInit();
    _getCurrentUser();
    isFirstTime.value = storage.read('isFirstTime') ?? true;
    isBiometricEnabled.value = storage.read('biometricEnabled') ?? false;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    customerFullNameController.dispose();
    customerEmailController.dispose();
    customerPasswordController.dispose();
    companyNameController.dispose();
    companyBusinessEmailController.dispose();
    companyBusinessNumberController.dispose();
    companyCountryController.dispose();
    companyAddressController.dispose();
    companyPasswordController.dispose();
  }

  // Reset all data
  void resetData() {
    customerFullNameController.clear();
    customerChfidController.text = '121212'; // Reset to default
    customerUsernameController.clear();
    customerHeadChfidController.text = '112112'; // Reset to default
    customerPhoneNumberController.text = '9849298499'; // Reset to default
    customerConfirmPasswordController.text = 'Apple@12345'; // Reset to default
    customerEmailController.text = 'kadl.invoker@gmail.com'; // Reset to default
    customerPasswordController.text = 'Apple@12345'; // Reset to default
    customerOTPController.clear(); // Assuming OTP can be cleared
    _rxcustomerOtpVerifyState.value = Status.idle();
    _rxCustomerRegisterState.value = Status.idle();
    isVerified.value = false;
    canResend.value = false;
  }

  void _getCurrentUser() async {
    final result = await _authRepository.readStorage(key: 'user');
    result.whenOrNull(
        success: (data) => _rxnCurrentUser.value = UserEntity.fromMap(data));
  }

  void getAppConfig() async {
    final result = await _authRepository.readStorage(key: 'appconfig');
    result.whenOrNull(
        success: (data) => _rxnAppConfig.value = AppConfigEntity.fromMap(data));
  }

  void onCountryChanged(Country country) {
    _rxCountry.value = "+${country.dialCode}";
  }

  Future<void> onLoginSubmit() async {
    if (loginFormKey.currentState!.validate()) {
      await _login();
    }
  }

  Future<void> onRegisterSubmit() async {
    if (registerType == RegisterType.CUSTOMER &&
        customerFormKey.currentState!.validate()) {
      //await _registerCustomer(); registering insuree
    } else if (registerType == RegisterType.COMPANY &&
        companyFormKey.currentState!.validate()) {
      //other
    }
  }

  bool isFaculty() {
    return currentUser?.status == "FACULTY";
  }

  bool isInsuree() {
    return currentUser?.isInsuree == true;
  }

  InsureeInfo? insureeInfo() {
    return currentUser?.insureeInfo;
  }

  bool isOfficer() {
    return currentUser?.isOfficer == true;
  }

  void logout() async {
    final result = await _authRepository.removeStorage(key: 'user');

    // Clear authentication data from DioClient
    final dioClient = getIt.get<DioClient>();
    dioClient.clearAuthData();

    // Reset current user data
    if (AuthController.to.currentUser != null) {
      AuthController.to.currentUser!.token = null;
      AuthController.to.currentUser!.refresh = null;
      AuthController.to.currentUser!.csrfToken = null;
    }

    result.whenOrNull(success: (data) => Get.offAllNamed(Routes.LOGIN));
  }

  Future<void> _login() async {
    // Use new GraphQL authentication
    final result = await _authRepository.graphqlLogin(
      username: loginEmailController.text,
      password: loginPasswordController.text,
    );

    result.whenOrNull(
      success: (authData) async {
        // After successful authentication, get current user details
        final userResult = await _authRepository.getCurrentUser();
        userResult.whenOrNull(
          success: (userData) {
            _saveUserInStorage(
              id: userData?.id ?? "",
              email: userData?.username ?? "", // Use username as email for now
              name: userData?.iUser != null
                  ? "${userData!.iUser!.otherNames} ${userData.iUser!.lastName}"
                  : userData?.username ?? "",
              token: authData?.tokenAuth.token ?? "",
              role: "officer", // Default role for now
              is_insuree: false, // Officers are not insurees
              is_officer: true, // All users logging in are officers
              refresh: authData?.tokenAuth.refreshExpiresIn.toString() ?? "",
              username: userData?.username ?? "",
              csrfToken: authData?.getCsrfToken.csrfToken ?? "",
              officerInfo: userData?.iUser,
            );
            storage.write('loginUsername', loginEmailController.text);
            storage.write('loginPassword', loginPasswordController.text);
            _getCurrentUser();
            Get.offAllNamed(Routes.ROOT);
            _clearTextControllers();
          },
          failure: (error) {
            showSnackBarOnFailure(error);
          },
        );
      },
      failure: showSnackBarOnFailure,
    );
  }

  void toggleBiometric(bool value) async {
    isBiometricEnabled.value = value;
    storage.write('biometricEnabled', value);
    if (value) {
      await enableBiometricAuthentication();
    }
  }

  Future<void> enableBiometricAuthentication() async {
    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isBiometricAvailable =
          canCheckBiometrics || await auth.isDeviceSupported();

      if (isBiometricAvailable) {
        final isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to enable biometrics',
          options: AuthenticationOptions(biometricOnly: true),
        );

        if (isAuthenticated) {
          storage.write('biometricEnabled', true);
        } else {
          // Revert the toggle if authentication fails
          isBiometricEnabled.value = false;
          storage.write('biometricEnabled', false);
        }
      } else {
        // Handle case where biometric authentication is not available
        Get.snackbar('Biometric Unavailable',
            'Biometric authentication is not available on this device.');
      }
    } catch (e) {
      // Handle errors if necessary
      Get.snackbar('Biometric Error',
          'An error occurred during biometric authentication.');
    }
  }

  Future<void> tryBiometricAuthentication() async {
    final isEnabled = storage.read('biometricEnabled') ?? false;

    if (isEnabled) {
      try {
        final isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to login',
          options: AuthenticationOptions(biometricOnly: true),
        );

        if (isAuthenticated) {
          // Retrieve saved credentials
          final username = storage.read('loginUsername');
          final password = storage.read('loginPassword');

          if (username != null && password != null) {
            // Perform login with saved credentials
            await _loginWithSavedCredentials(username, password);
          } else {
            Get.snackbar('Error', 'No saved credentials found.');
          }
        } else {
          Get.snackbar(
              'Authentication Failed', 'Biometric authentication failed.');
        }
      } on PlatformException catch (e) {
        Get.snackbar('Authentication Error',
            'An error occurred during biometric authentication.');
        print(e);
      }
    }
  }

  Future<void> _loginWithSavedCredentials(
      String username, String password) async {
    // Use new GraphQL authentication for biometric login too
    final result = await _authRepository.graphqlLogin(
      username: username,
      password: password,
    );

    result.whenOrNull(
      success: (authData) async {
        // After successful authentication, get current user details
        final userResult = await _authRepository.getCurrentUser();
        userResult.whenOrNull(
          success: (userData) {
            _saveUserInStorage(
              id: userData?.id ?? "",
              email: userData?.username ?? "",
              name: userData?.iUser != null
                  ? "${userData!.iUser!.otherNames} ${userData.iUser!.lastName}"
                  : userData?.username ?? "",
              token: authData?.tokenAuth.token ?? "",
              role: "officer",
              is_insuree: false,
              is_officer: true,
              refresh: authData?.tokenAuth.refreshExpiresIn.toString() ?? "",
              username: userData?.username ?? "",
              csrfToken: authData?.getCsrfToken.csrfToken ?? "",
              officerInfo: userData?.iUser,
            );
            _getCurrentUser();
            Get.offAllNamed(Routes.ROOT);
          },
          failure: (error) {
            showSnackBarOnFailure(error);
          },
        );
      },
      failure: showSnackBarOnFailure,
    );
  }

  void _saveUserInStorage({
    required String id,
    required String email,
    required String name,
    required String token,
    String? phone,
    String? status,
    String? role,
    bool? is_insuree,
    bool? is_officer,
    String? refresh,
    InsureeInfo? insureeInfo, // Add insureeInfo as an optional parameter
    String? username,
    String? csrfToken,
    UserInfo? officerInfo,
  }) {
    final user = UserEntity(
      id: id,
      email: email,
      name: name,
      token: token,
      role: role,
      refresh: refresh,
      isInsuree: is_insuree,
      isOfficer: is_officer,
      insureeInfo: insureeInfo,
      phoneNumber: phone,
      status: status,
      username: username,
      csrfToken: csrfToken,
      officerInfo: officerInfo != null
          ? OfficerInfo.fromJson(officerInfo.toJson())
          : null,
    );

    storage.write('user', user.toMap());
  }

  void _saveConfigInStorage(
      {String? domainName,
      String? appVersion,
      String? supportEmail,
      String? apiBaseUrl}) async {
    await _authRepository.writeStorage(
      key: 'appconfig',
      entity: AppConfigEntity(
          domainName: domainName,
          appVersion: appVersion,
          apiBaseUrl: apiBaseUrl,
          supportEmail: supportEmail),
    );
  }

  bool validatePasswords() {
    return customerPasswordController.text ==
        customerConfirmPasswordController.text;
  }

  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (!validatePasswords()) {
      return 'Passwords do not match';
    }
    return null; // Return null if validation is successful
  }

  void toggleObscurePassword() {
    _rxIsObscure.value = !isObscure;
  }

  void _clearTextControllers() {
    loginEmailController.clear();
    loginPasswordController.clear();
    customerFullNameController.clear();
    customerPhoneNumberController.clear();
    customerEmailController.clear();
    customerPasswordController.clear();
    companyNameController.clear();
    companyBusinessEmailController.clear();
    companyBusinessNumberController.clear();
    companyCountryController.clear();
    companyAddressController.clear();
    companyPasswordController.clear();
  }

  void onSignUp() {
    popupBottomSheet(
      bottomSheetBody: const ChooseBottomSheetBody(),
      isDismissible: true,
      enableDrag: true,
    );
  }

  void onSelectRegisterType(RegisterType type) {
    if (type != RegisterType.NOTSELECTED) {
      _rxRegisterType.value = type;
      Get.offAllNamed(Routes.REGISTER);
    }
  }

  void showSnackBarOnFailure(String? err) {
    Get.closeAllSnackbars();
    SnackBars.failure("Oops!", err.toString());
  }
}
