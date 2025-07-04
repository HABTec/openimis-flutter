import 'package:openimis_app/app/data/local/base/i_entity.dart';

class ContributionConfigEntity implements IEntity {
  final int? id;
  final String membershipLevel; // Level 1, Level 2, Level 3
  final String membershipType; // Paying, Indigent
  final String areaType; // Rural, City
  final double baseRate;
  final double perMemberRate;
  final String currency;
  final DateTime lastUpdated;
  final bool isActive;

  ContributionConfigEntity({
    this.id,
    required this.membershipLevel,
    required this.membershipType,
    required this.areaType,
    required this.baseRate,
    required this.perMemberRate,
    required this.currency,
    required this.lastUpdated,
    this.isActive = true,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'membership_level': membershipLevel,
      'membership_type': membershipType,
      'area_type': areaType,
      'base_rate': baseRate,
      'per_member_rate': perMemberRate,
      'currency': currency,
      'last_updated': lastUpdated.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ContributionConfigEntity.fromMap(Map<String, dynamic> map) {
    return ContributionConfigEntity(
      id: map['id'],
      membershipLevel: map['membership_level'] ?? '',
      membershipType: map['membership_type'] ?? '',
      areaType: map['area_type'] ?? '',
      baseRate: (map['base_rate'] ?? 0).toDouble(),
      perMemberRate: (map['per_member_rate'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'ETB',
      lastUpdated: DateTime.parse(map['last_updated'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  ContributionConfigEntity copyWith({
    int? id,
    String? membershipLevel,
    String? membershipType,
    String? areaType,
    double? baseRate,
    double? perMemberRate,
    String? currency,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return ContributionConfigEntity(
      id: id ?? this.id,
      membershipLevel: membershipLevel ?? this.membershipLevel,
      membershipType: membershipType ?? this.membershipType,
      areaType: areaType ?? this.areaType,
      baseRate: baseRate ?? this.baseRate,
      perMemberRate: perMemberRate ?? this.perMemberRate,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
} 