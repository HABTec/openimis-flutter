import 'package:get/get.dart';
import 'package:openimis_app/app/modules/root/views/widgets/notices.dart';

import '../modules/Insuree/views/insuree_profile.dart';
import '../modules/Insuree/views/insuree_profile_details.dart';
import '../modules/Insuree/views/profile_body.dart';
import '../modules/Organization/bindings/company_profile_binding.dart';
import '../modules/Organization/views/company_profile_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login/login_view.dart';
import '../modules/auth/views/register/register_view.dart';

import '../modules/Insuree/bindings/customer_profile_binding.dart';
import '../modules/enrollment/bindings/enrollment_binding.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/enrollment/views/enrollment_view.dart';
import '../modules/enrollment/views/enrollment_list_view.dart';
import '../modules/public_enrollment/views/public_enrollment_view.dart';
import '../modules/root/bindings/root_binding.dart';
import '../modules/root/views/root_view.dart';
import '../modules/root/views/widgets/partners.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/waiting/bindings/waiting_binding.dart';
import '../modules/waiting/views/waiting_view.dart';
import '../modules/auth/views/register/widgets/otp_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.OTP,
      page: () => OtpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.WAITTING,
      page: () => const WaitingView(),
      binding: WaitingBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.COMPANY_PROFILE,
      page: () => const CompanyProfileView(),
      binding: CompanyProfileBinding(),
    ),
    GetPage(
      name: _Paths.ROOT,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    GetPage(
      name: _Paths.ENROLLMENT,
      page: () => const EnrollmentView(),
      binding: EnrollmentBindings(),
    ),
    GetPage(
      name: _Paths.ENROLLMENT_LIST,
      page: () => const EnrollmentListView(),
      binding: EnrollmentBindings(),
    ),
    GetPage(
      name: _Paths.PARTNERS,
      page: () => PartnersPage(),
    ),
    GetPage(
      name: _Paths.NOTICES,
      page: () => NoticesPage(),
    ),
    GetPage(
      name: _Paths.PUBLIC_ENROLLMENT,
      page: () => PublicEnrollmentView(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileView(),
      binding: CustomerProfileBinding(),
    ),
  ];
}
