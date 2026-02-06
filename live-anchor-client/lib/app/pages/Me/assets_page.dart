import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/assets_controller.dart';
import '../../../data/models/picture_list_model.dart';
import '../../../data/models/video_list_model.dart';
import 'add_media_preview_page.dart';
import 'video_record_page.dart';

/// 资产页面（照片/视频管理）
class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PageController? _pageController;
  final ScrollController _typeSelectorScrollController = ScrollController();
  final ScrollController _videoListScrollController = ScrollController();
  // 存储按钮的 GlobalKey，用于滚动定位
  final Map<String, GlobalKey> _buttonKeys = {};
  int _selectedPhotoType = 0; // 0: Daily Photos, 1: Sexy Photos
  int _selectedVideoType = 0; // 0: Daily Videos, 1: Sexy Videos（Say Hi 已隐藏）
  int _currentPage = 0; // 当前页面索引

  AssetsController get _controller => Get.find<AssetsController>();

  @override
  void initState() {
    super.initState();
    Get.put(AssetsController());
    // 先初始化 PageController
    _pageController = PageController(initialPage: 0);
    // 再初始化 TabController
    _tabController = TabController(length: 2, vsync: this);

    // TabController 监听器：点击标签时切换页面
    _tabController.addListener(_onTabChanged);
    // 进入页面后加载当前 Tab 数据
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentTabData());
  }

  /// 根据当前 Tab 和类型加载数据
  void _loadCurrentTabData() {
    if (_currentPage == 0) {
      _controller.currentPhotoType = _selectedPhotoType;
      _controller.loadPhotos(type: _selectedPhotoType);
    } else {
      _controller.loadVideos(type: _selectedVideoType);
    }
  }

  /// TabController 变化监听
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // 切换完成，同步 PageView
      if (_pageController != null && _pageController!.hasClients && _currentPage != _tabController.index) {
        _pageController!.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController?.dispose();
    _typeSelectorScrollController.dispose();
    _videoListScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: _buildHeader(),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildPhotoGrid()),
    );
  }

  /// 构建头部 Tab（居中显示，放在 AppBar 的 title 中）
  Widget _buildHeader() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Photos'),
        Tab(text: 'Videos'),
      ],
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(
          color: Color(0xFFFF1493), // 底部指示器颜色（粉色）
          width: 3, // 指示器高度
        ),
        insets: const EdgeInsets.only(bottom: 5), // 指示器距离底部 5
      ),
      indicatorSize: TabBarIndicatorSize.label, // 指示器宽度与文字一致
      dividerColor: Colors.transparent,
      isScrollable: false,
      tabAlignment: TabAlignment.center,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  /// 构建照片/视频类型选择器
  /// [isVideosPage] 由调用方传入：Photos 页传 false，Videos 页传 true，避免依赖 _currentPage 导致切到 Videos 后仍显示 Photos 栏
  Widget _buildPhotoTypeSelector({required bool isVideosPage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            // 类型按钮区域（可水平滚动）
            Expanded(
              child: SingleChildScrollView(
                controller: _typeSelectorScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVideosPage) ...[
                      _buildTypeButton('Daily Videos', 0, isVideo: true),
                      const SizedBox(width: 12),
                      _buildTypeButton('Sexy Videos', 1, isVideo: true),
                    ] else ...[
                      _buildTypeButton('Daily Photos', 0, isVideo: false),
                      const SizedBox(width: 12),
                      _buildTypeButton('Sexy Photos', 1, isVideo: false),
                    ],
                  ],
                ),
              ),
            ),
            // 只在 Photos 页面显示 Save 按钮
            if (!isVideosPage) ...[const SizedBox(width: 12), _buildSaveButton()],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, int index, {required bool isVideo}) {
    final isSelected = isVideo ? _selectedVideoType == index : _selectedPhotoType == index;
    // 使用唯一的 key 标识每个按钮
    final String keyId = '${isVideo ? 'video' : 'photo'}_$index';
    if (!_buttonKeys.containsKey(keyId)) {
      _buttonKeys[keyId] = GlobalKey();
    }
    final buttonKey = _buttonKeys[keyId]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isVideo) {
            _selectedVideoType = index;
            _controller.loadVideos(type: index);
          } else {
            _selectedPhotoType = index;
            _controller.currentPhotoType = index;
            _controller.loadPhotos(type: index);
          }
        });
        // 延迟一帧后滚动，确保按钮已渲染
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToButton(buttonKey);
        });
      },
      child: Container(
        key: buttonKey,
        constraints: const BoxConstraints(minWidth: 0), // 防止无限宽度
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF1493) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey),
        ),
        child: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// 滚动到指定按钮，确保按钮完全可见
  void _scrollToButton(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // 将按钮滚动到视口中间
      );
    }
  }

  Widget _buildSaveButton() {
    return Obx(() {
      final saving = _controller.isSavingPhotoChanges.value;
      return GestureDetector(
        onTap: saving ? null : () => _controller.savePhotoChanges(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF69B4), // 亮粉
                Color(0xFFFF1493), // 深粉
                Color(0xFFC71585), // 紫红
                Color(0xFF8B008B), // 深紫
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 48,
            height: 24,
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      );
    });
  }

  /// 构建描述文字
  Widget _buildDescription() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        'Users can see these images when viewing your detailed information. These photos should not be too revealing, they can be very sexy. If it\'s too exposed, we won\'t be able to approve it. And these images are meant to increase your exposure. It is recommended to upload free images, as paying for them may affect your exposure.',
        style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
      ),
    );
  }

  /// 构建照片网格（支持水平滑动切换 Photos 和 Videos）
  /// 整个页面都可以左右滑动切换
  Widget _buildPhotoGrid() {
    // 确保 _pageController 已初始化
    if (_pageController == null) {
      return const SizedBox.shrink();
    }

    return PageView(
      controller: _pageController!,
      onPageChanged: (index) {
        // 页面切换时，同步更新 TabController 和当前页面索引
        setState(() {
          _currentPage = index;
        });
        if (_tabController.index != index) {
          _tabController.animateTo(index);
        }
        _loadCurrentTabData();
      },
      children: [
        // Photos 页面（包含完整内容）
        _buildPhotosPage(),
        // Videos 页面（包含完整内容）
        _buildVideosPage(),
      ],
    );
  }

  /// 构建 Photos 完整页面
  Widget _buildPhotosPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoTypeSelector(isVideosPage: false),
        Expanded(child: _buildPhotosContent()),
      ],
    );
  }

  /// 构建 Videos 完整页面（按选中的子类型切换不同 UI）
  Widget _buildVideosPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoTypeSelector(isVideosPage: true),
        Expanded(child: _buildDailySexyVideosContent()),
      ],
    );
  }

  /// Say Hi Video 界面：说明 + 上传区 + Submit + 绿色按钮（第一张图）
  Widget _buildSayHiVideoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'The introduction video is where you showcase yourself to users, and this video is usually automatically pushed to users by the system in the form of a message, so this type of video can be sexy, but it cannot be exposed, otherwise we will not pass the review.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildSayHiUploadArea(),
          const SizedBox(height: 16),
          const Text(
            'To make your profile more attractive, please upload a self-introduction video; video length should be between 30-60 seconds.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSubmitButton()),
              const SizedBox(width: 12),
              _buildGreenCircleButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSayHiUploadArea() {
    return GestureDetector(
      onTap: () {
        /* TODO: 选择视频 */
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 8),
              Text('Upload video', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFC71585), Color(0xFF8B008B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Submit',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildGreenCircleButton() {
    return Material(
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          /* TODO: 刷新或操作 */
        },
        borderRadius: BorderRadius.circular(24),
        child: const SizedBox(width: 48, height: 48, child: Icon(Icons.refresh, color: Colors.white, size: 24)),
      ),
    );
  }

  /// Daily / Sexy Videos 界面：说明 + 吸顶 Video total income + 列表/空状态 + 底部固定加号（第二、三张图）
  Widget _buildDailySexyVideosContent() {
    return Stack(
      children: [
        CustomScrollView(
          controller: _videoListScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  _selectedVideoType == 0
                      ? 'After uploading and passing the review, the system will automatically send these videos in the form of messages to daily logged in users. Improve your exposure and upload paid and larger scale videos, which can increase your income.'
                      : 'Users can see these videos when viewing your detailed information. These videos should not be too explicit, they can be very sexy. If it\'s too exposed, we won\'t be able to approve it. And these videos are intended to increase your exposure to users.',
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _VideoTotalIncomeSliverDelegate(child: _buildVideoTotalIncomeBar()),
            ),
            // Video total income 与下方内容留出间距
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            Obx(() {
              final pending = _controller.pendingPublishVideo.value;
              final list = pending != null ? [..._controller.videoList, pending] : _controller.videoList;
              final isLoading = _controller.isLoadingVideos.value;
              final isPublishing = _controller.isPublishingVideo.value;
              if (isLoading && list.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
                  ),
                );
              }
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.videocam_outlined, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Uploading high-quality videos will bring you more calls and video income.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              // 有数据时只显示实际数据项，不增加添加占位格
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = list[index];
                    final showPublishing = item.videoId == null && isPublishing;
                    return _buildDailySexyVideoItem(item, isPublishing: showPublishing);
                  }, childCount: list.length),
                ),
              );
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildFixedFab()),
      ],
    );
  }

  /// 吸顶的 Video total income 条（高度需与 _VideoTotalIncomeSliverDelegate._headerExtent 一致）
  /// 金币数量显示接口返回的 totalIncome
  Widget _buildVideoTotalIncomeBar() {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFC71585), Color(0xFF8B008B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Obx(() {
        final income = _controller.videoTotalIncome.value;
        final display = '\$ ${income.toStringAsFixed(2)}';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Video total income:',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              display,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFixedFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: Material(
          color: const Color(0xFF4CAF50),
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: () {
              // Daily=0, Sexy=1：两种类型都走同一套添加流程，仅请求参数 type 不同
              if (_selectedVideoType == 0 || _selectedVideoType == 1 || _selectedVideoType == 2) {
                _showVideoSourceSheet();
              }
            },
            customBorder: const CircleBorder(),
            child: const SizedBox(width: 56, height: 56, child: Icon(Icons.add, color: Colors.white, size: 28)),
          ),
        ),
      ),
    );
  }

  /// Photos 标签下：点击选项时弹出「从相册/相机」选择照片的 sheet
  void _showPhotoSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF1493)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Get.back();
                  _pickPhotoFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFF1493)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Get.back();
                  _takePhoto();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Videos 标签下：点击底部 + 时弹出「从相册/相机」选择视频的 sheet
  void _showVideoSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library, color: Color(0xFFFF1493)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Get.back();
                  _pickVideoFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFFFF1493)),
                title: const Text('Record Video', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Get.back();
                  _recordVideo();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        _controller.currentPhotoType = _selectedPhotoType;
        Get.to(() => AddMediaPreviewPage(path: xFile.path, isVideo: false));
      }
    } catch (e) {
      if (mounted) Get.snackbar('Notice', 'Failed to select image');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? xFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        _controller.currentPhotoType = _selectedPhotoType;
        Get.to(() => AddMediaPreviewPage(path: xFile.path, isVideo: false));
      }
    } catch (e) {
      if (mounted) Get.snackbar('Notice', 'Failed to take photo');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file != null && mounted) {
        final result = await Get.to<Map<String, dynamic>?>(
          () => AddMediaPreviewPage(path: file.path, isVideo: true, videoType: _selectedVideoType),
        );
        _onVideoPreviewResult(result);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Notice', 'Failed to select video');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final path = await Get.to<String?>(() => const VideoRecordPage());
      if (path != null && path.isNotEmpty && mounted) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        final result = await Get.to<Map<String, dynamic>?>(
          () => AddMediaPreviewPage(path: path, isVideo: true, videoType: _selectedVideoType),
        );
        _onVideoPreviewResult(result);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Notice', 'Failed to record video');
    }
  }

  void _onVideoPreviewResult(Map<String, dynamic>? result) {
    if (result == null || result['videoUrl'] == null || !mounted) return;
    _controller.addPendingVideoAndPublish(
      videoUrl: result['videoUrl'] as String,
      cover: result['cover'] as String? ?? '',
      duration: result['duration'] as int? ?? 0,
      type: result['type'] as int? ?? _selectedVideoType,
      coin: result['coin'] as int? ?? 0,
    );
    // 新视频插入列表末尾，等列表布局完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_videoListScrollController.hasClients) {
          _videoListScrollController.animateTo(
            _videoListScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Widget _buildDailySexyVideoItem(VideoListItem item, {bool isPublishing = false}) {
    return GestureDetector(
      onTap: () {
        if (!isPublishing) {
          // TODO: 播放/编辑
        }
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.cover != null && (item.cover?.isNotEmpty ?? false))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item.cover!, fit: BoxFit.cover),
              )
            else
              const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48)),
            // 视频播放图标（居中叠加）
            const Center(child: Icon(Icons.play_circle_filled, color: Colors.white70, size: 48)),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Text(item.durationText, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  if (!isPublishing && item.videoId != null) {
                    _controller.removeVideoFromList(item.videoId!);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            if (isPublishing)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
              ),
            // 底部：金币在上、左对齐；有审核状态时审核标签在金币下面，没有时金币自然落底
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('asset/images/common/coin.png', width: 18, height: 18, fit: BoxFit.contain),
                        const SizedBox(width: 4),
                        Text(
                          '${item.coin ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (item.auditStatus != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF362A5A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: item.statusColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.statusIcon, color: item.statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(item.statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Photos 页面内容（包含描述文字和网格，统一滚动）
  Widget _buildPhotosContent() {
    return Obx(() {
      final list = _controller.photoList;
      final pending = _controller.pendingAddPhotos;
      final isLoading = _controller.isLoadingPhotos.value;
      final isUploading = _controller.isUploadingPhoto.value;
      // 展示列表 = 接口数据 + 待保存（上传得到 url 的）
      final displayList = <PictureListItem>[
        ...list,
        ...pending.map((p) => PictureListItem(url: p.url, type: p.type, coin: p.coin)),
      ];
      final count = displayList.length + 1; // 数据项 + 1 个添加位
      final childCount = count < 9 ? 9 : count;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildDescription()),
          if (isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < displayList.length) {
                    return _buildPhotoItem(displayList[index]);
                  }
                  // 只有第一个添加格（紧挨数据的那格）显示上传中，其余空位不转圈
                  final isFirstAddSlot = index == displayList.length;
                  return _buildPhotoItem(null, isUploading: isUploading && isFirstAddSlot);
                }, childCount: childCount),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    });
  }

  Widget _buildPhotoItem(PictureListItem? item, {bool isUploading = false}) {
    final isAddSlot = item == null;
    return GestureDetector(
      onTap: () {
        if (isAddSlot && !isUploading) {
          _showPhotoSourceSheet();
        } else if (!isAddSlot) {
          // TODO: 预览/编辑
        }
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(12)),
        child: isAddSlot
            ? Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 32),
                  if (isUploading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: Color(0xFFFF1493), strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              )
            : _buildPhotoThumb(item),
      ),
    );
  }

  Widget _buildPhotoThumb(PictureListItem item) {
    final url = item.url;
    final id = item.id;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null && url.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.cover),
          )
        else
          const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 32)),
        // 左上角：cover 为 true 时显示 Cover 标志
        if (item.cover == true)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'Cover',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        // 右上角：关闭按钮。有 id 为已保存项→加入待删除；无 id 有 url 为待保存项→从待保存移除
        if (id != null || (url != null && url.isNotEmpty))
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                if (id != null) {
                  _controller.removePhotoFromList(id);
                } else if (url != null && url.isNotEmpty) {
                  _controller.removePendingAddPhoto(url);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('asset/images/common/coin.png', width: 18, height: 18, fit: BoxFit.contain),
                  const SizedBox(width: 4),
                  Text(
                    '${item.coin ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Video total income 吸顶条用的 SliverPersistentHeaderDelegate
class _VideoTotalIncomeSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _VideoTotalIncomeSliverDelegate({required this.child});

  @override
  double get minExtent => _VideoTotalIncomeSliverDelegate._headerExtent;

  @override
  double get maxExtent => _VideoTotalIncomeSliverDelegate._headerExtent;

  static const double _headerExtent = 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.black,
      child: SizedBox(height: _headerExtent, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _VideoTotalIncomeSliverDelegate oldDelegate) => oldDelegate.child != child;
}
