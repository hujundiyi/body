import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/country_dict_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/anchor_model.dart';
import '../../routes/app_routes.dart';

/// 主播申请控制器
class AnchorApplyController extends BaseController {
  // 表单控制器
  final formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController();
  final whatsappController = TextEditingController();
  final signatureController = TextEditingController();
  final agentCodeController = TextEditingController();

  // 图片选择器
  final ImagePicker _picker = ImagePicker();

  // 照片列表（至少3张）
  final RxList<File> photos = <File>[].obs;
  // 照片 URL 列表（与 photos 一一对应）
  final RxList<String> photoUrls = <String>[].obs;
  static const int minPhotos = 3;
  static const int maxPhotos = 9;

  // 选中的标签
  final RxList<UserTag> selectedTags = <UserTag>[].obs;

  // 可选标签列表
  final RxList<UserTag> availableTags = <UserTag>[].obs;

  // 选中的国家
  final Rx<int?> selectedCountry = Rx<int?>(null);

  // 选中的性别（默认：女）
  final Rx<int?> selectedGender = Rx<int?>(Gender.female);

  // 生日
  final Rx<DateTime?> birthday = Rx<DateTime?>(null);

  // 是否重新提交
  bool isResubmit = false;
  String? rejectReason;

  /// 是否从「我」页头像进入的资料编辑模式（标题显示 Edit，先请求用户信息并预填）
  bool isEditMode = false;

  /// 已有照片 URL（从接口拉取，编辑时展示，提交时一并带上）
  final RxList<String> existingPhotoUrls = <String>[].obs;

  // 国家列表（从接口获取）
  final RxList<Map<String, dynamic>> countries = <Map<String, dynamic>>[].obs;

  // 性别选项列表（从接口获取）
  final RxList<Map<String, dynamic>> genderOptions = <Map<String, dynamic>>[].obs;

  // 联系方式类型列表（从接口获取）
  final RxList<Map<String, dynamic>> linkTypeOptions = <Map<String, dynamic>>[].obs;

  // 选中的联系方式类型
  final Rx<int?> selectedLinkType = Rx<int?>(null);

  // 通话价格列表（从接口获取）
  final RxList<Map<String, dynamic>> callPriceOptions = <Map<String, dynamic>>[].obs;

  // 选中的通话价格
  final Rx<double?> selectedCallPrice = Rx<double?>(null);

  @override
  void onControllerInit() {
    super.onControllerInit();
    _loadArguments();
    _loadDictData().then((_) {
      if (isEditMode) {
        _loadUserInfo();
      } else {
        _fillFormFromLocalIfNeeded();
      }
    });
  }

  /// 未从登录带入 anchor 时（如杀进程重启后直接进申请页），用本地已存储的用户信息预填
  void _fillFormFromLocalIfNeeded() {
    final args = Get.arguments;
    final hasAnchorFromArgs = args is Map && args.containsKey('anchor');
    if (hasAnchorFromArgs) return;
    try {
      final auth = Get.find<AuthService>();
      if (auth.userInfo != null) {
        _fillFormFromAnchor(auth.userInfo!);
      }
    } catch (e) {
      debugPrint('从本地用户信息预填失败: $e');
    }
  }

  @override
  void onControllerClose() {
    nicknameController.dispose();
    whatsappController.dispose();
    signatureController.dispose();
    agentCodeController.dispose();
    super.onControllerClose();
  }

  /// 加载参数（含登录后带入的 anchor，用于预填表单）
  void _loadArguments() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      isEditMode = args['fromAvatar'] == true || args['edit'] == true;
      isResubmit = args['resubmit'] == true;
      rejectReason = args['reason'] as String?;
      if (rejectReason != null && rejectReason!.isNotEmpty && !isResubmit) {
        isResubmit = true;
      }
      final anchorJson = args['anchor'];
      if (anchorJson != null && anchorJson is Map<String, dynamic>) {
        try {
          final anchor = AnchorModel.fromJson(anchorJson);
          _fillFormFromAnchor(anchor);
        } catch (e) {
          debugPrint('预填登录信息失败: $e');
        }
      }
    }
  }

  /// 用登录返回的 anchor 预填申请表单
  void _fillFormFromAnchor(AnchorModel info) {
    nicknameController.text = info.nickname ?? '';
    whatsappController.text = info.linkNo ?? '';
    signatureController.text = info.signature ?? '';
    agentCodeController.text = info.agentCode ?? '';
    if (info.country != null) selectedCountry.value = info.country;
    if (info.gender != null) selectedGender.value = info.gender;
    if (info.birthday != null) birthday.value = info.birthday;
    if (info.linkType != null) selectedLinkType.value = info.linkType;
    if (info.callPrice != null) selectedCallPrice.value = info.callPrice;
    if (info.userTags != null && info.userTags!.isNotEmpty) {
      selectedTags.assignAll(info.userTags!);
    }
    if (info.userPictures != null && info.userPictures!.isNotEmpty) {
      existingPhotoUrls.assignAll(info.userPictures!.map((p) => p.url ?? '').where((url) => url.isNotEmpty));
    }
  }

  /// 编辑模式下请求个人用户信息并预填表单
  Future<void> _loadUserInfo() async {
    try {
      final info = await AnchorAPIService.shared.getAnchorInfo();
      nicknameController.text = info.nickname ?? '';
      whatsappController.text = info.linkNo ?? '';
      signatureController.text = info.signature ?? '';
      agentCodeController.text = info.agentCode ?? '';
      if (info.country != null) selectedCountry.value = info.country;
      if (info.gender != null) selectedGender.value = info.gender;
      if (info.birthday != null) birthday.value = info.birthday;
      if (info.linkType != null) selectedLinkType.value = info.linkType;
      if (info.callPrice != null) selectedCallPrice.value = info.callPrice;
      if (info.userTags != null && info.userTags!.isNotEmpty) {
        selectedTags.assignAll(info.userTags!);
      }
      if (info.userPictures != null && info.userPictures!.isNotEmpty) {
        existingPhotoUrls.assignAll(info.userPictures!.map((p) => p.url ?? '').where((url) => url.isNotEmpty));
      }
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
    }
  }

  /// 删除已有照片（编辑模式下从接口拉取的）
  void removeExistingPhoto(int index) {
    if (index >= 0 && index < existingPhotoUrls.length) {
      existingPhotoUrls.removeAt(index);
    }
  }

  /// 点击已有照片：选择新图并上传，替换该位置的 URL
  Future<void> replaceExistingPhotoAt(int index, ImageSource source) async {
    if (index < 0 || index >= existingPhotoUrls.length) return;
    try {
      final XFile? image = source == ImageSource.camera
          ? await _picker.pickImage(
              source: source,
              maxWidth: 1080,
              maxHeight: 1080,
              imageQuality: 85,
              preferredCameraDevice: CameraDevice.front,
            )
          : await _picker.pickImage(source: source, maxWidth: 1080, maxHeight: 1080, imageQuality: 85);
      if (image == null) return;
      final file = File(image.path);
      final url = await _uploadSingleFileAndGetUrl(file);
      if (url != null) {
        existingPhotoUrls[index] = url;
      }
    } catch (e) {
      showError('Failed to replace photo');
    }
  }

  /// 点击新照片：选择新图并上传，替换该位置
  Future<void> replaceNewPhotoAt(int index, ImageSource source) async {
    if (index < 0 || index >= photos.length) return;
    try {
      final XFile? image = source == ImageSource.camera
          ? await _picker.pickImage(
              source: source,
              maxWidth: 1080,
              maxHeight: 1080,
              imageQuality: 85,
              preferredCameraDevice: CameraDevice.front,
            )
          : await _picker.pickImage(source: source, maxWidth: 1080, maxHeight: 1080, imageQuality: 85);
      if (image == null) return;
      final file = File(image.path);
      final url = await _uploadSingleFileAndGetUrl(file);
      if (url != null) {
        photos[index] = file;
        if (index < photoUrls.length) {
          photoUrls[index] = url;
        } else {
          photoUrls.insert(index, url);
        }
      }
    } catch (e) {
      showError('Failed to replace photo');
    }
  }

  /// 加载字典数据（国家优先本地缓存，其余从接口拉取）
  Future<void> _loadDictData() async {
    try {
      // 国家：优先本地缓存，无则请求字典接口
      final countryService = Get.find<CountryDictService>();
      await countryService.loadCountryDict();
      countries.assignAll(
        countryService.getCountryItemsList().map((item) {
          return {'code': item.value, 'name': item.label, 'flag': item.icon ?? '🌍'};
        }),
      );

      // 其余字典从接口获取
      final dictList = await AnchorAPIService.shared.getDict(['gender', 'anchor_self_tags', 'link_type', 'call_price']);

      for (final dict in dictList) {
        if (dict.dictType == 'gender') {
          // 处理性别数据
          genderOptions.assignAll(
            dict.dictItems.map((item) {
              return {'value': item.value, 'label': item.label, 'icon': item.icon};
            }),
          );
        } else if (dict.dictType == 'anchor_self_tags') {
          // 处理标签数据
          availableTags.assignAll(
            dict.dictItems.map((item) {
              return UserTag(dictType: 'anchor_self_tags', dictValue: item.value, dictLabel: item.label);
            }),
          );
        } else if (dict.dictType == 'link_type') {
          // 处理联系方式类型数据
          linkTypeOptions.assignAll(
            dict.dictItems.map((item) {
              return {'value': item.value, 'label': item.label, 'icon': item.icon};
            }),
          );
          // 默认选择第一个
          if (linkTypeOptions.isNotEmpty && selectedLinkType.value == null) {
            selectedLinkType.value = linkTypeOptions[0]['value'] as int;
          }
        } else if (dict.dictType == 'call_price') {
          // 处理通话价格数据
          callPriceOptions.assignAll(
            dict.dictItems.map((item) {
              return {
                'value': item.value.toDouble(), // 转换为 double
                'label': item.label, // 显示金额
              };
            }),
          );
          // 默认选择第一个
          if (callPriceOptions.isNotEmpty && selectedCallPrice.value == null) {
            selectedCallPrice.value = callPriceOptions[0]['value'] as double;
          }
        }
      }
    } catch (e) {
      debugPrint('获取字典数据失败: $e');
      // 如果接口失败，使用默认数据
      _loadDefaultData();
    }
  }

  /// 加载默认数据（接口失败时的备用数据）
  void _loadDefaultData() {
    // 默认国家列表
    countries.assignAll([
      {'code': 1, 'name': 'China', 'flag': '🇨🇳'},
      {'code': 2, 'name': 'United States', 'flag': '🇺🇸'},
      {'code': 3, 'name': 'Japan', 'flag': '🇯🇵'},
      {'code': 4, 'name': 'South Korea', 'flag': '🇰🇷'},
      {'code': 5, 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': 6, 'name': 'France', 'flag': '🇫🇷'},
      {'code': 7, 'name': 'Germany', 'flag': '🇩🇪'},
      {'code': 8, 'name': 'Russia', 'flag': '🇷🇺'},
      {'code': 9, 'name': 'India', 'flag': '🇮🇳'},
      {'code': 10, 'name': 'Brazil', 'flag': '🇧🇷'},
      {'code': 11, 'name': 'Australia', 'flag': '🇦🇺'},
      {'code': 12, 'name': 'Canada', 'flag': '🇨🇦'},
      {'code': 16, 'name': 'Indonesia', 'flag': '🇮🇩'},
      {'code': 17, 'name': 'Thailand', 'flag': '🇹🇭'},
      {'code': 18, 'name': 'Vietnam', 'flag': '🇻🇳'},
      {'code': 19, 'name': 'Philippines', 'flag': '🇵🇭'},
      {'code': 20, 'name': 'Malaysia', 'flag': '🇲🇾'},
      {'code': 21, 'name': 'Singapore', 'flag': '🇸🇬'},
      {'code': 860, 'name': 'Uzbekistan', 'flag': '🇺🇿'},
    ]);

    // 默认性别选项
    genderOptions.assignAll([
      {'value': 0, 'label': 'Male', 'icon': 'male'},
      {'value': 1, 'label': 'Female', 'icon': 'female'},
      {'value': 2, 'label': 'Unknown', 'icon': 'help'},
    ]);

    // 默认标签列表
    availableTags.assignAll([
      UserTag(dictType: 'anchor_self_tags', dictValue: 1, dictLabel: 'Sexy'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 2, dictLabel: 'Cute'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 3, dictLabel: 'Toy'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 4, dictLabel: 'ASMR'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 5, dictLabel: 'Dance'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 6, dictLabel: 'Sing'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 7, dictLabel: 'Chat'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 8, dictLabel: 'Cosplay'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 9, dictLabel: 'Fitness'),
      UserTag(dictType: 'anchor_self_tags', dictValue: 10, dictLabel: 'Gaming'),
    ]);

    // 默认联系方式类型
    linkTypeOptions.assignAll([
      {'value': 1, 'label': 'WhatsApp', 'icon': 'whatsapp'},
      {'value': 2, 'label': 'Telegram', 'icon': 'telegram'},
      {'value': 3, 'label': 'Line', 'icon': 'line'},
    ]);
    // 默认选择第一个
    if (selectedLinkType.value == null) {
      selectedLinkType.value = 1;
    }

    // 默认通话价格
    callPriceOptions.assignAll([
      {'value': 10.0, 'label': '10'},
      {'value': 20.0, 'label': '20'},
      {'value': 30.0, 'label': '30'},
      {'value': 50.0, 'label': '50'},
      {'value': 100.0, 'label': '100'},
    ]);
    // 默认选择第一个
    if (selectedCallPrice.value == null) {
      selectedCallPrice.value = 10.0;
    }
  }

  /// 选择联系方式类型
  void selectLinkType(int linkType) {
    selectedLinkType.value = linkType;
  }

  /// 选择通话价格
  void selectCallPrice(double callPrice) {
    selectedCallPrice.value = callPrice;
  }

  /// 选择照片
  Future<void> pickPhoto() async {
    if (photos.length >= maxPhotos) {
      showError('Max $maxPhotos photos allowed');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        photos.add(file);
        // 上传照片并获取 URL
        await _uploadPhotoAndGetUrl(file);
      }
    } catch (e) {
      showError('Failed to select photo');
    }
  }

  /// 拍照
  Future<void> takePhoto() async {
    if (photos.length >= maxPhotos) {
      showError('Max $maxPhotos photos allowed');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        final file = File(image.path);
        photos.add(file);
        // 上传照片并获取 URL
        await _uploadPhotoAndGetUrl(file);
      }
    } catch (e) {
      showError('Failed to take photo');
    }
  }

  /// 删除照片
  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      photos.removeAt(index);
      // 同步删除对应的 URL
      if (index < photoUrls.length) {
        photoUrls.removeAt(index);
      }
    }
  }

  /// 切换标签选中状态
  void toggleTag(UserTag tag) {
    final index = selectedTags.indexWhere((t) => t.dictValue == tag.dictValue);
    if (index >= 0) {
      selectedTags.removeAt(index);
    } else {
      if (selectedTags.length < 5) {
        selectedTags.add(tag);
      } else {
        showError('Maximum 5 tags allowed');
      }
    }
  }

  /// 标签是否选中
  bool isTagSelected(UserTag tag) {
    return selectedTags.any((t) => t.dictValue == tag.dictValue);
  }

  /// 选择国家
  void selectCountry(int code) {
    selectedCountry.value = code;
  }

  /// 选择性别
  void selectGender(int gender) {
    selectedGender.value = gender;
  }

  /// 选择生日
  Future<void> selectBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = birthday.value ?? DateTime(now.year - 20);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 18), // 必须满18岁
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF1493),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      birthday.value = date;
    }
  }

  /// 验证昵称
  String? validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter nickname';
    }
    if (value.length < 2 || value.length > 20) {
      return 'Nickname must be 2-20 characters';
    }
    return null;
  }

  /// 验证WhatsApp
  String? validateWhatsApp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter contact information';
    }
    return null;
  }

  /// 计算年龄
  int? get age {
    if (birthday.value == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - birthday.value!.year;
    if (now.month < birthday.value!.month || (now.month == birthday.value!.month && now.day < birthday.value!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// 总照片数（已有 + 新上传）
  int get totalPhotoCount => existingPhotoUrls.length + photos.length;

  /// 提交申请
  Future<void> submitApplication() async {
    if (totalPhotoCount < minPhotos) {
      showError('Please upload at least $minPhotos photos');
      return;
    }
    if (photoUrls.length != photos.length) {
      showError('Please wait for photos to finish uploading');
      return;
    }

    // 验证表单
    if (!formKey.currentState!.validate()) {
      return;
    }

    // 验证生日
    if (birthday.value == null) {
      showError('Please select birthday');
      return;
    }

    // 验证国家
    if (selectedCountry.value == null) {
      showError('Please select country/region');
      return;
    }

    await executeWithLoading(() async {
      try {
        // 1. 构建图集数据：已有 URL + 新上传 URL，第一张为封面
        final allUrls = <String>[...existingPhotoUrls, ...photoUrls];
        final pictures = allUrls.asMap().entries.map((entry) {
          return UserPicture(url: entry.value, cover: entry.key == 0, type: 0);
        }).toList();

        // 2. 提交资料（第一个 URL 作为头像）
        final request = AnchorSetInfoRequest(
          avatar: allUrls.isNotEmpty ? allUrls[0] : null,
          nickname: nicknameController.text.trim(),
          birthday: birthday.value,
          signature: signatureController.text.trim().isEmpty ? null : signatureController.text.trim(),
          gender: selectedGender.value, // 性别传 id
          country: selectedCountry.value, // 国家传 id
          callPrice: selectedCallPrice.value, // 通话价格（从接口获取）
          linkType: selectedLinkType.value, // 联系方式类型（从接口获取）
          linkNo: whatsappController.text.trim(),
          agentCode: agentCodeController.text.trim().isEmpty ? null : agentCodeController.text.trim(),
          userTags: selectedTags.isEmpty ? null : selectedTags.toList(), // 标签放到 userTags
          userPictures: pictures, // 图片放到 userPictures
        );

        await AnchorAPIService.shared.setAnchorInfo(request);

        if (isEditMode) {
          showSuccess('Saved');
          Get.back();
        } else {
          showSuccess('Waiting for manual review');
          AppRoutes.goToAnchorLogin();
        }
      } catch (e) {
        showErrorUnlessAuth(e, 'Submission failed: ${e.toString()}');
      }
    });
  }

  /// 上传单张照片并获取 URL（仅追加到 photoUrls，用于新增）
  Future<void> _uploadPhotoAndGetUrl(File photo) async {
    final url = await _uploadSingleFileAndGetUrl(photo);
    if (url != null) {
      photoUrls.add(url);
    } else {
      photos.remove(photo);
    }
  }

  /// 上传单张文件并返回 getUrl，失败返回 null
  Future<String?> _uploadSingleFileAndGetUrl(File photo) async {
    try {
      final uploadInfos = await AnchorAPIService.shared.getPutFileUrls(files: [photo], type: 'picture');
      if (uploadInfos.isEmpty || uploadInfos[0].putUrl == null || uploadInfos[0].getUrl == null) {
        showError('Photo upload failed, please try again');
        return null;
      }
      final uploadInfo = uploadInfos[0];
      await AnchorAPIService.shared.uploadFileToUrl(photo, uploadInfo.putUrl!);
      return uploadInfo.getUrl;
    } catch (e) {
      debugPrint('上传照片失败: $e');
      showErrorUnlessAuth(e, 'Photo upload failed: ${e.toString()}');
      return null;
    }
  }
}
