import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:openimis_app/app/data/remote/api/dio_client.dart';
import 'package:openimis_app/app/utils/database_helper.dart';
import 'package:openimis_app/app/utils/api_response.dart';
import 'package:openimis_app/app/utils/enhanced_database_helper.dart';
import 'package:openimis_app/app/data/remote/dto/enrollment/family_dto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Added for jsonDecode

class FamilyService {
  final DioClient dioClient;
  final GetStorage _storage = GetStorage();
  final _uuid = const Uuid();

  FamilyService({required this.dioClient});

  /// Convert enrollment form data to GraphQL createFamily input
  Map<String, dynamic> mapEnrollmentToGraphQLInput({
    required String chfId,
    required String lastName,
    required String otherNames,
    required String gender,
    required String dob,
    required String phone,
    required String email,
    required String identificationNo,
    required String maritalStatus,
    String? photoBase64,
    int? locationId,
    bool poverty = false,
    String familyTypeId = 'H',
    String? address,
    String confirmationTypeId = 'C',
    String? confirmationNo,
    int? healthFacilityId,
    int? professionId,
    int? educationId,
    String typeOfIdId = 'N',
    String status = 'AC',
  }) {
    final clientMutationId = _uuid.v4();

    return {
      'clientMutationId': clientMutationId,
      'clientMutationLabel': 'Create family - $lastName $otherNames ($chfId)',
      'headInsuree': {
        'chfId': chfId,
        'lastName': lastName,
        'otherNames': otherNames,
        'genderId': _mapGender(gender),
        'dob': dob,
        'head': true,
        'marital': _mapMaritalStatus(maritalStatus),
        'passport': identificationNo,
        'phone': phone,
        'email': email,
        if (photoBase64 != null)
          'photo': {
            'officerId': 6, // Default officer ID
            'date': DateTime.now().toIso8601String().split('T')[0],
          },
        'cardIssued': true,
        'professionId': professionId ?? 3,
        'educationId': educationId ?? 4,
        'typeOfIdId': typeOfIdId,
        'status': status,
        if (healthFacilityId != null) 'healthFacilityId': healthFacilityId,
      },
      if (locationId != null) 'locationId': locationId,
      'poverty': poverty,
      'familyTypeId': familyTypeId,
      if (address != null) 'address': address,
      'confirmationTypeId': confirmationTypeId,
      if (confirmationNo != null) 'confirmationNo': confirmationNo,
      'jsonExt': '{}',
    };
  }

  /// Create family using GraphQL (online)
  Future<ApiResponse> createFamilyOnline(Map<String, dynamic> input) async {
    const String mutation = '''
      mutation CreateFamily(\$input: CreateFamilyInputType!) {
        createFamily(input: \$input) {
          clientMutationId
          internalId
        }
      }
    ''';

    final data = {
      'query': mutation,
      'variables': {'input': input},
    };

    try {
      final response = await dioClient.post('/api/graphql', data: data);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final createFamilyData = response.data['data']['createFamily'];
        if (createFamilyData != null) {
          return ApiResponse.success(createFamilyData,
              message: "Family created successfully.");
        }
      }

      final errorMessage =
          response.data['errors']?[0]?['message'] ?? 'Unknown error';
      return ApiResponse.failure(errorMessage);
    } on DioError catch (e) {
      if (e.response?.data?['errors'] != null) {
        final errorMessage = e.response!.data['errors'][0]['message'];
        return ApiResponse.failure(errorMessage);
      }
      return ApiResponse.failure(e.message ?? 'Network error');
    }
  }

  /// List families using GraphQL (online)
  Future<ApiResponse> listFamiliesOnline(Map<String, dynamic> filters) async {
    // Build the query dynamically based on filters
    String filterArgs = '';
    if (filters.isNotEmpty) {
      List<String> args = [];
      filters.forEach((key, value) {
        if (value != null) {
          if (value is String) {
            args.add('$key: "$value"');
          } else if (value is List) {
            String listArgs = value.map((item) => '"$item"').join(', ');
            args.add('$key: [$listArgs]');
          } else {
            args.add('$key: $value');
          }
        }
      });
      filterArgs = args.join('\n          ');
    }

    final String query = '''
      query {
        families(
          $filterArgs
        ) {
          totalCount
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
          edges {
            node {
              id
              uuid
              poverty
              confirmationNo
              validityFrom
              validityTo
              headInsuree {
                id
                uuid
                chfId
                lastName
                otherNames
                email
                phone
                dob
                genderId
              }
              location {
                id
                uuid
                code
                name
                type
                parent {
                  id
                  uuid
                  code
                  name
                  type
                  parent {
                    id
                    uuid
                    code
                    name
                    type
                    parent {
                      id
                      uuid
                      code
                      name
                      type
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''';

    final data = {
      'query': query,
      'variables': {},
    };

    try {
      final response = await dioClient.post('/api/graphql', data: data);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final familiesData = response.data['data']['families'];
        return ApiResponse.success(familiesData);
      }

      final errorMessage =
          response.data['errors']?[0]?['message'] ?? 'Unknown error';
      return ApiResponse.failure(errorMessage);
    } on DioError catch (e) {
      if (e.response?.data?['errors'] != null) {
        final errorMessage = e.response!.data['errors'][0]['message'];
        return ApiResponse.failure(errorMessage);
      }
      return ApiResponse.failure(e.message ?? 'Network error');
    }
  }

  /// Store family locally for offline sync
  Future<ApiResponse> storeFamilyOffline(
      Map<String, dynamic> familyData) async {
    try {
      final dbHelper = DatabaseHelper();

      // Add sync metadata
      familyData['syncStatus'] = 0; // 0 = pending sync
      familyData['createdAt'] = DateTime.now().toIso8601String();

      // Store as a complete family with head member
      final headData = familyData['headInsuree'] ?? {};
      final photoPath = ''; // Handle photo separately if needed

      final familyRecord = {
        'chfid': headData['chfId'] ?? '',
        'membershipType': 'Paying',
        'membershipLevel': 'Level 1',
        'areaType': 'Rural',
        'calculatedContribution': 0.0,
        'familyTypeId': familyData['familyTypeId'] ?? 'H',
        'confirmationTypeId': familyData['confirmationTypeId'] ?? 'C',
        'confirmationNo': familyData['confirmationNo'] ?? '',
        'address': familyData['address'] ?? '',
        'poverty': familyData['poverty'] ?? false,
        'locationId': familyData['locationId'],
      };

      final headMemberData = {
        'chfid': headData['chfId'] ?? '',
        'givenName': headData['otherNames'] ?? '',
        'lastName': headData['lastName'] ?? '',
        'gender': headData['genderId'] ?? '',
        'phone': headData['phone'] ?? '',
        'email': headData['email'] ?? '',
        'birthdate': headData['dob'] ?? '',
        'maritalStatus': headData['marital'] ?? '',
        'identificationNo': headData['passport'] ?? '',
      };

      // Store in local database using existing method
      final id = await dbHelper.insertCompleteFamilyWithHead(
        familyRecord,
        headMemberData,
        photoPath,
      );

      return ApiResponse.success({'localId': id},
          message: "Family stored offline. Will sync when online.");
    } catch (e) {
      return ApiResponse.failure("Failed to store family offline: $e");
    }
  }

  /// Create family with offline support
  Future<ApiResponse> createFamilyWithOfflineSupport(
      Map<String, dynamic> input) async {
    if (await _isOnline()) {
      return await createFamilyOnline(input);
    } else {
      return await storeFamilyOffline(input);
    }
  }

  /// Sync pending families when online
  Future<void> syncPendingFamilies() async {
    if (!await _isOnline()) return;

    try {
      final dbHelper = DatabaseHelper();
      final unsyncedData = await dbHelper.getUnsyncedData();

      for (final familyData in unsyncedData) {
        try {
          final family = familyData['family'];
          final members = familyData['members'];

          // Convert local data to GraphQL format
          final headMember = members.firstWhere(
            (member) => member['head'] == 1,
            orElse: () => members.first,
          );

          final headMemberJson = headMember['json_content'] != null
              ? Map<String, dynamic>.from(
                  jsonDecode(headMember['json_content']))
              : {};

          final graphqlInput = mapEnrollmentToGraphQLInput(
            chfId: headMemberJson['chfid'] ?? family['chfid'],
            lastName: headMemberJson['lastName'] ?? '',
            otherNames: headMemberJson['givenName'] ?? '',
            gender: headMemberJson['gender'] ?? 'M',
            dob: headMemberJson['birthdate'] ?? '',
            phone: headMemberJson['phone'] ?? '',
            email: headMemberJson['email'] ?? '',
            identificationNo: headMemberJson['identificationNo'] ?? '',
            maritalStatus: headMemberJson['maritalStatus'] ?? '',
            address: family['json_content'] != null
                ? (jsonDecode(family['json_content'])['address'] ?? '')
                : '',
          );

          final result = await createFamilyOnline(graphqlInput);

          if (!result.error) {
            // Mark as synced using existing method
            await dbHelper.updateSyncStatusWithError(
              family['id'],
              status: 'SYNCED',
            );
          } else {
            // Mark as failed
            await dbHelper.updateSyncStatusWithError(
              family['id'],
              status: 'FAILED',
              errorMessage: result.message,
            );
          }
        } catch (e) {
          // Handle sync error for individual family
          await dbHelper.updateSyncStatusWithError(
            familyData['family']['id'],
            status: 'FAILED',
            errorMessage: e.toString(),
          );
        }
      }
    } catch (e) {
      print('Error syncing pending families: $e');
    }
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to map gender values
  String _mapGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'M';
      case 'female':
        return 'F';
      case 'other':
        return 'O';
      default:
        return gender.isNotEmpty ? gender[0].toUpperCase() : 'M';
    }
  }

  /// Helper method to map marital status
  String _mapMaritalStatus(String maritalStatus) {
    switch (maritalStatus.toLowerCase()) {
      case 'single':
        return 'S';
      case 'married':
        return 'M';
      case 'divorced':
        return 'D';
      case 'widowed':
        return 'W';
      default:
        return maritalStatus.isNotEmpty ? maritalStatus[0].toUpperCase() : 'S';
    }
  }

  /// Fetch families from backend and cache them locally
  Future<ApiResponse> fetchFamilies({int first = 10}) async {
    try {
      if (!await _isOnline()) {
        return ApiResponse.failure('No internet connection');
      }

      final String query = '''
        query {
          families(first: $first, orderBy: ["-validityFrom"]) {
            totalCount
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
            edges {
              node {
                id
                uuid
                poverty
                confirmationNo
                validityFrom
                validityTo
                headInsuree {
                  id
                  uuid
                  chfId
                  lastName
                  otherNames
                  email
                  phone
                  dob
                }
                location {
                  id
                  uuid
                  code
                  name
                  type
                  parent {
                    id
                    uuid
                    code
                    name
                    type
                    parent {
                      id
                      uuid
                      code
                      name
                      type
                      parent {
                        id
                        uuid
                        code
                        name
                        type
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200 && response.data['data'] != null) {
        // Parse the response using our DTOs
        final familyResponse = FamilyResponse.fromJson(response.data);
        final families = getFamiliesFromResponse(familyResponse);

        if (families.isNotEmpty) {
          // Cache families in local database
          final dbHelper = EnhancedDatabaseHelper();
          await dbHelper.cacheFamilies(families);

          return ApiResponse.success({
            'families': families,
            'totalCount': familyResponse.data?.families?.totalCount ?? 0,
            'hasNextPage':
                familyResponse.data?.families?.pageInfo?.hasNextPage ?? false,
          },
              message:
                  'Successfully fetched and cached ${families.length} families');
        } else {
          return ApiResponse.success({
            'families': [],
            'totalCount': 0,
            'hasNextPage': false,
          }, message: 'No families found');
        }
      }

      final errorMessage =
          response.data['errors']?[0]?['message'] ?? 'Unknown error';
      return ApiResponse.failure(errorMessage);
    } on DioError catch (e) {
      if (e.response?.data?['errors'] != null) {
        final errorMessage = e.response!.data['errors'][0]['message'];
        return ApiResponse.failure(errorMessage);
      }
      return ApiResponse.failure(e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse.failure('Error fetching families: $e');
    }
  }

  /// Get cached families from local database
  Future<List<FamilyNode>> getCachedFamilies() async {
    final dbHelper = EnhancedDatabaseHelper();
    return await dbHelper.getCachedFamilies();
  }

  /// Get cached families filtered by location
  /// Note: Location filtering is not available with current table structure
  Future<List<FamilyNode>> getCachedFamiliesByLocation(
      String locationCode) async {
    // Location filtering not available with current table structure
    // Return empty list for now
    return [];
  }

  /// Get families with head insuree issues (for issue list)
  Future<List<FamilyNode>> getFamiliesWithHeadIssues() async {
    final dbHelper = EnhancedDatabaseHelper();
    final allFamilies = await dbHelper.getCachedFamilies();

    // Filter families that have head insuree issues
    // This could be families without head insuree, or with incomplete head insuree data
    return allFamilies.where((family) {
      final headInsuree = family.headInsuree;
      if (headInsuree == null) return true; // No head insuree

      // Check for missing critical data
      return headInsuree.chfId == null ||
          headInsuree.chfId!.isEmpty ||
          headInsuree.lastName == null ||
          headInsuree.lastName!.isEmpty ||
          headInsuree.otherNames == null ||
          headInsuree.otherNames!.isEmpty ||
          headInsuree.dob == null ||
          headInsuree.dob!.isEmpty;
    }).toList();
  }
}
