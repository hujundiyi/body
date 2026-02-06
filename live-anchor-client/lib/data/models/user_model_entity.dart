import 'package:weeder/generated/json/base/json_field.dart';
import 'package:weeder/generated/json/user_model_entity.g.dart';
import 'package:weeder/data/models/call_history_model.dart';
import 'dart:convert';
export 'package:weeder/generated/json/user_model_entity.g.dart';

@JsonSerializable()
class UserModelEntity {
	int userId = 0;
	String avatar = '';
	String nickname = '';
	String birthday = '';
	String signature = '';
	int gender = 0;
	/// 详情接口返回的性别展示文案（gender_dict）
	String genderDict = '';
	int country = 0;
	int userCategory = 0;
	int onlineStatus = 1;
	int following = 0;
	int follower = 0;
	int blacks = 0;
	String createTime = '';
	String lastLoginTime = '';
	String email = '';
	bool isChangeInfo = false;
	String token = '';
	String rtmToken = '';
	String tencentUserSig = '';
	int callPrice = 0;
	String agentCode = '';
	int linkType = 0;
	String linkNo = '';
	int experience = 0;
	String experienceDescribe = '';
	int walletBalance = 0;
	int availableBalance = 0;
	int auditStatus = 0;
	int coinBalance = 0;
	String auditReason = '';
	List<UserModelUserTags> userTags = [];
	List<UserModelUserPictures> userPictures = [];
	int freezeMoney = 0;
	int age = 0;
	/// 根据 birthday 时间戳计算的年龄（当 age 为 0 且 birthday 为时间戳时使用）
	int? get ageFromBirthday {
		if (birthday.isEmpty) return null;
		final ts = int.tryParse(birthday);
		if (ts == null || ts <= 0) return null;
		final birth = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
		final now = DateTime.now();
		int a = now.year - birth.year;
		if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) a--;
		return a > 0 ? a : null;
	}
	/// 平均通话时长（秒），来自 user/getInfo 的 callAvgTimes
	int callAvgTimes = 0;
	/// 通话次数，来自详情接口 user/getInfo 的 callNum
	int callNum = 0;
	/// 通话记录列表，来自详情接口 user/getInfo 的 callList
	List<CallHistory> callList = [];

	UserModelEntity();

	factory UserModelEntity.fromJson(Map<String, dynamic> json) => $UserModelEntityFromJson(json);

	Map<String, dynamic> toJson() => $UserModelEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class UserModelUserTags {
	String dictType = '';
	int dictValue = 0;
	String dictLabel = '';

	UserModelUserTags();

	factory UserModelUserTags.fromJson(Map<String, dynamic> json) => $UserModelUserTagsFromJson(json);

	Map<String, dynamic> toJson() => $UserModelUserTagsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class UserModelUserPictures {
	String url = '';
	bool cover = false;
	int type = 0;
	int id = 0;
	int coin = 0;
	bool isPay = false;

	UserModelUserPictures();

	factory UserModelUserPictures.fromJson(Map<String, dynamic> json) => $UserModelUserPicturesFromJson(json);

	Map<String, dynamic> toJson() => $UserModelUserPicturesToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}