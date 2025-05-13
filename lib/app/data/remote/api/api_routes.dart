import 'dart:io'; // Import to check platform
import 'package:get_storage/get_storage.dart';

class ApiRoutes {
  static final GetStorage _storage = GetStorage();
  static String get BASE_URL {
    return _storage.read('baseUrl') ??
        (Platform.isAndroid
            ? "http://192.168.1.6:8000"
            : "http://192.168.1.6:8000");
  }

  // static final BASE_URL = Platform.isAndroid ? "https://imisbeta.hib.gov.np" : "https://imisbeta.hib.gov.np";
  static const _API = "/api/membership";
  static const APP_CONFIG = "$_API/config";
  static const ENROLLMENT = "$_API/enrollment/";
  static const LOCATIONS = "$_API/locations/";
  static const HOSPITALS = "$_API/hospitals";
  static const MEMBERSHIP_CARD = "$_API/membership/card/";
  static const SEARCH = "$_API/insuree-information/";
  static const LOGIN = "$_API/login";
  static const CUSTOMERS = "$_API/profile";
  static const TOGGLE_SAVE = "$CUSTOMERS/save/";
  static const INSUREE_VALIDATION = "$_API/register/";
  static const INSUREE_OTP_VALIDATION = "$_API/validate-otp/";
  static const INSUREE_OTP_RESEND = "$_API/resend-otp/";
  static const NOTICES = "$_API/notices";
  static const CLAIMS = "$_API/claims/";
  static const PROFILE = "$_API/fhir-patient/";
  static const USERNAME_VERIFY = "$_API/check-username/";
  static const CLAIMSERVITEMS = "$_API/claimed-item-services/";

  static const NATIONAL_ID = "$_API/nationalId/";
  static const DEVICE_TOKEN = "$_API/save_fcm_token/";
  //** payment route **//

  static const ACCESS_TOKEN = "$_API/access-token/";
  static const CREATE_PAYMENT = "$_API/create-payment/";
  static const EXECUTE_PAYMENT = "$_API/execute-payment/";
  static const PAYMENT_COMPLETE = "$_API/payment/complete/";
}
