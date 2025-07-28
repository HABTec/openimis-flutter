import 'package:get/get.dart';
import '../controller/enhanced_enrollment_controller.dart';
import '../controllers/sync_status_controller.dart';

class EnhancedEnrollmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EnhancedEnrollmentController>(
        () => EnhancedEnrollmentController());
    Get.lazyPut<SyncStatusController>(() => SyncStatusController());
  }
}
