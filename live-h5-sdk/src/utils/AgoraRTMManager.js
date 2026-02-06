/**
 * Agora RTM 管理器 (适配 agora-rtm-sdk 1.5.1 版本)
 * 用于在通话中进行实时消息收发
 *
 * 使用流程：
 * 1. 应用启动时调用 login() 登录 RTM
 * 2. 进入通话时调用 joinChannel() 加入频道
 * 3. 离开通话时调用 leaveChannel() 离开频道
 * 4. 应用退出时调用 logout() 登出 RTM
 */
import AgoraRTM from "agora-rtm-sdk";
import store from "@/store";
import { getRtmToken } from "@/api/sdk/call";

// 自定义消息类型（与 TencentImUtils 保持一致）
export const RTM_MSG_TYPE = {
  TEXT: 'MSG_TEXT',
  CUSTOM: 'MSG_CUSTOM',
  GIFT: 2000,
};

// 模块级私有变量
let rtmClient = null;
let rtmChannel = null;
let currentChannel = null;
let isLoggedIn = false;
let isJoinedChannel = false;
let onMessageCallback = null;
let currentUserId = null;
let appId = null;
let rtmToken = null;

/**
 * 设置 RTM 客户端事件监听
 */
function setupEventListeners() {
  if (!rtmClient) return;

  rtmClient.on('ConnectionStateChanged', (newState, reason) => {
    console.log('[📨AgoraRTMManager] 连接状态变化:', newState, reason);
  });

  rtmClient.on('MessageFromPeer', (message, peerId) => {
    console.log('[📨AgoraRTMManager] 收到点对点消息:', message, 'from:', peerId);
    handleReceivedMessage(message, peerId);
  });

  rtmClient.on('TokenExpired', async () => {
    console.log('[📨AgoraRTMManager] Token 即将过期，尝试续期...');
    try {
      const tokenResponse = await getRtmToken();
      if (tokenResponse && tokenResponse.success) {
        const newToken = tokenResponse.data?.rtmToken || tokenResponse.data;
        rtmToken = newToken;
        await rtmClient.renewToken(newToken);
        console.log('[📨AgoraRTMManager] ✅ Token 续期成功');
      }
    } catch (error) {
      console.error('[📨AgoraRTMManager] Token 续期失败:', error);
    }
  });
}

/**
 * 设置频道事件监听
 */
function setupChannelEventListeners() {
  if (!rtmChannel) return;

  rtmChannel.on('ChannelMessage', (message, memberId) => {
    console.log('[📨AgoraRTMManager] 收到频道消息:', message, 'from:', memberId);
    handleReceivedMessage(message, memberId);
  });

  rtmChannel.on('MemberJoined', (memberId) => {
    console.log('[📨AgoraRTMManager] 成员加入频道:', memberId);
  });

  rtmChannel.on('MemberLeft', (memberId) => {
    console.log('[📨AgoraRTMManager] 成员离开频道:', memberId);
  });
}

/**
 * 处理接收到的消息
 */
function handleReceivedMessage(message, senderId) {
  try {
    const messageText = message.text;
    let parsedMessage;
    try {
      parsedMessage = JSON.parse(messageText);
    } catch (e) {
      parsedMessage = {
        type: RTM_MSG_TYPE.TEXT,
        payload: { text: messageText }
      };
    }

    const formattedMessage = formatMessageForDisplay(parsedMessage, senderId);

    if (onMessageCallback) {
      onMessageCallback({
        data: [formattedMessage]
      });
    }
  } catch (error) {
    console.error('[📨AgoraRTMManager] 处理消息失败:', error);
  }
}

/**
 * 格式化消息为显示格式
 */
function formatMessageForDisplay(parsedMessage, senderId) {
  const timestamp = Date.now();
  const messageId = `rtm_${timestamp}_${Math.random().toString(36).substr(2, 9)}`;

  const baseMessage = {
    ID: messageId,
    type: parsedMessage.type || RTM_MSG_TYPE.TEXT,
    from: senderId,
    to: currentUserId,
    time: Math.floor(timestamp / 1000),
    sequence: timestamp,
    random: Math.floor(Math.random() * 1000000),
    conversationID: `C2C${senderId}`,
    payload: parsedMessage.payload || { text: '' },
    isRTMMessage: true
  };

  if (parsedMessage.type === RTM_MSG_TYPE.CUSTOM || parsedMessage.customType) {
    baseMessage.type = RTM_MSG_TYPE.CUSTOM;
    baseMessage.customData = parsedMessage.customData || parsedMessage;
  }

  return baseMessage;
}

/**
 * 登录 RTM
 */
async function login(_appId, userId) {
  if (isLoggedIn && rtmClient) {
    console.log('[📨AgoraRTMManager] 已登录，跳过');
    return true;
  }

  try {
    console.log('[📨AgoraRTMManager] 开始登录 RTM...', { appId: _appId, userId });

    appId = _appId;
    currentUserId = String(userId);

    console.log('[📨AgoraRTMManager] 获取 RTM Token...');
    const tokenResponse = await getRtmToken();
    if (!tokenResponse || !tokenResponse.success) {
      throw new Error('获取 RTM Token 失败');
    }
    rtmToken = tokenResponse.data?.rtmToken || tokenResponse.data;
    console.log("appid", appId);
    console.log("userId", currentUserId);
    console.log('[📨AgoraRTMManager] ✅ RTM Token 获取成功', rtmToken);

    rtmClient = AgoraRTM.createInstance(appId);
    console.log('[📨AgoraRTMManager] ✅ RTM Client 创建成功');

    setupEventListeners();

    console.log('[📨AgoraRTMManager] 登录 RTM...');
    await rtmClient.login({
      uid: currentUserId,
      token: rtmToken
    });
    isLoggedIn = true;
    console.log('[📨AgoraRTMManager] ✅ RTM 登录成功');

    return true;
  } catch (error) {
    console.error('[📨AgoraRTMManager] 登录失败:', error);
    throw error;
  }
}

/**
 * 加入频道
 */
async function joinChannel(channelName) {
  if (!isLoggedIn || !rtmClient) {
    throw new Error('RTM 未登录，请先调用 login()');
  }

  if (isJoinedChannel && currentChannel === channelName) {
    console.log('[📨AgoraRTMManager] 已在频道中，跳过');
    return true;
  }

  if (isJoinedChannel && currentChannel !== channelName) {
    await leaveChannel();
  }

  try {
    console.log('[📨AgoraRTMManager] 加入频道:', channelName);
    currentChannel = channelName;

    rtmChannel = rtmClient.createChannel(channelName);
    setupChannelEventListeners();
    await rtmChannel.join();

    isJoinedChannel = true;
    console.log('[📨AgoraRTMManager] ✅ 加入频道成功');

    return true;
  } catch (error) {
    console.error('[📨AgoraRTMManager] 加入频道失败:', error);
    throw error;
  }
}

/**
 * 离开频道
 */
async function leaveChannel() {
  if (!rtmChannel || !isJoinedChannel) {
    return true;
  }

  try {
    console.log('[📨AgoraRTMManager] 离开频道:', currentChannel);

    await rtmChannel.leave();

    rtmChannel = null;
    currentChannel = null;
    isJoinedChannel = false;
    offMessageReceived();
    console.log('[📨AgoraRTMManager] ✅ 离开频道成功');

    return true;
  } catch (error) {
    console.error('[📨AgoraRTMManager] 离开频道失败:', error);
    throw error;
  }
}

/**
 * 登出 RTM
 */
async function logout() {
  try {
    if (isJoinedChannel) {
      await leaveChannel();
    }

    if (rtmClient && isLoggedIn) {
      console.log('[📨AgoraRTMManager] 登出 RTM...');
      await rtmClient.logout();
      console.log('[📨AgoraRTMManager] ✅ RTM 登出成功');
    }
  } catch (error) {
    console.error('[📨AgoraRTMManager] 登出失败:', error);
  }

  rtmClient = null;
  isLoggedIn = false;
  rtmToken = null;

  return true;
}

/**
 * 发送文本消息
 */
async function sendTextMessage(text) {
  if (!rtmChannel || !isJoinedChannel) {
    throw new Error('RTM 频道未加入');
  }
  console.log("RTM 频道", rtmChannel);

  try {
    const messageContent = {
      type: RTM_MSG_TYPE.TEXT,
      payload: { text: text }
    };

    const message = { text: JSON.stringify(messageContent) };
    await rtmChannel.sendMessage(message);

    console.log('[📨AgoraRTMManager] ✅ 文本消息发送成功:', text);

    return formatMessageForDisplay(messageContent, currentUserId);
  } catch (error) {
    console.error('[📨AgoraRTMManager] 发送文本消息失败:', error);
    throw error;
  }
}

/**
 * 发送礼物消息
 */
async function sendGiftMessage(gift) {
  if (!rtmChannel || !isJoinedChannel) {
    throw new Error('RTM 频道未加入');
  }

  try {
    const messageContent = {
      type: RTM_MSG_TYPE.CUSTOM,
      customType: RTM_MSG_TYPE.GIFT,
      customData: {
        type: RTM_MSG_TYPE.GIFT,
        customType: RTM_MSG_TYPE.GIFT,
        content: gift,
        ...gift
      }
    };

    const message = { text: JSON.stringify(messageContent) };
    await rtmChannel.sendMessage(message);

    console.log('[📨AgoraRTMManager] ✅ 礼物消息发送成功:', gift);

    return formatMessageForDisplay(messageContent, currentUserId);
  } catch (error) {
    console.error('[📨AgoraRTMManager] 发送礼物消息失败:', error);
    throw error;
  }
}

/**
 * 发送自定义消息
 */
async function sendCustomMessage(customData, customType) {
  if (!rtmChannel || !isJoinedChannel) {
    throw new Error('RTM 频道未加入');
  }

  try {
    const messageContent = {
      type: RTM_MSG_TYPE.CUSTOM,
      customType: customType,
      customData: customData
    };

    const message = { text: JSON.stringify(messageContent) };
    await rtmChannel.sendMessage(message);

    console.log('[📨AgoraRTMManager] ✅ 自定义消息发送成功:', customData);

    return formatMessageForDisplay(messageContent, currentUserId);
  } catch (error) {
    console.error('[📨AgoraRTMManager] 发送自定义消息失败:', error);
    throw error;
  }
}

/**
 * 设置消息接收回调
 */
function onMessageReceived(callback) {
  onMessageCallback = callback;
}

/**
 * 移除消息接收回调
 */
function offMessageReceived() {
  onMessageCallback = null;
}

/**
 * 判断是否是自己发送的消息
 */
function isSelf(userId) {
  return String(userId) === String(currentUserId);
}

/**
 * 获取当前用户 ID
 */
function getCurrentUserId() {
  return currentUserId;
}

/**
 * 销毁频道
 */
async function destroy() {
  console.log('[📨AgoraRTMManager] 开始销毁频道...');

  try {
    await leaveChannel();
  } catch (error) {
    console.error('[📨AgoraRTMManager] 销毁频道出错:', error);
  }

  console.log('[📨AgoraRTMManager] ✅ 频道销毁完成');
}

/**
 * 检查是否已登录
 */
function checkLoggedIn() {
  return isLoggedIn;
}

/**
 * 检查是否已加入频道
 */
function checkJoinedChannel() {
  return isJoinedChannel;
}

// 默认导出所有方法
export default {
  login,
  joinChannel,
  leaveChannel,
  logout,
  sendTextMessage,
  sendGiftMessage,
  sendCustomMessage,
  onMessageReceived,
  offMessageReceived,
  isSelf,
  getCurrentUserId,
  destroy,
  checkLoggedIn,
  checkJoinedChannel
};
