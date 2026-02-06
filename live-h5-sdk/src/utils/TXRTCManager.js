/**
 * 腾讯 TRTC 管理器单例
 * 用于在通话创建成功后提前初始化音视频轨道，加快进入房间速度
 */
import TRTC from 'trtc-sdk-v5';
import store from "@/store";

class TXRTCManager {
  constructor() {
    // 单例实例
    if (TXRTCManager.instance) {
      return TXRTCManager.instance;
    }
    TXRTCManager.instance = this;

    // TRTC 客户端
    this.trtcClient = null;
    // 是否已初始化
    this.isInitialized = false;
    // 是否正在初始化
    this.isInitializing = false;
    // 初始化 Promise（用于等待初始化完成）
    this.initPromise = null;
    // 房间信息
    this.roomId = null;
    this.userId = null;
    // 当前摄像头ID
    this.currentCameraId = null;
  }

  /**
   * 获取单例实例
   */
  static getInstance() {
    if (!TXRTCManager.instance) {
      TXRTCManager.instance = new TXRTCManager();
    }
    return TXRTCManager.instance;
  }

  /**
   * 预初始化 - 创建 TRTC Client 和本地音视频轨道
   * 在创建通话成功后调用，提前准备好音视频
   */
  async preInit() {
    // 如果已初始化，直接返回
    if (this.isInitialized) {
      console.log('[🎥TXRTCManager] 已初始化，跳过');
      return { trtcClient: this.trtcClient };
    }

    // 如果正在初始化，等待初始化完成
    if (this.isInitializing && this.initPromise) {
      console.log('[🎥TXRTCManager] 正在初始化中，等待...');
      return this.initPromise;
    }

    // 开始初始化
    this.isInitializing = true;
    console.log('[🎥TXRTCManager] 开始预初始化...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    this.initPromise = this._doInit();
    return this.initPromise;
  }

  /**
   * 执行初始化
   */
  async _doInit() {
    try {
      // 检查系统要求
      const checkResult = TRTC.isSupported();
      if (!checkResult) {
        throw new Error('当前浏览器不支持 TRTC');
      }
      console.log('[🎥TXRTCManager] 系统要求检查通过');

      // 创建 TRTC Client
      console.log('[🎥TXRTCManager] 创建 TRTC Client...');
      this.trtcClient = TRTC.create();
      console.log('[🎥TXRTCManager] ✅ TRTC Client 创建成功');

      this.isInitialized = true;
      this.isInitializing = false;
      console.log('[🎥TXRTCManager] ====== 预初始化完成 ======', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

      return { trtcClient: this.trtcClient};
    } catch (error) {
      console.error('[🎥TXRTCManager] 预初始化失败:', error);
      this.isInitializing = false;
      this.initPromise = null;
      throw error;
    }
  }

  /**
   * 加入房间并发布流
   * @param {number} sdkAppId - 腾讯云 SDKAppId
   * @param {string} roomId - 房间号
   * @param {string} userSig - 用户签名
   * @param {string} userId - 用户 ID
   * @param {Object} options - 配置选项
   * @param {Function} options.onRemoteUserEnter - 远程用户进入回调
   * @param {Function} options.onRemoteUserLeave - 远程用户离开回调
   * @param {Function} options.onRemoteVideoAvailable - 远程视频可用回调
   * @param {Function} options.onRemoteAudioAvailable - 远程音频可用回调
   * @param {Function} options.onError - 错误回调
   */
  async joinAndPublish(sdkAppId, roomId, userSig, userId, options = {}) {
    // 确保已初始化
    if (!this.isInitialized) {
      console.log('[🎥TXRTCManager] 未预初始化，开始初始化...');
      await this.preInit();
    }

    const {
      onRemoteUserEnter,
      onRemoteUserLeave,
      onRemoteVideoAvailable,
      onRemoteAudioAvailable,
      onError
    } = options;

    this.roomId = roomId;
    this.userId = userId;

    // 设置事件监听
    if (onRemoteUserEnter) {
      this.trtcClient.on(TRTC.EVENT.REMOTE_USER_ENTER, onRemoteUserEnter);
    }
    if (onRemoteUserLeave) {
      this.trtcClient.on(TRTC.EVENT.REMOTE_USER_LEAVE, onRemoteUserLeave);
    }
    if (onRemoteVideoAvailable) {
      this.trtcClient.on(TRTC.EVENT.REMOTE_VIDEO_AVAILABLE, onRemoteVideoAvailable);
    }
    if (onRemoteAudioAvailable) {
      this.trtcClient.on(TRTC.EVENT.REMOTE_AUDIO_AVAILABLE, onRemoteAudioAvailable);
    }
    if (onError) {
      this.trtcClient.on(TRTC.EVENT.ERROR, onError);
    }

    // 加入房间
      console.log('[🎥TXRTCManager] callData',store.state.call.callData)
    console.log('[🎥TXRTCManager] 开始加入房间...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
    console.log('[🎥TXRTCManager] 房间信息:', { sdkAppId, roomId, userId });
    console.log('[🎥TXRTCManager] userSig:', userSig);

    await this.trtcClient.enterRoom({
      sdkAppId: sdkAppId,
      userId: userId,
      userSig: userSig,
      strRoomId: roomId,
      scene: 'rtc'
    });
    console.log('[🎥TXRTCManager] ✅ 加入房间成功', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    // 开启并发布本地音视频
    console.log('[🎥TXRTCManager] 开始推流...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    // 开启本地音频（会自动发布）
    await this.trtcClient.startLocalAudio();
    console.log('[🎥TXRTCManager] ✅ 本地音频开启成功');

    // 开启本地视频（会自动发布）
    await this.trtcClient.startLocalVideo({
      option: {
        profile: '720p',
        facingMode: 'user'
      }
    });
    console.log('[🎥TXRTCManager] ✅ 本地视频开启成功', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

    return { trtcClient: this.trtcClient };
  }

  /**
   * 播放远端用户的视频流
   * @param {string} userId - 远端用户 ID
   * @param {HTMLElement|string} view - 播放视频的 DOM 元素或元素 ID
   * @param {string} streamType - 流类型，默认 'main'
   */
  async startRemoteVideo(userId, view, streamType = 'main') {
    try {
      await this.trtcClient.startRemoteVideo({ userId, streamType, view });
      console.log('[🎥TXRTCManager] ✅ 远端视频播放成功:', userId);
    } catch (error) {
      console.error('[🎥TXRTCManager] 播放远端视频失败:', error);
      throw error;
    }
  }

  /**
   * 停止播放远端用户的视频流
   * @param {string} userId - 远端用户 ID
   * @param {string} streamType - 流类型，默认 'main'
   */
  async stopRemoteVideo(userId, streamType = 'main') {
    try {
      await this.trtcClient.stopRemoteVideo({ userId, streamType });
      console.log('[🎥TXRTCManager] ✅ 远端视频已停止:', userId);
    } catch (error) {
      console.error('[🎥TXRTCManager] 停止远端视频失败:', error);
      throw error;
    }
  }

  /**
   * 控制远端用户的音频播放（SDK 默认自动播放远端音频）
   * @param {string} userId - 远端用户 ID
   * @param {boolean} mute - true 静音，false 取消静音
   */
  async muteRemoteAudio(userId, mute) {
    try {
      await this.trtcClient.muteRemoteAudio(userId, mute);
      console.log('[🎥TXRTCManager] ✅ 远端音频状态:', userId, mute ? '静音' : '取消静音');
    } catch (error) {
      console.error('[🎥TXRTCManager] 控制远端音频失败:', error);
      throw error;
    }
  }

  // 兼容旧方法名
  async subscribeRemoteVideo(userId, element) {
    return this.startRemoteVideo(userId, element, 'main');
  }

  // 兼容旧方法名（远端音频默认自动播放，此方法仅取消静音）
  async subscribeRemoteAudio(userId) {
    return this.muteRemoteAudio(userId, false);
  }

  /**
   * 获取 TRTC Client
   */
  getTrtcClient() {
    return this.trtcClient;
  }

  /**
   * 检查是否已初始化
   */
  checkInitialized() {
    return this.isInitialized;
  }

  /**
   * 设置视频启用状态
   */
  async setVideoEnabled(enabled) {
    if (this.trtcClient) {
      if (enabled) {
        await this.trtcClient.updateLocalVideo({ mute: false });
      } else {
        await this.trtcClient.updateLocalVideo({ mute: true });
      }
    }
  }

  /**
   * 设置音频启用状态
   */
  async setAudioEnabled(enabled) {
    if (this.trtcClient) {
      if (enabled) {
        await this.trtcClient.updateLocalAudio({ mute: false });
      } else {
        await this.trtcClient.updateLocalAudio({ mute: true });
      }
    }
  }

  /**
   * 切换摄像头
   */
  async switchCamera() {
    if (this.trtcClient) {
      try {
        const devices = await TRTC.getCameraList();
        if (devices.length < 2) {
          console.warn('[🎥TXRTCManager] 没有其他摄像头可切换');
          return false;
        }
        // 获取当前摄像头，切换到下一个
        const currentCameraId = this.currentCameraId || devices[0].deviceId;
        const currentIndex = devices.findIndex(d => d.deviceId === currentCameraId);
        const nextIndex = (currentIndex + 1) % devices.length;
        const nextCameraId = devices[nextIndex].deviceId;

        await this.trtcClient.updateLocalVideo({ option: { cameraId: nextCameraId } });
        this.currentCameraId = nextCameraId;
        return true;
      } catch (error) {
        console.error('[🎥TXRTCManager] 切换摄像头失败:', error);
        return false;
      }
    }
    return false;
  }

  /**
   * 播放本地视频到指定元素
   */
  playLocalVideo(element) {
    if (this.trtcClient && element) {
      this.trtcClient.updateLocalVideo({ view: element });
    }
  }

  /**
   * 销毁并重置
   */
  async destroy() {
    console.log('[🎥TXRTCManager] 开始销毁...');
    try {
      // 停止本地音视频
      if (this.trtcClient) {
        await this.trtcClient.stopLocalVideo();
        await this.trtcClient.stopLocalAudio();
        // 离开房间
        await this.trtcClient.exitRoom();
        this.trtcClient.destroy();
        this.trtcClient = null;
      }
    } catch (e) {
      console.error('[🎥TXRTCManager] 销毁出错:', e);
    }

    // 重置状态
    this.isInitialized = false;
    this.isInitializing = false;
    this.initPromise = null;
    this.roomId = null;
    this.userId = null;
    this.currentCameraId = null;

    console.log('[🎥TXRTCManager] ✅ 销毁完成');
  }

  /**
   * 仅停止轨道（不销毁，用于通话结束时）
   */
  async stopTracks() {
    if (this.trtcClient) {
      await this.trtcClient.stopLocalVideo();
      await this.trtcClient.stopLocalAudio();
    }
  }
}

// 导出单例
export default TXRTCManager.getInstance();
