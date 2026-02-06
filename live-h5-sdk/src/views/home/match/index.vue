<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div class="match-container">
        <!-- Background -->
        <div class="background-overlay"></div>

        <!-- 首充入口：距导航栏底部 30px，距右 20px，64px；allPurchased 时隐藏 -->
        <div v-if="!allPurchased" class="first-recharge-entry" @click="openFirstRecharge">
          <img src="@/assets/image/sdk/ic-tab-firstrecharge.gif" alt="" class="first-recharge-icon"/>
          <div v-if="countdown > 0" class="first-recharge-timer">{{ countdownText }}</div>
          <div class="first-recharge-entryextra-wrap">
            <img src="@/assets/image/premium/ic-recharge-extra-bub@2x.png" alt="" class="first-recharge-extra-icon" />
            <span class="first-recharge-extra-intros">{{ firstRechargeDiscount }}</span>
          </div>
        </div>
        <!-- 签到入口 -->
        <div v-if="showCheckinEntry" class="checkin-entry" @click="openCheckin">
          <div class="checkin-icon-wrapper">
            <img src="@/assets/image/sdk/ic-tab-sign.gif" alt="" class="checkin-icon" />
            <img src="@/assets/image/sdk/ic-tab-sign-left-coin.png" alt="" class="checkin-left-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-right-coin.png" alt="" class="checkin-right-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-btm-oval.png" alt="" class="checkin-bottom-oval" />
          </div>
        </div>

        <!-- Top Bar -->
        <div class="top-bar">
          <div class="avatar-container" @click="menuClick({name:'PageEditUserInfo'})">
            <img
                :src="userInfo.avatar || require('@/assets/image/ic-placeholder-avatar.png')"
                @error="handleAvatarError"
                class="avatar"/>
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

        <!-- Earth 区域：背景图 + 星球组件，同一容器保证尺寸一致 -->
        <div class="earth-bg">
          <earth-planet/>
        </div>

        <!-- Match Main: status + filters + MATCH button -->
        <div class="match-main">
          <p class="match-status">
            <span class="match-status-value">{{ matchCountFormatted }}</span>
            <span class="match-status-text"> People matching | Estimated match in </span>
            <span class="match-status-value">{{ estimatedMatchTime }}</span>
          </p>
          <div class="bottom-filters">
            <img class="filter-icon" src="@/assets/image/match/ic-match-conuntry-icon@2x.png" alt=""
                 @click="openCountryFilter"/>
            <div class="private-filter-wrapper">
              <img class="filter-icon" src="@/assets/image/match/ic-match-private-icon@2x.png" alt=""
                   @click="openPrivateFilter"/>
              <img class="vip-badge-icon" src="@/assets/image/match/ic-match-vip@2x.png" alt=""/>
            </div>
          </div>
          <button class="match-btn" @click="startMatch">MATCH</button>
          <p v-if="!isVip" class="premium-promo" @click="handleVipClick">Upgrade to Premium for priority matching>>></p>
        </div>

      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MPageWrap from "@/components/MPageWrap.vue";
import EarthPlanet from "./EarthPlanet.vue";
import {showConfirmDialog,
  showCountryFilterDialog,
  showPrivateFilterDialog,
  showRechargeDialog,
  showRechargePromoDialog
} from "@/components/dialog";
import {openPremium} from "@/utils/PageUtils";
import clientNative from "@/utils/ClientNative";
import {showCallToast} from "@/components/toast/callToast";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import { getCheckinInfo } from "@/api/sdk/user";

export default {
  name: 'PageMatch',
  components: {MPageWrap, EarthPlanet},
  data() {
    return {
      matchCount: Math.floor(Math.random() * (1500 - 1200 + 1)) + 1200,
      matchCountTimer: null,
      estimatedMatchSeconds: 3 + Math.floor(Math.random() * 5),
      estimatedMatchTimer: null,
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
    allPurchased() {
      return !!this.$store.state.user.allPurchased;
    },
    firstRechargeDiscount() {
      return this.$store.state.user.firstRechargeDiscount;
    },
    isVip() {
      return this.userInfo.vipCategory !== 0;
    },
    vipIcon() {
      return this.isVip
          ? require('@/assets/image/match/ic-match-vip@2x.png')
          : require('@/assets/image/match/ic-match-novip@2x.png');
    },
    // 从store获取相机状态
    isCameraOpen() {
      return this.$store.getters.isOpenCamera;
    },
    // 从store获取麦克风状态
    isMicrophoneOpen() {
      return this.$store.getters.isOpenMicrophone;
    },
    // 格式化匹配数量（添加千位分隔符）
    matchCountFormatted() {
      return this.matchCount.toLocaleString();
    },
    estimatedMatchTime() {
      const s = this.estimatedMatchSeconds;
      return `00:${String(s).padStart(2, '0')}`;
    },
    coinDisplay() {
      const balance = this.userInfo.coinBalance || 0;
      return balance <= 0 ? 'Shop' : this.formatNumber(balance);
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
    }
  },
  watch: {
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
  mounted() {
    this.matchCountTimer = setInterval(() => {
      const min = -30;
      const max = 30;
      const delta = Math.floor(Math.random() * (max - min + 1)) + min;
      const newCount = this.matchCount + delta;
      this.matchCount = Math.min(2000, Math.max(1000, newCount));
    }, 3000);

    const tickEstimated = () => {
      this.estimatedMatchTimer = setTimeout(() => {
        this.estimatedMatchSeconds = 3 + Math.floor(Math.random() * 5);
        tickEstimated();
      }, 3000 + Math.floor(Math.random() * 5000));
    };
    tickEstimated();
    const user = cache.local.getJSON(key_cache.user_info) || {};
    const ct = user.createTime;
    this.createTime = ct != null && ct !== '' ? Number(ct) : null;
    this.tickCountdown();
    this.startCountdown();
    this.addTouchMoveListener();
    this.fetchCheckinStatus();
  },
  beforeDestroy() {
    if (this.matchCountTimer) {
      clearInterval(this.matchCountTimer);
      this.matchCountTimer = null;
    }
    if (this.estimatedMatchTimer) {
      clearTimeout(this.estimatedMatchTimer);
      this.estimatedMatchTimer = null;
    }
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = null;
    }
    this.removeTouchMoveListener();
  },
  activated() {
    this.addTouchMoveListener();
  },
  deactivated() {
    this.removeTouchMoveListener();
  },
  methods: {
    openPremium,
    /**
     * 禁止页面左右滑动；星球组件内不阻止，保留拖动旋转。
     */
    preventTouchMove(e) {
      const matchContainer = this.$el?.querySelector('.match-container');
      if (!matchContainer?.contains(e.target)) return;
      if (e.target.closest?.('.earth-planet-wrap') || e.target.closest?.('.earth-bg')) return;
      e.preventDefault();
    },
    addTouchMoveListener() {
      document.addEventListener('touchmove', this.preventTouchMove, {passive: false});
    },
    removeTouchMoveListener() {
      document.removeEventListener('touchmove', this.preventTouchMove);
    },
    handleAvatarError(event) {
      // 图片加载失败时，设置为占位图
      event.target.src = require('@/assets/image/ic-placeholder-avatar.png');
    },
    handleVipClick() {
      this.openPremium();
    },
    async startMatch() {
      const cameraPromise = await clientNative.requestPermission(1);
      const microphonePromise = await clientNative.requestPermission(3);
      console.log('microphonePromise===', microphonePromise);
      // 等待两个权限都获取成功后再执行后续操作
      try {
        await Promise.all([cameraPromise, microphonePromise]);
        const {getType: cameraType, isOpen: cameraIsOpen} = cameraPromise;
        const {getType: microphoneType, isOpen: microphoneIsOpen} = microphonePromise;
        if (!microphoneIsOpen && !cameraIsOpen) {
          showConfirmDialog({
            title: 'Enable Microphone and Camera Access',
            message: 'To enable the microphone and camera for video chat, please enable microphone and camera access in your system settings.',
            confirmText: 'Cancel',
            cancelText: 'Go to Settings',
            onConfirm: () => {
              return false;
            },
            onCancel: () => {
              clientNative.openNativePermissionSetting();
              return true;
            }
          });
          return;
        } else if (!microphoneIsOpen) {
          showConfirmDialog({
            title: 'Enable Microphone Access',
            message: 'To enable the microphone for video chat, please enable microphone access in your system settings.',
            confirmText: 'Cancel',
            cancelText: 'Go to Settings',
            onConfirm: () => {
              return false;
            },
            onCancel: () => {
              clientNative.openNativePermissionSetting();
              return true;
            }
          });
          return;
        } else if (!cameraIsOpen) {
          showConfirmDialog({
            title: 'Enable Camera Access',
            message: 'To enable the camera for video chat, please enable camera access in your system settings.',
            confirmText: 'Cancel',
            cancelText: 'Go to Settings',
            onConfirm: () => {
              return false;
            },
            onCancel: () => {
              clientNative.openNativePermissionSetting();
              return true;
            }
          });
          return;
        }
        await this.$router.push({name: 'PageMatching'});
      } catch (e) {
        showCallToast.info(e.message);
        console.error('permissions failed:', e);
        throw e; // 权限获取失败，抛出错误终止流程
      }

    },
    openRecharge() {
      showRechargeDialog();
    },
    openFirstRecharge() {
      showRechargePromoDialog();
    },
    menuClick({name}) {
      if (name) {
        this.$router.push({name: name})
      }
    },
    openCountryFilter() {
      showCountryFilterDialog(this.handleCountryConfirm);
    },
    openPrivateFilter() {
      showPrivateFilterDialog(this.handlePrivateFilterConfirm);
    },
    handleCountryConfirm(data) {
      console.log("Country filter confirmed:", data);
    },
    handlePrivateFilterConfirm(data) {
      console.log("Private Filter confirmed:", data);
      this.startMatch();
    },
    /**
     * 切换相机开关
     */
    toggleCamera() {
      const newState = !this.isCameraOpen;
      this.$store.dispatch('call/setIsOpenCamera', newState);
      showCallToast && showCallToast(newState ? 'Camera enabled' : 'Camera disabled');
    },
    /**
     * 切换麦克风开关
     */
    toggleVoice() {
      const newState = !this.isMicrophoneOpen;
      this.$store.dispatch('call/setIsOpenMicrophone', newState);
      showCallToast && showCallToast(newState ? 'Microphone enabled' : 'Microphone disabled');
    },
    /**
     * 切换前后摄像头
     */
    switchCamera() {
      const newState = !this.$store.getters.isFrontCamera;
      this.$store.dispatch('call/setIsFrontCamera', newState);
      showCallToast && showCallToast(newState ? 'Switched to front camera' : 'Switched to back camera');
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
.match-container {
  // position: absolute;
  // top: 0;
  // left: 0;
  // right: 0;
  // bottom: 0;
  background: #141414;
  height: 100vh;
  /* Use a gradient to simulate camera feed placeholder */
  overflow: hidden;
  color: white;
}

.background-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.1);
  z-index: 2;
  pointer-events: none;
}

.first-recharge-entry {
  position: fixed;
  right: 20px;
  top: calc(160px + constant(safe-area-inset-top));
  top: calc(160px + env(safe-area-inset-top));
  width: 64px;
  z-index: 99;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  -webkit-tap-highlight-color: transparent;
  tap-highlight-color: transparent;
}

.checkin-entry {
  position: fixed;
  right: 20px;
  top: calc(70px + constant(safe-area-inset-top));
  top: calc(70px + env(safe-area-inset-top));
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
  vertical-align: top;
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

.top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  padding-top: constant(safe-area-inset-top); /* iOS < 11.2，状态栏高度 */
  padding-top: env(safe-area-inset-top); /* 状态栏高度 */
  padding-bottom: 15px;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  box-sizing: border-box;
}

.earth-bg {
  position: absolute;
  top: calc(60px + constant(safe-area-inset-top));
  top: calc(60px + env(safe-area-inset-top));
  left: 0;
  right: 0;
  width: 100%;
  bottom: calc(75px + 25px + 22px + 20px + 20px + 44px + 10px + 52px + constant(safe-area-inset-bottom));
  bottom: calc(75px + 25px + 22px + 20px + 20px + 44px + 10px + 52px + env(safe-area-inset-bottom));
  background-image: url('@/assets/image/match/ic-match-earth-bg@2x.png');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  z-index: 1;
  pointer-events: none;
}

.earth-bg /deep/ .earth-planet-wrap {
  pointer-events: auto;
}

.avatar-container {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  overflow: hidden;

  .avatar {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.top-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.premium-btn {
  background: rgba(255, 255, 255, 0.10);
  color: black;
  border-radius: 20px;
  padding: 4px 12px;
  display: flex;
  align-items: center;
  font-weight: bold;
  font-size: 14px;
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: all 0.3s;

  .crown-icon {
    width: 22px;
    height: 22px;
    margin-right: 4px;
  }

  span {
    color: white;
  }

  &.is-vip {
    span {
      color: #FEE98A;
    }
  }
}

.coin-pill {
  background: rgba(255, 255, 255, 0.10);
  color: black;
  border-radius: 20px;
  padding: 4px 12px;
  display: flex;
  align-items: center;
  font-size: 14px;
  font-weight: bold;

  .coin-icon {
    width: 22px;
    height: 22px;
    margin-right: 4px;
  }

  span {
    color: white;
  }
}

.right-sidebar {
  position: absolute;
  right: 16px;
  top: 100px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  z-index: 10;
}

.icon-btn {
  position: relative;
  width: 44px;
  height: 44px;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(4px);
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 20px;
  color: white;

  .icon-img {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }

  .vip-badge {
    position: absolute;
    top: 0;
    right: 0;
    width: 15px;
    height: 15px;
    object-fit: contain;
  }
}

.match-main {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  /* 底部距视口 75px（premium-promo 已在 match-main 内） */
  bottom: calc(75px + constant(safe-area-inset-bottom));
  bottom: calc(75px + env(safe-area-inset-bottom));
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0;
  z-index: 5;
  width: 100%;
  box-sizing: border-box;
  padding: 0 24px;
}

.match-status {
  margin: 0 0 20px 0;
  padding: 0;
  font-size: 14px;
  font-weight: 400;
  line-height: 1;
  text-align: center;
  white-space: nowrap;
}

.match-status .match-status-text {
  color: #999999;
}

.match-status .match-status-value {
  color: #ffffff;
  font-weight: bold;
}

.match-main .match-btn {
  margin-top: 10px;
}

.bottom-filters {
  display: flex;
  gap: 13px;
  justify-content: center;
  z-index: 10;
}

.match-btn {
  width: 100%;
  max-width: 320px;
  height: 54px;
  border: none;
  border-radius: 26px;
  background: #ffffff;
  color: #000000;
  font-size: 20px;
  font-weight: 1000;
  letter-spacing: 0.02em;
  cursor: pointer;
  text-transform: uppercase;
  transition: transform 0.2s, opacity 0.2s;
}

.match-btn:active {
  transform: scale(0.98);
  opacity: 0.9;
}

.premium-promo {
  margin: 25px 0 0;
  font-size: 14px;
  color: white;
  text-align: center;
  cursor: pointer;
  text-decoration: underline;
  white-space: nowrap;
}

.bottom-filters .filter-icon {
  width: 150px;
  height: 44px;
  object-fit: contain;
  cursor: pointer;
  flex-shrink: 0;
  border-radius: 22px;
}

.private-filter-wrapper {
  position: relative;
  display: inline-block;
}

.private-filter-wrapper .vip-badge-icon {
  position: absolute;
  top: -10px;
  right: 6px;
  width: 22px;
  height: 22px;
  object-fit: contain;
  z-index: 1;
}
</style>
