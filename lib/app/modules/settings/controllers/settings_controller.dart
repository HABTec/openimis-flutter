import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../../../data/remote/api/dio_client.dart';
import '../../../di/locator.dart';

class SettingsController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Form controllers
  final baseUrlController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observable variables
  var isLoading = false.obs;
  var baseUrl = ''.obs;

  // Default URLs for quick selection
  final List<Map<String, String>> predefinedUrls = [
    {
      'name': 'Local Development',
      'url': 'http://127.0.0.1:8000',
    },
    {
      'name': 'Local Network (Android)',
      'url': 'http://192.168.1.6:8000',
    },
    {
      'name': 'Beta Server',
      'url': 'https://imisbeta.hib.gov.np',
    },
    {
      'name': 'Production Server',
      'url': 'https://imis.hib.gov.np',
    },
    {
      'name': 'Ngrok Server',
      'url': 'https://409a1533028d.ngrok-free.app',
    }
  ];

  @override
  void onInit() {
    super.onInit();
    loadCurrentSettings();
  }

  @override
  void onClose() {
    baseUrlController.dispose();
    super.onClose();
  }

  /// Load current settings from storage
  void loadCurrentSettings() {
    final savedUrl = _storage.read('baseUrl') ?? 'http://127.0.0.1:8000';
    baseUrl.value = savedUrl;
    baseUrlController.text = savedUrl;
  }

  /// Save base URL to storage and update API client
  Future<void> saveBaseUrl(String url) async {
    try {
      isLoading.value = true;

      // Validate URL format
      if (!_isValidUrl(url)) {
        Get.snackbar(
          'Invalid URL',
          'Please enter a valid URL (e.g., http://example.com)',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Save to storage
      await _storage.write('baseUrl', url);
      baseUrl.value = url;

      // Update the API client
      final dioClient = getIt.get<DioClient>();
      dioClient.updateBaseUrl(url);

      Get.snackbar(
        'Settings Saved',
        'Base URL updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Test connection to the current base URL
  Future<void> testConnection() async {
    try {
      isLoading.value = true;

      final testUrl = baseUrlController.text.trim();
      if (testUrl.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter a base URL first',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Simple connectivity test
      final dioClient = getIt.get<DioClient>();

      // Temporarily update base URL for testing
      final originalUrl = baseUrl.value;
      dioClient.updateBaseUrl(testUrl);

      try {
        // Test with a simple endpoint (you can adjust this)
        await dioClient.get('/api/health-check',
            options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ));

        Get.snackbar(
          'Connection Successful',
          'Successfully connected to $testUrl',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        // Check if it's a 404 error - which is expected and means server is reachable
        if (e is DioError && e.response?.statusCode == 404) {
          Get.snackbar(
            'Connection Successful',
            'Successfully connected to $testUrl (404 is expected)',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Restore original URL on failure
          dioClient.updateBaseUrl(originalUrl);

          Get.snackbar(
            'Connection Failed',
            'Could not connect to $testUrl\nError: ${e.toString()}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Test Failed',
        'Error testing connection: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      isLoading.value = true;

      const defaultUrl = 'http://127.0.0.1:8000';

      await _storage.write('baseUrl', defaultUrl);
      baseUrl.value = defaultUrl;
      baseUrlController.text = defaultUrl;

      // Update the API client
      final dioClient = getIt.get<DioClient>();
      dioClient.updateBaseUrl(defaultUrl);

      Get.snackbar(
        'Settings Reset',
        'Settings reset to default values',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Quick select a predefined URL
  void selectPredefinedUrl(String url) {
    baseUrlController.text = url;
  }

  /// Clear all app data (settings, cache, etc.)
  Future<void> clearAppData() async {
    try {
      isLoading.value = true;

      await _storage.erase();
      loadCurrentSettings(); // This will load defaults

      Get.snackbar(
        'Data Cleared',
        'All app data has been cleared',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear app data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Get app version and build info
  String get appInfo => 'OpenIMIS Enrollment v1.0.0';

  /// Get current base URL for display
  String get currentBaseUrl => baseUrl.value;
}
