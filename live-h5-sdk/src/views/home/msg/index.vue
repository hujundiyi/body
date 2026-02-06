<template>
  <m-page-wrap :show-action-bar="false" class="ios-safe-area-inset-top-padding">
    <template #page-content-wrap>
      <div class="page-layout">
        <div v-if="!allPurchased" class="first-recharge-entry" @click="openFirstRecharge">
          <img src="@/assets/image/sdk/ic-tab-firstrecharge.gif" alt="" class="first-recharge-icon" />
          <div v-if="countdown > 0" class="first-recharge-timer">{{ countdownText }}</div>
          <div v-if="firstRechargeDiscount" class="first-recharge-entryextra-wrap">
            <img src="@/assets/image/premium/ic-recharge-extra-bub@2x.png" alt="" class="first-recharge-extra-icon" />
            <span class="first-recharge-extra-intros">{{ firstRechargeDiscount }}</span>
          </div>
        </div>
        <div v-if="showCheckinEntry" class="checkin-entry" @click="openCheckin">
          <div class="checkin-icon-wrapper">
            <img src="@/assets/image/sdk/ic-tab-sign.gif" alt="" class="checkin-icon" />
            <img src="@/assets/image/sdk/ic-tab-sign-left-coin.png" alt="" class="checkin-left-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-right-coin.png" alt="" class="checkin-right-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-btm-oval.png" alt="" class="checkin-bottom-oval" />
          </div>
        </div>
        <div class="fixed-header">
          <div class="header">
            <div class="header-info">
              <div class="header-info-avatar" @click="$router.push({ name: 'PageEditUserInfo' }).catch(() => {})">
                <img
                  class="header-info-img"
                  :src="$store.state.user.loginUserInfo.avatar || require('@/assets/image/ic-placeholder-avatar.png')"
                  alt=""
                >
              </div>
            <div class="top-right">
              <div class="premium-btn" :class="{'is-vip': isVip}" @click="handleVipClick">
                <img :src="vipIcon" class="crown-icon" alt=""/>
                <span>Premium</span>
              </div>
              <div class="coin-pill" @click="openRecharge">
                <img src="@/assets/image/match/ic-match-coin@2x.png" class="coin-icon"/>
                <span>{{ coinDisplay }}</span>
              </div>
            </div>
            </div>

            <div class="header-items">
              <div class="header-items-call" @click="goToCallRecord">
                <img src="@/assets/image/message/ic-message-item-call.png" alt="">
                <span v-if="unreadCallCount > 0" class="unread-badge">{{ unreadCallCount > 99 ? '99+' : unreadCallCount }}</span>
              </div>
              <div class="header-items-like" @click="goToLikeList">
                <img src="@/assets/image/message/ic-message-item-like.png" alt="">
                <span v-if="unreadLikeCount > 0" class="unread-badge">{{ unreadLikeCount > 99 ? '99+' : unreadLikeCount }}</span>
              </div>
              <div class="header-items-gift" @click="goToGiftRecord">
                <img src="@/assets/image/message/ic-message-item-gifts.png" alt="">
                <span v-if="unreadGiftCount > 0" class="unread-badge">{{ unreadGiftCount > 99 ? '99+' : unreadGiftCount }}</span>
              </div>
            </div>
          </div>
          <p class="message-title">Message</p>
        </div>
        <div class="header-spacer" ref="headerSpacer">
          <div class="header">
            <div class="header-info"></div>
            <div class="header-items"></div>
          </div>
          <p class="message-title"></p>
        </div>
        <div class="list-container" ref="listContainer">
        <m-list ref="list" :open-load-more="false" :open-drop-down-refresh="false" :on-refresh-call-back="onRefresh" class="m-list">
        <template v-slot:m-list-item="{items}">
          <div class="list-items">
            <div v-for="(it,index) in items" :key="index" class="slide-to-item">
              <div class="item" @click="openChat(it.conversationID)">
                <div class="avatar-wrapper">
                  <img 
                    :src="getAvatarUrl(it.userProfile)" 
                    @error="handleAvatarError"
                    @load="handleAvatarLoad"
                    :key="getAvatarKey(it.userProfile)"
                    alt=""/>
                  <img v-if="it.userProfile && (it.userProfile.onlineStatus === 0)"
                    class="online-indicator" src="@/assets/image/message/ic-message-list-online.png" alt=""/>
                </div>
                <div class="center">
                  <p class="item-nick">{{ getDisplayName(it.userProfile) }}</p>
                  <p class="item-content" v-if="it.lastMessage">{{ it.lastMessage.digest }}</p>
                </div>
                <div class="right">
                  <p>{{ formatTimeAgoEnglish(it.lastMessage.lastTime * 1000) }}</p>
                  <span v-if="it.unreadCount">{{ it.unreadCount }}</span>
                </div>
              </div>
            </div>
          </div>
        </template>
        </m-list>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MList from "@/components/MList.vue";
import {openChat, openPremium, requestCall} from "@/utils/PageUtils";
import store from "@/store";
import {formatTimeAgoEnglish} from "@/utils/Utils";
import {TencentImUtils} from "@/utils/TencentImUtils";
import TencentCloudChat from "@tencentcloud/chat";
import {showRechargeDialog, showRechargePromoDialog} from "@/components/dialog";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";
import { getCheckinInfo } from "@/api/sdk/user";

export default {
  name: 'PageMsgList',
  components: {MList},
  data() {
    return {
      // 未读数量，可以从 store 或其他地方获取
      unreadCallCount: 0,
      unreadLikeCount: 0,
      unreadGiftCount: 0,
      countdown: 0,
      createTime: null,
      countdownTimer: null,
      checkinAllDone: false
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    coinDisplay() {
      const balance = this.userInfo.coinBalance || 0;
      return balance <= 0 ? 'Shop' : this.formatNumber(balance);
    },
    isVip() {
      return this.userInfo.vipCategory !== 0;
    },
    vipIcon() {
      return this.isVip
        ? require('@/assets/image/match/ic-match-vip@2x.png')
        : require('@/assets/image/match/ic-match-novip@2x.png');
    },
    allPurchased() {
      return !!this.$store.state.user.allPurchased;
    },
    firstRechargeDiscount() {
      return this.$store.state.user.firstRechargeDiscount || '';
    },
    countdownText() {
      const s = Math.max(0, Math.floor(this.countdown));
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      const sec = s % 60;
      const pad = (n) => String(n).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(sec)}`;
    },
    showCheckinEntry() {
      return this.isVip && !this.checkinAllDone;
    },
    checkinDialogVisible() {
      return !!this.$store.state.PageCache?.checkinDialogVisible;
    },
    chatInitSuccess() {
      return this.$store.state.PageCache.chatInitSuccess
    },
    chatConversationList() {
      return this.$store.state.PageCache.chatConversationList
    }
  },
  watch: {
    chatConversationList: {
      handler(newVal) {
        if (this.$refs.list && newVal && Array.isArray(newVal)) {
          this.$refs.list.initResult(true, [...newVal]);
        }
      },
      immediate: true
    },
    chatInitSuccess() {
      this.onRefresh();
      this.initView();
    },
    isVip(value) {
      if (value) {
        this.fetchCheckinStatus();
      } else {
        this.checkinAllDone = false;
      }
    },
    checkinDialogVisible(value) {
      if (!value) {
        this.fetchCheckinStatus();
      }
    }
  },
  created() {
  },
  mounted() {
    this.updateListTop();
    const user = cache.local.getJSON(key_cache.user_info) || {};
    const ct = user.createTime;
    this.createTime = ct != null && ct !== '' ? Number(ct) : null;
    this.tickCountdown();
    this.startCountdown();
    this.fetchCheckinStatus();
    // 喜欢消息未读数从本地缓存读取（下次进入 APP 也要展示）
    this.syncUnreadLikeCount();
    this._unreadLikeCountHandler = () => this.syncUnreadLikeCount();
    document.addEventListener('unreadLikeCountUpdated', this._unreadLikeCountHandler);
    // 禁用下拉刷新后，需要手动触发一次数据加载
    if (this.chatInitSuccess) {
      this.onRefresh();
    }
  },
  beforeDestroy() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = null;
    }
    if (this._unreadLikeCountHandler) {
      document.removeEventListener('unreadLikeCountUpdated', this._unreadLikeCountHandler);
      this._unreadLikeCountHandler = null;
    }
  },
  activated() {
    this.updateListTop();
    this.syncUnreadLikeCount();
  },
  methods: {
    openPremium,
    showRechargeDialog,
    handleVipClick() {
      this.openPremium();
    },
    openRecharge() {
      showRechargeDialog();
    },
    openFirstRecharge() {
      showRechargePromoDialog();
    },
    requestCall,
    formatTimeAgoEnglish,
    openChat,
    handleAvatarError(event) {
      // 图片加载失败时，设置为占位图
      const placeholder = require('@/assets/image/ic-placeholder-avatar.png');
      if (event.target.src !== placeholder) {
        event.target.src = placeholder;
      }
    },
    handleAvatarLoad(event) {
      // 图片加载成功，确保显示
      // 可以在这里添加缓存逻辑
    },
    getAvatarUrl(userProfile) {
      if (userProfile && userProfile.avatar && userProfile.avatar.trim() !== '') {
        return userProfile.avatar;
      }
      return require('@/assets/image/ic-placeholder-avatar.png');
    },
    getAvatarKey(userProfile) {
      // 用于强制重新渲染图片，当头像 URL 变化时
      // 使用 userId 和 avatar URL 的组合作为 key，确保头像更新时能正确刷新
      if (userProfile && userProfile.avatar) {
        return `avatar_${userProfile.userId}_${userProfile.avatar}`;
      }
      return `avatar_${userProfile?.userId || 'unknown'}_placeholder`;
    },
    getDisplayName(userProfile) {
      if (!userProfile) return '';
      const name = userProfile.nick || '';
      const age = userProfile.age;
      if (age) {
        return `${name}, ${age}`;
      }
      return name;
    },
    initView() {
      TencentImUtils.chatObj.on(TencentCloudChat.EVENT.TOTAL_UNREAD_MESSAGE_COUNT_UPDATED, () => {
        this.onRefresh()
      });
      TencentImUtils.chatObj.on(TencentCloudChat.EVENT.CONVERSATION_LIST_UPDATED, () => {
        this.onRefresh()
      });
    },
    onRefresh() {
      // setTimeout(() => {
        store.dispatch('PageCache/loadChatConversationList').then()
      // }, 500)
    },
    updateListTop() {
      this.$nextTick(() => {
        const spacer = this.$refs.headerSpacer;
        const listContainer = this.$refs.listContainer;
        if (spacer && listContainer) {
          const spacerHeight = spacer.offsetHeight;
          listContainer.style.top = `${spacerHeight}px`;
        }
      });
    },
    goToCallRecord() {
      this.$router.push({ name: 'PageCallRecord' });
    },
    goToLikeList() {
      this.$router.push({ name: 'PageLikeList' });
    },
    syncUnreadLikeCount() {
      const raw = cache.local.get(key_cache.unread_like_count);
      this.unreadLikeCount = Math.max(0, parseInt(raw || '0', 10));
    },
    goToGiftRecord() {
      this.$router.push({ name: 'PageGiftRecord' });
    },
    formatNumber(value) {
      if (value === null || value === undefined) {
        return '';
      }
      const number = Number(value);
      if (Number.isNaN(number)) {
        return value;
      }
      return number.toLocaleString();
    },
    tickCountdown() {
      if (this.createTime == null) return;
      const end = this.createTime + 3 * 24 * 3600;
      const now = Math.floor(Date.now() / 1000);
      this.countdown = Math.max(0, end - now);
    },
    startCountdown() {
      this.countdownTimer = setInterval(() => {
        this.tickCountdown();
        if (this.countdown <= 0 && this.countdownTimer) {
          clearInterval(this.countdownTimer);
          this.countdownTimer = null;
        }
      }, 1000);
    },
    openCheckin() {
      const { showCheckinDialog } = require('@/components/dialog');
      showCheckinDialog();
    },
    fetchCheckinStatus() {
      if (!this.isVip) {
        this.checkinAllDone = false;
        return;
      }
      getCheckinInfo().then((res) => {
        if (res && (res.code === 200 || res.code === 0 || res.success) && res.data) {
          const data = res.data;
          const rewards = Array.isArray(data.rewards)
            ? data.rewards
            : (Array.isArray(data.checkinDays) ? data.checkinDays : []);
          if (rewards.length === 0) {
            this.checkinAllDone = false;
            return;
          }
          this.checkinAllDone = rewards.every((day) => {
            const checked = day.checked ?? day.isCheckin ?? day.isCheckIn ?? day.is_checkin ?? day.is_check_in;
            return !!checked;
          });
        } else {
          this.checkinAllDone = false;
        }
      }).catch(() => {
        this.checkinAllDone = false;
      });
    }
  }
}
</script>
<style scoped lang="less">
.page-layout {
  position: relative;
  height: 100vh;
  overflow: hidden;
}

.first-recharge-entry {
  position: fixed;
  right: 10px;
  bottom: calc(180px + constant(safe-area-inset-bottom));
  bottom: calc(180px + env(safe-area-inset-bottom));
  width: 72px;
  z-index: 99;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  -webkit-tap-highlight-color: transparent;
  tap-highlight-color: transparent;
}

.first-recharge-icon {
  width: 64px;
  height: 64px;
  display: block;
  object-fit: contain;
}

.first-recharge-timer {
  margin-top: -7px;
  min-width: 55px;
  height: 20px;
  padding-top: 2px;
  padding-left: 3px;
  padding-right: 3px;
  border-radius: 10px;
  background: #000000;
  color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.first-recharge-entryextra-wrap {
  position: absolute;
  left: -5px;
  top: 8px;
  transform: rotate(-15deg);
  transform-origin: left top;
  display: inline-block;
}

.first-recharge-extra-icon {
  display: block;
  width: auto;
  height: 20px;
  object-fit: contain;
}

.first-recharge-extra-intros {
  position: absolute;
  left: 0;
  top: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  pointer-events: none;
}

.checkin-entry {
  position: fixed;
  right: 10px;
  bottom: calc(90px + constant(safe-area-inset-bottom));
  bottom: calc(90px + env(safe-area-inset-bottom));
  width: 64px;
  z-index: 99;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.checkin-icon-wrapper {
  position: relative;
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.checkin-icon {
  width: 64px;
  height: 64px;
  display: block;
  object-fit: contain;
  z-index: 1;
}

.checkin-left-coin {
  position: absolute;
  bottom: 7px;
  left: 5px;
  width: 20px;
  height: 20px;
  z-index: 2;
}

.checkin-right-coin {
  position: absolute;
  bottom: 4px;
  right: 10px;
  width: 20px;
  height: 20px;
  z-index: 2;
}

.checkin-bottom-oval {
  position: absolute;
  bottom: 4px;
  left: 50%;
  transform: translateX(-50%);
  width: 60px;
  height: 15px;
  z-index: 0;
}

.fixed-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  padding-top: env(safe-area-inset-top);
  padding-top: constant(safe-area-inset-top);
  background: #141414;
}

.header-spacer {
  width: 100%;
  visibility: hidden;
  pointer-events: none;

  // 复制头部结构以匹配高度
  .header {
    display: flex;
    flex-direction: column;
    padding: 0 15px;
    padding-top: env(safe-area-inset-top);
    padding-top: constant(safe-area-inset-top);

    .header-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      width: 100%;
      height: 45px;
    }

    .header-items {
      height: 82px;
      width: 100%;
      margin-top: 10px;
    }
  }

  .message-title {
    font-size: 22px;
    font-weight: bold;
    margin-left: 15px;
    margin-top: 20px;
    margin-bottom: 0;
    height: 22px;
  }
}

.header {
  display: flex;
  flex-direction: column;
  padding: 0 20px;

  .header-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;

    .header-info-avatar {
      width: 45px;
      height: 45px;
      border-radius: 50%;
      overflow: hidden;
      flex-shrink: 0;

      .header-info-img {
        width: 100%;
        height: 100%;
      object-fit: cover;
        display: block;
      }
    }

    .top-right {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .premium-btn {
      background: rgba(255, 255, 255, 0.10);
      border-radius: 20px;
      padding: 4px 12px;
      display: flex;
      align-items: center;
      font-weight: bold;
      font-size: 14px;
      border: 1px solid rgba(255, 255, 255, 0.05);
      transition: all 0.3s;
      cursor: pointer;

      .crown-icon {
        width: 22px;
        height: 22px;
        margin-right: 4px;
      }

      span {
        color: white;
      }

      &.is-vip span {
        color: #FEE98A;
      }
    }

    .coin-pill {
      background: rgba(255, 255, 255, 0.10);
      border-radius: 20px;
      padding: 4px 12px;
      display: flex;
      align-items: center;
      font-size: 14px;
      font-weight: bold;
      cursor: pointer;

      .coin-icon {
        width: 22px;
        height: 22px;
        margin-right: 4px;
      }

      span {
        color: white;
      }
    }
  }


  .header-items {
    height: 82px;
    width: 100%;
    display: flex;
    gap: 10px;
    margin-top: 10px;

    .header-items-call {
      flex: 2;
    }
    .header-items-like,
    .header-items-gift {
      flex: 1;
    }
    .header-items-call,
    .header-items-like,
    .header-items-gift {
      position: relative;
      background: transparent;
      border-radius: 15px;
      cursor: pointer;
      transition: opacity 0.2s;

      &:active {
        opacity: 0.7;
      }

      img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        border-radius: 20px;
      }

      .unread-badge {
        position: absolute;
        top: -6px;
        right: 0;
        min-width: 20px;
        height: 20px;
        padding: 2px 5px 0 5px;
        background: #FE5621;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        text-align: center;
        font-size: 12px;
        font-weight: 500;
        color: #ffffff;
        line-height: 20px;
        box-sizing: border-box;
        z-index: 10;
      }
    }
  }
}

.message-title {
  font-size: 22px;
  font-weight: bold;
  margin-left: 15px;
  margin-top: 20px;
  margin-bottom: 10px;
}

.list-container {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  box-sizing: border-box;
  overflow: hidden;

  /deep/ .list-wrap {
    height: 100%;
    overflow-y: auto;
    overflow-x: hidden;
    -webkit-overflow-scrolling: touch;
  }

  /deep/ .refresh-mobile {
    background: transparent;
    min-height: 100%;
  }

  /deep/ .load-mobile {
    background: transparent;
  }

  .m-list{
    background: #000000;
  }
}

.list-items {
  margin-top: 10px;
  box-sizing: border-box;
  padding-left: 20px;
  padding-right: 20px;
  padding-bottom: calc(90px + env(safe-area-inset-bottom));
  padding-bottom: calc(90px + constant(safe-area-inset-bottom));
}

.slide-to-item {
  margin-bottom: 10px;
  height: 75px;
}

.item {
  display: flex;
  align-items: center;
  height: 75px;
  border-radius: 20px;
  background: #282828;
  box-sizing: border-box;

  .avatar-wrapper {
    position: relative;
    flex-shrink: 0;
    margin-left: 20px;
  }

  .avatar-wrapper img:first-child {
    width: 50px;
    height: 50px;
    border-radius: 25px;
    display: block;
    object-fit: cover;
  }

  .online-indicator {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 12px;
    height: 12px;
  }

  .center {
    margin-left: 15px;
    flex: 1;
    text-align: left;
    display: flex;
    flex-direction: column;
    justify-content: center;
    overflow: hidden;
    position: relative;

    .item-nick {
      text-align: left;
      font-size: 15px;
      color: rgba(255, 255, 255, 0.6);
      margin-top: 5px;
      margin-bottom: 5px;
    }

    .item-content {
      font-size: 17px;
      color: white;
      margin: 0;
      padding: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      display: block;
      width: 100%;
      box-sizing: border-box;
      position: relative;
    }
  }

  .right {
    flex-shrink: 0;
    text-align: right;
    margin-right: 20px;
    margin-top: 16px;
    align-self: flex-start;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: flex-end;

    p {
      color: #999999;
      font-size: 12px;
    }

    span {
      width: 20px;
      height: 20px;
      text-align: center;
      display: inline-block;
      font-size: 12px;
      font-weight: bold;
      background: #FE5621;
      border-radius: 10px;
    }

  }
}



</style>
