import '../../base/idto.dart';

class PolicyDto implements IDto {
  PolicyDto({
    this.localId,
    this.enrollDate,
    this.startDate,
    this.expiryDate,
    this.value,
    this.productId,
    this.familyId,
    this.officerId,
    this.uuid,
    this.syncStatus,
    this.remotePolicyId,
    this.createdAt,
    this.updatedAt,
    this.syncError,
  });

  PolicyDto.fromJson(Map<String, dynamic> json) {
    localId = json['localId'];
    enrollDate = json['enrollDate'];
    startDate = json['startDate'];
    expiryDate = json['expiryDate'];
    value = json['value'];
    productId = json['productId'];
    familyId = json['familyId'];
    officerId = json['officerId'];
    uuid = json['uuid'];
    syncStatus = json['syncStatus'] ?? 0;
    remotePolicyId = json['remotePolicyId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    syncError = json['syncError'];
  }

  int? localId;
  String? enrollDate;
  String? startDate;
  String? expiryDate;
  String? value;
  int? productId;
  int? familyId;
  int? officerId;
  String? uuid;
  int? syncStatus; // 0 = pending, 1 = synced, 2 = failed
  int? remotePolicyId;
  String? createdAt;
  String? updatedAt;
  String? syncError;

  PolicyDto copyWith({
    int? localId,
    String? enrollDate,
    String? startDate,
    String? expiryDate,
    String? value,
    int? productId,
    int? familyId,
    int? officerId,
    String? uuid,
    int? syncStatus,
    int? remotePolicyId,
    String? createdAt,
    String? updatedAt,
    String? syncError,
  }) =>
      PolicyDto(
        localId: localId ?? this.localId,
        enrollDate: enrollDate ?? this.enrollDate,
        startDate: startDate ?? this.startDate,
        expiryDate: expiryDate ?? this.expiryDate,
        value: value ?? this.value,
        productId: productId ?? this.productId,
        familyId: familyId ?? this.familyId,
        officerId: officerId ?? this.officerId,
        uuid: uuid ?? this.uuid,
        syncStatus: syncStatus ?? this.syncStatus,
        remotePolicyId: remotePolicyId ?? this.remotePolicyId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncError: syncError ?? this.syncError,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['localId'] = localId;
    map['enrollDate'] = enrollDate;
    map['startDate'] = startDate;
    map['expiryDate'] = expiryDate;
    map['value'] = value;
    map['productId'] = productId;
    map['familyId'] = familyId;
    map['officerId'] = officerId;
    map['uuid'] = uuid;
    map['syncStatus'] = syncStatus;
    map['remotePolicyId'] = remotePolicyId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['syncError'] = syncError;
    return map;
  }

  // Convert to GraphQL mutation format
  Map<String, dynamic> toGraphQLInput(
      String clientMutationId, String clientMutationLabel) {
    return {
      'clientMutationId': clientMutationId,
      'clientMutationLabel': clientMutationLabel,
      'enrollDate': enrollDate,
      'startDate': startDate,
      'expiryDate': expiryDate,
      'value': value ?? '0.00',
      'productId': productId,
      'familyId': familyId,
      'officerId': officerId ?? 1,
      'uuid': uuid,
    };
  }
}

class ContributionDto implements IDto {
  ContributionDto({
    this.localId,
    this.receipt,
    this.payDate,
    this.payType,
    this.isPhotoFee,
    this.action,
    this.amount,
    this.policyUuid,
    this.syncStatus,
    this.remoteContributionId,
    this.createdAt,
    this.updatedAt,
    this.syncError,
  });

  ContributionDto.fromJson(Map<String, dynamic> json) {
    localId = json['localId'];
    receipt = json['receipt'];
    payDate = json['payDate'];
    payType = json['payType'];
    isPhotoFee = json['isPhotoFee'];
    action = json['action'];
    amount = json['amount'];
    policyUuid = json['policyUuid'];
    syncStatus = json['syncStatus'] ?? 0;
    remoteContributionId = json['remoteContributionId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    syncError = json['syncError'];
  }

  int? localId;
  String? receipt;
  String? payDate;
  String? payType;
  bool? isPhotoFee;
  String? action;
  String? amount;
  String? policyUuid;
  int? syncStatus; // 0 = pending, 1 = synced, 2 = failed
  int? remoteContributionId;
  String? createdAt;
  String? updatedAt;
  String? syncError;

  ContributionDto copyWith({
    int? localId,
    String? receipt,
    String? payDate,
    String? payType,
    bool? isPhotoFee,
    String? action,
    String? amount,
    String? policyUuid,
    int? syncStatus,
    int? remoteContributionId,
    String? createdAt,
    String? updatedAt,
    String? syncError,
  }) =>
      ContributionDto(
        localId: localId ?? this.localId,
        receipt: receipt ?? this.receipt,
        payDate: payDate ?? this.payDate,
        payType: payType ?? this.payType,
        isPhotoFee: isPhotoFee ?? this.isPhotoFee,
        action: action ?? this.action,
        amount: amount ?? this.amount,
        policyUuid: policyUuid ?? this.policyUuid,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteContributionId: remoteContributionId ?? this.remoteContributionId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncError: syncError ?? this.syncError,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['localId'] = localId;
    map['receipt'] = receipt;
    map['payDate'] = payDate;
    map['payType'] = payType;
    map['isPhotoFee'] = isPhotoFee;
    map['action'] = action;
    map['amount'] = amount;
    map['policyUuid'] = policyUuid;
    map['syncStatus'] = syncStatus;
    map['remoteContributionId'] = remoteContributionId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['syncError'] = syncError;
    return map;
  }

  // Convert to GraphQL mutation format
  Map<String, dynamic> toGraphQLInput(
      String clientMutationId, String clientMutationLabel) {
    return {
      'clientMutationId': clientMutationId,
      'clientMutationLabel': clientMutationLabel,
      'receipt': receipt,
      'payDate': payDate,
      'payType': payType ?? 'B',
      'isPhotoFee': isPhotoFee ?? false,
      'action': action ?? 'ENFORCE',
      'amount': amount,
      'policyUuid': policyUuid,
    };
  }
}
