import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/remote/base/status.dart';
import '../../../data/remote/dto/company/company_out_dto.dart';
import '../../../data/remote/dto/enrollment/enrollment_in_dto.dart';
import '../../../data/remote/repositories/company/company_repository.dart';
import '../../../di/locator.dart';
import '../../../widgets/dialogs.dart';

class CompanyProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final _companyRepository = getIt.get<CompanyRepository>();
  final String uuid = Get.arguments;
  late TabController tabController;

  final Rx<Status<CompanyOutDto>> _rxCompany =
      Rx<Status<CompanyOutDto>>(const Status.loading());

  Status<CompanyOutDto> get rxCompany => _rxCompany.value;

  final Rx<Status<List<EnrollmentInDto>>> _rxEnrollment =
      Rx<Status<List<EnrollmentInDto>>>(const Status.loading());

  Status<List<EnrollmentInDto>> get rxEnrollments => _rxEnrollment.value;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    loadPage();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getCompany() async {
    Status<CompanyOutDto> state = await _companyRepository.get(uuid: uuid);
    _rxCompany.value = state;
  }

  void loadPage() async {
    await getCompany();

    showDialogOnFailure();
  }

  void onRetry() async {
    _rxCompany.value = const Status.loading();
    await getCompany();
    showDialogOnFailure();
  }

  void showDialogOnFailure() {
    if (rxCompany is Failure) {
      Dialogs.spaceDialog(
        description: (rxCompany as Failure).reason.toString(),
        btnOkOnPress: onRetry,
        dismissOnBackKeyPress: false,
        dismissOnTouchOutside: false,
      );
    }
  }
}
