import 'package:sqflite/sqflite.dart';
import 'package:get_storage/get_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../entities/contribution_config_entity.dart';
import '../../../utils/database_helper.dart';

class ContributionConfigService {
  static final ContributionConfigService _instance = ContributionConfigService._internal();
  factory ContributionConfigService() => _instance;
  ContributionConfigService._internal();

  final GetStorage _storage = GetStorage();

  // Create contribution config table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contribution_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        membership_level TEXT NOT NULL,
        membership_type TEXT NOT NULL,
        area_type TEXT NOT NULL,
        base_rate REAL NOT NULL,
        per_member_rate REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'ETB',
        last_updated TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        UNIQUE(membership_level, membership_type, area_type)
      )
    ''');
  }

  // Fetch configuration from backend when online
  Future<bool> syncConfigFromBackend() async {
    try {
      // Check connectivity
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print('No internet connection available for config sync');
        return false;
      }

      // Mock API response - in real implementation, replace with actual API call
      final mockConfigData = await _getMockConfigData();
      
      // Store in local database
      await _storeConfigLocally(mockConfigData);
      
      // Update last sync time
      await _storage.write('config_last_sync', DateTime.now().toIso8601String());
      
      return true;
    } catch (e) {
      print('Error syncing config from backend: $e');
      return false;
    }
  }

  // Mock configuration data - replace with actual API call
  Future<List<ContributionConfigEntity>> _getMockConfigData() async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));
    
    return [
      // Paying - Rural
      ContributionConfigEntity(
        membershipLevel: 'Level 1',
        membershipType: 'Paying',
        areaType: 'Rural',
        baseRate: 720.0,
        perMemberRate: 24.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 2',
        membershipType: 'Paying',
        areaType: 'Rural',
        baseRate: 1260.0,
        perMemberRate: 46.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 3',
        membershipType: 'Paying',
        areaType: 'Rural',
        baseRate: 1710.0,
        perMemberRate: 30.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      
      // Paying - City
      ContributionConfigEntity(
        membershipLevel: 'Level 1',
        membershipType: 'Paying',
        areaType: 'City',
        baseRate: 720.0,
        perMemberRate: 16.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 2',
        membershipType: 'Paying',
        areaType: 'City',
        baseRate: 1310.0,
        perMemberRate: 64.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 3',
        membershipType: 'Paying',
        areaType: 'City',
        baseRate: 1930.0,
        perMemberRate: 20.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      
      // Indigent - Rural (typically lower rates)
      ContributionConfigEntity(
        membershipLevel: 'Level 1',
        membershipType: 'Indigent',
        areaType: 'Rural',
        baseRate: 360.0,
        perMemberRate: 12.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 2',
        membershipType: 'Indigent',
        areaType: 'Rural',
        baseRate: 630.0,
        perMemberRate: 23.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 3',
        membershipType: 'Indigent',
        areaType: 'Rural',
        baseRate: 855.0,
        perMemberRate: 15.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      
      // Indigent - City
      ContributionConfigEntity(
        membershipLevel: 'Level 1',
        membershipType: 'Indigent',
        areaType: 'City',
        baseRate: 360.0,
        perMemberRate: 8.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 2',
        membershipType: 'Indigent',
        areaType: 'City',
        baseRate: 655.0,
        perMemberRate: 32.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
      ContributionConfigEntity(
        membershipLevel: 'Level 3',
        membershipType: 'Indigent',
        areaType: 'City',
        baseRate: 965.0,
        perMemberRate: 10.0,
        currency: 'ETB',
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  // Store configuration data locally
  Future<void> _storeConfigLocally(List<ContributionConfigEntity> configs) async {
    final db = await DatabaseHelper().database;
    
    // Clear existing config data
    await db.delete('contribution_config');
    
    // Insert new config data
    for (final config in configs) {
      await db.insert(
        'contribution_config',
        config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Get configuration for specific criteria
  Future<ContributionConfigEntity?> getConfig({
    required String membershipLevel,
    required String membershipType,
    required String areaType,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.query(
        'contribution_config',
        where: 'membership_level = ? AND membership_type = ? AND area_type = ? AND is_active = 1',
        whereArgs: [membershipLevel, membershipType, areaType],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return ContributionConfigEntity.fromMap(result.first);
      }
      
      return null;
    } catch (e) {
      print('Error getting config: $e');
      return null;
    }
  }

  // Calculate total contribution
  Future<double> calculateContribution({
    required String membershipLevel,
    required String membershipType,
    required String areaType,
    required int numberOfMembers,
  }) async {
    try {
      final config = await getConfig(
        membershipLevel: membershipLevel,
        membershipType: membershipType,
        areaType: areaType,
      );
      
      if (config == null) {
        // Fallback to default calculation if no config found
        return _getDefaultContribution(membershipLevel, membershipType, numberOfMembers);
      }
      
      // Calculate: base rate + (per member rate * number of members)
      return config.baseRate + (config.perMemberRate * numberOfMembers);
    } catch (e) {
      print('Error calculating contribution: $e');
      return _getDefaultContribution(membershipLevel, membershipType, numberOfMembers);
    }
  }

  // Default fallback calculation
  double _getDefaultContribution(String membershipLevel, String membershipType, int numberOfMembers) {
    double baseRate = 0.0;
    switch (membershipLevel) {
      case 'Level 1':
        baseRate = membershipType == 'Paying' ? 100.0 : 50.0;
        break;
      case 'Level 2':
        baseRate = membershipType == 'Paying' ? 150.0 : 75.0;
        break;
      case 'Level 3':
        baseRate = membershipType == 'Paying' ? 200.0 : 100.0;
        break;
    }
    return baseRate * numberOfMembers;
  }

  // Check if config needs updating (older than 24 hours)
  Future<bool> shouldSyncConfig() async {
    try {
      final lastSync = await _storage.read('config_last_sync') as String?;
      if (lastSync == null) return true;
      
      final lastSyncDate = DateTime.parse(lastSync);
      final hoursSinceSync = DateTime.now().difference(lastSyncDate).inHours;
      
      return hoursSinceSync >= 24;
    } catch (e) {
      return true; // Force sync on error
    }
  }

  // Get all available configurations
  Future<List<ContributionConfigEntity>> getAllConfigs() async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.query(
        'contribution_config',
        where: 'is_active = 1',
        orderBy: 'membership_level, membership_type, area_type',
      );
      
      return result.map((e) => ContributionConfigEntity.fromMap(e)).toList();
    } catch (e) {
      print('Error getting all configs: $e');
      return [];
    }
  }
} 