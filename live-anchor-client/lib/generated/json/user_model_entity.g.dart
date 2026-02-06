import 'package:weeder/generated/json/base/json_convert_content.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import 'package:weeder/data/models/call_history_model.dart';

UserModelEntity $UserModelEntityFromJson(Map<String, dynamic> json) {
  final UserModelEntity userModelEntity = UserModelEntity();
  final int? userId = jsonConvert.convert<int>(json['userId']);
  if (userId != null) {
    userModelEntity.userId = userId;
  }
  final String? avatar = jsonConvert.convert<String>(json['avatar']);
  if (avatar != null) {
    userModelEntity.avatar = avatar;
  }
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) {
    userModelEntity.nickname = nickname;
  }
  final dynamic birthdayRaw = json['birthday'];
  if (birthdayRaw != null) {
    if (birthdayRaw is int) {
      userModelEntity.birthday = birthdayRaw.toString();
    } else {
      final String? birthday = jsonConvert.convert<String>(birthdayRaw);
      if (birthday != null) {
        userModelEntity.birthday = birthday;
      }
    }
  }
  final String? signature = jsonConvert.convert<String>(json['signature']);
  if (signature != null) {
    userModelEntity.signature = signature;
  }
  final int? gender = jsonConvert.convert<int>(json['gender']);
  if (gender != null) {
    userModelEntity.gender = gender;
  }
  final String? genderDict = jsonConvert.convert<String>(json['gender_dict']);
  if (genderDict != null) {
    userModelEntity.genderDict = genderDict;
  }
  final int? country = jsonConvert.convert<int>(json['country']);
  if (country != null) {
    userModelEntity.country = country;
  }
  final int? userCategory = jsonConvert.convert<int>(json['userCategory']);
  if (userCategory != null) {
    userModelEntity.userCategory = userCategory;
  }
  final int? onlineStatus = jsonConvert.convert<int>(json['onlineStatus']);
  if (onlineStatus != null) {
    userModelEntity.onlineStatus = onlineStatus;
  }
  final int? followStatus = jsonConvert.convert<int>(json['followStatus']);
  final int? following = jsonConvert.convert<int>(json['following']);
  if (followStatus != null) {
    userModelEntity.following = followStatus;
  } else if (following != null) {
    userModelEntity.following = following;
  }
  final int? follower = jsonConvert.convert<int>(json['follower']);
  if (follower != null) {
    userModelEntity.follower = follower;
  }
  final int? blacks = jsonConvert.convert<int>(json['blacks']);
  if (blacks != null) {
    userModelEntity.blacks = blacks;
  }
  final String? createTime = jsonConvert.convert<String>(json['createTime']);
  if (createTime != null) {
    userModelEntity.createTime = createTime;
  }
  final String? lastLoginTime = jsonConvert.convert<String>(json['lastLoginTime']);
  if (lastLoginTime != null) {
    userModelEntity.lastLoginTime = lastLoginTime;
  }
  final String? email = jsonConvert.convert<String>(json['email']);
  if (email != null) {
    userModelEntity.email = email;
  }
  final bool? isChangeInfo = jsonConvert.convert<bool>(json['isChangeInfo']);
  if (isChangeInfo != null) {
    userModelEntity.isChangeInfo = isChangeInfo;
  }
  final String? token = jsonConvert.convert<String>(json['token']);
  if (token != null) {
    userModelEntity.token = token;
  }
  final String? rtmToken = jsonConvert.convert<String>(json['rtmToken']);
  if (rtmToken != null) {
    userModelEntity.rtmToken = rtmToken;
  }
  final String? tencentUserSig = jsonConvert.convert<String>(json['tencentUserSig']);
  if (tencentUserSig != null) {
    userModelEntity.tencentUserSig = tencentUserSig;
  }
  final int? callPrice = jsonConvert.convert<int>(json['callPrice']);
  if (callPrice != null) {
    userModelEntity.callPrice = callPrice;
  }
  final String? agentCode = jsonConvert.convert<String>(json['agentCode']);
  if (agentCode != null) {
    userModelEntity.agentCode = agentCode;
  }
  final int? linkType = jsonConvert.convert<int>(json['linkType']);
  if (linkType != null) {
    userModelEntity.linkType = linkType;
  }
  final String? linkNo = jsonConvert.convert<String>(json['linkNo']);
  if (linkNo != null) {
    userModelEntity.linkNo = linkNo;
  }
  final int? experience = jsonConvert.convert<int>(json['experience']);
  if (experience != null) {
    userModelEntity.experience = experience;
  }
  final String? experienceDescribe = jsonConvert.convert<String>(json['experienceDescribe']);
  if (experienceDescribe != null) {
    userModelEntity.experienceDescribe = experienceDescribe;
  }
  final int? walletBalance = jsonConvert.convert<int>(json['walletBalance']);
  if (walletBalance != null) {
    userModelEntity.walletBalance = walletBalance;
  }
  final int? coinBalance = jsonConvert.convert<int>(json['coinBalance']);
  if (coinBalance != null) {
    userModelEntity.coinBalance = coinBalance;
  }
  final int? availableBalance = jsonConvert.convert<int>(json['availableBalance']);
  if (availableBalance != null) {
    userModelEntity.availableBalance = availableBalance;
  }
  final int? auditStatus = jsonConvert.convert<int>(json['auditStatus']);
  if (auditStatus != null) {
    userModelEntity.auditStatus = auditStatus;
  }
  final String? auditReason = jsonConvert.convert<String>(json['auditReason']);
  if (auditReason != null) {
    userModelEntity.auditReason = auditReason;
  }
  final List<UserModelUserTags>? userTags = (json['userTags'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<UserModelUserTags>(e) as UserModelUserTags)
      .toList();
  if (userTags != null) {
    userModelEntity.userTags = userTags;
  }
  final List<UserModelUserPictures>? userPictures = (json['userPictures'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<UserModelUserPictures>(e) as UserModelUserPictures)
      .toList();
  if (userPictures != null) {
    userModelEntity.userPictures = userPictures;
  }
  final int? freezeMoney = jsonConvert.convert<int>(json['freezeMoney']);
  if (freezeMoney != null) {
    userModelEntity.freezeMoney = freezeMoney;
  }
  final int? age = jsonConvert.convert<int>(json['age']);
  if (age != null) {
    userModelEntity.age = age;
  }
  final int? callAvgTimes =
      jsonConvert.convert<int>(json['callAvgTimes']) ?? jsonConvert.convert<int>(json['call_avg_times']);
  if (callAvgTimes != null) {
    userModelEntity.callAvgTimes = callAvgTimes;
  }
  final int? callNum = jsonConvert.convert<int>(json['callNum']) ?? jsonConvert.convert<int>(json['call_num']);
  if (callNum != null) {
    userModelEntity.callNum = callNum;
  }
  final List<CallHistory>? callList = (json['callList'] as List<dynamic>?)
      ?.map((e) => CallHistory.fromJson(e as Map<String, dynamic>))
      .toList();
  if (callList != null) {
    userModelEntity.callList = callList;
  }
  return userModelEntity;
}

Map<String, dynamic> $UserModelEntityToJson(UserModelEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['userId'] = entity.userId;
  data['avatar'] = entity.avatar;
  data['nickname'] = entity.nickname;
  data['birthday'] = entity.birthday;
  data['signature'] = entity.signature;
  data['gender'] = entity.gender;
  data['gender_dict'] = entity.genderDict;
  data['country'] = entity.country;
  data['userCategory'] = entity.userCategory;
  data['onlineStatus'] = entity.onlineStatus;
  data['following'] = entity.following;
  data['follower'] = entity.follower;
  data['blacks'] = entity.blacks;
  data['createTime'] = entity.createTime;
  data['lastLoginTime'] = entity.lastLoginTime;
  data['email'] = entity.email;
  data['isChangeInfo'] = entity.isChangeInfo;
  data['token'] = entity.token;
  data['rtmToken'] = entity.rtmToken;
  data['tencentUserSig'] = entity.tencentUserSig;
  data['callPrice'] = entity.callPrice;
  data['agentCode'] = entity.agentCode;
  data['linkType'] = entity.linkType;
  data['linkNo'] = entity.linkNo;
  data['experience'] = entity.experience;
  data['experienceDescribe'] = entity.experienceDescribe;
  data['walletBalance'] = entity.walletBalance;
  data['coinBalance'] = entity.coinBalance;
  data['availableBalance'] = entity.availableBalance;
  data['auditStatus'] = entity.auditStatus;
  data['auditReason'] = entity.auditReason;
  data['userTags'] = entity.userTags.map((v) => v.toJson()).toList();
  data['userPictures'] = entity.userPictures.map((v) => v.toJson()).toList();
  data['freezeMoney'] = entity.freezeMoney;
  data['age'] = entity.age;
  data['callAvgTimes'] = entity.callAvgTimes;
  data['callNum'] = entity.callNum;
  data['callList'] = entity.callList.map((v) => v.toJson()).toList();
  return data;
}

extension UserModelEntityExtension on UserModelEntity {
  UserModelEntity copyWith({
    int? userId,
    String? avatar,
    String? nickname,
    String? birthday,
    String? signature,
    int? gender,
    String? genderDict,
    int? country,
    int? userCategory,
    int? onlineStatus,
    int? following,
    int? follower,
    int? blacks,
    String? createTime,
    String? lastLoginTime,
    String? email,
    bool? isChangeInfo,
    String? token,
    String? rtmToken,
    String? tencentUserSig,
    int? callPrice,
    String? agentCode,
    int? linkType,
    String? linkNo,
    int? experience,
    String? experienceDescribe,
    int? walletBalance,
    int? coinBalance,
    int? availableBalance,
    int? auditStatus,
    String? auditReason,
    List<UserModelUserTags>? userTags,
    List<UserModelUserPictures>? userPictures,
    int? freezeMoney,
    int? age,
    int? callAvgTimes,
    int? callNum,
    List<CallHistory>? callList,
  }) {
    return UserModelEntity()
      ..userId = userId ?? this.userId
      ..avatar = avatar ?? this.avatar
      ..nickname = nickname ?? this.nickname
      ..birthday = birthday ?? this.birthday
      ..signature = signature ?? this.signature
      ..gender = gender ?? this.gender
      ..genderDict = genderDict ?? this.genderDict
      ..country = country ?? this.country
      ..userCategory = userCategory ?? this.userCategory
      ..onlineStatus = onlineStatus ?? this.onlineStatus
      ..following = following ?? this.following
      ..follower = follower ?? this.follower
      ..blacks = blacks ?? this.blacks
      ..createTime = createTime ?? this.createTime
      ..lastLoginTime = lastLoginTime ?? this.lastLoginTime
      ..email = email ?? this.email
      ..isChangeInfo = isChangeInfo ?? this.isChangeInfo
      ..token = token ?? this.token
      ..rtmToken = rtmToken ?? this.rtmToken
      ..tencentUserSig = tencentUserSig ?? this.tencentUserSig
      ..callPrice = callPrice ?? this.callPrice
      ..agentCode = agentCode ?? this.agentCode
      ..linkType = linkType ?? this.linkType
      ..linkNo = linkNo ?? this.linkNo
      ..experience = experience ?? this.experience
      ..experienceDescribe = experienceDescribe ?? this.experienceDescribe
      ..walletBalance = walletBalance ?? this.walletBalance
      ..coinBalance = coinBalance ?? this.coinBalance
      ..availableBalance = availableBalance ?? this.availableBalance
      ..auditStatus = auditStatus ?? this.auditStatus
      ..auditReason = auditReason ?? this.auditReason
      ..userTags = userTags ?? this.userTags
      ..userPictures = userPictures ?? this.userPictures
      ..freezeMoney = freezeMoney ?? this.freezeMoney
      ..age = age ?? this.age
      ..callAvgTimes = callAvgTimes ?? this.callAvgTimes
      ..callNum = callNum ?? this.callNum
      ..callList = callList ?? this.callList;
  }
}

UserModelUserTags $UserModelUserTagsFromJson(Map<String, dynamic> json) {
  final UserModelUserTags userModelUserTags = UserModelUserTags();
  final String? dictType = jsonConvert.convert<String>(json['dictType']);
  if (dictType != null) {
    userModelUserTags.dictType = dictType;
  }
  final int? dictValue = jsonConvert.convert<int>(json['dictValue']);
  if (dictValue != null) {
    userModelUserTags.dictValue = dictValue;
  }
  final String? dictLabel = jsonConvert.convert<String>(json['dictLabel']);
  if (dictLabel != null) {
    userModelUserTags.dictLabel = dictLabel;
  }
  return userModelUserTags;
}

Map<String, dynamic> $UserModelUserTagsToJson(UserModelUserTags entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['dictType'] = entity.dictType;
  data['dictValue'] = entity.dictValue;
  data['dictLabel'] = entity.dictLabel;
  return data;
}

extension UserModelUserTagsExtension on UserModelUserTags {
  UserModelUserTags copyWith({String? dictType, int? dictValue, String? dictLabel}) {
    return UserModelUserTags()
      ..dictType = dictType ?? this.dictType
      ..dictValue = dictValue ?? this.dictValue
      ..dictLabel = dictLabel ?? this.dictLabel;
  }
}

UserModelUserPictures $UserModelUserPicturesFromJson(Map<String, dynamic> json) {
  final UserModelUserPictures userModelUserPictures = UserModelUserPictures();
  final String? url = jsonConvert.convert<String>(json['url']);
  if (url != null) {
    userModelUserPictures.url = url;
  }
  final bool? cover = jsonConvert.convert<bool>(json['cover']);
  if (cover != null) {
    userModelUserPictures.cover = cover;
  }
  final int? type = jsonConvert.convert<int>(json['type']);
  if (type != null) {
    userModelUserPictures.type = type;
  }
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    userModelUserPictures.id = id;
  }
  final int? coin = jsonConvert.convert<int>(json['coin']);
  if (coin != null) {
    userModelUserPictures.coin = coin;
  }
  final bool? isPay = jsonConvert.convert<bool>(json['isPay']);
  if (isPay != null) {
    userModelUserPictures.isPay = isPay;
  }
  return userModelUserPictures;
}

Map<String, dynamic> $UserModelUserPicturesToJson(UserModelUserPictures entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['url'] = entity.url;
  data['cover'] = entity.cover;
  data['type'] = entity.type;
  data['id'] = entity.id;
  data['coin'] = entity.coin;
  data['isPay'] = entity.isPay;
  return data;
}

extension UserModelUserPicturesExtension on UserModelUserPictures {
  UserModelUserPictures copyWith({String? url, bool? cover, int? type, int? id, int? coin, bool? isPay}) {
    return UserModelUserPictures()
      ..url = url ?? this.url
      ..cover = cover ?? this.cover
      ..type = type ?? this.type
      ..id = id ?? this.id
      ..coin = coin ?? this.coin
      ..isPay = isPay ?? this.isPay;
  }
}
