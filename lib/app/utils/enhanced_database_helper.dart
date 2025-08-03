import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../data/remote/dto/enrollment/profession_dto.dart';
import '../data/remote/dto/enrollment/education_dto.dart';
import '../data/remote/dto/enrollment/relation_dto.dart';
import '../data/remote/dto/enrollment/family_type_dto.dart';
import '../data/remote/dto/enrollment/confirmation_type_dto.dart';
import '../data/remote/dto/enrollment/location_hierarchy_dto.dart';
import '../data/remote/dto/enrollment/insuree_dto.dart';

class EnhancedDatabaseHelper {
  static final EnhancedDatabaseHelper _instance =
      EnhancedDatabaseHelper._internal();
  factory EnhancedDatabaseHelper() => _instance;

  static Database? _database;

  EnhancedDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'enhanced_enrollment1.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle future migrations
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Reference data tables for caching
    await db.execute('''
      CREATE TABLE professions (
        id INTEGER PRIMARY KEY,
        profession TEXT NOT NULL,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE educations (
        id INTEGER PRIMARY KEY,
        education TEXT NOT NULL,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE relations (
        id INTEGER PRIMARY KEY,
        relation TEXT NOT NULL,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE family_types (
        code TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE confirmation_types (
        code TEXT PRIMARY KEY,
        is_confirmation_number_required INTEGER DEFAULT 0,
        confirmationtype TEXT NOT NULL,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        uuid TEXT,
        code TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        parent_id TEXT,
        full_path TEXT,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(parent_id) REFERENCES locations(id)
      )
    ''');

    // Enhanced family table
    await db.execute('''
      CREATE TABLE families (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        location_id INTEGER,
        poverty INTEGER DEFAULT 0,
        family_type_id TEXT DEFAULT 'H',
        address TEXT,
        confirmation_type_id TEXT DEFAULT 'A',
        confirmation_no TEXT,
        json_ext TEXT DEFAULT '{}',
        sync_status INTEGER DEFAULT 0,
        sync_error TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(family_type_id) REFERENCES family_types(code),
        FOREIGN KEY(confirmation_type_id) REFERENCES confirmation_types(code)
      )
    ''');

    // Enhanced insuree table
    await db.execute('''
      CREATE TABLE insurees (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        chf_id TEXT NOT NULL UNIQUE,
        last_name TEXT NOT NULL,
        other_names TEXT NOT NULL,
        gender_id TEXT NOT NULL,
        dob TEXT NOT NULL,
        head INTEGER DEFAULT 0,
        marital TEXT DEFAULT 'N',
        passport TEXT,
        phone TEXT,
        email TEXT,
        photo_data TEXT,
        photo_officer_id INTEGER,
        photo_date TEXT,
        card_issued INTEGER DEFAULT 1,
        profession_id INTEGER,
        education_id INTEGER,
        type_of_id_id TEXT DEFAULT 'D',
        local_family_id INTEGER,
        remote_family_id INTEGER,
        relationship_id INTEGER,
        status TEXT DEFAULT 'AC',
        json_ext TEXT DEFAULT '{}',
        sync_status INTEGER DEFAULT 0,
        sync_error TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(local_family_id) REFERENCES families(local_id),
        FOREIGN KEY(profession_id) REFERENCES professions(id),
        FOREIGN KEY(education_id) REFERENCES educations(id),
        FOREIGN KEY(relationship_id) REFERENCES relations(id)
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        code TEXT,
        name TEXT NOT NULL,
        lump_sum TEXT,
        premium_adult TEXT,
        age_maximal INTEGER,
        card_replacement_fee TEXT,
        enrolment_period_start_date TEXT,
        enrolment_period_end_date TEXT,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Membership types table
    await db.execute('''
      CREATE TABLE membership_types (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        region TEXT,
        district TEXT,
        level_type TEXT,
        level_index INTEGER,
        price TEXT,
        product_node_id TEXT,
        product_node_name TEXT,
        product_lump_sum TEXT,
        product_premium_adult TEXT,
        product_age_maximal INTEGER,
        product_card_replacement_fee TEXT,
        last_synced TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    // Policies table
    await db.execute('''
      CREATE TABLE policies (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        enroll_date TEXT NOT NULL,
        start_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        value TEXT DEFAULT '0.00',
        product_id INTEGER NOT NULL,
        family_id INTEGER NOT NULL,
        officer_id INTEGER DEFAULT 1,
        uuid TEXT NOT NULL UNIQUE,
        sync_status INTEGER DEFAULT 0,
        remote_policy_id INTEGER,
        sync_error TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Contributions table
    await db.execute('''
      CREATE TABLE contributions (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt TEXT NOT NULL,
        pay_date TEXT NOT NULL,
        pay_type TEXT DEFAULT 'B',
        is_photo_fee INTEGER DEFAULT 0,
        action TEXT DEFAULT 'ENFORCE',
        amount TEXT NOT NULL,
        policy_uuid TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        remote_contribution_id INTEGER,
        sync_error TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(policy_uuid) REFERENCES policies(uuid)
      )
    ''');

    // Sync operations tracking table
    await db.execute('''
      CREATE TABLE sync_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        local_id INTEGER NOT NULL,
        remote_id INTEGER,
        status TEXT DEFAULT 'PENDING',
        error_message TEXT,
        data TEXT,
        attempts INTEGER DEFAULT 0,
        max_attempts INTEGER DEFAULT 3,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes separately
    await db.execute(
        'CREATE INDEX idx_sync_operations_status ON sync_operations(status)');
    await db.execute(
        'CREATE INDEX idx_sync_operations_entity ON sync_operations(entity_type, local_id)');
    await db
        .execute('CREATE INDEX idx_policies_family_id ON policies(family_id)');
    await db.execute(
        'CREATE INDEX idx_contributions_policy_uuid ON contributions(policy_uuid)');
    await db.execute(
        'CREATE INDEX idx_membership_types_product_id ON membership_types(product_id)');
  }

  // Reference data methods
  Future<void> cacheProfessions(List<ProfessionDto> professions) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('professions');
      for (var profession in professions) {
        await txn.insert('professions', {
          'id': profession.id,
          'profession': profession.profession,
          'last_synced': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<ProfessionDto>> getProfessions() async {
    final db = await database;
    final results = await db.query('professions', orderBy: 'profession');
    return results
        .map((map) => ProfessionDto(
              id: map['id'] as int?,
              profession: map['profession'] as String?,
            ))
        .toList();
  }

  Future<void> cacheEducations(List<EducationDto> educations) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('educations');
      for (var education in educations) {
        await txn.insert('educations', {
          'id': education.id,
          'education': education.education,
          'last_synced': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<EducationDto>> getEducations() async {
    final db = await database;
    final results = await db.query('educations', orderBy: 'education');
    return results
        .map((map) => EducationDto(
              id: map['id'] as int?,
              education: map['education'] as String?,
            ))
        .toList();
  }

  Future<void> cacheRelations(List<RelationDto> relations) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('relations');
      for (var relation in relations) {
        await txn.insert('relations', {
          'id': relation.id,
          'relation': relation.relation,
          'last_synced': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<RelationDto>> getRelations() async {
    final db = await database;
    final results = await db.query('relations', orderBy: 'relation');
    return results
        .map((map) => RelationDto(
              id: map['id'] as int?,
              relation: map['relation'] as String?,
            ))
        .toList();
  }

  Future<void> cacheFamilyTypes(List<FamilyTypeDto> familyTypes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('family_types');
      for (var familyType in familyTypes) {
        await txn.insert('family_types', {
          'code': familyType.code,
          'type': familyType.type,
          'last_synced': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<FamilyTypeDto>> getFamilyTypes() async {
    final db = await database;
    final results = await db.query('family_types', orderBy: 'type');
    return results
        .map((map) => FamilyTypeDto(
              code: map['code'] as String?,
              type: map['type'] as String?,
            ))
        .toList();
  }

  Future<void> cacheConfirmationTypes(
      List<ConfirmationTypeDto> confirmationTypes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('confirmation_types');
      for (var confirmationType in confirmationTypes) {
        await txn.insert('confirmation_types', {
          'code': confirmationType.code,
          'confirmationtype': confirmationType.confirmationtype,
          'is_confirmation_number_required':
              confirmationType.isConfirmationNumberRequired == true ? 1 : 0,
          'last_synced': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<ConfirmationTypeDto>> getConfirmationTypes() async {
    final db = await database;
    final results = await db.query('confirmation_types', orderBy: 'code');
    return results
        .map((map) => ConfirmationTypeDto(
              code: map['code'] as String?,
              confirmationtype: map['confirmationtype'] as String?,
              isConfirmationNumberRequired:
                  (map['is_confirmation_number_required'] as int?) == 1,
            ))
        .toList();
  }

  Future<void> cacheLocations(List<FlatLocationDto> locations) async {
    final db = await database;
    print("=== CACHING ${locations.length} LOCATIONS ===");

    await db.transaction((txn) async {
      await txn.delete('locations');

      int districtsWithParent = 0;
      int districtsWithoutParent = 0;

      for (var location in locations) {
        if (location.type == 'D') {
          if (location.parentId != null && location.parentId!.isNotEmpty) {
            districtsWithParent++;
            print(
                "District WITH parent: ${location.name} -> parentId: ${location.parentId}");
          } else {
            districtsWithoutParent++;
            print(
                "District WITHOUT parent: ${location.name} -> parentId: ${location.parentId}");
          }
        }

        final insertData = {
          'id': location.id,
          'uuid': location.uuid,
          'code': location.code,
          'name': location.name,
          'type': location.type,
          'full_path': location.fullPath,
          'parent_id': location.parentId,
          'last_synced': DateTime.now().toIso8601String(),
        };

        if (location.type == 'D') {
          print("INSERTING DISTRICT: ${location.name}");
          print("  - ID: ${location.id}");
          print("  - Parent ID: '${location.parentId}'");
          print("  - Insert data parent_id: '${insertData['parent_id']}'");
        }

        await txn.insert('locations', insertData);
      }

      print("Districts with parent: $districtsWithParent");
      print("Districts without parent: $districtsWithoutParent");
    });
  }

  Future<List<FlatLocationDto>> getLocationsByType(String type) async {
    final db = await database;
    final results = await db.query(
      'locations',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name',
    );

    print("=== RETRIEVING LOCATIONS OF TYPE: $type ===");
    print("Found ${results.length} locations");

    final locations = results.map((map) {
      if (type == 'D') {
        print("RAW DB ROW: ${map}");
        print("  - parent_id value: '${map['parent_id']}'");
        print("  - parent_id type: ${map['parent_id'].runtimeType}");
      }
      return FlatLocationDto(
        id: map['id'] as String?,
        uuid: map['uuid'] as String?,
        code: map['code'] as String?,
        name: map['name'] as String?,
        type: map['type'] as String?,
        fullPath: map['full_path'] as String?,
        parentId: map['parent_id'] as String?,
      );
    }).toList();

    if (type == 'D') {
      int withParent = 0;
      int withoutParent = 0;
      for (var loc in locations) {
        if (loc.parentId != null && loc.parentId!.isNotEmpty) {
          withParent++;
        } else {
          withoutParent++;
          print("District retrieved WITHOUT parent: ${loc.name} (${loc.id})");
        }
      }
      print(
          "Retrieved districts: $withParent with parent, $withoutParent without parent");
    }

    return locations;
  }

  // Family and Insuree operations
  Future<int> insertFamily(FamilyDto family) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final familyId = await db.insert('families', {
      'location_id': family.locationId,
      'poverty': family.poverty == true ? 1 : 0,
      'family_type_id': family.familyTypeId,
      'address': family.address,
      'confirmation_type_id': family.confirmationTypeId,
      'confirmation_no': family.confirmationNo,
      'json_ext': family.jsonExt,
      'sync_status': family.syncStatus ?? 0,
      'created_at': now,
      'updated_at': now,
    });

    // Insert head insuree if provided
    if (family.headInsuree != null) {
      family.headInsuree!.localFamilyId = familyId;
      family.headInsuree!.head = true;
      await insertInsuree(family.headInsuree!);
    }

    // Add sync operation
    await _addSyncOperation(
        'CREATE', 'FAMILY', familyId, jsonEncode(family.toJson()));

    return familyId;
  }

  Future<int> insertInsuree(InsureeDto insuree) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final insureeId = await db.insert('insurees', {
      'chf_id': insuree.chfId,
      'last_name': insuree.lastName,
      'other_names': insuree.otherNames,
      'gender_id': insuree.genderId,
      'dob': insuree.dob,
      'head': insuree.head == true ? 1 : 0,
      'marital': insuree.marital,
      'passport': insuree.passport,
      'phone': insuree.phone,
      'email': insuree.email,
      'photo_data': insuree.photo?.photo,
      'photo_officer_id': insuree.photo?.officerId,
      'photo_date': insuree.photo?.date,
      'card_issued': insuree.cardIssued == true ? 1 : 0,
      'profession_id': insuree.professionId,
      'education_id': insuree.educationId,
      'type_of_id_id': insuree.typeOfIdId,
      'local_family_id': insuree.localFamilyId,
      'remote_family_id': insuree.familyId,
      'relationship_id': insuree.relationshipId,
      'status': insuree.status,
      'json_ext': insuree.jsonExt,
      'sync_status': insuree.syncStatus ?? 0,
      'created_at': now,
      'updated_at': now,
    });

    // Add sync operation for non-head insurees (head is synced with family)
    if (insuree.head != true) {
      await _addSyncOperation(
          'CREATE', 'INSUREE', insureeId, jsonEncode(insuree.toJson()));
    }

    return insureeId;
  }

  Future<void> _addSyncOperation(
      String operationType, String entityType, int localId, String data) async {
    final db = await database;
    await db.insert('sync_operations', {
      'operation_type': operationType,
      'entity_type': entityType,
      'local_id': localId,
      'status': 'PENDING',
      'data': data,
      'attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_operations',
      where: 'status = ? AND attempts < max_attempts',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> updateSyncOperationStatus(int operationId, String status,
      {String? errorMessage, int? remoteId}) async {
    final db = await database;
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (errorMessage != null) {
      updates['error_message'] = errorMessage;
      updates['attempts'] = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT attempts FROM sync_operations WHERE id = ?',
              [operationId]))! +
          1;
    }

    if (remoteId != null) {
      updates['remote_id'] = remoteId;
    }

    await db.update(
      'sync_operations',
      updates,
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  Future<List<FamilyDto>> getUnsyncedFamilies() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT f.*, 
             i.local_id as head_local_id, i.chf_id as head_chf_id, 
             i.last_name as head_last_name, i.other_names as head_other_names,
             i.gender_id as head_gender_id, i.dob as head_dob, i.marital as head_marital,
             i.passport as head_passport, i.phone as head_phone, i.email as head_email,
             i.photo_data as head_photo_data, i.photo_officer_id as head_photo_officer_id,
             i.photo_date as head_photo_date, i.card_issued as head_card_issued,
             i.profession_id as head_profession_id, i.education_id as head_education_id,
             i.type_of_id_id as head_type_of_id_id, i.status as head_status,
             i.json_ext as head_json_ext
      FROM families f
      LEFT JOIN insurees i ON f.local_id = i.local_family_id AND i.head = 1
      WHERE f.sync_status = 0
      ORDER BY f.created_at ASC
    ''');

    return results.map((map) {
      final family = FamilyDto(
        localId: map['local_id'] as int?,
        locationId: map['location_id'] as int?,
        poverty: (map['poverty'] as int?) == 1,
        familyTypeId: map['family_type_id'] as String?,
        address: map['address'] as String?,
        confirmationTypeId: map['confirmation_type_id'] as String?,
        confirmationNo: map['confirmation_no'] as String?,
        jsonExt: map['json_ext'] as String?,
        syncStatus: map['sync_status'] as int?,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
      );

      // Add head insuree if exists
      if (map['head_local_id'] != null) {
        family.headInsuree = InsureeDto(
          localId: map['head_local_id'] as int?,
          chfId: map['head_chf_id'] as String?,
          lastName: map['head_last_name'] as String?,
          otherNames: map['head_other_names'] as String?,
          genderId: map['head_gender_id'] as String?,
          dob: map['head_dob'] as String?,
          head: true,
          marital: map['head_marital'] as String?,
          passport: map['head_passport'] as String?,
          phone: map['head_phone'] as String?,
          email: map['head_email'] as String?,
          photo: map['head_photo_data'] != null
              ? PhotoDto(
                  photo: map['head_photo_data'] as String?,
                  officerId: map['head_photo_officer_id'] as int?,
                  date: map['head_photo_date'] as String?,
                )
              : null,
          cardIssued: (map['head_card_issued'] as int?) == 1,
          professionId: map['head_profession_id'] as int?,
          educationId: map['head_education_id'] as int?,
          typeOfIdId: map['head_type_of_id_id'] as String?,
          status: map['head_status'] as String?,
          jsonExt: map['head_json_ext'] as String?,
        );
      }

      return family;
    }).toList();
  }

  Future<List<InsureeDto>> getUnsyncedInsurees() async {
    final db = await database;
    final results = await db.query(
      'insurees',
      where: 'sync_status = 0 AND head = 0',
      orderBy: 'created_at ASC',
    );

    return results
        .map((map) => InsureeDto(
              localId: map['local_id'] as int?,
              chfId: map['chf_id'] as String?,
              lastName: map['last_name'] as String?,
              otherNames: map['other_names'] as String?,
              genderId: map['gender_id'] as String?,
              dob: map['dob'] as String?,
              head: (map['head'] as int?) == 1,
              marital: map['marital'] as String?,
              passport: map['passport'] as String?,
              phone: map['phone'] as String?,
              email: map['email'] as String?,
              photo: map['photo_data'] != null
                  ? PhotoDto(
                      photo: map['photo_data'] as String?,
                      officerId: map['photo_officer_id'] as int?,
                      date: map['photo_date'] as String?,
                    )
                  : null,
              cardIssued: (map['card_issued'] as int?) == 1,
              professionId: map['profession_id'] as int?,
              educationId: map['education_id'] as int?,
              typeOfIdId: map['type_of_id_id'] as String?,
              localFamilyId: map['local_family_id'] as int?,
              familyId: map['remote_family_id'] as int?,
              relationshipId: map['relationship_id'] as int?,
              status: map['status'] as String?,
              jsonExt: map['json_ext'] as String?,
              syncStatus: map['sync_status'] as int?,
              createdAt: map['created_at'] as String?,
              updatedAt: map['updated_at'] as String?,
            ))
        .toList();
  }

  Future<void> updateFamilySyncStatus(int localId, int syncStatus,
      {int? remoteFamilyId, String? syncError}) async {
    final db = await database;
    final updates = <String, dynamic>{
      'sync_status': syncStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (remoteFamilyId != null) {
      updates['remote_id'] = remoteFamilyId;
    }

    if (syncError != null) {
      updates['sync_error'] = syncError;
    }

    await db.update(
      'families',
      updates,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> updateInsureeSyncStatus(int localId, int syncStatus,
      {String? remoteId, String? syncError}) async {
    final db = await database;
    final updates = <String, dynamic>{
      'sync_status': syncStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (remoteId != null) {
      updates['remote_id'] = remoteId;
    }

    if (syncError != null) {
      updates['sync_error'] = syncError;
    }

    await db.update(
      'insurees',
      updates,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  // Clear all reference data (for manual refresh)
  Future<void> clearAllReferenceData() async {
    final db = await database;

    await db.delete('professions');
    await db.delete('educations');
    await db.delete('relations');
    await db.delete('family_types');
    await db.delete('confirmation_types');
    await db.delete('locations');
  }

  // Check if reference data needs sync (can be enhanced with timestamp logic)
  Future<bool> needsReferenceDataSync() async {
    final db = await database;

    // Simple check: if any reference table is empty, we need sync
    final professionsCount =
        await db.query('professions').then((rows) => rows.length);
    final educationsCount =
        await db.query('educations').then((rows) => rows.length);
    final relationsCount =
        await db.query('relations').then((rows) => rows.length);
    final familyTypesCount =
        await db.query('family_types').then((rows) => rows.length);
    final confirmationTypesCount =
        await db.query('confirmation_types').then((rows) => rows.length);
    final locationsCount =
        await db.query('locations').then((rows) => rows.length);
    final productsCount =
        await db.query('products').then((rows) => rows.length);
    return professionsCount == 0 ||
        educationsCount == 0 ||
        relationsCount == 0 ||
        familyTypesCount == 0 ||
        confirmationTypesCount == 0 ||
        locationsCount == 0 ||
        productsCount == 0;
  }

  Future<Map<String, int>> getSyncStats() async {
    final db = await database;

    final familyStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN sync_status = 0 THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN sync_status = 1 THEN 1 ELSE 0 END) as synced,
        SUM(CASE WHEN sync_status = 2 THEN 1 ELSE 0 END) as failed
      FROM families
    ''');

    final insureeStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN sync_status = 0 THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN sync_status = 1 THEN 1 ELSE 0 END) as synced,
        SUM(CASE WHEN sync_status = 2 THEN 1 ELSE 0 END) as failed
      FROM insurees
      WHERE head = 0
    ''');

    return {
      'families_total': familyStats.first['total'] as int,
      'families_pending': familyStats.first['pending'] as int,
      'families_synced': familyStats.first['synced'] as int,
      'families_failed': familyStats.first['failed'] as int,
      'insurees_total': insureeStats.first['total'] as int,
      'insurees_pending': insureeStats.first['pending'] as int,
      'insurees_synced': insureeStats.first['synced'] as int,
      'insurees_failed': insureeStats.first['failed'] as int,
    };
  }
}
