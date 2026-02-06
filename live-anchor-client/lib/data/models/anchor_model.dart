/// 用户标签模型
class UserTag {
  final String? dictType;
  final int? dictValue;
  final String? dictLabel;

  UserTag({
    this.dictType,
    this.dictValue,
    this.dictLabel,
  });

  factory UserTag.fromJson(Map<String, dynamic> json) {
    return UserTag(
      dictType: json['dictType'] as String?,
      dictValue: json['dictValue'] as int?,
      dictLabel: json['dictLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dictType': dictType ?? '',
      'dictValue': dictValue ?? 0,
      'dictLabel': dictLabel ?? '',
    };
  }
}

/// 用户图集模型
class UserPicture {
  final int? id;
  final String? url;
  final bool? cover;
  final int? type;       // 1: 普通图片, 2: 付费图片
  final int? coin;       // 解锁所需金币
  final bool? isPay;     // 是否已付费

  UserPicture({
    this.id,
    this.url,
    this.cover,
    this.type,
    this.coin,
    this.isPay,
  });

  factory UserPicture.fromJson(Map<String, dynamic> json) {
    return UserPicture(
      id: json['id'] as int?,
      url: json['url'] as String?,
      cover: json['cover'] as bool?,
      type: json['type'] as int?,
      coin: json['coin'] as int?,
      isPay: json['isPay'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    // 提交时只传 url, cover, type 三个参数
    return {
      'url': url ?? '',
      'cover': cover ?? false,
      'type': type ?? 0,
    };
  }
}

/// 主播模型
/// 对应 /authorize/anchorLogin 和 /authorize/getAnchorInfo 响应
class AnchorModel {
  final int? userId;
  final String? avatar;
  final String? nickname;
  final DateTime? birthday;
  final String? signature;
  final int? gender;           // 0:男 1:女 2:未知
  final int? country;          // 国家代码
  final int? userCategory;     // 用户类别
  final int? onlineStatus;     // 0:离线 1:在线 2:忙碌
  final int? following;        // 关注数
  final int? follower;         // 粉丝数
  final int? blacks;           // 拉黑数
  final DateTime? createTime;
  final DateTime? lastLoginTime;
  final String? email;
  final bool? isChangeInfo;    // 是否已修改过资料
  final String? token;
  final String? rtmToken;
  final String? tencentUserSig;
  
  // 主播特有字段
  final double? callPrice;           // 通话价格
  final String? agentCode;           // 经纪人码
  final int? linkType;               // 联系方式类型 1:WhatsApp 2:Telegram 3:Line
  final String? linkNo;              // 联系方式号码
  final int? experience;             // 经验值
  final String? experienceDescribe;  // 经验描述
  final double? walletBalance;       // 钱包余额
  final double? availableBalance;    // 可提现余额
  final double? freezeMoney;         // 冻结金额
  final int? auditStatus;            // 审核状态 0:待审核 1:通过 2:拒绝
  final String? auditReason;         // 审核原因
  
  // 关联数据
  final List<UserTag>? userTags;
  final List<UserPicture>? userPictures;

  AnchorModel({
    this.userId,
    this.avatar,
    this.nickname,
    this.birthday,
    this.signature,
    this.gender,
    this.country,
    this.userCategory,
    this.onlineStatus,
    this.following,
    this.follower,
    this.blacks,
    this.createTime,
    this.lastLoginTime,
    this.email,
    this.isChangeInfo,
    this.token,
    this.rtmToken,
    this.tencentUserSig,
    this.callPrice,
    this.agentCode,
    this.linkType,
    this.linkNo,
    this.experience,
    this.experienceDescribe,
    this.walletBalance,
    this.availableBalance,
    this.freezeMoney,
    this.auditStatus,
    this.auditReason,
    this.userTags,
    this.userPictures,
  });

  factory AnchorModel.fromJson(Map<String, dynamic> json) {
    return AnchorModel(
      userId: json['userId'] as int?,
      avatar: json['avatar'] as String?,
      nickname: json['nickname'] as String?,
      birthday: _parseBirthday(json['birthday']),
      signature: json['signature'] as String?,
      gender: json['gender'] as int?,
      country: json['country'] as int?,
      userCategory: json['userCategory'] as int?,
      onlineStatus: json['onlineStatus'] as int?,
      following: json['following'] as int?,
      follower: json['follower'] as int?,
      blacks: json['blacks'] as int?,
      createTime: json['createTime'] != null 
          ? DateTime.tryParse(json['createTime'].toString()) 
          : null,
      lastLoginTime: json['lastLoginTime'] != null 
          ? DateTime.tryParse(json['lastLoginTime'].toString()) 
          : null,
      email: json['email'] as String?,
      isChangeInfo: json['isChangeInfo'] as bool?,
      token: json['token'] as String?,
      rtmToken: json['rtmToken'] as String?,
      tencentUserSig: json['tencentUserSig'] as String?,
      callPrice: (json['callPrice'] as num?)?.toDouble(),
      agentCode: json['agentCode'] as String?,
      linkType: json['linkType'] as int?,
      linkNo: json['linkNo'] as String?,
      experience: json['experience'] as int?,
      experienceDescribe: json['experienceDescribe'] as String?,
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
      availableBalance: (json['availableBalance'] as num?)?.toDouble(),
      freezeMoney: (json['freezeMoney'] as num?)?.toDouble(),
      auditStatus: json['auditStatus'] as int?,
      auditReason: json['auditReason'] as String?,
      userTags: (json['userTags'] as List<dynamic>?)
          ?.map((e) => UserTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      userPictures: (json['userPictures'] as List<dynamic>?)
          ?.map((e) => UserPicture.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 解析 birthday：支持秒级时间戳（int/num）或 ISO 字符串
  static DateTime? _parseBirthday(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final seconds = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'avatar': avatar,
      'nickname': nickname,
      'birthday': birthday?.toIso8601String(),
      'signature': signature,
      'gender': gender,
      'country': country,
      'userCategory': userCategory,
      'onlineStatus': onlineStatus,
      'following': following,
      'follower': follower,
      'blacks': blacks,
      'createTime': createTime?.toIso8601String(),
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'email': email,
      'isChangeInfo': isChangeInfo,
      'token': token,
      'rtmToken': rtmToken,
      'tencentUserSig': tencentUserSig,
      'callPrice': callPrice,
      'agentCode': agentCode,
      'linkType': linkType,
      'linkNo': linkNo,
      'experience': experience,
      'experienceDescribe': experienceDescribe,
      'walletBalance': walletBalance,
      'availableBalance': availableBalance,
      'freezeMoney': freezeMoney,
      'auditStatus': auditStatus,
      'auditReason': auditReason,
      'userTags': userTags?.map((e) => e.toJson()).toList(),
      'userPictures': userPictures?.map((e) => e.toJson()).toList(),
    };
  }

  /// 计算年龄
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// 是否审核通过
  bool get isApproved => auditStatus == 1;

  /// 是否待审核
  bool get isPending => auditStatus == 0;

  /// 是否审核拒绝
  bool get isRejected => auditStatus == 2;

  /// 是否在线
  bool get isOnline => onlineStatus == 1;

  /// 是否忙碌
  bool get isBusy => onlineStatus == 2;

  /// 复制并覆盖部分字段（用于合并 getAnchorInfo 与本地 token）
  AnchorModel copyWith({
    int? userId,
    String? avatar,
    String? nickname,
    DateTime? birthday,
    String? signature,
    int? gender,
    int? country,
    int? userCategory,
    int? onlineStatus,
    int? following,
    int? follower,
    int? blacks,
    DateTime? createTime,
    DateTime? lastLoginTime,
    String? email,
    bool? isChangeInfo,
    String? token,
    String? rtmToken,
    String? tencentUserSig,
    double? callPrice,
    String? agentCode,
    int? linkType,
    String? linkNo,
    int? experience,
    String? experienceDescribe,
    double? walletBalance,
    double? availableBalance,
    double? freezeMoney,
    int? auditStatus,
    String? auditReason,
    List<UserTag>? userTags,
    List<UserPicture>? userPictures,
  }) {
    return AnchorModel(
      userId: userId ?? this.userId,
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      birthday: birthday ?? this.birthday,
      signature: signature ?? this.signature,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      userCategory: userCategory ?? this.userCategory,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      following: following ?? this.following,
      follower: follower ?? this.follower,
      blacks: blacks ?? this.blacks,
      createTime: createTime ?? this.createTime,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      email: email ?? this.email,
      isChangeInfo: isChangeInfo ?? this.isChangeInfo,
      token: token ?? this.token,
      rtmToken: rtmToken ?? this.rtmToken,
      tencentUserSig: tencentUserSig ?? this.tencentUserSig,
      callPrice: callPrice ?? this.callPrice,
      agentCode: agentCode ?? this.agentCode,
      linkType: linkType ?? this.linkType,
      linkNo: linkNo ?? this.linkNo,
      experience: experience ?? this.experience,
      experienceDescribe: experienceDescribe ?? this.experienceDescribe,
      walletBalance: walletBalance ?? this.walletBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      freezeMoney: freezeMoney ?? this.freezeMoney,
      auditStatus: auditStatus ?? this.auditStatus,
      auditReason: auditReason ?? this.auditReason,
      userTags: userTags ?? this.userTags,
      userPictures: userPictures ?? this.userPictures,
    );
  }
}

/// 主播资料提交请求模型
class AnchorSetInfoRequest {
  final String? avatar;
  final String? nickname;
  final DateTime? birthday;
  final String? signature;
  final int? gender;
  final int? country;
  final double? callPrice;
  final int? linkType;
  final String? linkNo;
  final int? experience;
  final String? experienceDescribe;
  final String? agentCode;
  final List<UserTag>? userTags;
  final List<UserPicture>? userPictures;

  AnchorSetInfoRequest({
    this.avatar,
    this.nickname,
    this.birthday,
    this.signature,
    this.gender,
    this.country,
    this.callPrice,
    this.linkType,
    this.linkNo,
    this.experience,
    this.experienceDescribe,
    this.agentCode,
    this.userTags,
    this.userPictures,
  });

  Map<String, dynamic> toJson() {
    return {
      if (avatar != null && avatar!.isNotEmpty) 'avatar': avatar,
      if (nickname != null && nickname!.isNotEmpty) 'nickname': nickname,
      if (birthday != null) 'birthday': _formatBirthday(birthday!),
      if (signature != null && signature!.isNotEmpty) 'signature': signature,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (callPrice != null) 'callPrice': callPrice,
      if (linkType != null) 'linkType': linkType,
      if (linkNo != null && linkNo!.isNotEmpty) 'linkNo': linkNo,
      if (experience != null) 'experience': experience,
      if (experienceDescribe != null && experienceDescribe!.isNotEmpty) 'experienceDescribe': experienceDescribe,
      if (agentCode != null && agentCode!.isNotEmpty) 'agentCode': agentCode,
      if (userTags != null && userTags!.isNotEmpty) 'userTags': userTags!.map((e) => e.toJson()).toList(),
      if (userPictures != null && userPictures!.isNotEmpty) 'userPictures': userPictures!.map((e) => e.toJson()).toList(),
    };
  }
  
  /// 格式化生日为秒级时间戳（与 getAnchorInfo 返回格式一致，接口要求秒）
  int _formatBirthday(DateTime birthday) {
    // 按当天 0 点 UTC 转秒，避免时区导致日期漂移
    final utc = DateTime.utc(birthday.year, birthday.month, birthday.day);
    return utc.millisecondsSinceEpoch ~/ 1000;
  }
}

/// 主播登录请求模型
class AnchorLoginRequest {
  final String type;           // IOS / ANDROID
  final String loginNo;        // 邮箱
  final String password;
  final String? invitationCode; // 邀请码（经纪人码）

  AnchorLoginRequest({
    required this.type,
    required this.loginNo,
    required this.password,
    this.invitationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'loginNo': loginNo,
      'password': password,
      if (invitationCode != null) 'invitationCode': invitationCode,
    };
  }
}

/// 修改密码请求
class ChangePasswordRequest {
  final String oldPassword;
  final String password;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'password': password,
    };
  }
}
