import '../../../utils/api_response.dart';
import '../../remote/dto/enrollment/product_dto.dart';
import '../../remote/services/enrollment/product_service.dart';
import '../../../di/locator.dart';

class EnhancedContributionService {
  final ProductService _productService = getIt.get<ProductService>();

  /// Calculate contribution using the new formula
  /// Formula:
  /// total = 0
  /// if(member.disabled || member.age < 18): total += 0
  /// else if(member.head): total += premiumAdult
  /// else: total += (premiumAdult * 0.75)
  ///
  /// Then add:
  /// - Registration fee (price)
  /// - Lump sum fee (lumpSum)
  Future<ContributionCalculationResult> calculateContribution({
    required String membershipTypeId,
    required List<FamilyMemberForCalculation> familyMembers,
  }) async {
    try {
      // Get membership type details
      final membershipType =
          await _productService.getMembershipTypeById(membershipTypeId);

      if (membershipType == null) {
        return ContributionCalculationResult.failure(
            'Membership type not found');
      }

      // Get product details (since membershipType no longer has nested product details,
      // we need to get the product directly)
      final products = await _productService.getLocalProducts();
      if (products.isEmpty) {
        return ContributionCalculationResult.failure('No products available');
      }

      // Use the first product as it contains the pricing information
      final product = products.first;

      // Get pricing information
      final premiumAdult = product.premiumAdultAmount;
      final registrationFee = membershipType.registrationFee;
      final lumpSum = product.lumpSumAmount;

      // Calculate member contributions
      double memberContributions = 0.0;
      List<MemberContributionBreakdown> memberBreakdowns = [];

      for (final member in familyMembers) {
        double memberAmount = 0.0;
        String reason = '';

        if (member.disabled || member.age < 18) {
          memberAmount = 0.0;
          reason = member.disabled
              ? 'Disabled member - no contribution'
              : 'Under 18 - no contribution';
        } else if (member.isHead) {
          memberAmount = premiumAdult;
          reason = 'Head of family - full premium';
        } else {
          memberAmount = premiumAdult * 0.75;
          reason = 'Family member - 75% of premium';
        }

        memberContributions += memberAmount;
        memberBreakdowns.add(MemberContributionBreakdown(
          memberName: member.name,
          amount: memberAmount,
          reason: reason,
          isHead: member.isHead,
          age: member.age,
          disabled: member.disabled,
        ));
      }

      // Calculate total
      final totalAmount = memberContributions + registrationFee + lumpSum;

      final breakdown = ContributionBreakdown(
        memberContributions: memberContributions,
        registrationFee: registrationFee,
        lumpSum: lumpSum,
        totalAmount: totalAmount,
        memberBreakdowns: memberBreakdowns,
        premiumAdultRate: premiumAdult,
        membershipTypeName: membershipType.levelType ?? '',
        membershipLevel: membershipType.levelIndex?.toString() ?? '',
        region: membershipType.region ?? '',
        district: membershipType.district ?? '',
      );

      return ContributionCalculationResult.success(breakdown);
    } catch (e) {
      return ContributionCalculationResult.failure('Calculation error: $e');
    }
  }

  /// Get available membership types for selection
  Future<List<MembershipTypeDto>> getAvailableMembershipTypes({
    String? region,
    String? district,
    String? levelType,
  }) async {
    try {
      return await _productService.getMembershipTypes(
        region: region,
        district: district,
        levelType: levelType,
      );
    } catch (e) {
      throw Exception('Failed to get membership types: $e');
    }
  }

  /// Sync products if needed
  Future<ApiResponse> syncProductsIfNeeded() async {
    return await _productService.syncProductsIfNeeded();
  }
}

class ContributionCalculationResult {
  final bool success;
  final String? errorMessage;
  final ContributionBreakdown? breakdown;

  ContributionCalculationResult._({
    required this.success,
    this.errorMessage,
    this.breakdown,
  });

  factory ContributionCalculationResult.success(
      ContributionBreakdown breakdown) {
    return ContributionCalculationResult._(
      success: true,
      breakdown: breakdown,
    );
  }

  factory ContributionCalculationResult.failure(String errorMessage) {
    return ContributionCalculationResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

class ContributionBreakdown {
  final double memberContributions;
  final double registrationFee;
  final double lumpSum;
  final double totalAmount;
  final List<MemberContributionBreakdown> memberBreakdowns;
  final double premiumAdultRate;
  final String membershipTypeName;
  final String membershipLevel;
  final String region;
  final String district;

  ContributionBreakdown({
    required this.memberContributions,
    required this.registrationFee,
    required this.lumpSum,
    required this.totalAmount,
    required this.memberBreakdowns,
    required this.premiumAdultRate,
    required this.membershipTypeName,
    required this.membershipLevel,
    required this.region,
    required this.district,
  });

  /// Get formatted breakdown for display
  String getFormattedBreakdown() {
    final buffer = StringBuffer();
    buffer.writeln('Contribution Breakdown:');
    buffer.writeln('');

    // Member contributions
    buffer.writeln('Member Contributions:');
    for (final member in memberBreakdowns) {
      buffer.writeln(
          '  ${member.memberName}: ${member.amount.toStringAsFixed(2)} ETB (${member.reason})');
    }
    buffer.writeln('  Subtotal: ${memberContributions.toStringAsFixed(2)} ETB');
    buffer.writeln('');

    // Fees
    buffer.writeln('Fees:');
    buffer.writeln(
        '  Registration Fee: ${registrationFee.toStringAsFixed(2)} ETB');
    buffer.writeln('  Lump Sum: ${lumpSum.toStringAsFixed(2)} ETB');
    buffer.writeln('');

    // Total
    buffer.writeln('Total Amount: ${totalAmount.toStringAsFixed(2)} ETB');

    return buffer.toString();
  }
}

class MemberContributionBreakdown {
  final String memberName;
  final double amount;
  final String reason;
  final bool isHead;
  final int age;
  final bool disabled;

  MemberContributionBreakdown({
    required this.memberName,
    required this.amount,
    required this.reason,
    required this.isHead,
    required this.age,
    required this.disabled,
  });
}

class FamilyMemberForCalculation {
  final String name;
  final int age;
  final bool isHead;
  final bool disabled;

  FamilyMemberForCalculation({
    required this.name,
    required this.age,
    required this.isHead,
    required this.disabled,
  });

  factory FamilyMemberForCalculation.fromMap(Map<String, dynamic> map) {
    return FamilyMemberForCalculation(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      isHead: map['isHead'] ?? false,
      disabled: map['disabled'] ?? false,
    );
  }

  /// Calculate age from date of birth
  static int calculateAge(String dateOfBirth) {
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      final age = now.year - dob.year;

      // Check if birthday has occurred this year
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        return age - 1;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}
