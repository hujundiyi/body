/**
 * Agora RTC 管理器单例
 * 用于在通话创建成功后提前初始化音视频轨道，加快进入房间速度
 */
import AgoraRTC from "agora-rtc-sdk-ng";
import store from "@/store";

class AgoraRTCManager {
  constructor() {
    // 单例实例
    if (AgoraRTCManager.instance) {
      return AgoraRTCManager.instance;
    }
    AgoraRTCManager.instance = this;

    // RTC 客户端
    this.rtcClient = null;
    // 本地音视频轨道
    this.localTracks = {
      videoTrack: null,
      audioTrack: null
    };
    // 是否已初始化
    this.isInitialized = false;
    // 是否正在初始化
    this.isInitializing = false;
    // 初始化 Promise（用于等待初始化完成）
    this.initPromise = null;
    // 美颜开关状态
    this.beautyEnabled = true;
    // 美颜参数配置
    this.beautyOptions = {
      smoothnessLevel: 0.5,
      lighteningLevel: 0.7,
      rednessLevel: 0.1,
      lighteningContrastLevel: 1
    };
  }

  /**
   * 获取单例实例
   */
  static getInstance() {
    if (!AgoraRTCManager.instance) {
      AgoraRTCManager.instance = new AgoraRTCManager();
    }
    return AgoraRTCManager.instance;
  }

  /**
   * 预初始化 - 创建 RTC Client 和本地音视频轨道
   * 在创建通话成功后调用，提前准备好音视频
   */
  async preInit() {
    // 如果已初始化，直接返回
    if (this.isInitialized) {
      console.log('[🎥AgoraRTCManager] 已初始化，跳过');
      return { rtcClient: this.rtcClient, localTracks: this.localTracks };
    }

    // 如果正在初始化，等待初始化完成
    if (this.isInitializing && this.initPromise) {
      console.log('[🎥AgoraRTCManager] 正在初始化中，等待...');
      return this.initPromise;
    }

    // 开始初始化
    this.isInitializing = true;
    console.log('[🎥AgoraRTCManager] 开始预初始化...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    this.initPromise = this._doInit();
    return this.initPromise;
  }

  /**
   * 执行初始化
   */
  async _doInit() {
    try {
      // 检查系统要求
      AgoraRTC.checkSystemRequirements();
      console.log('[🎥AgoraRTCManager] 系统要求检查通过');

      // 1. 创建 RTC Client
      console.log('[🎥AgoraRTCManager] 创建 RTC Client...');
      this.rtcClient = AgoraRTC.createClient({
        mode: "rtc",
        codec: "vp8"
      });
      console.log('[🎥AgoraRTCManager] ✅ RTC Client 创建成功');

      // 2. 创建本地音视频轨道
      console.log('[🎥AgoraRTCManager] 开始创建本地音视频轨道...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
      
      // 并行创建音频和视频轨道
      const [audioTrack, videoTrack] = await Promise.all([
        AgoraRTC.createMicrophoneAudioTrack({
          encoderConfig: "music_standard"
        }),
        AgoraRTC.createCameraVideoTrack({
          encoderConfig: "720p_1",
          optimizationMode: "motion",
        })
      ]);

      this.localTracks.audioTrack = audioTrack;
      this.localTracks.videoTrack = videoTrack;
      console.log('[🎥AgoraRTCManager] ✅ 本地音视频轨道创建成功', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

      // 3. 默认开启美颜效果
      try {
        await this.localTracks.videoTrack.setBeautyEffect(true, this.beautyOptions);
        this.beautyEnabled = true;
        console.log('[🎥AgoraRTCManager] ✅ 美颜效果已开启');
      } catch (error) {
        console.warn('[🎥AgoraRTCManager] 美颜效果开启失败:', error);
      }

      // 4. 监听美颜过载事件
      this.localTracks.videoTrack.on("beauty-effect-overload", () => {
        console.warn('[🎥AgoraRTCManager] 美颜过载，自动关闭');
        this.localTracks.videoTrack.setBeautyEffect(false);
        this.beautyEnabled = false;
      });

      this.isInitialized = true;
      this.isInitializing = false;
      console.log('[🎥AgoraRTCManager] ====== 预初始化完成 ======', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

      return { rtcClient: this.rtcClient, localTracks: this.localTracks };
    } catch (error) {
      console.error('[🎥AgoraRTCManager] 预初始化失败:', error);
      this.isInitializing = false;
      this.initPromise = null;
      throw error;
    }
  }

  /**
   * 加入房间并发布流
   * @param {string} appId - Agora App ID
   * @param {string} channel - 频道名称
   * @param {string} token - RTC Token
   * @param {number|string} uid - 用户 ID
   * @param {Object} options - 配置选项
   * @param {Function} options.onUserPublished - 远程用户发布流回调
   * @param {Function} options.onUserUnpublished - 远程用户取消发布流回调
   * @param {Function} options.onException - 异常回调
   */
  async joinAndPublish(appId, channel, token, uid, options = {}) {
    // 确保已初始化
    if (!this.isInitialized) {
      console.log('[🎥AgoraRTCManager] 未预初始化，开始初始化...');
      await this.preInit();
    }

    const { onUserPublished, onUserUnpublished, onException } = options;

    // 设置事件监听
    if (onUserPublished) {
      this.rtcClient.on("user-published", onUserPublished);
    }
    if (onUserUnpublished) {
      this.rtcClient.on("user-unpublished", onUserUnpublished);
    }
    if (onException) {
      this.rtcClient.on("exception", onException);
    }

    // 加入频道
    console.log('[🎥AgoraRTCManager] 开始加入房间...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
    console.log('[🎥AgoraRTCManager] 房间信息:', { appId, channel, uid });
    await this.rtcClient.join(appId, channel, token, uid);
    console.log('[🎥AgoraRTCManager] ✅ 加入房间成功', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    // 确保轨道启用后再发布
    await this.localTracks.audioTrack.setEnabled(true);
    await this.localTracks.videoTrack.setEnabled(true);

    // 发布音视频轨道
    console.log('[🎥AgoraRTCManager] 开始推流...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
    await this.rtcClient.publish(this.localTracks.audioTrack);
    console.log('[🎥AgoraRTCManager] ✅ 音频轨道推流成功');
    await this.rtcClient.publish(this.localTracks.videoTrack);
    console.log('[🎥AgoraRTCManager] ✅ 视频轨道推流成功', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    return { rtcClient: this.rtcClient, localTracks: this.localTracks };
  }

  /**
   * 获取 RTC Client
   */
  getRtcClient() {
    return this.rtcClient;
  }

  /**
   * 获取本地轨道
   */
  getLocalTracks() {
    return this.localTracks;
  }

  /**
   * 检查是否已初始化
   */
  checkInitialized() {
    return this.isInitialized;
  }

  /**
   * 销毁并重置
   */
  async destroy() {
    console.log('[🎥AgoraRTCManager] 开始销毁...');
    try {
      // 停止并关闭本地轨道
      if (this.localTracks.videoTrack) {
        this.localTracks.videoTrack.stop();
        this.localTracks.videoTrack.close();
        this.localTracks.videoTrack = null;
      }
      if (this.localTracks.audioTrack) {
        this.localTracks.audioTrack.stop();
        this.localTracks.audioTrack.close();
        this.localTracks.audioTrack = null;
      }

      // 离开频道
      if (this.rtcClient) {
        await this.rtcClient.leave();
        this.rtcClient = null;
      }
    } catch (e) {
      console.error('[🎥AgoraRTCManager] 销毁出错:', e);
    }

    // 重置状态
    this.isInitialized = false;
    this.isInitializing = false;
    this.initPromise = null;
    this.beautyEnabled = true;

    console.log('[🎥AgoraRTCManager] ✅ 销毁完成');
  }

  /**
   * 仅停止轨道（不销毁，用于通话结束时）
   */
  stopTracks() {
    if (this.localTracks.videoTrack) {
      this.localTracks.videoTrack.stop();
    }
    if (this.localTracks.audioTrack) {
      this.localTracks.audioTrack.stop();
    }
  }
}

// 导出单例
export default AgoraRTCManager.getInstance();
