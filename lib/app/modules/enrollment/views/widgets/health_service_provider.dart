import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/enrollment_controller.dart';

class HealthServiceProviderDropdown extends StatelessWidget {
  const HealthServiceProviderDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EnrollmentController controller = Get.put(EnrollmentController());

    return Obx(
      () => controller.hospitalState.when(
        idle: () => Container(),
        loading: () => const Center(child: CircularProgressIndicator()),
        success: (hospitals) => hospitals == null || hospitals.isEmpty
            ? Container()
            : DropdownButtonFormField<String>(
                value: controller.selectedHealthFacility.value.isEmpty
                    ? null
                    : controller.selectedHealthFacility.value,
                onChanged: (newValue) {
                  controller.selectedHealthFacility.value = newValue!;
                  // Handle the selected value
                  debugPrint('Selected hospital: $newValue');
                },
                decoration: const InputDecoration(
                  labelText: 'First Service Point',
                  border: OutlineInputBorder(),
                ),
                items: hospitals.map<DropdownMenuItem<String>>((hospital) {
                  return DropdownMenuItem<String>(
                    value: hospital.id.toString(), // Ensure unique values
                    child: Text(hospital.name ?? 'No Name'),
                  );
                }).toList(),
              ),
        failure: (error) => Center(
          child: Text(error ?? 'An error occurred'),
        ),
      ),
    );
  }
}
