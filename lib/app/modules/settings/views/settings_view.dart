import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openimis_app/app/data/remote/api/dio_client.dart';
import 'package:openimis_app/app/di/locator.dart';

class SettingsController extends GetxController {
  final GetStorage _storage = GetStorage();
  final RxString baseUrl = ''.obs;
  final DioClient _dioClient = getIt<DioClient>();

  @override
  void onInit() {
    super.onInit();
    baseUrl.value = _storage.read('baseUrl') ?? 'http://192.168.1.6:8000';
  }

  void saveBaseUrl(String url) {
    baseUrl.value = url;
    _storage.write('baseUrl', url);
    _dioClient.updateBaseUrl(url);
  }
}

class SettingsView extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Base URL'),
              controller: TextEditingController(text: controller.baseUrl.value),
              onChanged: (value) => controller.saveBaseUrl(value),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                controller.saveBaseUrl(controller.baseUrl.value);
                Get.snackbar('Success', 'Base URL updated');
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
