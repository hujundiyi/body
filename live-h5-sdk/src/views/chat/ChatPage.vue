<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <!-- 自定义导航栏 -->
      <div ref="customNavBar" class="custom-nav-bar" :style="navBarStyle">
        <img class="ic-back" :src="backIcon" alt="Back" @click="goBack" />
        <div class="center-content" @click="openAnchorUserDetail(userInfo.userId, 'chat')">
          <div class="user-info">
            <span class="nickname">{{ userInfo.nickname }}</span>
            <span v-if="shouldShowStatus" class="onlineStatus" :class="getStatusClass">
              <span v-if="isAvailable" class="status-dot"></span>
              {{ getStatusText }}
            </span>
          </div>
        </div>
        <div class="premium-badge-wrap">
          <div v-if="!isOtherUserVip" class="premium-badge" @click="openPremium()">
            <img class="premium-icon" src="@/assets/image/message/ic-message-un-pre-icon.png" alt=""/>
            <span class="premium-text">Premium</span>
          </div>
          <!-- 礼物促销气泡：紧贴 Premium badge 下方 -->
          <transition name="fade-bubble">
            <div v-if="showGiftBubble" class="gift-promo-bubble" :class="{ 'gift-below-badge': !isOtherUserVip }" :style="giftBubbleStyle" @click="openPremium()"
            >
              <img class="gift-icon" src="@/assets/image/message/ic-message-pre-gift-icon.png" alt=""/>
              <transition name="slide-text" mode="out-in">
                <span :key="currentGiftText" class="gift-text">{{ currentGiftText }}</span>
              </transition>
            </div>
          </transition>
        </div>
      </div>
      <div class="main">
        <div ref="msgList" class="list-wrap" :style="listWrapStyle" :class="{ 'list-loading': isFirstLoading }">
          <div class="time no-more" v-show="noMoreMessage" :data-time="noMoreMessage">
          </div>

          <div v-for="(it,index) in messageList" :key="index">
            <div class="time" v-if="shouldShowTime(it, index)" :data-time="formatTimeAgoEnglish(it.time * 1000)">
            </div>
            <div :class="['item',isSelf(it.from)?'send-self':'receive']">
              <div v-if="!isSelf(it.from)" class="msg-avatar" @click="openAnchorUserDetail(userInfo.userId, 'chat')">
                <img v-if="userInfo.headImage" :src="userInfo.headImage" alt=""/>
              </div>
              <div class="msg-content" :class="{ 'msg-content-text': it.type===TencentCloudChat.TYPES.MSG_TEXT }">
                <div class="msg-text-wrapper" v-if="it.type===TencentCloudChat.TYPES.MSG_TEXT">
                  <p class="msg-text">{{ it.payload.text }}</p>
                  <div v-if="getTranslatedText(it)" class="msg-translation-content">
                    <div class="msg-translation-divider"></div>
                    <p class="msg-translated-text">{{ getTranslatedText(it) }}</p>
                  </div>
                </div>
                <img class="msg-content msg-img" v-if="it.type===TencentCloudChat.TYPES.MSG_IMAGE"
                     :src="it.payload.imageInfoArray[1].imageUrl" alt="" @click="handleImageClick(it,index)"/>
                <div class="msg-content msg-video" v-if="it.type===TencentCloudChat.TYPES.MSG_VIDEO" @click="handleVideoClick(it, index)">
                  <img v-if="getVideoCover(it)" class="msg-video-preview" :src="getVideoCover(it)" alt="Video"/>
                  <video v-else-if="getVideoUrl(it)" class="msg-video-preview" :src="getVideoUrl(it)" muted loop playsinline webkit-playsinline></video>
                  <div class="msg-video-play-button">
                    <img src="@/assets/image/sdk/ic-userdetail-big-play.png" alt="Play" class="play-icon"/>
                  </div>
                </div>
                <div class="msg-content" v-if="it.type===TencentCloudChat.TYPES.MSG_CUSTOM">
                  <div class="msg-gift" v-if="it.customData.customType===custom_type_gift">
                    <img :src="it.customData.image"/>
                    <div class="msg-gift-info">
                      <p class="msg-gift-info-name">{{ it.customData.name }}</p>
                      <div class="msg-gift-info-coin">
                        <img src="@/assets/image/message/ic-message-gift-coins.png" alt="">
                        <p>{{ it.customData.coin }}</p>
                      </div>
                    </div>
                    <div class="msg-gift-quantity" v-if="it.customData.giftNum > 1">x{{ it.customData.giftNum }}</div>
                  </div>
                  <div class="msg-call" v-if="it.customData.customType===CALL_STATUS_CHANGE"
                       :class="{'msg-call-missed': isCallMissed(it), 'msg-call-self': isSelf(it.from)}"
                       @click="handleCall">
                    <img :src="getCallIcon(it)" alt=""/>
                    <p>{{ it.customData.typeText }}</p>
                  </div>
                </div>
              </div>
              <img
                v-if="!isSelf(it.from) && it.type===TencentCloudChat.TYPES.MSG_TEXT && it.payload.text && !getTranslatedText(it)"
                class="msg-translation" src="@/assets/image/message/ic-message-translation_icon.png" alt=""
                @click.stop="translateMessage(it, index)"
              />
            </div>
          </div>

        </div>
        <!-- 悬浮视频按钮 -->
        <img src="@/assets/image/message/ic-message-video.png" class="video-icon-float" alt="" :style="videoIconStyle"
          @click="handleCall"/>
        <footer class="bottom-wrap">
          <div>
<!--           <img class="gift-icon" src="@/assets/image/message/ic-message-gift.png" alt="" @click="openGiftDialog"/>-->
            <div class="textarea-wrapper">
              <textarea ref="msgInput" v-model="textContent" @input="handleInput"/>
              <span v-if="!hasInput" class="custom-placeholder">Message</span>
            </div>
            <img v-if="textContent" class="send-btn" :src="require('@/assets/image/message/ic-message-send-sel.png')"
                 alt="" @click="sendTextMessage"/>
            <img v-else class="send-btn" :src="require('@/assets/image/message/ic-message-send-nor.png')" alt=""/>
          </div>
        </footer>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>

import {showGiftCheckDialog, showGiftDialog, showGiftGoodsDialog, showRechargeDialog} from "@/components/dialog";
import {
  CALL_STATUS_CHANGE,
  custom_type_gift,
  TencentImUtils,
} from "@/utils/TencentImUtils";
import TencentCloudChat from "@tencentcloud/chat";
import {formatTimeAgoEnglish} from "@/utils/Utils";
import {openAnchorUserDetail, openPicturePreview, openPremium, openUserInfo} from "@/utils/PageUtils";
import {callCreate} from "@/utils/CallUtils";
import store from "@/store";
import {sendGift} from "@/api/sdk/call";
import tencentChat, {isSelf} from "@/views/chat/ChatCompon";
import {getAnchorInfo} from "@/api/sdk/anchor";
import {CALL_STATUS, key_cache} from "@/utils/Constant";
import {translationMsg} from "@/api/sdk/message";
import cache from "@/utils/cache";
import clientNative from "@/utils/ClientNative";
import {toast} from "@/components/toast";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'ChatPage',
  components: {},
  data() {
    return {
      custom_type_gift,
      CALL_STATUS_CHANGE,
      msgListHeight: this.calculateMsgListHeight(),
      topHeight: 0,
      bottomHeight: 0,
      noMoreMessage: '',
      userInfo: {userId: null, nickname: 'chat', headImage: '', onlineStatus: 99, vipCategory: null},
      userInfoLoaded: false,
      nextReqMessageID: null,
      isCompleted: false,
      messageList: [],
      textContent: '',
      isKeyboardOpen: false,
      isFirstLoading: true,
      keyboardHeight: 0,
      initialWindowHeight: 0,
      hasInput: false,
      firstKeyboardViewportHeight: 0, // 记录第一次键盘弹出时的 viewportHeight
      showGiftBubble: false, // 是否显示礼物气泡
      currentGiftText: 'Get up to 100,000 FREE Coins!', // 当前显示的文案
      giftBubbleTimers: [], // 礼物气泡相关的定时器
      giftBubbleShown: false // 本次会话中是否已经显示过气泡
    }
  },
  beforeRouteLeave(to, from, next) {
    // 对同一主播累计发出 >=5 条消息后退出私聊页，弹出好评（条数存本地）
    const uid = this.userInfo && this.userInfo.userId;
    if (uid) {
      const counts = cache.local.getJSON(key_cache.chat_sent_count_by_anchor) || {};
      const count = Number(counts[uid]) || 0;
      if (count >= 5) {
        const hasShownGoodPop = cache.local.get(key_cache.dialog_show_good_pop);
        if (hasShownGoodPop !== '1') {
          clientNative.openEvaluate();
          cache.local.set(key_cache.dialog_show_good_pop, '1');
        }
      }
    }
    next();
  },
  computed: {
    backIcon() {
      return require('@/assets/image/ic-common-back.png');
    },
    TencentCloudChat() {
      return TencentCloudChat
    },
    chatInitSuccess() {
      return this.$store.state.PageCache.chatInitSuccess
    },
    loginUserInfo() {
      return this.$store.state.user.loginUserInfo
    },
    shouldShowStatus() {
      // 只有在数据加载完成后才显示状态
      if (!this.userInfoLoaded) {
        return false;
      }
      const status = Number(this.userInfo.onlineStatus);
      // 检查 onlineStatus 是否为 0 (Available) 或 2 (In call)
      return status === 0 || status === 2;
    },
    getStatusText() {
      const status = Number(this.userInfo.onlineStatus);
      if (status === 0) {
        return 'Available';
      } else if (status === 2) {
        return 'In Call';
      }
      return '';
    },
    isAvailable() {
      return Number(this.userInfo.onlineStatus) === 0;
    },
    getStatusClass() {
      const status = Number(this.userInfo.onlineStatus);
      if (status === 0) {
        return 'status-available';
      } else if (status === 2) {
        return 'status-in-call';
      }
      return '';
    },
    isOtherUserVip() {
      // 判断当前登录用户是否是 VIP：如果是 VIP 就不显示图标
      const loginUserInfo = this.loginUserInfo || {};
      const vipCategory = loginUserInfo.vipCategory;
      return vipCategory !== undefined && 
             vipCategory !== null && 
             vipCategory !== 0;
    },
    giftBubbleStyle() {
      // 有 Premium badge 时气泡用 CSS 紧贴其下方，无需 top/right
      if (!this.isOtherUserVip) return {};
      // 无 badge 时：固定于导航栏下、距右 20px
      const navBarHeight = this.topHeight || 70;
      return {
        top: `${navBarHeight}px`,
        right: '20px'
      };
    },
    listWrapStyle() {
      const style = {
        top: (this.topHeight + this.keyboardHeight) + 'px',
        bottom: this.bottomHeight + 'px'
      };

      // 键盘弹出时，添加顶部内边距
      if (this.isKeyboardOpen) {
        style.paddingTop = '200px';
      }

      return style;
    },
    navBarStyle() {
      if (this.keyboardHeight > 0) {
        return {
          top: `${this.keyboardHeight}px`
        };
      }
      return {};
    },
    videoIconStyle() {
      // 距离底部11px，距离屏幕右边20px
      // 输入框是 fixed 定位在底部，键盘弹起时输入框会跟着键盘移动
      // 键盘关闭时输入框高度是70px+安全区域，键盘打开时是50px+安全区域
      // 视频按钮应该在输入框上方11px的位置
      // 使用实际计算的 bottomHeight，如果还没有更新则根据键盘状态估算
      let inputHeight = this.bottomHeight;
      if (!inputHeight || inputHeight === 0) {
        // 如果 bottomHeight 还没有计算，根据键盘状态估算
        const safeAreaBottom = window.innerHeight > 800 ? 34 : 0;
        inputHeight = this.isKeyboardOpen ? (50 + safeAreaBottom) : (70 + safeAreaBottom);
      }
      const bottomOffset = inputHeight + 11; // 始终在输入框上方11px
      return {
        bottom: `${bottomOffset}px`,
        right: '15px'
      };
    }
  },
  watch: {
    chatInitSuccess() {
      this.loadHistoryList();
    }
  },
  created() {
    this.initChatSdkListener();
  },
  mounted() {
    // 保存初始窗口高度，用于计算键盘高度
    this.initialWindowHeight = window.innerHeight;

    this.handleKeyboardResize();
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', this.handleKeyboardResize);
    }

    const {userId, nickname, headImage} = this.$route.query
    this.userInfo = {userId, nickname, headImage, onlineStatus: null};
    if (userId === 1) {
      this.userInfo.nickname = "Admin";
    }else {
      getAnchorInfo(this.userInfo.userId).then(({data, code}) => {
        if (code === 200) {
          this.userInfo.nickname = data.nickname;
          this.userInfo.headImage = data.avatar;
          this.userInfo.onlineStatus = data.onlineStatus;
          this.userInfo.vipCategory = data.vipCategory;
          // 标记数据已加载
          this.userInfoLoaded = true;
          // 强制更新视图
          this.$forceUpdate();
        }
      });
    }

    this.initView();
    // 等待 DOM 渲染完成后重新计算列表高度
    this.$nextTick(() => {
      this.updateListDimensions();
      this.msgListHeight = this.calculateMsgListHeight();
      if (this.chatInitSuccess) {
        this.loadHistoryList()
      }
    });
    // 添加测试礼物消息
    // this.addTestGiftMessage();
    // 添加测试通话消息
    // this.addTestCallMessage();
    
    // 只有非 VIP 用户才启动礼物气泡定时器
    if (!this.isOtherUserVip) {
      this.startGiftBubbleTimer();
    }
  },
  activated() {
    // 更新导航栏高度
    this.$nextTick(() => {
      this.updateListDimensions();
      this.msgListHeight = this.calculateMsgListHeight();
    });

    if (this.chatInitSuccess) {
      this.nextReqMessageID = null;
      this.loadHistoryList();
    }

    // 只有非 VIP 用户才启动礼物气泡定时器
    if (!this.isOtherUserVip) {
      this.startGiftBubbleTimer();
    }
  },
  deactivated() {
    // 离开页面时清理定时器
    this.clearGiftBubbleTimers();
    this.showGiftBubble = false;
  },
  methods: {
    openPremium,
    updateListDimensions() {
      // 更新列表的 top 和 bottom 高度
      const customNavBar = this.$refs.customNavBar;
      const bottomWrap = document.querySelector('.bottom-wrap');

      if (customNavBar) {
        // 使用实际高度（包括 padding 和安全区域）
        this.topHeight = customNavBar.offsetHeight;
      } else {
        // 备用方案：计算导航栏高度（70px = 60px action-bar + 10px padding + 安全区域）
        const safeAreaTop = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--safe-area-inset-top')) ||
                           (window.innerHeight > 800 ? 44 : 0);
        this.topHeight = 70 + safeAreaTop;
      }

      if (bottomWrap) {
        this.bottomHeight = bottomWrap.offsetHeight;
      } else {
        const safeAreaBottom = window.innerHeight > 800 ? 34 : 0;
        this.bottomHeight = 70 + safeAreaBottom;
      }
    },
    goBack() {
      this.$router.back();
    },
    calculateMsgListHeight() {
      // 更新尺寸
      this.updateListDimensions();

      // 获取原始的 viewportHeight
      const rawViewportHeight = window.visualViewport ? window.visualViewport.height : window.innerHeight;
      
      // 如果已经记录过第一次键盘弹出时的值，确保不小于该值
      let viewportHeight = rawViewportHeight;
      if (this.isKeyboardOpen && this.firstKeyboardViewportHeight > 0) {
        viewportHeight = Math.max(rawViewportHeight, this.firstKeyboardViewportHeight);
      }
      
      return viewportHeight - this.topHeight - this.bottomHeight;
    },
    handleInput(event) {
      // 当有输入时（包括任何字符，包括空格），隐藏占位符
      // 只要输入框有任何内容，就隐藏占位符
      this.hasInput = event.target.value.length > 0;
    },
    handleKeyboardResize() {
      if (!window.visualViewport) {
        return;
      }
      // 获取原始的 viewportHeight
      const rawViewportHeight = window.visualViewport.height;
      // 使用初始窗口高度来判断键盘是否弹起
      const keyboardOpen = rawViewportHeight < this.initialWindowHeight - 100;
      const wasKeyboardOpen = this.isKeyboardOpen;
      this.isKeyboardOpen = keyboardOpen;

      let viewportHeight = rawViewportHeight;

      // 如果键盘从关闭变为打开（第一次弹出）
      if (keyboardOpen && !wasKeyboardOpen) {
        // 记录第一次键盘弹出时的 viewportHeight
        this.firstKeyboardViewportHeight = rawViewportHeight;
        viewportHeight = rawViewportHeight;
      } 
      // 如果键盘已经打开，且已经记录过第一次的值
      else if (keyboardOpen && this.firstKeyboardViewportHeight > 0) {
        // 确保 viewportHeight 不小于第一次记录的值
        viewportHeight = Math.max(rawViewportHeight, this.firstKeyboardViewportHeight);
      }
      // 如果键盘关闭，保持原始值（但不会用于计算）
      else {
        viewportHeight = rawViewportHeight;
      }

      // 计算键盘高度：初始高度 - 当前可视区域高度
      if (keyboardOpen) {
        this.keyboardHeight = this.initialWindowHeight - viewportHeight;
      } else {
        this.keyboardHeight = 0;
      }

      document.body.classList.toggle('keyboard-open', keyboardOpen);

      // 键盘弹出/收起时，更新列表尺寸
      this.updateListDimensions();

      // 如果键盘弹出，滚动到底部，确保能看到最新消息
      if (keyboardOpen) {
        this.$nextTick(() => {
          setTimeout(() => {
            this.scrollToBottom();
          }, 100);
        });
      }
      console.log('initialWindowHeight', this.initialWindowHeight);
      console.log('viewportHeight', viewportHeight);
      console.log('keyboardHeight', this.keyboardHeight);
    },
    openAnchorUserDetail,
    showGiftGoodsDialog,
    isSelf,
    async handleCall() {
      const userInfo = this.userInfo;
      if (!userInfo || !userInfo.userId) return;
      await store.dispatch('call/setAnchorInfo', userInfo);
      callCreate(userInfo.userId).then(() => {}).catch(() => {});
    },
    openUserInfo,
    showGiftCheckDialog,
    formatTimeAgoEnglish,
    shouldShowTime(message, index) {
      // 第一条消息总是显示时间
      if (index === 0) {
        return true;
      }
      // 获取上一条消息
      const prevMessage = this.messageList[index - 1];
      if (!prevMessage) {
        return true;
      }
      // 计算时间差（毫秒）
      const timeDiff = (message.time * 1000) - (prevMessage.time * 1000);
      // 如果时间差大于2分钟（120000毫秒），显示时间
      return timeDiff > 120000;
    },
    initView() {
      const msgList = this.$refs.msgList;
      if (!msgList) {
        return;
      }
      msgList.addEventListener('scroll', () => {
        if (msgList.scrollTop <= 10) {
          this.loadHistoryList();
        }
      });
    },
    onMessageReceived(event) {
      const messageList = event.data;
      messageList.forEach((message) => {
        if (message.conversationID === TencentImUtils.getConversationIdByUserId(this.userInfo.userId)) {
          // 判断是否需要跳过该消息（只有 customData 存在且 callStatus 为 ANSWER 时才跳过）
          const shouldSkip = message.customData && message.customData.callStatus === CALL_STATUS.ANSWER.code;
          if (!shouldSkip) {
            this.messageList.push(message);
          }
          this.$nextTick(() => {
            this.scrollToBottom();
          });
        }
      });
    },
    onMessageModified(event) {
      // event.data - 存储被修改过的 Message 对象的数组
      const modifiedMessages = event.data || [];
      modifiedMessages.forEach((modifiedMessage) => {
        // 查找消息列表中对应的消息并更新
        const index = this.messageList.findIndex(msg => {
          // 通过消息的唯一标识符匹配（ID、sequence、random、time 等）
          return msg.ID === modifiedMessage.ID ||
              (msg.sequence === modifiedMessage.sequence &&
                  msg.random === modifiedMessage.random &&
                  msg.time === modifiedMessage.time);
        });

        if (index !== -1) {
          // 完全替换旧消息为新消息
          this.$set(this.messageList, index, modifiedMessage);
        }
      });
    },
    initChatSdkListener() {
      TencentImUtils.onMessageReceived(this.onMessageReceived);
      TencentImUtils.onMessageModified(this.onMessageModified);
    },
    loadHistoryList() {
      const options = {
        conversationID: TencentImUtils.getConversationIdByUserId(this.userInfo.userId),
        nextReqMessageID: this.nextReqMessageID
      };

      // 如果是加载历史消息，保存当前滚动位置
      let oldScrollHeight = 0;
      let oldScrollTop = 0;
      const msgList = this.$refs.msgList;
      if (this.nextReqMessageID != null && msgList) {
        oldScrollHeight = msgList.scrollHeight;
        oldScrollTop = msgList.scrollTop;
      }

      TencentImUtils.chatObj.getMessageList(options).then(({data}) => {
        const {isCompleted, messageList, nextReqMessageID} = data;
        console.log(messageList)
        if (this.isCompleted) {
          this.noMoreMessage = 'No more'
          return
        }
        messageList.forEach((it) => {
          TencentImUtils.initCustomMessage(it);
        })

        if (this.nextReqMessageID == null) {
          // 首次加载时，先隐藏列表，避免显示中间位置
          this.isFirstLoading = true;
          this.messageList = messageList;
          // 首次加载时，需要等待布局完成
          this.$nextTick(() => {
            // 重新计算高度，确保准确（此时底部输入框已渲染）
            this.msgListHeight = this.calculateMsgListHeight();
            // 再次等待，确保高度更新生效
            this.$nextTick(() => {
              const msgList = this.$refs.msgList;
              if (msgList) {
                // 立即设置滚动位置到底部，不使用动画
                msgList.scrollTop = msgList.scrollHeight;
                // 使用 requestAnimationFrame 确保滚动完成后再显示
                requestAnimationFrame(() => {
                  requestAnimationFrame(() => {
                    if (this.$refs.msgList) {
                      // 再次确保滚动到底部
                      this.$refs.msgList.scrollTop = this.$refs.msgList.scrollHeight;
                      // 显示列表
                      this.isFirstLoading = false;
                    }
                  });
                });
              }
            });
          });
        } else {
          // 加载历史消息前，保存滚动位置
          for (let i = messageList.length - 1; i >= 0; i--) {
            this.messageList.unshift(messageList[i]);
          }

          // 恢复滚动位置，保持用户看到的第一个消息不变
          this.$nextTick(() => {
            if (msgList) {
              const newScrollHeight = msgList.scrollHeight;
              const scrollDiff = newScrollHeight - oldScrollHeight;
              msgList.scrollTop = oldScrollTop + scrollDiff;
            }
          });
        }
        this.nextReqMessageID = nextReqMessageID;
        this.isCompleted = isCompleted;
        TencentImUtils.setMessageRead(this.userInfo.userId)
      });
    },
    sendTextMessage() {
      if (!this.textContent) {
        return
      }
      // 确保 textarea 保持焦点
      const msgInput = this.$refs.msgInput;
      if (msgInput) {
        msgInput.focus();
      }
      const messageText = this.textContent;

      tencentChat.m_sendTextMessage(this.userInfo.userId, messageText, (data) => {
        console.log("文本消息发送成功:",data);
        if (cache.local.get(key_cache.dialog_show_good_pop) === '1') return;
        const uid = this.userInfo.userId;
        if (uid) {
          const counts = cache.local.getJSON(key_cache.chat_sent_count_by_anchor) || {};
          counts[uid] = (Number(counts[uid]) || 0) + 1;
          cache.local.setJSON(key_cache.chat_sent_count_by_anchor, counts);
        }
      }, (error) => {

      });

      this.textContent = '';
      this.hasInput = false; // 清空内容后重置输入状态
      // 发送后立即重新聚焦，保持键盘打开
      this.$nextTick(() => {
        if (msgInput) {
          msgInput.focus();
        }
      });
    },
    openGiftDialog() {
      const giftDialog = showGiftGoodsDialog({userId: this.userInfo.userId, onSend: (gift) => {
          tencentChat.m_sendGiftMessage(this.userInfo.userId, gift, (data) => {
            console.log("礼物消息发送成功:",data);
            // 关闭礼物选择弹窗
            if (giftDialog && giftDialog.$refs && giftDialog.$refs.bottomDialog) {
              giftDialog.$refs.bottomDialog.closeDialog();
            }
            // 显示礼物动效
            showGiftDialog(gift.svg);
          }, (error) => {
            console.error("礼物消息发送失败:", error);
          });
        }
      });
    },
    scrollToBottom(isFirstLoad = false) {
      const container = this.$refs.msgList;
      if (!container) {
        return;
      }

      // 使用 requestAnimationFrame 确保在下一帧执行，DOM 已更新
      requestAnimationFrame(() => {
        if (!this.$refs.msgList) {
          return;
        }
        const msgList = this.$refs.msgList;

        // 首次加载时，等待 DOM 完全渲染后再滚动
        if (isFirstLoad) {
          setTimeout(() => {
            if (this.$refs.msgList) {
              // 重新计算高度，确保准确
              this.msgListHeight = this.calculateMsgListHeight();
              this.$nextTick(() => {
                if (this.$refs.msgList) {
                  this.$refs.msgList.scrollTop = this.$refs.msgList.scrollHeight;
                }
              });
            }
          }, 100);
        } else {
          // 非首次加载，直接滚动到底部
          msgList.scrollTop = msgList.scrollHeight;
        }
      });
    },
    handleImageClick(it) {
      if (it.type === TencentCloudChat.TYPES.MSG_IMAGE) {
        let url = [], imgIndex = -1, index = 0;
        this.messageList.forEach((msg) => {
          if (msg.type === TencentCloudChat.TYPES.MSG_IMAGE) {
            ++imgIndex;
            url.push(msg.payload.imageInfoArray[1].imageUrl);
            if (msg.ID === it.ID) {
              index = imgIndex;
            }
          }
        })
        openPicturePreview(url, index)
      }
    },
    getVideoUrl(message) {
      // 获取视频URL，优先使用 remoteVideoUrl，其次使用 videoUrl
      if (message.payload) {
        if (message.payload.remoteVideoUrl) {
          return message.payload.remoteVideoUrl;
        }
        if (message.payload.videoUrl) {
          return message.payload.videoUrl;
        }
      }
      return '';
    },
    getVideoCover(message) {
      // 获取视频封面，优先使用 snapshotUrl，其次使用 thumbUrl
      if (message.payload) {
        if (message.payload.snapshotUrl) {
          return message.payload.snapshotUrl;
        }
        if (message.payload.thumbUrl) {
          return message.payload.thumbUrl;
        }
      }
      // 如果没有封面，返回空字符串（不显示封面）
      return '';
    },
    handleVideoClick(message, index) {
      const videoUrl = this.getVideoUrl(message);
      if (!videoUrl) {
        console.warn('视频URL不存在');
        return;
      }

      // 跳转到视频播放页面
      this.$router.push({
        name: 'PageVideoPlay',
        query: {
          params: JSON.stringify({
            videoUrl: videoUrl,
            userId: this.userInfo.userId,
            nickname: this.userInfo.nickname
          })
        }
      });
    },
    onBlackSuccess() {
      TencentImUtils.chatObj.deleteConversation(TencentImUtils.getConversationIdByUserId(this.userInfo.userId));
    },
    // 判断是否是未接听的通话
    isCallMissed(message) {
      if (message.customData) {
        const callMsgType = message.customData.callStatus;
        return callMsgType === CALL_STATUS.CALL_TIMEOUT_DONE.code;
      }
      return false;
    },
    // 获取通话图标
    getCallIcon(message) {
      // 如果是未接听，使用未接听图标
      if (this.isCallMissed(message)) {
        return require('@/assets/image/message/ic-message-call-mis.png');
      }
      // 如果是自己发送的，使用自己的图标
      if (this.isSelf(message.from)) {
        return require('@/assets/image/message/ic-message-call-self.png');
      }
      // 对方发送的，使用对方图标
      return require('@/assets/image/message/ic-message-call.png');
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
        console.error('解析 cloudCustomData 失败:', e);
        return null;
      }
    },
    // 翻译消息
    translateMessage(message, index) {
      translationMsg(message).then((result) => {
        console.log("翻译返回:", result);
      }).catch((error) => {
        console.error("翻译失败:", error);
      });
    },
    // 启动礼物气泡定时器
    startGiftBubbleTimer() {
      // 如果本次会话中已经显示过气泡，不再启动
      if (this.giftBubbleShown) {
        return;
      }
      
      // 清理之前的定时器
      this.clearGiftBubbleTimers();
      
      // 重置状态
      this.showGiftBubble = false;
      this.currentGiftText = 'Get up to 100,000 FREE Coins!';
      
      // 10秒后显示气泡
      const timer1 = setTimeout(() => {
        this.showGiftBubble = true;
        this.giftBubbleShown = true; // 标记已显示
      }, 10000);
      this.giftBubbleTimers.push(timer1);
      
      // 15秒后（10秒显示 + 5秒）切换文案
      const timer2 = setTimeout(() => {
        this.currentGiftText = '10% off Video Chats per minute FOREVER!';
      }, 15000);
      this.giftBubbleTimers.push(timer2);
      
      // 20秒后（10秒显示 + 5秒切换 + 5秒）隐藏气泡
      const timer3 = setTimeout(() => {
        this.showGiftBubble = false;
      }, 20000);
      this.giftBubbleTimers.push(timer3);
    },
    // 清理礼物气泡定时器
    clearGiftBubbleTimers() {
      this.giftBubbleTimers.forEach(timer => {
        clearTimeout(timer);
      });
      this.giftBubbleTimers = [];
    },
  },
  beforeDestroy() {
    TencentImUtils.chatObj.off(TencentCloudChat.EVENT.MESSAGE_RECEIVED, this.onMessageReceived);
    TencentImUtils.chatObj.off(TencentCloudChat.EVENT.MESSAGE_MODIFIED, this.onMessageModified);
    if (window.visualViewport) {
      window.visualViewport.removeEventListener('resize', this.handleKeyboardResize);
    }
    document.body.classList.remove('keyboard-open');
    this.isKeyboardOpen = false;
    // 清理礼物气泡定时器
    this.clearGiftBubbleTimers();
  }
}
</script>

<style scoped lang="less">
:global(body.keyboard-open) .bottom-wrap {
  height: calc(50px + constant(safe-area-inset-bottom));
  height: calc(50px + env(safe-area-inset-bottom));
  padding: 0 16px;
  padding-bottom: calc(0px + constant(safe-area-inset-bottom));
  padding-bottom: calc(0px + env(safe-area-inset-bottom));
}
// 自定义导航栏 - 高度与 m-action-bar 保持一致
// m-action-bar 高度 60px + padding-top 10px = 70px + 安全区域
// 总高度 = 60px (内容) + 10px (padding-top) + 安全区域 = 70px + 安全区域
.custom-nav-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  height: 60px; // 内容区域高度，与 m-action-bar 一致
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #000000;
  padding-top: calc(env(safe-area-inset-top) + 0px);
  padding-top: calc(constant(safe-area-inset-top) + 0px);
  padding-left: 20px;
  padding-right: 20px;
  padding-bottom: 0;
  box-sizing: content-box; // 使用 content-box，这样总高度 = height + padding = 60px + 10px + 安全区域 = 70px + 安全区域

  .ic-back {
    cursor: pointer;
    width: 30px;
    height: 30px;
    object-fit: contain;
    flex-shrink: 0;
  }

  .video-icon {
    width: 39px;
    height: 39px;
    cursor: pointer;
    flex-shrink: 0;
  }

  .premium-badge-wrap {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    flex-shrink: 0;
  }

  .premium-badge {
    display: flex;
    align-items: center;
    gap: 6px;
    background-color: #2d2d2d;
    border-radius: 20px;
    padding: 6px 10px;
    flex-shrink: 0;
  }

  .premium-icon {
    width: 22px;
    height: 22px;
    object-fit: contain;
    flex-shrink: 0;
  }

  .premium-text {
    color: #ffffff;
    font-size: 14px;
    font-weight: bold;
    white-space: nowrap;
  }
}

.gift-promo-bubble {
  position: fixed;
  z-index: 999;
  display: flex;
  align-items: center;
  gap: 8px;
  background-image: url('@/assets/image/message/ic-message-pre-gift-bg.png');
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center;
  object-fit: contain;
  padding: 0 8px;
  height: 45px;
  width: auto;
  min-width: fit-content;
  cursor: pointer;
  transition: opacity 0.3s ease;

  /* 紧贴 Premium badge 下方时：相对 wrap 绝对定位 */
  &.gift-below-badge {
    position: absolute;
    top: 100%;
    right: 0;
    margin-top: 6px;
  }

  .gift-icon {
    width: 36px;
    height: 36px;
    object-fit: contain;
    flex-shrink: 0;
    margin-top: 10px;
  }

  .gift-text {
    color: #ffffff;
    font-size: 14px;
    font-weight: bold;
    white-space: nowrap;
    margin-top: 10px;
  }
}

// 气泡整体动画
.fade-bubble-enter-active {
  transition: all 0.4s ease-out;
}

.fade-bubble-leave-active {
  transition: all 0.3s ease-in;
}

.fade-bubble-enter {
  opacity: 0;
  transform: translateX(20px) scale(0.9);
}

.fade-bubble-enter-to {
  opacity: 1;
  transform: translateX(0) scale(1);
}

.fade-bubble-leave {
  opacity: 1;
  transform: translateX(0) scale(1);
}

.fade-bubble-leave-to {
  opacity: 0;
  transform: translateX(20px) scale(0.9);
}

// 文案切换动画 - 右侧划入
.slide-text-enter-active {
  transition: all 0.3s ease-out;
}

.slide-text-leave-active {
  transition: all 0.3s ease-in;
}

.slide-text-enter {
  opacity: 0;
  transform: translateX(20px);
}

.slide-text-enter-to {
  opacity: 1;
  transform: translateX(0);
}

.slide-text-leave {
  opacity: 1;
  transform: translateX(0);
}

.slide-text-leave-to {
  opacity: 0;
  transform: translateX(-20px);
}

.main {
  height: 100%;
  position: relative;
  background: #000000;
  // 不需要 padding-top，因为导航栏是 fixed 定位

  .video-icon-float {
    position: fixed;
    width: 49px;
    height: 49px;
    cursor: pointer;
    z-index: 1000;
    transition: bottom 0.3s ease;
    pointer-events: auto;
    object-fit: cover;
    border-radius: 50%;
  }
}

.custom-nav-bar {
  .center-content {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: start;
    margin-left: 10px;
    cursor: pointer;
  }

  .user-info {
    display: flex;
    flex-direction: column;
    align-items: start;
  }

  .nickname {
    color: #ffffff;
    font-size: 16px;
    font-weight: bold;
    line-height: 1.2;
  }

  .onlineStatus {
    font-size: 12px;
    font-weight: 400;
    line-height: 1.2;
    margin-top: 2px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background-color: #72FF50;
    flex-shrink: 0;
    display: inline-block;
  }

  .status-available {
    color: #72FF50;
  }

  .status-in-call {
    color: #FFF79C;
  }
}

.crown-icon {
  width: 22px;
  height: 22px;
  margin-left: 5px;
  vertical-align: middle;
}

.list-wrap {
  position: fixed;
  left: 0;
  right: 0;
  width: 100%;
  padding-left: 16px;
  padding-right: 16px;
  padding-bottom: 10px;
  overflow-y: scroll;
  box-sizing: border-box;
  z-index: 1;
  background: #000000;
  transition: opacity 0.2s ease-in-out;

  &.list-loading {
    opacity: 0;
    visibility: hidden;
  }

  .item {
    margin-bottom: 12px;
    display: flex;
    align-items: flex-start;

    &.receive {
      justify-content: flex-start;
    }

    &.send-self {
      justify-content: flex-end;
    }

    .msg-avatar {
      width: 34px;
      height: 34px;
      border-radius: 17px;
      margin-right: 8px;
      flex-shrink: 0;
      align-self: flex-start;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;

      img {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }
    }

    .msg-translation {
      margin-left: 5px;
      width: 20px;
      height: 20px;
      flex-shrink: 0;
      cursor: pointer;
      align-self: center;
    }

    .msg-content {
      display: inline-block;
      vertical-align: top;
      min-height: 40px;
      word-wrap: break-word;

      .msg-text-wrapper {
        padding: 10px 12px;
        display: inline-block;
        margin: 0;
        word-break: break-all;
        line-height: 1.4;
        font-size: 16px;
      }

      .msg-text {
        margin: 0;
        word-break: break-all;
        line-height: 1.4;
        font-size: 16px;
        color: white;
      }

      .msg-translation-content {
        margin-top: 10px;
      }

      .msg-translation-divider {
        width: 100%;
        height: 1px;
        margin-bottom: 10px;
      }

      .msg-translated-text {
        margin: 0;
        word-break: break-all;
        line-height: 1.4;
        font-size: 16px;
        color: white;
      }
    }

    .msg-img {
      width: 150px;
      height: 180px;
      border-radius: 10px;
      max-width: none;
    }

    .msg-video {
      position: relative;
      width: 150px;
      height: 180px;
      border-radius: 10px;
      overflow: hidden;
      cursor: pointer;

      .msg-video-preview {
        width: 100%;
        height: 100%;
        object-fit: cover;
        border-radius: 10px;
      }

      .msg-video-play-button {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 50px;
        height: 50px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(0, 0, 0, 0.5);
        border-radius: 50%;
        pointer-events: none;

        .play-icon {
          width: 30px;
          height: 30px;
          object-fit: contain;
        }
      }
    }
  }

  // 只有文本消息才设置 max-width
  .msg-content-text {
    max-width: 70%;
  }

  .msg-gift-quantity {
    margin-left: 8px;
    padding: 8px 11px;
    background: #FFCC00;
    border-radius: 45%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    font-weight: bold;
    color: #FFFFFF;
    -webkit-text-stroke: 2px black;
  }

  .receive {
    .msg-content {
      background: #282828;
      border-radius: 15px;
      margin-left: 0;

      .msg-text {
        color: #ffffff;
      }

      .msg-translated-text {
        color: #ffffff;
      }

      .msg-translation-divider {
        background: rgba(255, 255, 255, 0.2);
      }
    }
  }

  .send-self {
    .msg-content {
      background: #FFE4D5;
      border-radius: 15px;
      margin-right: 0;

      .msg-text {
        color: #000000;
      }

      .msg-translated-text {
        color: #000000;
      }

      .msg-translation-divider {
        background: rgba(0, 0, 0, 0.2);
      }
    }
  }

  .msg-gift {
    min-width: 160px;
    padding: 10px 12px;
    display: flex;
    align-items: center;
    box-sizing: border-box;
    background: linear-gradient(90deg, #E51FFF 0%, #8C00FF 100%);
    border-radius: 15px;

    img {
      width: 48px;
      height: 48px;
      flex-shrink: 0;
    }

    .msg-gift-info {
      display: flex;
      flex-direction: column;
      justify-content: center;
      flex: 1;
      margin-left: 8px;

      .msg-gift-info-name {
        font-size: 16px;
        font-weight: bold;
        color: #ffffff;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin: 0;
        line-height: 1.2;
      }

      .msg-gift-info-coin {
        display: flex;
        align-items: center;
        margin-top: 4px;
        gap: 0;

        img {
          width: 16px;
          height: 16px;
          flex-shrink: 0;
        }

        p {
          font-size: 14px;
          color: #ffffff;
        }
      }
    }
  }

  .send-self {
    .msg-gift {
      p {
        color: #000000;
      }
    }
  }

  .msg-call {
    min-width: 100px;
    max-height: 44px;
    display: flex;
    align-items: center;
    padding: 10px 12px;

    img {
      width: 23px;
      height: 23px;
    }

    p {
      line-height: 24px;
      margin-left: 10px;
      color: #ffffff;
      white-space: nowrap;
      font-weight: 500;
    }

    &.msg-call-missed {
      p {
        color: #FF1500;
      }
    }
  }

  .send-self {
    .msg-call {
      p {
        color: #000000;
      }

      &.msg-call-missed {
        p {
          color: #FF1500;
        }
      }
    }
  }
}

.time {
  text-align: center;
  margin: 20px 0;
  font-size: 14px;
  width: 100%;

  &::before {
    content: attr(data-time);
    display: inline-block;
    border-radius: 16px;
    padding: 6px 18px;
    color: white;
    background: #282828;
  }

  &.no-more::before {
    background: transparent;
    color: white;
  }
}

.no-more {
  margin-bottom: 50px;
  color: rgba(255, 255, 255, 0.6);

  &::before {
    display: none;
  }
}

.bottom-wrap {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: #000000;
  height: calc(70px + constant(safe-area-inset-bottom));
  height: calc(70px + env(safe-area-inset-bottom));
  width: 100%;
  max-width: 100vw;
  padding: 10px 16px;
  padding-bottom: calc(10px + constant(safe-area-inset-bottom));
  padding-bottom: calc(10px + env(safe-area-inset-bottom));
  box-sizing: border-box;
  border-top: 1px solid rgba(255, 255, 255, 0.1);

  div {
    width: 100%;
    height: 50px;
    display: flex;
    box-sizing: border-box;
    align-items: center;
  }

  .gift-icon {
    width: 37px;
    height: 37px;
    flex-shrink: 0;
  }

  .textarea-wrapper {
    position: relative;
    flex: 1;
    display: flex;
    align-items: center;
    margin: 10px 10px 10px 0;
  }

  textarea {
    flex: 1;
    background: #2d2d2d;
    border-radius: 20px;
    height: 49px;
    box-sizing: border-box;
    padding: 14px 20px;
    display: inline-block;
    border: none;
    color: #ffffff;
    font-size: 16px;
    line-height: 21px;
    resize: none;
    vertical-align: middle;
  }

  textarea:focus {
    outline: none;
  }

  .custom-placeholder {
    position: absolute;
    left: 16px;
    top: 50%;
    transform: translateY(-50%);
    color: #999999;
    font-size: 16px;
    line-height: 21px;
    pointer-events: none;
    user-select: none;
  }

  .send-btn {
    width: 49px;
    height: 49px;
    flex-shrink: 0;
    cursor: pointer;
  }
}
</style>
