import '../../base/idto.dart';

class GraphQLAuthRequest implements IDto {
  final String username;
  final String password;

  GraphQLAuthRequest({
    required this.username,
    required this.password,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'query': '''
        mutation {
          tokenAuth(username: "$username", password: "$password") {
            refreshExpiresIn
            token
            payload
          }
          getCsrfToken {
            csrfToken
          }
        }
      '''
    };
  }
}

class TokenAuthPayload {
  final String username;
  final int exp;
  final int origIat;
  final String jti;
  final int nbf;

  TokenAuthPayload({
    required this.username,
    required this.exp,
    required this.origIat,
    required this.jti,
    required this.nbf,
  });

  factory TokenAuthPayload.fromJson(Map<String, dynamic> json) {
    return TokenAuthPayload(
      username: json['username'] ?? '',
      exp: json['exp'] ?? 0,
      origIat: json['origIat'] ?? 0,
      jti: json['jti'] ?? '',
      nbf: json['nbf'] ?? 0,
    );
  }
}

class TokenAuthData {
  final int refreshExpiresIn;
  final String token;
  final TokenAuthPayload payload;

  TokenAuthData({
    required this.refreshExpiresIn,
    required this.token,
    required this.payload,
  });

  factory TokenAuthData.fromJson(Map<String, dynamic> json) {
    return TokenAuthData(
      refreshExpiresIn: json['refreshExpiresIn'] ?? 0,
      token: json['token'] ?? '',
      payload: TokenAuthPayload.fromJson(json['payload'] ?? {}),
    );
  }
}

class CsrfTokenData {
  final String csrfToken;

  CsrfTokenData({required this.csrfToken});

  factory CsrfTokenData.fromJson(Map<String, dynamic> json) {
    return CsrfTokenData(
      csrfToken: json['csrfToken'] ?? '',
    );
  }
}

class GraphQLAuthResponse implements IDto {
  final TokenAuthData tokenAuth;
  final CsrfTokenData getCsrfToken;

  GraphQLAuthResponse({
    required this.tokenAuth,
    required this.getCsrfToken,
  });

  factory GraphQLAuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return GraphQLAuthResponse(
      tokenAuth: TokenAuthData.fromJson(data['tokenAuth'] ?? {}),
      getCsrfToken: CsrfTokenData.fromJson(data['getCsrfToken'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'tokenAuth': {
        'refreshExpiresIn': tokenAuth.refreshExpiresIn,
        'token': tokenAuth.token,
        'payload': {
          'username': tokenAuth.payload.username,
          'exp': tokenAuth.payload.exp,
          'origIat': tokenAuth.payload.origIat,
          'jti': tokenAuth.payload.jti,
          'nbf': tokenAuth.payload.nbf,
        }
      },
      'getCsrfToken': {
        'csrfToken': getCsrfToken.csrfToken,
      }
    };
  }
}

class CurrentUserResponse implements IDto {
  final String id;
  final String username;
  final UserInfo? iUser;
  final dynamic tUser;

  CurrentUserResponse({
    required this.id,
    required this.username,
    this.iUser,
    this.tUser,
  });

  factory CurrentUserResponse.fromJson(Map<String, dynamic> json) {
    return CurrentUserResponse(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      iUser: json['i_user'] != null ? UserInfo.fromJson(json['i_user']) : null,
      tUser: json['t_user'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'i_user': iUser?.toJson(),
      't_user': tUser,
    };
  }
}

class UserInfo {
  final int id;
  final String language;
  final String lastName;
  final String otherNames;
  final int? healthFacilityId;
  final List<int> rights;
  final bool hasPassword;

  UserInfo({
    required this.id,
    required this.language,
    required this.lastName,
    required this.otherNames,
    this.healthFacilityId,
    required this.rights,
    required this.hasPassword,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      language: json['language'] ?? 'en',
      lastName: json['last_name'] ?? '',
      otherNames: json['other_names'] ?? '',
      healthFacilityId: json['health_facility_id'],
      rights: List<int>.from(json['rights'] ?? []),
      hasPassword: json['has_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'last_name': lastName,
      'other_names': otherNames,
      'health_facility_id': healthFacilityId,
      'rights': rights,
      'has_password': hasPassword,
    };
  }
}
