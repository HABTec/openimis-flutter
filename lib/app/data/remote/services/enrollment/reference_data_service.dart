import 'package:dio/dio.dart';
import 'package:openimis_app/app/data/remote/dto/enrollment/product_dto.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/product_service.dart';
import 'package:openimis_app/app/di/locator.dart';
import '../../api/dio_client.dart';
import '../../dto/enrollment/profession_dto.dart';
import '../../dto/enrollment/education_dto.dart';
import '../../dto/enrollment/relation_dto.dart';
import '../../dto/enrollment/family_type_dto.dart';
import '../../dto/enrollment/confirmation_type_dto.dart';
import '../../dto/enrollment/location_hierarchy_dto.dart';
import '../../../../utils/enhanced_database_helper.dart';
import '../../../../utils/api_response.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ReferenceDataService {
  final DioClient dioClient;
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();
  final ProductService _productService = getIt.get<ProductService>();

  ReferenceDataService({required this.dioClient});

  // Check if online
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Fetch all reference data
  Future<ApiResponse> syncAllReferenceData() async {
    try {
      if (!await _isOnline()) {
        return ApiResponse.failure('No internet connection');
      }

      // Sync all reference data in parallel
      final futures = [
        _syncProfessions(),
        _syncEducations(),
        _syncRelations(),
        _syncFamilyTypes(),
        _syncConfirmationTypes(),
        _syncLocations(),
        _productService.syncProductsIfNeeded(),
      ];

      final results = await Future.wait(futures);

      // Check if any failed
      final failures = results.where((result) => result.error).toList();
      if (failures.isNotEmpty) {
        return ApiResponse.failure('Some reference data failed to sync');
      }

      return ApiResponse.success(null,
          message: 'All reference data synced successfully');
    } catch (e) {
      return ApiResponse.failure('Failed to sync reference data: $e');
    }
  }

  Future<ApiResponse> _syncProfessions() async {
    try {
      const String query = '''
        query Professions {
          professions {
            id
            profession
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final data = response.data['data']['professions'] as List;
        final professions =
            data.map((item) => ProfessionDto.fromJson(item)).toList();
        await _dbHelper.cacheProfessions(professions);
        return ApiResponse.success(professions);
      }

      return ApiResponse.failure('Failed to fetch professions');
    } catch (e) {
      return ApiResponse.failure('Error fetching professions: $e');
    }
  }

  Future<ApiResponse> _syncEducations() async {
    try {
      const String query = '''
        query Educations {
          educations {
            id
            education
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final data = response.data['data']['educations'] as List;
        final educations =
            data.map((item) => EducationDto.fromJson(item)).toList();
        await _dbHelper.cacheEducations(educations);
        return ApiResponse.success(educations);
      }

      return ApiResponse.failure('Failed to fetch educations');
    } catch (e) {
      return ApiResponse.failure('Error fetching educations: $e');
    }
  }

  Future<ApiResponse> _syncRelations() async {
    try {
      const String query = '''
        query Relations {
          relations {
            id
            relation
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final data = response.data['data']['relations'] as List;
        final relations =
            data.map((item) => RelationDto.fromJson(item)).toList();
        await _dbHelper.cacheRelations(relations);
        return ApiResponse.success(relations);
      }

      return ApiResponse.failure('Failed to fetch relations');
    } catch (e) {
      return ApiResponse.failure('Error fetching relations: $e');
    }
  }

  Future<ApiResponse> _syncFamilyTypes() async {
    try {
      const String query = '''
        query FamilyTypes {
          familyTypes {
            code
            type
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final data = response.data['data']['familyTypes'] as List;
        final familyTypes =
            data.map((item) => FamilyTypeDto.fromJson(item)).toList();
        await _dbHelper.cacheFamilyTypes(familyTypes);
        return ApiResponse.success(familyTypes);
      }

      return ApiResponse.failure('Failed to fetch family types');
    } catch (e) {
      return ApiResponse.failure('Error fetching family types: $e');
    }
  }

  Future<ApiResponse> _syncConfirmationTypes() async {
    try {
      const String query = '''
        query ConfirmationTypes2 {
          confirmationTypes {
            isConfirmationNumberRequired
            code
            confirmationtype
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final data = response.data['data']['confirmationTypes'] as List;
        final confirmationTypes =
            data.map((item) => ConfirmationTypeDto.fromJson(item)).toList();
        await _dbHelper.cacheConfirmationTypes(confirmationTypes);
        return ApiResponse.success(confirmationTypes);
      }

      return ApiResponse.failure('Failed to fetch confirmation types');
    } catch (e) {
      return ApiResponse.failure('Error fetching confirmation types: $e');
    }
  }

  Future<ApiResponse> _syncLocations() async {
    try {
      const String query = '''
        query LocationsStr {
          locationsStr(type: "R") {
            edges {
              node {
                id
                uuid
                code
                name
                type
                clientMutationId
                children {
                  edges {
                    cursor
                    node {
                      id
                      uuid
                      code
                      name
                      type
                      clientMutationId
                      children {
                        edges {
                          node {
                            id
                            uuid
                            code
                            name
                            type
                            children {
                              edges {
                                node {
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
                }
              }
            }
          }
        }
      ''';

      final response =
          await dioClient.post('/api/graphql', data: {'query': query});

      if (response.statusCode == 200) {
        final locationResponse =
            LocationHierarchyResponse.fromJson(response.data);
        final flatLocations =
            LocationHierarchyUtils.flattenLocationHierarchy(locationResponse);
        await _dbHelper.cacheLocations(flatLocations);
        return ApiResponse.success(flatLocations);
      }

      return ApiResponse.failure('Failed to fetch locations');
    } catch (e) {
      return ApiResponse.failure('Error fetching locations: $e');
    }
  }

  // Get cached data methods

  Future<List<ProductDto>> getProducts() async {
    return await _productService.getLocalProducts();
  }

  Future<List<ProfessionDto>> getProfessions() async {
    return await _dbHelper.getProfessions();
  }

  Future<List<EducationDto>> getEducations() async {
    return await _dbHelper.getEducations();
  }

  Future<List<RelationDto>> getRelations() async {
    return await _dbHelper.getRelations();
  }

  Future<List<FamilyTypeDto>> getFamilyTypes() async {
    return await _dbHelper.getFamilyTypes();
  }

  Future<List<ConfirmationTypeDto>> getConfirmationTypes() async {
    return await _dbHelper.getConfirmationTypes();
  }

  Future<List<FlatLocationDto>> getLocationsByType(String type) async {
    return await _dbHelper.getLocationsByType(type);
  }

  // Sync if needed
  Future<ApiResponse> syncIfNeeded() async {
    try {
      if (await _dbHelper.needsReferenceDataSync()) {
        return await syncAllReferenceData();
      }
      return ApiResponse.success(null, message: 'Reference data is up to date');
    } catch (e) {
      return ApiResponse.failure('Error checking sync status: $e');
    }
  }

  // Force resync all reference data (for manual refresh)
  Future<ApiResponse> resyncAllReferenceData() async {
    try {
      // Clear existing cached data
      await _dbHelper.clearAllReferenceData();

      // Fetch fresh data from server
      return await syncAllReferenceData();
    } catch (e) {
      return ApiResponse.failure('Error resyncing reference data: $e');
    }
  }
}
