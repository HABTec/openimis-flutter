import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../../../data/remote/api/dio_client.dart';
import '../../../di/locator.dart';
import '../../../utils/database_helper.dart';
import '../../../utils/enhanced_database_helper.dart';
import '../../../utils/public_database_helper.dart';

class SettingsController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Form controllers
  final baseUrlController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observable variables
  var isLoading = false.obs;
  var baseUrl = ''.obs;
  var isDumpingDb = false.obs;

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
      'url': 'https://cbhi.habtechsolution.com',
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

  /// Generate and export database dump
  Future<void> exportDatabaseDump() async {
    try {
      isDumpingDb.value = true;

      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission Denied',
            'Storage permission is required to export database dump',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      Get.snackbar(
        'Generating Dump',
        'Please wait while we generate the database dump...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Generate comprehensive database dump
      final dumpData = await _generateDatabaseDump();

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'openimis_db_dump_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonEncode(dumpData));

      Get.snackbar(
        'Dump Generated',
        'Database dump saved as $fileName',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OpenIMIS Database Dump - $timestamp',
        subject: 'Database Dump Export',
      );
    } catch (e) {
      print('Error exporting database dump: $e');
      Get.snackbar(
        'Export Failed',
        'Failed to export database dump: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      isDumpingDb.value = false;
    }
  }

  /// Generate comprehensive database dump
  Future<Map<String, dynamic>> _generateDatabaseDump() async {
    final dumpData = <String, dynamic>{
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': appInfo,
        'base_url': currentBaseUrl,
        'device_info': await _getDeviceInfo(),
      },
      'databases': {},
    };

    try {
      // Dump main enrollment database
      final mainDbHelper = DatabaseHelper();
      final mainDb = await mainDbHelper.database;
      dumpData['databases']['main_enrollment'] = await _dumpDatabase(
        mainDb,
        'family_enrollment.db',
        ['family', 'members', 'contribution_config'],
      );
    } catch (e) {
      print('Error dumping main database: $e');
      dumpData['databases']['main_enrollment'] = {'error': e.toString()};
    }

    try {
      // Dump enhanced enrollment database
      final enhancedDbHelper = EnhancedDatabaseHelper();
      final enhancedDb = await enhancedDbHelper.database;
      dumpData['databases']['enhanced_enrollment'] = await _dumpDatabase(
        enhancedDb,
        'enhanced_enrollment1.db',
        [
          'professions',
          'educations',
          'relations',
          'family_types',
          'confirmation_types',
          'locations',
          'families',
          'insurees',
          'products',
          'membership_types',
          'policies'
        ],
      );
    } catch (e) {
      print('Error dumping enhanced database: $e');
      dumpData['databases']['enhanced_enrollment'] = {'error': e.toString()};
    }

    try {
      // Dump public enrollment database
      final publicDbHelper = PublicDatabaseHelper();
      final publicDb = await publicDbHelper.database;
      dumpData['databases']['public_enrollment'] = await _dumpDatabase(
        publicDb,
        'public_enrollment.db',
        ['family', 'members'],
      );
    } catch (e) {
      print('Error dumping public database: $e');
      dumpData['databases']['public_enrollment'] = {'error': e.toString()};
    }

    // Add storage data
    try {
      dumpData['storage'] = await _dumpStorageData();
    } catch (e) {
      print('Error dumping storage data: $e');
      dumpData['storage'] = {'error': e.toString()};
    }

    return dumpData;
  }

  /// Dump specific database tables
  Future<Map<String, dynamic>> _dumpDatabase(
    Database db,
    String dbName,
    List<String> tableNames,
  ) async {
    final dbDump = <String, dynamic>{
      'database_name': dbName,
      'tables': {},
      'metadata': {
        'version': await db.getVersion(),
        'path': db.path,
        'export_time': DateTime.now().toIso8601String(),
      },
    };

    for (final tableName in tableNames) {
      try {
        // Check if table exists
        final tableInfo = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
        );

        if (tableInfo.isEmpty) {
          dbDump['tables'][tableName] = {
            'error': 'Table does not exist',
            'data': [],
            'count': 0,
          };
          continue;
        }

        // Get table schema
        final schema = await db.rawQuery('PRAGMA table_info($tableName)');

        // Get table data
        final data = await db.query(tableName);

        // Get table statistics
        final count =
            await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        final rowCount = count.first['count'] as int;

        dbDump['tables'][tableName] = {
          'schema': schema,
          'data': data,
          'count': rowCount,
          'export_time': DateTime.now().toIso8601String(),
        };

        print('Dumped table $tableName: $rowCount rows');
      } catch (e) {
        print('Error dumping table $tableName: $e');
        dbDump['tables'][tableName] = {
          'error': e.toString(),
          'data': [],
          'count': 0,
        };
      }
    }

    return dbDump;
  }

  /// Dump GetStorage data
  Future<Map<String, dynamic>> _dumpStorageData() async {
    final storageData = <String, dynamic>{};

    // Common storage keys to dump
    final keysToCheck = [
      'baseUrl',
      'token',
      'user_data',
      'last_sync',
      'config_last_sync',
      'app_config',
      'language',
      'theme',
      'offline_mode',
    ];

    for (final key in keysToCheck) {
      try {
        final value = _storage.read(key);
        if (value != null) {
          storageData[key] = value;
        }
      } catch (e) {
        storageData[key] = {'error': e.toString()};
      }
    }

    // Get all storage keys
    try {
      final allKeys = _storage.getKeys();
      storageData['_all_keys'] = allKeys.toList();
    } catch (e) {
      storageData['_all_keys'] = {'error': e.toString()};
    }

    return storageData;
  }

  /// Get basic device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
      'environment':
          Platform.environment.keys.take(5).toList(), // Limited for privacy
    };
  }

  /// Get database statistics for display
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final stats = <String, dynamic>{};

    try {
      final mainDbHelper = DatabaseHelper();
      final mainDb = await mainDbHelper.database;

      final familyCount =
          await mainDb.rawQuery('SELECT COUNT(*) as count FROM family');
      final memberCount =
          await mainDb.rawQuery('SELECT COUNT(*) as count FROM members');

      stats['main_database'] = {
        'families': familyCount.first['count'],
        'members': memberCount.first['count'],
        'path': mainDb.path,
      };
    } catch (e) {
      stats['main_database'] = {'error': e.toString()};
    }

    try {
      final enhancedDbHelper = EnhancedDatabaseHelper();
      final enhancedDb = await enhancedDbHelper.database;

      final enhancedFamilyCount =
          await enhancedDb.rawQuery('SELECT COUNT(*) as count FROM families');
      final enhancedInsureeCount =
          await enhancedDb.rawQuery('SELECT COUNT(*) as count FROM insurees');

      stats['enhanced_database'] = {
        'families': enhancedFamilyCount.first['count'],
        'insurees': enhancedInsureeCount.first['count'],
        'path': enhancedDb.path,
      };
    } catch (e) {
      stats['enhanced_database'] = {'error': e.toString()};
    }

    return stats;
  }
}
