import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openimis_app/app/modules/enrollment/controller/enrollment_controller.dart';
import 'enrollment_form.dart';

class Body extends StatelessWidget {
  final EnrollmentController controller = Get.put(EnrollmentController());

  Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.enrollmentState.when(
        idle: () => EnrollmentForm(),
        loading: () => Scaffold(
          backgroundColor: Color(0xFF036273),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading enrollment form...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        failure: (reason) => Scaffold(
          backgroundColor: Color(0xFF036273),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 20),
                Text(
                  "Error: $reason",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF036273),
                  ),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
        success: (data) => EnrollmentForm(),
      );
    });
  }
}
