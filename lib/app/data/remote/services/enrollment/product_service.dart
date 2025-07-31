import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../../api/dio_client.dart';
import '../../dto/enrollment/product_dto.dart';
import '../../../../utils/api_response.dart';
import '../../../../utils/enhanced_database_helper.dart';
import '../../exceptions/dio_exceptions.dart';

class ProductService {
  final DioClient dioClient;
  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper();

  ProductService({required this.dioClient});

  /// Fetch products from GraphQL API
  Future<ApiResponse> fetchUserProducts() async {
    try {
      // Get username from storage or use default
      final username = GetStorage().read('loginUsername') ?? 'Admin';

      const String query = '''
        query(\$username: String!) {
          userProducts(username: \$username) {
            id
            username
            iUser {
              healthFacilityId
              products {
                id
                code
                name
                membershipTypes {
                  id
                  region
                  district
                  levelType
                  levelIndex
                  price
                  products {
                    edges {
                      node {
                        id
                        name
                        lumpSum
                        premiumAdult
                        ageMaximal
                        cardReplacementFee
                        enrolmentPeriodStartDate
                        enrolmentPeriodEndDate
                      }
                    }
                  }
                }
                enrolmentPeriodEndDate
                enrolmentPeriodStartDate
              }
            }
          }
        }
      ''';

      final data = {
        'query': query,
        'variables': {
          'username': username,
        },
      };

      final response = await dioClient.post('/api/graphql', data: data);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final userProductsResponse =
            UserProductsResponseDto.fromJson(response.data);

        // Filter to only use the first product with membershipTypes
        final filteredResponse =
            _filterFirstProductWithMembershipTypes(userProductsResponse);

        // Store products locally
        await _storeProductsLocally(filteredResponse);

        return ApiResponse.success(filteredResponse,
            message: 'Products fetched successfully');
      } else {
        final errorMessage =
            response.data['errors']?[0]?['message'] ?? 'Unknown error';
        return ApiResponse.failure(errorMessage);
      }
    } on DioException catch (e) {
      return ApiResponse.failure(DioExceptions.fromDioError(e).message);
    } catch (e) {
      return ApiResponse.failure('Failed to fetch products: $e');
    }
  }

  /// Store products in local database
  Future<void> _storeProductsLocally(
      UserProductsResponseDto userProductsResponse) async {
    try {
      final db = await _dbHelper.database;

      // Clear existing products
      await db.delete('products');
      await db.delete('membership_types');

      final products = userProductsResponse.data?.userProducts?.iUser?.products;

      if (products != null) {
        for (final product in products) {
          // Insert product
          await db.insert('products', {
            'id': product.id,
            'code': product.code,
            'name': product.name,
            'lump_sum': product.lumpSum,
            'premium_adult': product.premiumAdult,
            'age_maximal': product.ageMaximal,
            'card_replacement_fee': product.cardReplacementFee,
            'enrolment_period_start_date': product.enrolmentPeriodStartDate,
            'enrolment_period_end_date': product.enrolmentPeriodEndDate,
            'last_synced': DateTime.now().toIso8601String(),
          });

          // Insert membership types
          if (product.membershipTypes != null) {
            for (final membershipType in product.membershipTypes!) {
              final productDetails = membershipType.productDetails;

              await db.insert('membership_types', {
                'id': membershipType.id,
                'product_id': product.id,
                'region': membershipType.region,
                'district': membershipType.district,
                'level_type': membershipType.levelType,
                'level_index': membershipType.levelIndex,
                'price': membershipType.price,
                'product_node_id': productDetails?.id,
                'product_node_name': productDetails?.name,
                'product_lump_sum': productDetails?.lumpSum,
                'product_premium_adult': productDetails?.premiumAdult,
                'product_age_maximal': productDetails?.ageMaximal,
                'product_card_replacement_fee':
                    productDetails?.cardReplacementFee,
                'last_synced': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to store products locally: $e');
    }
  }

  /// Get all products from local database
  Future<List<ProductDto>> getLocalProducts() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> products = await db.query('products');

      List<ProductDto> productList = [];

      for (final productMap in products) {
        // Get membership types for this product
        final List<Map<String, dynamic>> membershipTypesData = await db.query(
          'membership_types',
          where: 'product_id = ?',
          whereArgs: [productMap['id']],
        );

        List<MembershipTypeDto> membershipTypes =
            membershipTypesData.map((mtMap) {
          return MembershipTypeDto(
            id: mtMap['id'],
            region: mtMap['region'],
            district: mtMap['district'],
            levelType: mtMap['level_type'],
            levelIndex: mtMap['level_index'],
            price: mtMap['price'],
            products: ProductEdgesDto(
              edges: [
                ProductEdgeDto(
                  node: ProductNodeDto(
                    id: mtMap['product_node_id'],
                    name: mtMap['product_node_name'],
                    lumpSum: mtMap['product_lump_sum'],
                    premiumAdult: mtMap['product_premium_adult'],
                    ageMaximal: mtMap['product_age_maximal'],
                    cardReplacementFee: mtMap['product_card_replacement_fee'],
                  ),
                ),
              ],
            ),
          );
        }).toList();

        final product = ProductDto(
          id: productMap['id'],
          code: productMap['code'],
          name: productMap['name'],
          lumpSum: productMap['lump_sum'],
          premiumAdult: productMap['premium_adult'],
          ageMaximal: productMap['age_maximal'],
          cardReplacementFee: productMap['card_replacement_fee'],
          enrolmentPeriodStartDate: productMap['enrolment_period_start_date'],
          enrolmentPeriodEndDate: productMap['enrolment_period_end_date'],
          membershipTypes: membershipTypes,
        );

        productList.add(product);
      }

      return productList;
    } catch (e) {
      throw Exception('Failed to get local products: $e');
    }
  }

  /// Get membership types by criteria
  Future<List<MembershipTypeDto>> getMembershipTypes({
    String? region,
    String? district,
    String? levelType,
    int? levelIndex,
  }) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (region != null) {
        whereClause += ' AND region = ?';
        whereArgs.add(region);
      }

      if (district != null) {
        whereClause += ' AND district = ?';
        whereArgs.add(district);
      }

      if (levelType != null) {
        whereClause += ' AND level_type = ?';
        whereArgs.add(levelType);
      }

      if (levelIndex != null) {
        whereClause += ' AND level_index = ?';
        whereArgs.add(levelIndex);
      }

      final List<Map<String, dynamic>> results = await db.query(
        'membership_types',
        where: whereClause,
        whereArgs: whereArgs,
      );

      return results.map((map) {
        return MembershipTypeDto(
          id: map['id'],
          region: map['region'],
          district: map['district'],
          levelType: map['level_type'],
          levelIndex: map['level_index'],
          price: map['price'],
          products: ProductEdgesDto(
            edges: [
              ProductEdgeDto(
                node: ProductNodeDto(
                  id: map['product_node_id'],
                  name: map['product_node_name'],
                  lumpSum: map['product_lump_sum'],
                  premiumAdult: map['product_premium_adult'],
                  ageMaximal: map['product_age_maximal'],
                  cardReplacementFee: map['product_card_replacement_fee'],
                ),
              ),
            ],
          ),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get membership types: $e');
    }
  }

  /// Get membership type by ID
  Future<MembershipTypeDto?> getMembershipTypeById(String id) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> results = await db.query(
        'membership_types',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final map = results.first;
      return MembershipTypeDto(
        id: map['id'],
        region: map['region'],
        district: map['district'],
        levelType: map['level_type'],
        levelIndex: map['level_index'],
        price: map['price'],
        products: ProductEdgesDto(
          edges: [
            ProductEdgeDto(
              node: ProductNodeDto(
                id: map['product_node_id'],
                name: map['product_node_name'],
                lumpSum: map['product_lump_sum'],
                premiumAdult: map['product_premium_adult'],
                ageMaximal: map['product_age_maximal'],
                cardReplacementFee: map['product_card_replacement_fee'],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      throw Exception('Failed to get membership type: $e');
    }
  }

  /// Check if products need syncing (older than 24 hours)
  Future<bool> shouldSyncProducts() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'products',
        orderBy: 'last_synced DESC',
        limit: 1,
      );

      if (results.isEmpty) return true;

      final lastSyncString = results.first['last_synced'] as String?;
      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      final hoursSinceSync = DateTime.now().difference(lastSync).inHours;

      return hoursSinceSync >= 24;
    } catch (e) {
      return true; // Force sync on error
    }
  }

  /// Sync products if needed
  Future<ApiResponse> syncProductsIfNeeded() async {
    try {
      if (await shouldSyncProducts()) {
        return await fetchUserProducts();
      } else {
        final products = await getLocalProducts();
        return ApiResponse.success(products, message: 'Using cached products');
      }
    } catch (e) {
      return ApiResponse.failure('Failed to sync products: $e');
    }
  }

  /// Filter to only return the first product with membershipTypes
  UserProductsResponseDto _filterFirstProductWithMembershipTypes(
      UserProductsResponseDto response) {
    final products = response.data?.userProducts?.iUser?.products;

    if (products == null || products.isEmpty) {
      return response;
    }

    // Find the first product with membershipTypes
    ProductDto? selectedProduct;
    for (final product in products) {
      if (product.membershipTypes != null &&
          product.membershipTypes!.isNotEmpty) {
        selectedProduct = product;
        break;
      }
    }

    if (selectedProduct == null) {
      // If no product has membershipTypes, return the original response
      return response;
    }

    // Create a new response with only the selected product
    final filteredProducts = [selectedProduct];

    final filteredIUser = response.data!.userProducts!.iUser!.copyWith(
      products: filteredProducts,
    );

    final filteredUserProducts = response.data!.userProducts!.copyWith(
      iUser: filteredIUser,
    );

    final filteredData = response.data!.copyWith(
      userProducts: filteredUserProducts,
    );

    return response.copyWith(
      data: filteredData,
    );
  }
}
