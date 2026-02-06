/// 排行榜用户模型
/// 对应 /user/rankingList 和 /anchor/rankingList 响应
class RankingUser {
  final int? userId;
  final String? avatar;
  final String? nickname;
  final DateTime? birthday;
  final String? signature;
  final int? gender;
  final int? country;
  final int? userCategory;
  final int? onlineStatus;
  final int? following;
  final int? follower;
  final int? blacks;
  final DateTime? createTime;
  final DateTime? lastLoginTime;
  final int? rankingNum;           // 排名数值（如消费金额、收益金额）
  final int? rankingNumLong;       // 长整型排名数值
  final String? ranking;           // 排名名次
  final int? age;

  RankingUser({
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
    this.rankingNum,
    this.rankingNumLong,
    this.ranking,
    this.age,
  });

  factory RankingUser.fromJson(Map<String, dynamic> json) {
    return RankingUser(
      userId: json['userId'] as int?,
      avatar: json['avatar'] as String?,
      nickname: json['nickname'] as String?,
      birthday: json['birthday'] != null 
          ? DateTime.tryParse(json['birthday'].toString()) 
          : null,
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
      rankingNum: json['rankingNum'] as int?,
      rankingNumLong: json['rankingNumLong'] as int?,
      ranking: json['ranking'] as String?,
      age: json['age'] as int?,
    );
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
      'rankingNum': rankingNum,
      'rankingNumLong': rankingNumLong,
      'ranking': ranking,
      'age': age,
    };
  }
}

/// 用户排行榜请求（财富榜）
class UserRankingRequest {
  final int page;
  final int size;
  final String timeType;     // ALL, DAY, WEEK, MONTH
  final int type;            // 排行榜类型
  final int? isSelfRanking;  // 是否查询自己的排名

  UserRankingRequest({
    required this.page,
    required this.size,
    required this.timeType,
    required this.type,
    this.isSelfRanking,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'timeType': timeType,
      'type': type,
      if (isSelfRanking != null) 'isSelfRanking': isSelfRanking,
    };
  }
}

/// 主播排行榜请求
class AnchorRankingRequest {
  final int page;
  final int size;
  final String timeType;     // ALL, DAY, WEEK, MONTH
  final int type;            // 排行榜类型

  AnchorRankingRequest({
    required this.page,
    required this.size,
    required this.timeType,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'timeType': timeType,
      'type': type,
    };
  }
}
