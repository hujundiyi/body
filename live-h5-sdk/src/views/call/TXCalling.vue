<template>
  <m-page-wrap :show-action-bar="false" :show-safe-area="true">
    <template #page-content-wrap>
      <!-- 固定全屏包裹层：避免外层 m-page-content 在 iOS 上抢触摸，使 chat-list 能正常滑动 -->
      <div class="call-page-root">
      <div class="call-content">
        <!-- 默认背景（视频流拉起前显示） -->
        <div class="call-default-bg" :class="{ 'call-default-bg-hidden': remoteVideoReady }">
          <div class="call-default-bg-image" :style="anchorInfo && anchorInfo.avatar ? { backgroundImage: `url(${anchorInfo.avatar})` } : {}"></div>
          <div class="call-default-bg-mask"></div>
          <!-- 连接中提示 -->
          <div class="call-connecting-tip" v-if="!remoteVideoReady">
            <span class="connecting-text">Connecting...</span>
          </div>
        </div>
        <!-- 通话中界面 && localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING -->
        <div class="call-active" v-if="localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING">
          <div class="trtc-remote" ref="playerFull"></div>
          <!-- 本地视频容器（带背景） -->
          <div class="trtc-local-wrapper">
            <div class="trtc-local-bg"></div>
            <div class="trtc-local" ref="playerMin" v-show="cameraEnabled && initialMediaStateApplied"></div>
          </div>
          <!-- 本地视频上方的控制面板（当摄像头或麦克风未开启时显示） -->
          <div class="local-control-panel" :class="{'local-control-panel-all-show': !cameraEnabled && !micEnabled}">
            <div class="control-item" @click="toggleCamera" v-if="!cameraEnabled">
              <img :src="cameraEnabled
                ? require('@/assets/image/call/calling/operate/ic_calling_cemera@2x.png')
                : require('@/assets/image/call/calling/operate/ic_calling_cemera_no@2x.png')"
              />
            </div>
            <div class="control-item" @click="toggleMic" v-if="!micEnabled">
              <img :src="micEnabled
                ? require('@/assets/image/call/calling/operate/ic_calling_mic@2x.png')
                : require('@/assets/image/call/calling/operate/ic_calling_mic_no@2x.png')"
              />
            </div>
            <!-- 通话计时器：已开始计时 或 用户金币不足（<= 单价）时显示 -->
            <div class="call-timer" v-if="showCallTimer">
              {{ callDurationText }}
            </div>
          </div>
          <!-- 顶部半透明渐变背景 -->
          <div class="call-top-gradient-bg"></div>
          <div class="call-top" v-if="anchorInfo">
            <div class="user">
              <img class="btn-back" :class="{ 'btn-disabled': hangupBtnDisabled }" src="@/assets/image/call/calling/ic_calling_close@2x.png" @click="onCallingHangupClick" alt=""/>
              <img class="avatar" :src="anchorInfo.avatar"/>
              <div class="meta">
                <div class="name">{{ anchorInfo.nickname }}</div>
                <div class="coin">
                  <img class="coin-icon" src="@/assets/image/call/calling/ic_calling_coin@2x.png"/>
                  <span class="coin-text">{{ callInfo.callPrice }}/min</span>
                </div>
              </div>
              <img class="btn-follow" :src="followBtnIcon" @click="onFollowClick"/>
            </div>
            <div class="top-actions">
              <img class="btn-more" src="@/assets/image/call/calling/ic_calling_more@2x.png" @click="onTopMoreClick"/>
            </div>
          </div>

          <!-- 设置面板遮罩 -->
          <div class="settings-overlay" v-if="showSettings" @click="showSettings = false"></div>

          <!-- 全屏闪烁背景（最后20秒） -->
          <div
            v-if="showRechargeReminder && rechargeCountdown <= 20"
            class="recharge-fullscreen-flash"
          >
            <img
              class="recharge-fullscreen-bg"
              :src="require('@/assets/image/call/calling/ic_calling_recharge_full_bg@2x.png')"
              alt=""
            />
          </div>

          <!-- 底部设置面板 -->
          <div class="settings-panel" :class="{ 'show': showSettings }">
            <div class="settings-options">
              <div class="setting-item" @click="toggleCamera">
                <img :src="cameraEnabled
                  ? require('@/assets/image/call/calling/operate/ic_calling_cemera@2x.png')
                  : require('@/assets/image/call/calling/operate/ic_calling_cemera_no@2x.png')"
                />
              </div>
              <div class="setting-item" @click="toggleMic">
                <img :src="micEnabled
                  ? require('@/assets/image/call/calling/operate/ic_calling_mic@2x.png')
                  : require('@/assets/image/call/calling/operate/ic_calling_mic_no@2x.png')"
                />
              </div>
              <div class="setting-item setting-item-vip" @click="switchCamera">
                <img src="@/assets/image/call/calling/operate/ic_calling_cemera_switch@2x.png"/>
                <img v-if="!isVip" class="vip-crown" src="@/assets/image/match/ic-match-vip@2x.png"/>
              </div>
            </div>
          </div>

          <div class="call-bottom">
          <img class="bottom-bg" src="@/assets/image/call/calling/ic_calling_bottom_trans@2x.png"/>

          <!-- 充值提示条 -->
          <div
            v-if="showRechargeReminder && showRechargeReminderCondition"
            class="recharge-reminder"
            :class="{
              'recharge-reminder-expanded': rechargeReminderExpanded,
              'recharge-reminder-collapsed': !rechargeReminderExpanded
            }"
            @click="onRechargeReminderClick"
          >
            <!-- 背景图 -->
            <img
              class="recharge-bg"
              :src="require('@/assets/image/call/calling/ic_calling_recharge_bg@2x.png')"
              alt=""
            />
            <!-- 展开状态：完整内容 -->
            <div v-if="rechargeReminderExpanded" class="recharge-content-expanded">
              <img
                class="recharge-clock"
                :src="require('@/assets/image/call/calling/ic_calling_recharge_clock@2x.png')"
                alt=""
              />
              <span class="recharge-text">Out of Time</span>
              <span class="recharge-countdown">{{ formatRechargeCountdown }}</span>
              <button class="recharge-btn" @click.stop="onRechargeClick">Recharge</button>
            </div>
            <!-- 收起状态：只显示倒计时和箭头 -->
            <div v-else class="recharge-content-collapsed" @click.stop="onRechargeClick">
              <span class="recharge-countdown-small">{{ formatRechargeCountdown }}</span>
              <img class="recharge-expand-arrow" src="@/assets/image/call/calling/ic_calling_recharge_arrow@2x.png" alt="" />
            </div>
          </div>

          <!-- 聊天区域 -->
          <div class="chat">
            <div class="chat-list" ref="msgList">
              <div class="chat-list-inner">
              <div :class="['item', isMessageFromSelf(it) ? 'send-self' : '']" :key="index" v-for="(it,index) in messageList">
                <div class="msg-content">
                  <div
                    class="msg-header"
                    :class="{'no-translation': !getTranslatedText(it)}"
                    v-if="isTextMessage(it) && !isMessageFromSelf(it)"
                  >
                    <p class="msg-text">{{ it.payload.text }}</p>
                    <img
                      class="msg-translate-btn"
                      :src="require('@/assets/image/call/calling/ic_calling_translate@2x.png')"
                      @click.stop="translateMessage(it, index)"
                      v-if="!getTranslatedText(it) && !it.translating"
                    />
                    <span v-if="it.translating" class="msg-translating">Translating...</span>
                  </div>
                  <p class="msg-text msg-text-self" v-if="isTextMessage(it) && isMessageFromSelf(it)">
                    {{ it.payload.text }}
                  </p>
                  <p class="msg-translated" v-if="getTranslatedText(it)">
                    {{ getTranslatedText(it) }}
                  </p>
                  <div v-if="isCustomMessage(it)">
                    <div class="msg-gift" v-if="isGiftMessage(it)">
                      <p>{{ it.customData.content?.name || it.customData.name }} [{{ it.customData.content?.coin || it.customData.coin }} coins] x {{ it.customData.content?.giftNum || it.customData.giftNum || 1 }}</p>
                    </div>
                  </div>
                </div>
              </div>
              </div>
            </div>
          </div>
          <!-- 聊天输入区域 -->
          <div class="chat-input">
            <input
              ref="msgInput"
              v-model="textContent"
              class="msg-field"
              placeholder="Say hi..."
              enterkeyhint="send"
              @keyup.enter="sendTextMessage"
            />
            <img
              class="btn-more-action"
              src="@/assets/image/call/calling/ic_calling_more_action@2x.png"
              @click="onMoreActionClick"
            />
            <img
              class="btn-gift"
              src="@/assets/image/call/calling/ic_calling_gift@2x.png"
              @click="openGiftDialog"
            />
          </div>
        </div>
        </div>

        <!-- 通话结束页面 -->
        <div v-if="localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END" class="call-end-overlay">
          <RechargeCallEnd
            v-if="hasFirstRecharge"
            @close="handleEndPageClose"
          />
          <CallEnd v-else
            @close="handleEndPageClose"
          />
        </div>
      </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import TRTC from 'trtc-sdk-v5';
import TXRTCManager from "@/utils/TXRTCManager";
import TencentCloudChat from "@tencentcloud/chat";
import store from "@/store";
import {sendGift} from "@/api/sdk/call";
import {callEnd} from "@/utils/CallUtils";
import {showGiftDialog, showGiftGoodsDialog, showUserDetailMoreDialog, showRechargeDialog, showUserReportPopup, showConfirmDialog, showFeedbackDialog, showReportDialog, showPremiumDialog} from "@/components/dialog";
import {router} from "@/router";
import {
  CALL_INVITE,
  CALL_STATUS_CHANGE,
  custom_type_gift,
  LESS_THAN_ONE_MINUTE,
  TencentImUtils
} from "@/utils/TencentImUtils";
import ChatCompon, {isSelf} from "@/views/chat/ChatCompon";
import {followStatus, statusBlack} from "@/api/sdk/user";
import {getUserInfo} from "@/api";
import {msToTime} from "@/utils/Utils";
import {DialogTaskArray} from "@/components/dialog/DialogTaskArray";
import CallEnd from "@/views/call/end.vue";
import RechargeCallEnd from "@/views/call/RechargeCallEnd.vue";
import {sendMessage, translationMsg} from "@/api/sdk/message";
import {toast} from "@/components/toast";
import {CALL_STATUS, LOCAL_CALL_STATUS} from "@/utils/Constant";
import clientNative from "@/utils/ClientNative";
import {getAnchorInfo} from "@/api/sdk/anchor";
import tencentChat from "@/views/chat/ChatCompon";
import chatCompon from "@/views/chat/ChatCompon";
import { showCallToast } from "@/components/toast/callToast";
import user from "@/store/modules/user";

export default {
  name: 'TXCalling',
  components: {
    CallEnd,
    RechargeCallEnd
  },
  data() {
    return {
      custom_type_gift,
      trtcClient: null,
      callInfo: {},
      anchorInfo: {},
      callTimer: null,
      callStartTime: 0,
      messageList: [],
      textContent: '',
      isSendingMessage: false,  // 防抖：是否正在发送消息
      // 设置面板
      showSettings: false,
      // 充值提示相关
      showRechargeReminder: false,      // 是否显示充值提示
      rechargeReminderExpanded: true,   // 是否展开（完整显示）
      rechargeCountdown: 60,            // 倒计时秒数
      rechargeTimer: null,              // 倒计时定时器
      rechargeExpandTimer: null,        // 3秒后收起的定时器
      pendingRechargeReminder: null,    // 待处理的充值提醒（通话未开始时暂存）
      // 初始媒体状态是否已应用
      initialMediaStateApplied: false,
      // 远端视频流是否就绪
      remoteVideoReady: false,
      // 挂断按钮是否禁用（进入页面5秒内禁用）
      hangupBtnDisabled: true,
      // 是否有首冲（从 API 获取）
      // hasFirstRecharge: false
    }
  },
  computed: {
    hasFirstRecharge() {
      console.error('[判断❌calling.vue]');
      const allPurchased = this.$store.state.user.allPurchased;
      const result = !allPurchased;
      console.error('[判断❌calling.vue] hasFirstRecharge', { allPurchased, result, userState: this.$store.state.user });
      return result;
    },
    showRechargeReminderCondition() {
      //购买后显示充值提示
      const coins = Number(this.loginUserInfo?.coinBalance ?? 0);
      const price = Number(this.callInfo?.callPrice ?? 0);
      return coins < price;
    },
    LOCAL_CALL_STATUS() {
      return LOCAL_CALL_STATUS
    },
    TencentCloudChat() {
      return TencentCloudChat
    },
    loginUserInfo() {
      return this.$store.state.user.loginUserInfo;
    },
    followBtnIcon() {
      const isFollowed = this.anchorInfo.followStatus && this.anchorInfo.followStatus !== 1;
      return isFollowed
        ? require('@/assets/image/call/calling/ic_calling_liked@2x.png')
        : require('@/assets/image/call/calling/ic_calling_like_add@2x.png');
    },
    localCallStatus() {
      return this.$store.state.call.localCallStatus
    },
    callDurationText() {
      const seconds = Math.floor(this.callStartTime / 1000);
      const m = Math.floor(seconds / 60);
      const s = seconds % 60;
      const pad = v => String(v).padStart(2, '0');
      return `${pad(m)}:${pad(s)}`;
    },
    // 是否显示通话计时器：已开始计时 或 用户金币数量 <= 通话单价 时显示
    showCallTimer() {

      if (this.callStartTime > 0) return true;
      return false;
    },
    // 从 store 获取摄像头状态
    cameraEnabled() {
      return this.$store.getters.isOpenCamera;
    },
    // 从 store 获取麦克风状态
    micEnabled() {
      return this.$store.getters.isOpenMicrophone;
    },
    // 格式化充值倒计时显示
    formatRechargeCountdown() {
      const seconds = Math.max(0, this.rechargeCountdown);
      const h = Math.floor(seconds / 3600);
      const m = Math.floor((seconds % 3600) / 60);
      const s = seconds % 60;
      const pad = v => String(v).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(s)}`;
    },
    // 判断是否是VIP用户
    isVip() {
      const loginUserInfo = this.$store.state.user.loginUserInfo || {};
      return loginUserInfo.vipCategory !== 0;
    }
  },
  watch: {
    // 监听通话状态变化，当通话结束时退出 TRTC 房间
    localCallStatus(newStatus, oldStatus) {
      if (newStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END && oldStatus !== LOCAL_CALL_STATUS.LOCAL_CALL_END) {
        console.log('[🎥TX_CALL_FLOW] 通话状态变为 LOCAL_CALL_END，退出 TRTC 房间');
        this.exitTRTCRoom();
      }else if (oldStatus === LOCAL_CALL_STATUS.LOCAL_CALL_NONE || newStatus === LOCAL_CALL_STATUS.LOCAL_CALL_NONE) {
        if (window.history.length > 1) {
          this.$router.back();
          console.log('[🎥TX_CALL_FLOW] handleEndPageClose back')
        } else {
          console.log('[🎥TX_CALL_FLOW] handleEndPageClose PageSdkIndex')
          this.$router.replace({name: 'PageSdkIndex'});
        }
      }
    }
  },
  mounted() {
    setTimeout(() => {
      this.initParams();
    }, 100)
  },
  created() {
    console.log('[🎥TX_CALL_FLOW] ====== 进入 TXCalling 页面 ======', new Date().toLocaleString('zh-CN', { hour12: false }));
    console.log('[🎥TX_CALL_FLOW] 页面创建时间:', new Date().toLocaleTimeString('zh-CN', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit', fractionalSecondDigits: 3 }));
    // 初始化腾讯 IM 消息监听
    this.initData();
    this.initTencentImMessageListener();
  },
  methods: {
    isSelf,
    showRechargeDialog,
    msToTime,

    /**
     * 退出 TRTC 房间
     */
    async exitTRTCRoom() {
      try {
        console.log('[🎥TX_CALL_FLOW] 开始退出 TRTC 房间...');
        await TXRTCManager.destroy();
        console.log('[🎥TX_CALL_FLOW] ✅ 已退出 TRTC 房间');
      } catch (error) {
        console.error('[🎥TX_CALL_FLOW] 退出 TRTC 房间失败:', error);
      }
    },

    /**
     * 判断消息是否是自己发送的（腾讯 IM）
     */
    isMessageFromSelf(message) {
      if (!message) return false;
      return isSelf(message.from);
    },

    /**
     * 判断是否是文本消息（腾讯 IM）
     */
    isTextMessage(message) {
      if (!message) return false;
      return message.type === TencentCloudChat.TYPES.MSG_TEXT;
    },

    /**
     * 判断是否是自定义消息（腾讯 IM）
     */
    isCustomMessage(message) {
      if (!message) return false;
      return message.type === TencentCloudChat.TYPES.MSG_CUSTOM;
    },

    /**
     * 判断是否是礼物消息（腾讯 IM）
     */
    isGiftMessage(message) {
      if (!message || !message.customData) return false;
      const customType = message.customData.type || message.customData.customType;
      return customType === custom_type_gift;
    },
    initData() {
      // 优先从 store 的 callData 中获取数据
      const callData = this.$store.state.call?.callData || {};
      this.callInfo = callData;
      this.anchorInfo =  this.$store.state.call.anchorInfo || callData.anchorInfo || null;
    },
    initParams() {
      console.log('[🎥TX_CALL_FLOW] initParams 初始化参数', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
      if (this.localCallStatus !== LOCAL_CALL_STATUS.LOCAL_CALL_CALLING) {
        console.log('[🎥TX_CALL_FLOW] ❌ 通话状态异常，返回上一页');
        // 若仍停留在通话页（如 history 只有一页），则替换到匹配页，确保页面被关闭
        if (window.history.length > 1) {
          this.$router.back();
        } else {
          this.$router.replace({ name: 'PageSdkIndex' });
        }
        return;
      }
      this.$store.dispatch('call/setIsMyCallEnd', false);

      console.log('[🎥TX_CALL_FLOW] 开始初始化通话...', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
      this.onCallStart();
      // 5秒后启用挂断按钮
      this.hangupBtnTimer = setTimeout(() => {
        this.hangupBtnDisabled = false;
      }, 5000);
    },

    initTencentImMessageListener() {
      // 腾讯 IM 监听：用于通话状态和聊天消息
      TencentImUtils.onMessageReceived(this.onTencentImMessageReceived);
      TencentImUtils.onMessageModified(this.onMessageModified);
    },

    /**
     * 腾讯 IM 消息接收处理：文本消息展示到聊天列表，自定义消息处理通话状态/礼物等
     */
    onTencentImMessageReceived(event) {
      const messageList = event.data;
      messageList.forEach((message) => {
        console.log("[🎥TX_CALL_FLOW] 收到腾讯 IM 消息:", message);

        // 处理文本消息，加入列表并展示
        if (message.type === TencentCloudChat.TYPES.MSG_TEXT) {
          this.messageList.push(message);
          this.scrollToBottom();
          return;
        }

        // 只处理自定义消息中的通话状态相关消息
        if (message.type === TencentCloudChat.TYPES.MSG_CUSTOM) {
          TencentImUtils.initCustomMessage(message);
          const { customType, callNo, callStatus } = message.customData;

          // 处理通话状态变更
          if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING) {
            const { callTime, spendCoin, callStatusMsg } = message.customData;
            console.log("callStatus:", callStatus);
            console.log("callStatusMsg:", callStatusMsg);
            console.log("callTime:", callTime);
            console.log("spendCoin:", spendCoin);

            if (callStatus === CALL_STATUS.CALL_DONE.code) {
              if (callTime && spendCoin && callTime > 0 && spendCoin > 0) {
                if (this.$store.state.call.isMyCallEnd === false) {
                  showCallToast("The other person has left the room.");
                }
                store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END);
                store.dispatch('call/setCallStatus', CALL_STATUS.CALL_DONE.value);
                store.dispatch('call/setEndCallData', message.customData);
                this.otherHungUp(message.customData, callTime);
                this.fetchFirstRechargeStatus();
              }
            } else if (callStatus === CALL_STATUS.CALLING_ERROR_DONE.code) {
              if (callTime && spendCoin && callTime > 0 && spendCoin > 0) {
                store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END);
                store.dispatch('call/setCallStatus', CALL_STATUS.CALL_DONE.value);
                store.dispatch('call/setEndCallData', message.customData);
                this.otherHungUp(message.customData, callTime);
                this.fetchFirstRechargeStatus();
              }
            }
          } else if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END) {
            // 结束通话之后会收到通话时间和费用
            if (callNo === this.callInfo.callNo && (callStatus === CALL_STATUS.CALL_DONE.code || callStatus === CALL_STATUS.CALLING_ERROR_DONE.code)) {
              const { callTime, spendCoin } = message.customData;
              if (callTime && spendCoin && callTime > 0 && spendCoin > 0) {
                store.dispatch('call/setEndCallData', message.customData);
              }
            }
          }

          // 处理不足一分钟提醒
          if (customType === LESS_THAN_ONE_MINUTE) {
            console.log("=======LESS_THAN_ONE_MINUTE", callNo, this.callInfo.callNo);
            if (callNo === this.callInfo.callNo) {
              const remainingSeconds = 60;
              if (this.callStartTime > 0) {
                this.showRechargeReminderWithCountdown(remainingSeconds);
              } else {
                this.pendingRechargeReminder = remainingSeconds;
              }
            }
          }

          // 礼物消息仍然通过腾讯 IM 接收（兼容旧版本）
          if (customType === custom_type_gift) {
            this.messageList.push(message);
            this.scrollToBottom();
          }
        }
      });
    },

    // 监听消息修改事件（翻译结果会通过此事件返回）
    onMessageModified(event) {
      const modifiedMessages = event.data || [];
      modifiedMessages.forEach((modifiedMessage) => {
        // 查找消息列表中对应的消息并更新
        const index = this.messageList.findIndex(msg => {
          return msg.ID === modifiedMessage.ID ||
              (msg.sequence === modifiedMessage.sequence &&
                  msg.random === modifiedMessage.random &&
                  msg.time === modifiedMessage.time);
        });

        if (index !== -1) {
          // 完全替换旧消息为新消息
          this.$set(this.messageList, index, modifiedMessage);
          // 滚动到底部
          this.scrollToBottom();
        }
      });
    },

    // 获取翻译文本
    getTranslatedText(message) {
      if (!message.cloudCustomData) {
        return null;
      }
      try {
        const customData = typeof message.cloudCustomData === 'string'
          ? JSON.parse(message.cloudCustomData)
          : message.cloudCustomData;
        return customData.translatedText || null;
      } catch (e) {
        console.log('解析 cloudCustomData 失败:', e);
        return null;
      }
    },

    onTopMoreClick() {
      const userId = this.getRemoteUserId();
      if (!userId) {
        showCallToast('User ID not found');
        this.$router.back();
        return;
      }
      showUserDetailMoreDialog({
        onBlock: async () => {
          // 屏蔽用户
          const rsp = await statusBlack(this.userId);
          if (rsp && (rsp.success || rsp.code === 200 || rsp.code === 0)) {
            showCallToast('User blocked successfully');
          } else {
            showCallToast('Failed to block user');
          }
        },
        onReport: () => {
          // 显示举报对话框
          const userInfo = this.anchorInfo && Object.keys(this.anchorInfo).length > 0 ? {
            userId: this.anchorInfo.userId || this.userId,
            nickname: this.anchorInfo.nickname || this.anchorInfo.name || '',
            name: this.anchorInfo.name || this.anchorInfo.nickname || '',
            headImage: this.anchorInfo.headImage || this.anchorInfo.avatar || '',
            avatar: this.anchorInfo.avatar || this.anchorInfo.headImage || ''
          } : {};
          showReportDialog({
            userId: this.userId,
            userInfo: userInfo
          });
        },
        onBlockAndReport: async () => {
            const userInfo = this.anchorInfo && Object.keys(this.anchorInfo).length > 0 ? {
              userId: this.anchorInfo.userId || this.userId,
              nickname: this.anchorInfo.nickname || this.anchorInfo.name || '',
              name: this.anchorInfo.name || this.anchorInfo.nickname || '',
              headImage: this.anchorInfo.headImage || this.anchorInfo.avatar || '',
              avatar: this.anchorInfo.avatar || this.anchorInfo.headImage || ''
            } : {};
            showReportDialog({
              userId: this.userId,
              userInfo: userInfo
            });
        },
        onFeedback: () => {
          // 显示反馈对话框
          showFeedbackDialog();
        },
        onCancel: () => {
          // 取消操作，不需要做任何事
        }
      });
    },

    async onFollowClick() {
      const userId = this.getRemoteUserId();
      if (!userId) {
        showCallToast('User ID not found');
        this.$router.back();
        return;
      }
      // 判断当前是否已关注：followStatus !== 1 表示已关注
      const isCurrentlyFollowed = this.anchorInfo.followStatus && this.anchorInfo.followStatus !== 1;
      const follow = !isCurrentlyFollowed; // 如果当前已关注，则取消关注；如果未关注，则关注

      const {success, data} = await followStatus(userId, follow);
      if (success) {
        // 更新关注状态：1 表示未关注，其他值表示已关注
        this.anchorInfo.followStatus = follow ? 2 : 1;
        this.$store.dispatch('call/setAnchorInfo', this.anchorInfo);
        showCallToast(follow ? 'Liked' : 'Unliked');
      } else {
        showCallToast('Operation failed');
      }
    },

    onMoreActionClick() {
      this.showSettings = true;
    },

    // 切换摄像头开关
    async toggleCamera() {
      const newState = !this.cameraEnabled;
      await TXRTCManager.setVideoEnabled(newState);
      this.$store.dispatch('call/setIsOpenCamera', newState);
    },
    // 切换麦克风开关
    async toggleMic() {
      const newState = !this.micEnabled;
      await TXRTCManager.setAudioEnabled(newState);
      this.$store.dispatch('call/setIsOpenMicrophone', newState);
    },
    // 切换前后摄像头
    async switchCamera() {
      // 非VIP用户弹出VIP充值弹窗
      if (!this.isVip) {
        showPremiumDialog();
        return;
      }


      const success = await TXRTCManager.switchCamera();
      if (success) {
        // 更新 store 中的摄像头方向状态
        const isFrontCamera = !this.$store.getters.isFrontCamera;
        await this.$store.dispatch('call/setIsFrontCamera', isFrontCamera);
        showCallToast('Camera switched');
      } else {
        showCallToast('No other cameras');
      }
    },
    // 为 WKWebView 设置视频元素属性
    setVideoAttributes(container) {
      if (!container) return;

      // 等待 video 元素被创建（SDK 可能异步创建）
      const findAndSetAttributes = (retries = 10) => {
        const videoElement = container.querySelector('video');
        if (videoElement) {
          // 设置 iOS WKWebView 必需的属性
          videoElement.setAttribute('playsinline', 'true');
          videoElement.setAttribute('webkit-playsinline', 'true');
          videoElement.setAttribute('autoplay', 'true');
          videoElement.setAttribute('muted', 'true');
          // 确保视频可以播放
          if (videoElement.paused) {
            videoElement.play().catch(err => {
              console.warn('视频自动播放失败:', err);
            });
          }
        } else if (retries > 0) {
          // 如果还没找到，等待一段时间后重试
          setTimeout(() => findAndSetAttributes(retries - 1), 100);
        }
      };

      findAndSetAttributes();
    },
    getCallNo() {
      return this.callInfo?.callNo;
    },
    getRemoteUserId() {
      return this.callInfo?.anchorInfo?.userId || this.anchorInfo?.userId;
    },
    initCallStartTimer() {
      if (this.callTimer) {
        return
      }
      this.callTimer = setInterval(() => {
        this.callStartTime += 1000;
      }, 1000);

      // 检查是否有待处理的充值提醒（在通话计时开始前收到的）
      if (this.pendingRechargeReminder) {
        console.log('[🎥TX_CALL_FLOW] 处理待处理的充值提醒');
        this.showRechargeReminderWithCountdown(this.pendingRechargeReminder);
        this.pendingRechargeReminder = null;
      }
    },
    async ensureMediaPermissions() {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        return true;
      }
      try {
        const stream = await navigator.mediaDevices.getUserMedia({audio: true, video: true});
        stream.getTracks().forEach((t) => t.stop());
        return true;
      } catch (e) {
        showConfirmDialog({
          title: 'Enable Camera Access',
          message: 'To enable the camera for video chat, please enable camera access in your system settings.',
          confirmText: 'Cancel',
          cancelText: 'Go to Settings',
          onConfirm: () => {
            return false;
          },
          onCancel: () => {
            window.location.href = 'app-settings:';
            return true;
          }
        });
      }
    },
    onCallingHangupClick() {
      // 5秒内禁止点击
      if (this.hangupBtnDisabled) {
        return;
      }
      showConfirmDialog({
        title: 'End Video Chat',
        message: 'Are you sure you want to end this video chat?',
        confirmText: 'End Video Chat',
        onConfirm: () => {
          console.log('onCallingHangupClick');
          this.onCallEnd(CALL_STATUS.CALL_DONE,true);
        },
        onCancel: () => {

        }
      });
    },
    async onCallStart() {
      await this.initDevices();
    },
    async initDevices() {
      console.log('[🎥TX_CALL_FLOW] initDevices 开始初始化设备', new Date().toLocaleTimeString('zh-CN', { hour12: false }));

      const permissionOk = await this.ensureMediaPermissions();
      if (!permissionOk) {
        console.log('[🎥TX_CALL_FLOW] ❌ 媒体权限获取失败');
        return;
      }
      console.log('[🎥TX_CALL_FLOW] ✅ 媒体权限获取成功');

      // 使用 store 中的用户数据
      // 注意：需要从配置中获取腾讯云的 SDKAppId
      const { DEF_TENCENT_RTC_APP_ID } = store.state.PageCache.configData;

      // 获取 TRTC 相关的 Token 和配置
      console.log(this.$store.state.user.loginUserInfo);
      console.log(this.callInfo);

      let trtcUserSig = this.$store.state.user.loginUserInfo.userId === this.callInfo.createUserId ? this.callInfo.createUserSign : this.callInfo.toUserSign;
      console.log('[🎥TX_CALL_FLOW] localUserId',this.$store.state.user.loginUserInfo.userId);
      console.log('[🎥TX_CALL_FLOW] createUserId',this.callInfo.createUserId);
      console.log('[🎥TX_CALL_FLOW] trtcUserSig',trtcUserSig);
      console.log('[🎥TX_CALL_FLOW] createUserSign',this.callInfo.createUserSign);
      console.log('[🎥TX_CALL_FLOW] toUserSign',this.callInfo.toUserSign);
      // let trtcUserSig = this.callInfo.createUserSign;
      // createUserSign, toUserSign
      const sdkAppId = DEF_TENCENT_RTC_APP_ID;
      const roomId = this.getCallNo();
      const userId = this.loginUserInfo.userId.toString();
      console.log('[🎥TX_CALL_FLOW] configData',store.state.PageCache.configData);

      console.log('[🎥TX_CALL_FLOW] callInfo',this.callInfo);
      console.log('[🎥TX_CALL_FLOW] TRTC 配置', { sdkAppId, roomId, userId, trtcUserSig });

      // 使用 TXRTCManager 单例加入房间并发布流
      const { trtcClient } = await TXRTCManager.joinAndPublish(
        sdkAppId,
        roomId,
        trtcUserSig,
        userId,
        {
          onRemoteUserEnter: (event) => {
            console.log('[🎥TX_CALL_FLOW] 远端用户进入房间:', event.userId);
          },
          onRemoteUserLeave: (event) => {
            console.log('[🎥TX_CALL_FLOW] 远端用户离开房间:', event.userId);
          },
          onRemoteVideoAvailable: async (event) => {
            console.log('[🎥TX_CALL_FLOW] ====== 收到远程用户发布视频流 ======', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
            console.log('[🎥TX_CALL_FLOW] 远程用户信息:', { userId: event.userId });

            try {
              // 订阅远端视频流
              await TXRTCManager.subscribeRemoteVideo(event.userId, this.$refs.playerFull);

              this.$nextTick(() => {
                this.setVideoAttributes(this.$refs.playerFull);
                this.remoteVideoReady = true;
                console.log('[🎥TX_CALL_FLOW] ✅ 远端视频流就绪，开始显示', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
              });

              this.initCallStartTimer();

              // 第二次刷新本地推流，因为第三方主播端版本太低，有时候会黑屏
              setTimeout(() => {
                this.applyInitialMediaState(true);
              }, 300);
            } catch (error) {
              console.error('[🎥TX_CALL_FLOW] 订阅远端视频失败:', error);
            }
          },
          onRemoteAudioAvailable: async (event) => {
            console.log('[🎥TX_CALL_FLOW] ====== 收到远程用户发布音频流 ======', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
            try {
              await TXRTCManager.subscribeRemoteAudio(event.userId);
              console.log('[🎥TX_CALL_FLOW] ✅ 远端音频流开始播放', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
            } catch (error) {
              console.error('[🎥TX_CALL_FLOW] 订阅远端音频失败:', error);
            }
          },
          onError: (error) => {
            console.error('[🎥TX_CALL_FLOW] TRTC 错误:', error);
          }
        }
      );

      // 保存引用
      this.trtcClient = trtcClient;

      // 播放本地视频预览
      console.log('[🎥TX_CALL_FLOW] 开始播放本地视频预览');
      TXRTCManager.playLocalVideo(this.$refs.playerMin);
      this.$nextTick(() => {
        this.setVideoAttributes(this.$refs.playerMin);
        console.log('[🎥TX_CALL_FLOW] ✅ 本地视频预览就绪');
      });

      setTimeout(() => {
        this.applyInitialMediaState();
      }, 200);

      console.log('[🎥TX_CALL_FLOW] ====== 本地初始化完成，等待远程用户加入 ======', new Date().toLocaleTimeString('zh-CN', { hour12: false }));
    },
    // 进入房间后应用初始的摄像头和麦克风状态
    async applyInitialMediaState(isP = false) {
      // 使用标志位避免重复设置
      if (this.initialMediaStateApplied && isP === false) return;
      this.initialMediaStateApplied = true;

      // 根据 store 状态设置摄像头（异步执行，不阻塞）
      const cameraState = this.cameraEnabled;
      TXRTCManager.setVideoEnabled(cameraState).then(() => {
        console.log('摄像头状态已设置:', cameraState);
      }).catch(err => {
        console.error('摄像头状态设置失败:', err);
      });
      // 根据 store 状态设置麦克风（异步执行，不阻塞）
      const micState = this.micEnabled;
      TXRTCManager.setAudioEnabled(micState).then(() => {
        console.log('麦克风状态已设置:', micState);
      }).catch(err => {
        console.error('麦克风状态设置失败:', err);
      });
    },

    // 对方挂断电话
    async otherHungUp(data) {
      TXRTCManager.stopTracks();
    },

    /// 自己挂断电话
    async onCallEnd(status, isMyOperate = false, callTime = 0, is) {
      console.log('[🎥TX_CALL_FLOW] 通话结束 API 返回数据:',this.callInfo);
      await this.$store.dispatch('call/setIsMyCallEnd', true);
      // try {
        const res = await callEnd(this.getCallNo(), status);
        if (res && res.data) {
          console.log('[🎥TX_CALL_FLOW] 通话结束 API 返回数据:', res.data);
        }
      // } catch (error) {
      //   console.error('[🎥TX_CALL_FLOW] 通话结束 API 调用失败:', error);
      // }
      // 停止媒体流但不销毁，保持背景
      TXRTCManager.stopTracks();
    },
    formatDuration(seconds) {
      const s = Math.floor(seconds % 60);
      const m = Math.floor((seconds / 60) % 60);
      const h = Math.floor(seconds / 3600);
      const pad = v => String(v).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(s)}`;
    },
    /**
     * 从 API 获取首充状态
     */
    async fetchFirstRechargeStatus() {
      try {
        console.log('[🎥TX_CALL_FLOW] 获取首充状态（待实现）');
      } catch (error) {
        console.error('[🎥TX_CALL_FLOW] 获取首充状态失败:', error);
      }
    },
    async handleEndPageClose() {
      console.log('[🎥TX_CALL_FLOW] handleEndPageClose');
      try {
        await this.destroy();
      } catch (error) {
        console.error('[🎥CALL_FLOW] 销毁资源失败:', error);
      }
      if (window.history.length > 1) {
        this.$router.back();
        console.log('[🎥TX_CALL_FLOW] handleEndPageClose back')
      } else {
        console.log('[🎥TX_CALL_FLOW] handleEndPageClose PageSdkIndex')
        await this.$router.replace({name: 'PageSdkIndex'});
      }
    },


    // 翻译消息
    translateMessage(message, index) {
      // 如果已有翻译结果，则不处理
      if (this.getTranslatedText(message)) {
        return;
      }

      // 标记为正在翻译
      this.$set(this.messageList[index], 'translating', true);

      translationMsg(message).then((result) => {
        console.log("翻译返回:", result);
      }).catch((error) => {
        console.log("翻译失败:", error);
        toast(error);
      }).finally(() => {
        // 移除翻译标记
        this.$set(this.messageList[index], 'translating', false);
      });
    },
    openGiftDialog() {
      const giftDialog = showGiftGoodsDialog({userId: this.getRemoteUserId(), onSend: (gift) => {
          // 使用腾讯 IM 发送礼物消息
          tencentChat.m_sendGiftMessage(this.getRemoteUserId(), gift, (data) => {
            console.log("礼物消息发送成功:", data);
            // 关闭礼物选择弹窗
            if (giftDialog && giftDialog.$refs && giftDialog.$refs.bottomDialog) {
              giftDialog.$refs.bottomDialog.closeDialog();
            }
            // 显示礼物动效
            showGiftDialog(gift.svg);
          }, (error) => {
            console.log(error);
          });
        }
      });
    },
    async sendTextMessage() {
      if (!this.textContent || !this.textContent.trim()) {
        return;
      }
      // 防抖：正在发送时不允许重复发送
      if (this.isSendingMessage) {
        return;
      }
      this.isSendingMessage = true;

      const text = this.textContent.trim();
      // 立即清空输入框，防止重复发送
      this.textContent = '';
      console.log('[🎥TX_CALL_FLOW] sendTextMessage via 腾讯 IM:', text);

      // 使用腾讯 IM 发送消息
      tencentChat.m_sendTextMessage(this.getRemoteUserId(), text, (data) => {
        console.log("腾讯 IM 消息发送成功:", data);
        this.isSendingMessage = false;
      }, (error) => {
        console.error('[🎥TX_CALL_FLOW] 腾讯 IM 发送消息失败:', error);
        this.isSendingMessage = false;
        showCallToast('Send message failed');
      });
    },

    scrollToBottom() {
      const container = this.$refs.msgList;
      if (!container) {
        return;
      }
      setTimeout(() => {
        container.scrollTop = container.scrollHeight;
      }, 50);
    },
    // 显示充值提醒并开始倒计时
    showRechargeReminderWithCountdown(seconds = 60) {
      // 清除之前的定时器
      this.clearRechargeTimers();

      // 设置初始状态
      this.rechargeCountdown = seconds;
      this.showRechargeReminder = true;
      this.rechargeReminderExpanded = true;

      // 开始倒计时
      this.rechargeTimer = setInterval(() => {
        if (this.rechargeCountdown > 0) {
          this.rechargeCountdown--;
        } else {
          // 倒计时结束，清除定时器
          this.clearRechargeTimers();
        }
      }, 1000);

      // 3秒后自动收起
      this.rechargeExpandTimer = setTimeout(() => {
        this.rechargeReminderExpanded = false;
      }, 3000);
    },
    // 清除充值相关的定时器
    clearRechargeTimers() {
      if (this.rechargeTimer) {
        clearInterval(this.rechargeTimer);
        this.rechargeTimer = null;
      }
      if (this.rechargeExpandTimer) {
        clearTimeout(this.rechargeExpandTimer);
        this.rechargeExpandTimer = null;
      }
    },
    // 点击充值提示条
    onRechargeReminderClick() {
      if (!this.rechargeReminderExpanded) {
        // 如果是收起状态，点击展开
        this.rechargeReminderExpanded = true;
        // 清除之前的收起定时器
        if (this.rechargeExpandTimer) {
          clearTimeout(this.rechargeExpandTimer);
        }
        // 3秒后再次收起
        this.rechargeExpandTimer = setTimeout(() => {
          this.rechargeReminderExpanded = false;
        }, 3000);
      }
    },
    // 点击充值按钮
    onRechargeClick() {
      showRechargeDialog({
        showMessage: false,
        onSuccess: () => {
          // 充值成功后隐藏充值提醒
          this.clearRechargeTimers();
          this.showRechargeReminder = false;
        }
      });
    },
    async destroy() {
      // 清除挂断按钮定时器
      if (this.hangupBtnTimer) {
        clearTimeout(this.hangupBtnTimer);
        this.hangupBtnTimer = null;
      }
      // 清除充值提示相关定时器
      this.clearRechargeTimers();
      this.showRechargeReminder = false;
      // 重置远端视频状态
      this.remoteVideoReady = false;

      // 移除腾讯 IM 消息监听
      try {
        TencentImUtils.chatObj.off(TencentCloudChat.EVENT.MESSAGE_RECEIVED, this.onTencentImMessageReceived);
        TencentImUtils.chatObj.off(TencentCloudChat.EVENT.MESSAGE_MODIFIED, this.onMessageModified);
      } catch (e) {
        void e;
      }

      // 使用 TXRTCManager 销毁资源
      await TXRTCManager.destroy();
      this.trtcClient = null;
      if (this.callTimer) {
        clearInterval(this.callTimer);
        this.callTimer = null;
      }
    }
  },
  beforeRouteLeave(to, from, next) {
    if (!DialogTaskArray.isEmpty()) {
      DialogTaskArray.closeDialog();
      router.go(1)
      return;
    }
    next(true);
  },
  beforeDestroy() {
    this.destroy();
  }
}
</script>

<style scoped lang="less">
/* 固定全屏：避免外层 m-page-content 在 iOS 上抢触摸，使 chat-list 成为唯一可滚动区域 */
.call-page-root {
  position: fixed;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  overflow: hidden;
  z-index: 0;
}

.call-content {
  width: 100%;
  height: 100%;
  position: relative;
  box-sizing: border-box;
  background: red;
  .call-active {
    width: 100%;
    height: 100%;
  }

  .call-default-bg {
    position: fixed;
    inset: 0;
    z-index: 2;
    transition: opacity 0.5s ease;
    opacity: 1;
  }

  .call-default-bg-hidden {
    opacity: 0;
    pointer-events: none;
  }

  .call-default-bg-image {
    position: absolute;
    inset: -40px;
    background-size: cover;
    background-position: center;
    transform: scale(1.2);
    filter: blur(28px);
  }

  .call-default-bg-mask {
    position: absolute;
    inset: 0;
    background: linear-gradient(180deg, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0.55));
  }

  .call-connecting-tip {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 10;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
  }

  .connecting-text {
    color: rgba(255, 255, 255, 0.9);
    font-size: 18px;
    font-weight: 600;
    animation: pulse 1.5s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.5;
    }
  }

  .trtc-remote {
    position: fixed;
    inset: 0;
    z-index: 0;
    background: transparent;
  }

  .trtc-local-wrapper {
    position: fixed;
    z-index: 5;
    right: 0px;
    bottom: 100px;
    width: 100px;
    height: 150px;
    border-radius: 14px;
    overflow: hidden;
    border: 2px solid rgba(255, 255, 255, 0.8);
  }

  .trtc-local-bg {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    z-index: 0;
  }

  .trtc-local {
    position: relative;
    width: 100%;
    height: 100%;
    z-index: 1;
  }

  .local-control-panel {
    position: fixed;
    z-index: 6;
    right: 0px;
    bottom: 100px;
    width: 100px;
    height: 150px;
    border-radius: 14px;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 12px;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
  }

  .local-control-panel-all-show {
    padding-bottom: 50px;
  }

  .control-item {
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: transform 0.2s, opacity 0.2s;

    &:active {
      transform: scale(0.95);
      opacity: 0.8;
    }

    img {
      width: 36px;
      height: 36px;
    }
  }

  .call-top-gradient-bg {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 249px;
    z-index: 2;
    background: url('~@/assets/image/call/calling/ic_calling_top_bg@2x.png') no-repeat center top;
    background-size: 100% 100%;
    pointer-events: none;
  }

  .call-top {
    position: fixed;
    left: 12px;
    right: 12px;
    top: 59px;
    z-index: 3;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 10px;
    box-sizing: border-box;
  }

  .user {
    display: flex;
    align-items: center;
    min-width: 0;
  }

  .btn-back {
    width: 34px;
    height: 34px;
    border-radius: 999px;
    position: relative;
    margin-right: 10px;
    object-fit: contain;
    cursor: pointer;
    transition: opacity 0.3s, filter 0.3s;

    &.btn-disabled {
      opacity: 0.4;
      filter: grayscale(100%);
      cursor: not-allowed;
      pointer-events: none;
    }
  }

  .avatar {
    width: 38px;
    height: 38px;
    border-radius: 999px;
    object-fit: cover;
    border: 2px solid rgba(255, 255, 255, 0.7);
  }

  .meta {
    margin-left: 10px;
    min-width: 0;
  }

  .name {
    max-width: 220px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: #fff;
    font-size: 16px;
    font-weight: 600;
    line-height: 20px;
  }

  .coin {
    margin-top: 4px;
    display: inline-flex;
    align-items: center;
    padding: 2px 8px;
    border-radius: 999px;
    color: rgba(255, 255, 255, 0.95);
    font-size: 13px;
    line-height: 18px;
  }

  .coin-icon {
    width: 14px;
    height: 14px;
    margin-right: 6px;
  }

  .coin-text {
    display: inline-block;
  }

  .top-actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .btn-follow {
    width: 34px;
    height: 34px;
    margin-left: 12px;
  }

  .btn-more {
    width: 34px;
    height: 34px;
  }

  .call-timer {
    position: absolute;
    bottom: 10px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 4;
    background: rgba(0, 0, 0, 0.5);
    padding: 2px 12px 1px 12px;
    border-radius: 12px;
    color: #fff;
    font-size: 14px;
    font-weight: 500;
    white-space: nowrap;
    pointer-events: none;
  }

  .call-bottom {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 3;
    pointer-events: none;
  }

  .bottom-bg {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 0;
    width: 100%;
    height: 280px;
    object-fit: fill;
    pointer-events: none;
  }

  // 充值提示条样式
  .recharge-reminder {
    position: absolute;
    left: 0;
    bottom: 300px;
    z-index: 10;
    pointer-events: auto;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .recharge-bg {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 0 25px 25px 0;
  }

  // 展开状态
  .recharge-reminder-expanded {
    height: 50px;

    .recharge-bg {
      border-radius: 0 25px 25px 0;
    }
  }

  .recharge-content-expanded {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    height: 50px;
    padding: 0 12px 0 16px;
    gap: 8px;
  }

  .recharge-clock {
    width: 24px;
    height: 24px;
    flex-shrink: 0;
  }

  .recharge-text {
    color: #fff;
    font-size: 14px;
    font-weight: 600;
    white-space: nowrap;
  }

  .recharge-countdown {
    color: #fff;
    font-size: 16px;
    font-weight: 700;
    font-family: 'SF Mono', 'Monaco', monospace;
    white-space: nowrap;
  }

  .recharge-btn {
    margin-left: auto;
    padding: 6px 16px;
    background: #fff;
    border: none;
    border-radius: 20px;
    color: #FF6B35;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    transition: transform 0.2s, opacity 0.2s;

    &:active {
      transform: scale(0.95);
      opacity: 0.9;
    }
  }

  // 收起状态
  .recharge-reminder-collapsed {
    height: 36px;

    .recharge-bg {
      border-radius: 0 18px 18px 0;
    }
  }

  .recharge-content-collapsed {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    height: 36px;
    padding: 0 12px 0 16px;
    gap: 6px;
  }

  .recharge-countdown-small {
    color: #fff;
    font-size: 14px;
    font-weight: 700;
    font-family: 'SF Mono', 'Monaco', monospace;
    white-space: nowrap;
  }

  .recharge-expand-arrow {
    width: 12px;
    height: 12px;
    object-fit: contain;
  }

  // 全屏闪烁背景（最后20秒）
  .recharge-fullscreen-flash {
    position: fixed;
    inset: 0;
    z-index: 6;
    pointer-events: none;
    animation: fullscreen-blink 1s ease-in-out infinite;
  }

  .recharge-fullscreen-bg {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  @keyframes fullscreen-blink {
    0%, 100% {
      opacity: 0.8;
    }
    50% {
      opacity: 0.3;
    }
  }

  // 聊天区域
  .chat {
    position: absolute;
    left: 0;
    right: 60px;
    bottom: 110px;
    box-sizing: border-box;
    pointer-events: auto;
    overflow: hidden; /* 限定可滚动区域，配合子元素 .chat-list 在 iOS 上正常滑动 */
  }

  .chat-list {
    height: 190px;
    overflow-x: hidden;
    overflow-y: scroll; /* iOS 16：scroll 比 auto 更易触发内层滚动 */
    -webkit-overflow-scrolling: touch;
    touch-action: pan-y;
    padding: 0 20px 10px 20px;
    box-sizing: border-box;
    scrollbar-width: none;
    -ms-overflow-style: none;
    display: block; /* 避免 flex 在 iOS 上影响滚动高度计算 */
    transform: translateZ(0);
  }

  /* 内容包裹层：让 iOS 正确计算可滚动高度，配合 justify-content: flex-end 效果用 margin-top: auto */
  .chat-list-inner {
    min-height: min-content;
    display: flex;
    flex-direction: column;
    justify-content: flex-end;
  }

  .chat-list::-webkit-scrollbar {
    display: none;
  }

  .item {
    margin-bottom: 10px;
    width: 100%;
    min-width: 0;
    box-sizing: border-box;
  }

  /* 气泡固定宽度，对方发送的文字在气泡内换行 */
  .msg-content {
    display: inline-block;
    width: auto;
    max-width: 78%;
    min-width: 0;
    box-sizing: border-box;
    overflow: hidden;
    background: rgba(0, 0, 0, 0.30);
    border-radius: 10px 10px 10px 10px;
    padding: 5px 10px;
  }

  .msg-header {
    display: flex;
    align-items: flex-start;
    gap: 6px;
    padding: 8px 10px;
    min-width: 0;
    width: 100%;
    max-width: 100%;
    box-sizing: border-box;
    overflow: hidden;

    /* 对方消息文字与己方一致：左对齐，不居中 */
    &.no-translation {
      justify-content: flex-start;

      .msg-text {
        text-align: left;
        flex: 1;
        min-width: 0;
      }
    }

    .msg-text {
      min-width: 0;
      max-width: 100%;
      width: 100%;
      overflow-wrap: break-word;
      word-break: break-word;
    }
  }

  .msg-text {
    flex: 1;
    display: block;
    width: 100%;
    max-width: 100%;
    min-width: 0;
    word-break: break-word;
    overflow-wrap: break-word;
    white-space: pre-wrap;
    color: rgba(255, 255, 255, 0.95);
    font-family: 'PingFang SC-Heavy', 'PingFang SC', sans-serif;
    font-weight: 900;
    font-size: 12px;
    line-height: 1.4;
    margin: 0;
    text-align: left;
    padding: 6px 10px;
    box-sizing: border-box;
  }

  .msg-text-self {
    color: #FFDB0D;
  }

  .msg-translate-btn {
    width: 20px;
    height: 20px;
    flex-shrink: 0;
    cursor: pointer;
    opacity: 0.8;
    transition: opacity 0.2s;

    &:hover {
      opacity: 1;
    }

    &:active {
      opacity: 0.6;
    }
  }

  .msg-translated {
    padding: 6px 10px 8px 10px;
    display: block;
    word-break: break-word;
    color: rgba(255, 255, 255, 0.75);
    font-family: 'PingFang SC', sans-serif;
    font-weight: 400;
    font-size: 11px;
    line-height: 1.4;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    margin-top: 4px;
  }

  .msg-translating {
    flex-shrink: 0;
    font-size: 10px;
    color: rgba(255, 255, 255, 0.6);
    padding: 2px 6px;
  }

  .send-self {
  text-align: left;
}

.send-self .msg-content {
  background: rgba(255, 255, 255, 0.18);
  border-radius: 14px 14px 14px 14px;
}

  .msg-gift {
    padding: 6px 10px;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: rgba(255, 255, 255, 0.95);
    font-size: 12px;
  }

  .msg-gift img {
    width: 30px;
    height: 30px;
  }

  .chat-input {
    position: absolute;
    left: 0;
    right: 0;
    bottom: 46px;
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 0 20px;
    pointer-events: auto;
  }

  .msg-field {
    flex: 1;
    min-width: 0;
    height: 50px;
    border-radius: 999px;
    border: 1px solid rgba(255, 255, 255, 0.65);
    background: rgba(0, 0, 0, 0.18);
    padding: 0 14px;
    color: rgba(255, 255, 255, 0.95);
    outline: none;
    box-sizing: border-box;
    font-size: 16px;
  }

  .btn-more-action,
  .btn-gift {
    flex-shrink: 0;
    width: 37px;
    height: 37px;
  }

  // 设置面板遮罩
  .settings-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 10;
  }

  // 设置面板
  .settings-panel {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    background: #1a1a1a;
    border-radius: 16px 16px 0 0;
    z-index: 11;
    transform: translateY(100%);
    transition: transform 0.3s ease;
    padding-bottom: env(safe-area-inset-bottom);

    &.show {
      transform: translateY(0);
    }
  }

  .settings-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    color: #fff;
    font-size: 16px;
    font-weight: 600;

    .close-btn {
      font-size: 24px;
      cursor: pointer;
      opacity: 0.7;
    }
  }

  .settings-options {
    display: flex;
    justify-content: space-around;
    padding: 24px 16px 32px;
  }

  .setting-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    cursor: pointer;

    img {
      width: 48px;
      height: 48px;

      &.disabled {
        opacity: 0.4;
      }
    }

    span {
      color: rgba(255, 255, 255, 0.8);
      font-size: 12px;
    }
  }

  .setting-item-vip {
    position: relative;

    .vip-crown {
      position: absolute;
      top: -6px;
      right: -6px;
      width: 20px !important;
      height: 20px !important;
      z-index: 1;
    }
  }

}

.call-end-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  pointer-events: auto;
}
</style>

<style>
.trtc-local div {
  border-radius: 8px;
}
</style>
