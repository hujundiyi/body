<template>
  <m-page-wrap :scroll-y="true" :show-action-bar="false" :show-safe-area="true">
    <template #page-content-wrap>
      <div class="recharge-call-end-page">
        <!-- 背景图片 -->
        <div class="background-image" :style="bgStyle"></div>
        <div class="background-overlay"></div>

        <!-- 顶部关闭按钮 -->
        <div class="top-close-button" @click="onClose">
          <img src="@/assets/image/premium/ic-recharge-close@2x.png" class="close-icon" alt="Close" />
        </div>

        <!-- 可滚动内容区域 -->
        <div class="scrollable-content-wrapper">
          <div class="scrollable-content">
          <!-- 用户信息区域 -->
          <div class="user-info-section">
            <div class="user-avatar">
              <img :src="avatarSrc" alt="User Avatar" />
            </div>
            <div class="user-info-right">
              <div class="user-name">{{ displayName }}</div>
            <div class="call-duration">
              <img class="clock-icon" src="@/assets/image/premium/ic-recharge-time@2x.png" alt="Clock" />
              <span>{{ durationText }}</span>
            </div>
              <div class="user-actions">
                <button class="action-btn like-btn" @click="onLike">
                  <img :src="likeIcon" alt="Like" />
                </button>
                <button class="action-btn chat-btn" @click="onChat">
                  <img :src="chatIcon" alt="Chat" />
                </button>
                <button class="action-btn callback-btn" @click="onCallback">
                  <img :src="callbackIcon" alt="Callback" />
                  <span>Callback</span>
                </button>
              </div>
            </div>
          </div>

          <!-- 充值促销卡片 -->
          <div class="recharge-card">
            <!-- New Users Only 横幅 -->
            <div class="promo-banner">
              <div class="banner-content">
                <img
                  src="@/assets/image/premium/ic-recharge-shandian@2x.png"
                  class="banner-icon"
                  alt="Lightning"
                />
                <span class="banner-text">New Users Only</span>
              </div>
            </div>

            <!-- 倒计时 -->
            <div class="countdown-section">
              <span class="countdown-label">Offer ends in</span>
              <span class="countdown-time">{{ countdownText }}</span>
            </div>

            <!-- 充值套餐详情 - 可滑动 -->
            <div class="package-details-wrapper">
              <div class="package-details-scroll" ref="packageScroll">
                <div 
                  v-for="(option, index) in purchaseOptionsWithIcons" 
                  :key="index"
                  class="package-details"
                  :class="{ 'claimed': option.claimed }"
                >
                  <div class="card-extra-wrap">
                    <img src="@/assets/image/premium/ic-recharge-extra@2x.png" alt="" class="card-extra-icon" />
                    <span v-if="option.intros" class="card-extra-intros">{{ option.intros }}</span>
                  </div>
                  <div class="coin-price-row">
                    <div class="coin-section">
                      <img 
                        :src="option.coinIcon" 
                        alt="Coin" 
                        class="coin-icon"
                      />
                      <span 
                        class="coin-amount"
                        :class="{ 'claimed': option.claimed }"
                      >{{ formatNumber(option.coins) }}</span>
                      <div v-if="index === purchaseOptionsWithIcons.length - 1" class="coin-Best-Value">Best Value</div>
                    </div>
                    <div class="price-section">
                      <span v-if="option.originalPrice" class="originalPrice">${{ option.originalPrice }}</span>
                      <span 
                        class="price"
                        :class="{ 'claimed': option.claimed }"
                      >${{ option.price }}</span>
                    </div>
                  </div>

                  <!-- 功能列表 -->
                  <div class="features-list">
                    <div v-for="(feature, fIndex) in option.features" :key="fIndex" class="feature-item">
                      <img 
                        v-if="getFeatureIcon(feature)" 
                        :src="getFeatureIcon(feature)" 
                        alt="Feature Icon" 
                        class="feature-icon"
                      />
                      <span v-html="formatFeatureText(feature)"></span>
                    </div>
                  </div>
                  
                  <div v-if="option.claimed" class="claimed-badge">Claimed</div>
                </div>
              </div>
            </div>

            <!-- Continue 按钮 -->
            <button class="continue-button" @click="handleContinue">
              Continue
            </button>

            <!-- 支付选项：A0019 包只显示 Apple Pay；非 A0019 时不可用苹果支付则隐藏 Apple Pay -->
            <div class="payment-options">
              <div
                v-if="isA0019Package || !isApplePayDisabled"
                class="payment-option"
                :class="{ 'selected': selectedPayment === 'apple' }"
                @click="selectPayment('apple')"
              >
                <img 
                  :src="selectedPayment === 'apple' 
                    ? require('@/assets/image/match/ic-match-sel@2x.png')
                    : require('@/assets/image/match/ic-match-sel-no@2x.png')" 
                  alt="Selection" 
                  class="selection-icon"
                />
                <span>Apple Pay</span>
              </div>
              <div
                v-if="!isA0019Package"
                class="payment-option"
                :class="{ 'selected': selectedPayment === 'paypal' }"
                @click="selectPayment('paypal')"
              >
                <img 
                  :src="selectedPayment === 'paypal' 
                    ? require('@/assets/image/match/ic-match-sel@2x.png')
                    : require('@/assets/image/match/ic-match-sel-no@2x.png')" 
                  alt="Selection" 
                  class="selection-icon"
                />
                <span>PayPal</span>
              </div>
            </div>
          </div>

          <!-- 分页指示器 - 放在卡片外面 -->
          <div class="pagination-indicators">
            <span 
              v-for="(option, index) in purchaseOptionsWithIcons" 
              :key="index" 
              class="dot"
              :class="{ 'active': selectedOption === index }"
            ></span>
          </div>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import { followStatus } from "@/api/sdk/user";
import store from "@/store";
import {LOCAL_CALL_STATUS, key_cache} from "@/utils/Constant";
import {openChat, requestCall} from "@/utils/PageUtils";
import {getCountryFlagEmojiByCode, getCurrentUsrPackageName} from "@/utils/Utils";
import cache from "@/utils/cache";
import {showCallToast} from "@/components/toast/callToast";
import { requestPay } from "@/utils/PaymentUtils";
import { hideLoading, showLoading } from "@/components/MLoading";
import { toast } from "@/components/toast";
import clientNative from "@/utils/ClientNative";

const THREE_DAYS_SEC = 3 * 24 * 3600;
const BACKPACK_TYPE_LABELS = {
  2: 'Feed Filters',
  3: 'Match Filters',
  4: 'Album Videos'
};

export default {
  name: 'RechargeCallEnd',
  props: {

  },
  data() {
    return {
      selectedPayment: 'paypal',
      selectedOption: 0,
      createTime: null,
      countdown: 0,
      rawList: [],
      scrollContainer: null,
      coinIcons: {
        small: require('@/assets/image/premium/ic-recharge-small@2x.png'),
        'small-no': require('@/assets/image/premium/ic-recharge-small-no@2x.png'),
        mid: require('@/assets/image/premium/ic-recharge-mid@2x.png'),
        'mid-no': require('@/assets/image/premium/ic-recharge-mid-no@2x.png'),
        more: require('@/assets/image/premium/ic-recharge-more@2x.png'),
        'more-no': require('@/assets/image/premium/ic-recharge-more-no@2x.png')
      },
      countdownTimer: null,
      firstRechargeRefreshedHandler: null,
      autoScrollTimer: null
    }
  },
  computed: {
    // 从 store 获取 callData 中的对方用户信息
    callDataOtherUser() {
      const anchorInfo = this.$store.state.call.anchorInfo || {};
      return anchorInfo;
    },

    endCallData() {
      return this.$store.state.call.endCallData || {};
    },

    spendCoin() {
      return this.endCallData.spendCoin || 0;
    },

    // 获取对方用户ID
    remoteUserId() {
      return this.callDataOtherUser?.userId || null;
    },
    // 是否已关注（followStatus !== 1 表示已关注）
    isFollowed() {
      const followStatus = this.callDataOtherUser?.followStatus;
      return followStatus && followStatus !== 1;
    },
    avatarSrc() {
      return this.callDataOtherUser.avatar;
    },
    bgStyle() {
      return { backgroundImage: `url(${this.avatarSrc})` };
    },
    displayName() {
      return this.callDataOtherUser.nickname || 'Emily Davis';
    },
    chatIcon() {
      return require('@/assets/image/premium/ic-recharge-chat@2x.png');
    },
    likeIcon() {
      return this.isFollowed
        ? require('@/assets/image/premium/ic-recharge-like@2x.png')
        : require('@/assets/image/premium/ic-recharge-like-no@2x.png');
    },
    callbackIcon() {
      return require('@/assets/image/premium/ic-recharge-video@2x.png');
    },
    countdownText() {
      const s = Math.max(0, Math.floor(this.countdown));
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      const sec = s % 60;
      const pad = (n) => String(n).padStart(2, '0');
      console.error("倒计时",`${pad(h)}:${pad(m)}:${pad(sec)}`)
      return `${pad(h)}:${pad(m)}:${pad(sec)}`;
    },
    /** 按当前支付方式筛选：苹果 rechargeType===0，PayPal rechargeType===2 */
    filteredListByPayment() {
      const list = Array.isArray(this.rawList) ? this.rawList : [];
      const rechargeType = this.selectedPayment === 'apple' ? 0 : 2;
      return list.filter((item) => item != null && Number(item.rechargeType) === rechargeType);
    },
    purchaseOptions() {
      const list = this.filteredListByPayment;
      return list.map((item) => this.mapItemToOption(item));
    },
    purchaseOptionsWithIcons() {
      return this.purchaseOptions.map((option, index) => {
        let iconType = index === 0 ? 'small' : index === 1 ? 'mid' : 'more';
        const iconKey = option.claimed ? `${iconType}-no` : iconType;
        return { ...option, coinIcon: this.coinIcons[iconKey] };
      });
    },
    selectedPack() {
      if (this.selectedOption == null || this.selectedOption < 0) return null;
      const list = this.filteredListByPayment;
      return list[this.selectedOption] || null;
    },
    durationText() {
      const seconds = Number(this.endCallData.callTime || 0);
      if (!Number.isFinite(seconds) || seconds <= 0) return '00:00:00';
      const s = Math.floor(seconds % 60);
      const m = Math.floor((seconds / 60) % 60);
      const h = Math.floor(seconds / 3600);
      const pad = v => String(v).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(s)}`;
    },
    /** 包名 A0019 时只能用苹果支付，不显示 PayPal，优先级高于 isApplePayDisabled */
    isA0019Package() {
      const name = (getCurrentUsrPackageName() || '').toUpperCase();
      return name === 'A0019';
    },
    /** PAY_LIMIT_TYPE 同时包含 IOS 和 Paypal 且 GetInfo 返回 isRecharge 为 true 时，不可选苹果支付，隐藏 Apple Pay。A0019 包优先，不生效 */
    isApplePayDisabled() {
      const configData = store.state.PageCache?.configData || {};
      const payLimitStr = configData.PAY_LIMIT_TYPE;
      if (!payLimitStr || typeof payLimitStr !== 'string') {
        return false;
      }
      let payLimitObj = {};
      try {
        payLimitObj = JSON.parse(payLimitStr);
      } catch (e) {
        return false;
      }
      const hasIos = Object.prototype.hasOwnProperty.call(payLimitObj, 'IOS');
      const hasPaypal = Object.prototype.hasOwnProperty.call(payLimitObj, 'Paypal');
      if (!hasIos || !hasPaypal) {
        return false;
      }
      const userInfo = store.state.user?.loginUserInfo || {};
      return userInfo.isRecharge === true || userInfo.hasSubscribed === true;
    },
    /** 实际生效的苹果禁用状态：A0019 包不禁用苹果支付 */
    effectiveIsApplePayDisabled() {
      return this.isApplePayDisabled && !this.isA0019Package;
    }
  },
  watch: {
    effectiveIsApplePayDisabled: {
      handler(disabled) {
        if (disabled && this.selectedPayment === 'apple') {
          this.selectedPayment = 'paypal';
        }
      },
      immediate: true
    },
    isA0019Package: {
      handler(isA0019) {
        if (isA0019) {
          this.selectedPayment = 'apple';
        }
      },
      immediate: true
    }
  },
  created() {
    this.initF();
    // 存储已通话标记
    cache.local.set(key_cache.has_called, '1');
  },
  mounted() {
    if (this.isA0019Package) {
      this.selectedPayment = 'apple';
    }
    const user = cache.local.getJSON(key_cache.user_info) || {};
    const ct = user.createTime;
    this.createTime = ct != null && ct !== '' ? Number(ct) : null;
    this.tickCountdown();
    this.loadFirstRechargeList();
    this.startCountdown();
    this.$nextTick(() => {
      this.setupScrollListener();
    });
    this.firstRechargeRefreshedHandler = () => this.loadFirstRechargeList();
    document.addEventListener('firstRechargeListRefreshed', this.firstRechargeRefreshedHandler);
  },
  beforeDestroy() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
    }
    if (this.autoScrollTimer) {
      clearInterval(this.autoScrollTimer);
      this.autoScrollTimer = null;
    }
    if (this.scrollContainer) {
      this.scrollContainer.removeEventListener('scroll', this.handleScroll);
    }
    if (this.firstRechargeRefreshedHandler) {
      document.removeEventListener('firstRechargeListRefreshed', this.firstRechargeRefreshedHandler);
    }
  },
  methods: {
    initF() {
      store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END);
    },
    onChat() {
      openChat(this.remoteUserId, true);
    },
    async onLike() {
      const userId = this.remoteUserId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        const follow = !this.isFollowed;
        const { success } = await followStatus(userId, follow);

        if (success) {
          const callData = this.$store.state.call.callData || {};
          this.callDataOtherUser.followStatus = follow ? 2 : 1;
          this.isFollowed = follow;
          showCallToast(follow ? 'Liked' : 'Unliked');
        } else {
          showCallToast('Operation failed');
        }
      } catch (error) {
        showCallToast('Operation failed');
      }
    },
    onCallback() {
      const userId = this.remoteUserId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }
      requestCall(userId);
    },
    onClose() {
      store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
      this.$emit('close');
    },
    selectPayment(payment) {
      this.selectedPayment = payment;
      this.selectedOption = 0;
    },
    selectOption(index) {
      const opts = this.purchaseOptions;
      if (opts[index] && !opts[index].claimed) this.selectedOption = index;
    },
    handleContinue() {
      if (this.selectedOption == null) return;
      const pack = this.selectedPack;
      if (!pack) return;
      if (pack.purchased) return;
      if (this.selectedPayment === 'paypal' && !pack.rechargeId) {
        toast('Recharge info error');
        return;
      }
      // 移除 showLoading()，现在在内部统一调用
      requestPay(pack.productCode, this.selectedPayment, pack.rechargeId, 'Coin')
        .then((res) => {
          // 移除 PayPal 的外部处理，现在在内部统一处理
          if (this.selectedPayment !== 'paypal') {
            if (res && res.code === 0) {
              showCallToast('Payment success');
            } else {
              toast((res && res.msg) || 'Payment failed');
            }
          }
        })
        .catch((err) => {
          toast(err?.message || 'Payment request failed');
        })
        .finally(() => {
          // 统一在 finally 中执行 hideLoading
          hideLoading();
        });
    },
    formatNumber(num) {
      if (num == null || Number.isNaN(Number(num))) return '0';
      return Number(num).toLocaleString();
    },
    loadFirstRechargeList() {
      store.dispatch('FetchFirstRechargeList')
        .then((res) => {
          if (res && res.code === 200) {
            this.rawList = Array.isArray(res.data)
              ? res.data.filter((item) => !item?.purchased)
              : [];
            this.setDefaultSelectedOption();
            this.$nextTick(() => {
              this.scrollToSelectedOption();
              this.startAutoScroll();
            });
          } else {
            toast(res?.msg || 'Failed to load offers');
          }
        })
        .catch(() => {});
    },
    setDefaultSelectedOption() {
      const list = this.filteredListByPayment;
      if (list.length === 0) {
        this.selectedOption = 0;
        return;
      }
      const anyPurchased = list.some((item) => !!item.purchased);
      if (anyPurchased) {
        const idx = list.findIndex((item) => !item.purchased);
        this.selectedOption = idx >= 0 ? idx : 0;
      } else {
        const idx = list.findIndex((item) => !!item.isRecommend);
        this.selectedOption = idx >= 0 ? idx : 0;
      }
    },
    scrollToSelectedOption() {
      const el = this.$refs.packageScroll;
      if (!el || this.purchaseOptions.length === 0) return;
      const w = el.clientWidth;
      const index = Math.max(0, Math.min(this.selectedOption, this.purchaseOptions.length - 1));
      el.scrollLeft = index * w;
    },
    mapItemToOption(item) {
      const features = this.rewardsToFeatures(item.rewards);
      const priceVal = item.price != null ? Number(item.price) : 0;
      const priceStr = Number.isNaN(priceVal) ? '0' : (priceVal % 1 === 0 ? String(priceVal) : priceVal.toFixed(2));
      const originalPriceVal = Number(item.originalPrice);
      const originalPriceStr = (originalPriceVal != null && !Number.isNaN(originalPriceVal))
        ? (originalPriceVal % 1 === 0 ? String(originalPriceVal) : originalPriceVal.toFixed(2))
        : '';
      const rewardCoins = Array.isArray(item.rewards)
        ? item.rewards.reduce((sum, reward) => {
            if (reward && Number(reward.backpackType) === 5) {
              const qty = Number(reward.quantity);
              return sum + (Number.isNaN(qty) ? 0 : qty);
            }
            return sum;
          }, 0)
        : 0;
      const originalCoin = item.originalCoin != null ? Number(item.originalCoin) : 0;
      return {
        coins: rewardCoins + (Number.isNaN(originalCoin) ? 0 : originalCoin),
        price: priceStr,
        originalPrice: originalPriceStr,
        intros: item.intros ?? '',
        features,
        claimed: !!item.purchased,
        raw: item
      };
    },
    /** 从 rewards 解析出 features 列表，用于卡片展示（不包含背包类型 5 的金币） */
    rewardsToFeatures(rewards) {
      if (!Array.isArray(rewards) || rewards.length === 0) return [];
      return rewards
        .filter((r) => Number(r?.backpackType) !== 5)
        .map((r) => {
          const label = BACKPACK_TYPE_LABELS[r.backpackType] ?? (r.remark || 'Reward');
          const q = Math.max(1, Number(r.quantity) || 1);
          return `${label} x${q}`;
        });
    },
    tickCountdown() {
      if (this.createTime == null) return;
      const end = this.createTime + THREE_DAYS_SEC;
      const now = Math.floor(Date.now() / 1000);
      this.countdown = Math.max(0, end - now);
    },
    formatFeatureText(feature) {
      // 将 x1, x3, x5, x10 等数字部分变为白色
      return feature.replace(/([xX]\d+)/g, '<span class="feature-number">$1</span>');
    },
    getFeatureIcon(feature) {
      // 根据功能文字返回对应的图标
      if (feature.toLowerCase().includes('feed')) {
        return require('@/assets/image/premium/ic-recharge-feed@2x.png');
      } else if (feature.toLowerCase().includes('match')) {
        return require('@/assets/image/premium/ic-recharge-match@2x.png');
      } else if (feature.toLowerCase().includes('album')) {
        return require('@/assets/image/premium/ic-recharge-alum@2x.png');
      }
      return null;
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
    setupScrollListener() {
      const scrollElement = this.$refs.packageScroll;
      if (!scrollElement) return;
      this.scrollContainer = scrollElement;
      this.scrollContainer.addEventListener('scroll', this.handleScroll);
      this.scrollToSelectedOption();
    },
    handleScroll() {
      this.updateSelectedOption();
      this.resetAutoScroll();
    },
    updateSelectedOption() {
      const scrollElement = this.$refs.packageScroll;
      if (!scrollElement) return;
      
      const scrollLeft = scrollElement.scrollLeft;
      const containerWidth = scrollElement.clientWidth;
      
      // 计算当前显示在视口中的选项索引
      // 每个选项占据 100% 宽度，所以 scrollLeft / containerWidth 就是当前选项索引
      const currentIndex = Math.round(scrollLeft / containerWidth);
      
      // 确保索引在有效范围内
      if (currentIndex >= 0 && currentIndex < this.purchaseOptions.length) {
        this.selectedOption = currentIndex;
      }
    },
    scrollToIndex(index) {
      const el = this.$refs.packageScroll;
      if (!el || this.purchaseOptions.length === 0) return;
      const w = el.clientWidth;
      const nextIndex = Math.max(0, Math.min(index, this.purchaseOptions.length - 1));
      el.scrollTo({ left: nextIndex * w, behavior: 'smooth' });
    },
    startAutoScroll() {
      if (this.autoScrollTimer) {
        clearInterval(this.autoScrollTimer);
        this.autoScrollTimer = null;
      }
      if (!this.$refs.packageScroll || this.purchaseOptions.length <= 1) return;
      this.autoScrollTimer = setInterval(() => {
        const nextIndex = (this.selectedOption + 1) % this.purchaseOptions.length;
        this.selectedOption = nextIndex;
        this.scrollToIndex(nextIndex);
      }, 3000);
    },
    resetAutoScroll() {
      if (!this.autoScrollTimer) return;
      clearInterval(this.autoScrollTimer);
      this.autoScrollTimer = null;
      this.startAutoScroll();
    }
  }
}
</script>

<style scoped lang="scss">
.recharge-call-end-page {
  position: relative;
  width: 100%;
  min-height: 100vh;
  overflow-x: hidden;
}

// 滚动容器包装器
.scrollable-content-wrapper {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
  z-index: 2;
  // 从下到上的渐变背景：从 #141414 100% 到 #141414 50%
  // 对应 iOS CAGradientLayer: startPoint(0.5, 1) -> endPoint(0.5, 0)
  background: linear-gradient(0deg, rgba(20, 20, 20, 1) 0%, rgba(20, 20, 20, 0.5) 100%);
}

// 背景图片
.background-image {
  position: fixed;
  inset: -40px;
  background-size: cover;
  background-position: center;
  transform: scale(1.22);
  z-index: 0;
}

.background-overlay {
  position: fixed;
  inset: 0;
  background: linear-gradient(to bottom, rgba(20, 20, 20, 0.20) 0%, rgba(20, 20, 20, 1) 40%);
  z-index: 1;
}

// 顶部关闭按钮 - 固定不滚动
.top-close-button {
  position: fixed;
  top: calc(16px + env(safe-area-inset-top, 0));
  left: 16px;
  z-index: 200;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  background: transparent; // 去掉背景颜色
  border-radius: 50%;
  
  .close-icon {
    width: 20px;
    height: 20px;
    object-fit: contain;
  }
  
  &:active {
    transform: scale(0.95);
  }
}

// 可滚动内容区域
.scrollable-content {
  position: relative;
  width: 100%;
  min-height: calc(100vh + 100px); // 确保内容足够高以触发滚动
  // 关闭按钮位置(16px + 40px高度) + 68px间距 = 124px
  padding: calc(124px + env(safe-area-inset-top, 0)) 20px calc(20px + env(safe-area-inset-bottom, 0));
  padding-bottom: 40px;
  box-sizing: border-box;
}

// 用户信息区域
.user-info-section {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 40px;
  
  .user-avatar {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
    
    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }
  
  .user-info-right {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    height: 80px; // 与头像高度一致
  }
  
  .user-name {
    font-size: 24px;
    font-weight: 500;
    color: #fff;
    line-height: 1; // 确保名字顶部对齐
  }
  
  .call-duration {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: 8px;
    
    .clock-icon {
      width: 16px;
      height: 16px;
      object-fit: contain;
    }
    
    span {
      font-size: 14px;
      color: rgba(255, 255, 255, 0.8);
    }
  }
  
  .user-actions {
    display: flex;
    flex-direction: row;
    gap: 12px; // 按钮之间的间距
    align-items: center; // 垂直居中对齐
    flex-wrap: nowrap; // 不换行，确保所有按钮在同一排
    // 按钮与名字左边对齐
    
    .action-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      background: transparent;
      border: none;
      cursor: pointer;
      transition: all 0.3s ease;
      flex-shrink: 0;
      
      img {
        width: 100%;
        height: 100%;
        object-fit: contain;
        flex-shrink: 0;
      }
      
      span {
        font-size: 12px;
        color: #fff;
        white-space: nowrap;
      }
      
      // 心形和聊天按钮：圆形
      &.like-btn,
      &.chat-btn {
        width: 30px; // 固定宽度
        height: 30px; // 固定高度，与宽度相等
        padding: 0;
        border-radius: 50%; // 完美圆形
        background: transparent; // 不需要背景色
      }
      
      // Callback按钮：胶囊形状（左右半圆）
      &.callback-btn {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 8px 23px; // 上下8px，左右23px
        height: 40px; // 与圆形按钮高度一致
        width: 127px;
        border-radius: 20px; // 高度的一半，实现左右半圆
        white-space: nowrap;
        background: rgba(255, 255, 255, 0.10);
        font-weight: bold;

        img {
          width: 25px; // callback按钮中的图标大小
          height: 25px;
        }
      }
      
      &.is-liked {
        background: #FF40A7;
      }
      
      &:active {
        transform: scale(0.95);
      }
    }
  }
}

// 充值促销卡片
.recharge-card {
  background: transparent;
  border: 2px solid rgba(255, 255, 255, 0.1); // #FFFFFF 10%
  border-radius: 20px;
  padding: 20px;
  padding-top: 0; // 移除顶部padding，为横幅留出空间
  // backdrop-filter: blur(20px);
  width: 100%;
  box-sizing: border-box;
  max-width: 100%;
  overflow: visible; // 允许横幅超出卡片边界
  position: relative;
}

// 促销横幅
.promo-banner {
  margin-bottom: 10px; // 距离下面的 "Offer ends in" 为 10px
  display: flex;
  justify-content: flex-start;
  position: relative;
  // 将横幅向上移动，使其中心与卡片顶部对齐
  // 横幅高度约为 28px (6px padding * 2 + 16px font-size)，所以向上移动 14px
  top: -14px;
  
  .banner-content {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 16px;
    background: #000000;
    border-radius: 20px;
    
    .banner-icon {
      width: 16px;
      height: 16px;
      object-fit: contain;
    }
    
    .banner-text {
      color: #fff;
      font-size: 16px;
      font-weight: 600;
      line-height: 1;
    }
  }
}

// 倒计时
.countdown-section {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 8px;
  margin-bottom: 30px; // 距离下面的金币为 30px
  
  .countdown-label {
    color: #fff;
    font-size: 16px;
    font-weight: 400;
  }
  
  .countdown-time {
    color: #F14210;
    font-size: 16px;
    font-weight: 700;
  }
}

// 充值套餐详情包装器
.package-details-wrapper {
  margin-bottom: 24px;
  width: 100%;
  overflow: hidden;
}

// 可滚动的套餐详情容器
.package-details-scroll {
  display: flex;
  gap: 0; // 移除选项卡之间的间距
  overflow-x: auto;
  overflow-y: hidden;
  -webkit-overflow-scrolling: touch;
  scroll-snap-type: x mandatory;
  scrollbar-width: none; // Firefox
  -ms-overflow-style: none; // IE/Edge
  
  &::-webkit-scrollbar {
    display: none; // Chrome/Safari
  }
  
  // 每个卡片占据视口宽度
  .package-details {
    flex: 0 0 100%; // 占满整个滚动区域宽度
    min-width: 100%;
    scroll-snap-align: start;
  }
}

// 充值套餐详情
.package-details {
  position: relative;
  background: transparent; // 背景色设置为透明
  border: none; // 移除边框
  border-radius: 0; // 移除圆角
  padding: 0; // 移除内边距
  box-sizing: border-box;
  
  &.claimed {
    opacity: 0.6;
  }

  .card-extra-wrap {
    position: absolute;
    right: 0;
    bottom: 15px;
    width: 80px;
    height: 80px;
    pointer-events: none;
  }

  .card-extra-icon {
    position: absolute;
    left: 0;
    top: 0;
    width: 80px;
    height: 80px;
    object-fit: contain;
  }

  .card-extra-intros {
    position: absolute;
    left: 0;
    top: 0;
    right: 0;
    bottom: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    font-weight: bold;
    color: #ffffff;
    transform: rotate(-15deg);
    white-space: nowrap;
  }
  
  .coin-price-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    width: 100%;
    box-sizing: border-box;
    
    .coin-section {
      display: flex;
      align-items: center;
      gap: 3px;
      flex-shrink: 0;
      
      .coin-icon {
        width: 32px;
        height: 32px;
        object-fit: contain;
        flex-shrink: 0;
      }
      
      .coin-amount {
        font-size: 22px;
        font-weight: 500;
        color: #fff;
        white-space: nowrap;
        
        &.claimed {
          color: #999999;
        }
      }

      .coin-Best-Value {
        margin-left: 3px;
        padding-left: 5px;
        padding-right: 5px;
        font-size: 12px;
        color: #000000;
        font-weight: bold;
        background: linear-gradient(270deg, #EAC570 0%, #D3A351 100%);
        border-radius: 5px;
        height: 20px;
      }
    }
    
    .price-section {
      flex-shrink: 0;

      .originalPrice {
        color: #717171;
        font-size: 14px;
        margin-right: 5px;
        text-decoration: line-through;
      }
      
      .price {
        font-size: 16px;
        font-weight: 500;
        color: #fff;
        white-space: nowrap;
        
        &.claimed {
          color: #717171;
        }
      }
    }
  }
  
  .features-list {
    display: flex;
    flex-direction: column;
    gap: 6px;
    width: 100%;
    box-sizing: border-box;
    
    .feature-item {
      display: flex;
      align-items: center;
      gap: 4px;
      color: #999999;
      font-size: 16px;
      white-space: nowrap;
      width: 100%; // 占满宽度
      
      .feature-icon {
        width: 27px;
        height: 27px;
        object-fit: contain;
        flex-shrink: 0;
      }
    }
  }
  
  .claimed-badge {
    position: absolute;
    bottom: 0;
    right: 0;
    background: #BABABA;
    color: #000;
    padding: 4px 12px;
    border-top-left-radius: 16px;
    border-bottom-right-radius: 16px;
    font-size: 12px;
  }
  
}

// Continue按钮
.continue-button {
  width: 100%;
  height: 54px;
  background: url('@/assets/image/premium/ic-recharge-btnbg@2x.png') no-repeat center;
  background-size: cover;
  border: none;
  border-radius: 27px;
  color: #000;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-bottom: 20px;
  box-sizing: border-box;
  
  &:active {
    transform: scale(0.98);
    box-shadow: 0 4px 20px rgba(255, 215, 0, 0.4);
  }
}

// 支付选项
.payment-options {
  display: flex;
  justify-content: center;
  gap: 60px;
  padding: 0 20px 20px;
  
  .payment-option {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    position: relative;
    
    .selection-icon {
      width: 20px;
      height: 20px;
      object-fit: contain;
      flex-shrink: 0;
    }
    
    span {
      color: rgba(255, 255, 255, 0.6);
      font-size: 12px;
    }
    
    &.selected {
      span {
        color: #fff;
        font-weight: 600;
      }
    }
    
    &:active {
      transform: scale(0.95);
    }
  }
}

// 分页指示器 - 放在卡片外面
.pagination-indicators {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  margin-top: 20px; // 距离充值促销卡片底部20px
  
  .dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.3);
    transition: all 0.3s ease;
    
    &.active {
      background: #fff;
      width: 20px;
      border-radius: 3px;
    }
  }
}
</style>

<style lang="scss">
// 全局样式，确保 feature-number 样式生效（用于 v-html 动态插入的内容）
.recharge-call-end-page {
  .feature-item {
    .feature-number {
      color: #fff !important;
    }
  }
}
</style>
