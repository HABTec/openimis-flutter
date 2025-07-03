import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../data/local/services/contribution_config_service.dart';
import '../modules/auth/controllers/auth_controller.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'family_enrollment.db');
    return await openDatabase(
      path,
      version: 5, // Update version to trigger migrations
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToVersion2(db);
        }
        if (oldVersion < 5) {
          await _migrateToVersion5(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Create family table
    await db.execute('''
      CREATE TABLE family (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chfid TEXT NOT NULL UNIQUE,
        json_content TEXT,
        photo TEXT,
        sync INTEGER DEFAULT 0,
        membership_type TEXT DEFAULT 'Paying',
        membership_level TEXT DEFAULT 'Level 1',
        area_type TEXT DEFAULT 'Rural',
        calculated_contribution REAL DEFAULT 0.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create members table
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chfid TEXT NOT NULL UNIQUE,  -- Each member has a unique CHFID
        name TEXT NOT NULL,
        head INTEGER DEFAULT 0,      -- 1 for head, 0 for other members
        json_content TEXT,
        photo TEXT,
        sync INTEGER DEFAULT 0,
        family_id INTEGER,           -- Foreign key to link to the family
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(family_id) REFERENCES family(id) ON DELETE CASCADE
      );
    ''');

    // Create contribution config table
    await ContributionConfigService.createTable(db);
  }

  Future<void> _migrateToVersion2(Database db) async {
    // Example migration steps if needed for version upgrade
  }

  Future<void> _migrateToVersion5(Database db) async {
    // Add new columns to family table
    try {
      await db.execute('ALTER TABLE family ADD COLUMN membership_type TEXT DEFAULT "Paying"');
      await db.execute('ALTER TABLE family ADD COLUMN membership_level TEXT DEFAULT "Level 1"');
      await db.execute('ALTER TABLE family ADD COLUMN area_type TEXT DEFAULT "Rural"');
      await db.execute('ALTER TABLE family ADD COLUMN calculated_contribution REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE family ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP');
      await db.execute('ALTER TABLE family ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP');
    } catch (e) {
      // Columns might already exist
      print('Migration note: $e');
    }

    try {
      await db.execute('ALTER TABLE members ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP');
    } catch (e) {
      print('Migration note: $e');
    }

    // Create contribution config table
    await ContributionConfigService.createTable(db);
  }

  // Insert family and head member with enhanced data
  Future<int> insertFamilyAndHeadMember(
      String chfid, 
      Map<String, dynamic> familyDetails, 
      String headName, 
      String photoPath,
      {String membershipType = 'Paying',
      String membershipLevel = 'Level 1',
      String areaType = 'Rural',
      double calculatedContribution = 0.0}) async {
    final db = await database;

    // Family data
    String familyJsonContent = jsonEncode(familyDetails);
    int familyId = 0;

    await db.transaction((txn) async {
      // Insert into family table
      familyId = await txn.insert('family', {
        'chfid': chfid,
        'json_content': familyJsonContent,
        'photo': photoPath,
        'sync': 0,
        'membership_type': membershipType,
        'membership_level': membershipLevel,
        'area_type': areaType,
        'calculated_contribution': calculatedContribution,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert head member into members table
      await txn.insert('members', {
        'chfid': chfid,
        'name': headName,
        'head': 1,
        'json_content': familyJsonContent,
        'photo': photoPath,
        'sync': 0,
        'family_id': familyId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    return familyId;
  }

  // Insert additional family members
  Future<void> insertFamilyMember(
      String familyChfid, String memberName, Map<String, dynamic> memberDetails, String photoPath, int familyId) async {
    final db = await database;

    String memberJsonContent = jsonEncode(memberDetails);

    await db.insert('members', {
      'chfid': memberDetails['chfid'] ?? _generateChfid(),
      'name': memberName,
      'head': 0,
      'json_content': memberJsonContent,
      'photo': photoPath,
      'sync': 0,
      'family_id': familyId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _generateChfid() {
    return 'CHF${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  // Update family contribution
  Future<void> updateFamilyContribution(int familyId, double contribution) async {
    final db = await database;
    await db.update(
      'family',
      {
        'calculated_contribution': contribution,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [familyId],
    );
  }

  // Update family enrollment details
  Future<void> updateFamilyDetails(int familyId, {
    String? membershipType,
    String? membershipLevel,
    String? areaType,
    double? calculatedContribution,
  }) async {
    final db = await database;
    
    Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (membershipType != null) updates['membership_type'] = membershipType;
    if (membershipLevel != null) updates['membership_level'] = membershipLevel;
    if (areaType != null) updates['area_type'] = areaType;
    if (calculatedContribution != null) updates['calculated_contribution'] = calculatedContribution;
    
    await db.update(
      'family',
      updates,
      where: 'id = ?',
      whereArgs: [familyId],
    );
  }

  // Retrieve all family records
  Future<List<Map<String, dynamic>>> retrieveAllFamilies() async {
    final db = await database;
    return await db.query('family');
  }

  // Retrieve members for a specific family by chfid
  Future<List<Map<String, dynamic>>> retrieveFamilyMembers(String chfid) async {
    final db = await database;
    return await db.query('members', where: 'chfid = ?', whereArgs: [chfid]);
  }


  Future<List<Map<String, dynamic>>> getAllFamiliesWithMembers() async {
    final db = await database;

    // Query all families
    final List<Map<String, dynamic>> families = await db.query('family');

    List<Map<String, dynamic>> allData = [];

    for (var family in families) {
      // Get the family members associated with this family
      final List<Map<String, dynamic>> members = await db.query(
        'members',
        where: 'chfid = ?',
        whereArgs: [family['chfid']],
      );

      // Add family and its members to the result
      allData.add({
        'family': family,
        'members': members,
      });
    }

    return allData;
  }


  Future<Map<String, dynamic>?> getFamilyAndMembers(int familyId) async {
    final db = await database; // Access the database instance

    // Retrieve family data by family id
    final List<Map<String, dynamic>> familyResult = await db.query(
      'family', // Query the 'family' table
      where: 'id = ?', // Query by 'id'
      whereArgs: [familyId],
    );

    if (familyResult.isEmpty) {
      // If no family found, return null
      return null;
    }

    // Retrieve chfid from familyResult
    //final String chfid = familyResult.first['chfid'];

    // Retrieve members related to the family using the chfid
    final List<Map<String, dynamic>> membersResult = await db.query(
      'members', // Query the 'members' table
      where: 'family_id = ?', // Use chfid to get related members
      whereArgs: [familyId],
    );

    // Prepare the result with family and members
    Map<String, dynamic> result = {
      'family': familyResult.first, // There should only be one family per id
      'members': membersResult, // List of members related to the family
    };

    return result;
  }



  // Retrieve a specific enrollment (family) by ID
  Future<Map<String, dynamic>?> getFamilyById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('family', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Retrieve a specific family member by ID
  Future<Map<String, dynamic>?> getMemberById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('members', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Delete a family and its members by chfid
  Future<int> deleteFamily(int familyid) async {
    final db = await database;
    // SQLite foreign key constraint will handle members deletion
    return await db.delete('family', where: 'id = ?', whereArgs: [familyid]);

  }

  // Delete a member by ID
  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // Update sync status for a family and its members
  Future<void> updateSyncStatus(String chfid) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('family', {'sync': 1}, where: 'chfid = ?', whereArgs: [chfid]);
      await txn.update('members', {'sync': 1}, where: 'chfid = ?', whereArgs: [chfid]);
    });
  }

  // Generate unique CHFID with auto-increment and user ID
  Future<String> generateUniqueChfid() async {
    final db = await database;
    
    // Get the current max ID from the family table
    final result = await db.rawQuery('SELECT MAX(id) as maxId FROM family');
    final maxId = (result.first['maxId'] as int?) ?? 0;
    final nextId = maxId + 1;
    
    // Get current user ID from AuthController
    final userId = AuthController.to.currentUser?.id ?? 'unknown';
    
    // Format: 00001-userid
    final chfid = '${nextId.toString().padLeft(5, '0')}-$userId';
    
    return chfid;
  }
}
