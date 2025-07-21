import 'package:dio/src/response.dart';

import '../../../../modules/enrollment/controller/LocationDto.dart';
import '../../api/api_routes.dart';
import '../../api/dio_client.dart';
import 'i_enrollment_service.dart';
import '../../base/idto.dart';

class EnrollmentService implements IEnrollmentService<IDto> {
  final DioClient dioClient;

  EnrollmentService({required this.dioClient});

  @override
  Future<Response> enrollment({required IDto dto}) async {
    try {
      return await dioClient.post(ApiRoutes.ENROLLMENT, data: dto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> locations() async{
     //LocationDto dto = LocationDto();
    try {
      return await dioClient.get(ApiRoutes.LOCATIONS);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> hospitals() async {
    try {
      return await dioClient.get(ApiRoutes.HOSPITALS);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> membership_card({required String uuid}) async {
    try {
      return await dioClient.get(ApiRoutes.MEMBERSHIP_CARD+'/${uuid}');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response> enrollmentR(data) async {
    try {
      return await dioClient.post(ApiRoutes.ENROLLMENT, data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a family using GraphQL mutation
  Future<Response> createFamily({required Map<String, dynamic> input}) async {
    const String mutation = '''
      mutation CreateFamily(
        \$input: CreateFamilyInputType!
      ) {
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
      return await dioClient.post('/api/graphql', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// List families using GraphQL query
  Future<Response> listFamilies({required Map<String, dynamic> filters}) async {
    const String query = '''
      query ListFamilies(
        \$filters: FamiliesFilterInputType
      ) {
        families(
          ...\$filters
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
      'variables': {'filters': filters},
    };
    try {
      return await dioClient.post('/api/graphql', data: data);
    } catch (e) {
      rethrow;
    }
  }


}
