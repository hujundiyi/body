<template>
  <m-bottom-dialog ref="bottomDialog" :enable-swipe-close="false" dialog-class="recharge-promo-dialog">
    <div class="recharge-promo-container">
      <!-- 顶部固定区域 - 只保留关闭按钮 -->
      <div class="top-fixed-section">
        <img src="@/assets/image/dialog/ic-dialog-close.png" class="close-icon" alt="Close" @click="closeDialog" />
      </div>

      <!-- 顶部背景图片 - 从页面最顶部开始 -->
      <div class="top-background-wrapper">
        <div class="top-background-image">
          <img src="@/assets/image/premium/ic-recharge-bg@2x.png" alt="Background" />
        </div>
      </div>

      <!-- 中间可滚动区域 -->
      <div class="scrollable-content" ref="scrollContainer">
        <!-- 促销横幅 - 在可滚动区域内，叠加在背景图片上 -->
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
        
        <!-- 倒计时：注册时间 createTime + 3 天，归零后隐藏 -->
        <div v-if="countdown > 0" class="countdown-section">
          <span class="countdown-label">Offer ends in</span>
          <span class="countdown-time">{{ countdownText }}</span>
        </div>
        
        <div class="purchase-options">
          <!-- 购买选项卡片 -->
          <div 
            v-for="(option, index) in purchaseOptionsWithIcons" 
            :key="option.raw?.rechargeId ?? index"
            class="purchase-card"
            :class="{ 'selected': selectedOption === index, 'claimed': option.claimed }"
            @click="onSelectOption(index)"
          >
            <div class="card-extra-wrap">
              <img src="@/assets/image/premium/ic-recharge-extra@2x.png" alt="" class="card-extra-icon" />
              <span v-if="option.intros" class="card-extra-intros">{{ option.intros }}</span>
            </div>
            <div class="card-content">
              <div class="coin-section">
                <img :src="option.coinIcon" alt="Coin" class="coin-icon"/>
                <div class="coin-amount" :class="{ 'selected': selectedOption === index && !option.claimed,'claimed': option.claimed}">{{ formatNumber(option.coins) }}</div>
                <div v-if="index === purchaseOptionsWithIcons.length - 1" class="coin-Best-Value">Best Value</div>
              </div>
              <div class="price-section">
                <span v-if="option.originalPrice" class="originalPrice">${{ option.originalPrice }}</span>
                <span class="price" :class="{ 'selected': selectedOption === index && !option.claimed,'claimed': option.claimed}">${{ option.price }}</span>
              </div>
            </div>
            <div class="card-features">
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

      <!-- 底部固定区域 -->
      <div class="bottom-fixed-section">
        <!-- Continue按钮 -->
        <button
          class="continue-button"
          @click="handleContinue"
          :disabled="selectedOption == null || !selectedPack || !!selectedPack.purchased"
        >
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
            <span class="selection-icon-wrap">
              <img 
                :src="require('@/assets/image/match/ic-match-sel@2x.png')" 
                alt="" 
                class="selection-icon sel"
              />
              <img 
                :src="require('@/assets/image/match/ic-match-sel-no@2x.png')" 
                alt="" 
                class="selection-icon sel-no"
              />
            </span>
            <span class="payment-label">Apple Pay</span>
          </div>
          <div
            v-if="!isA0019Package"
            class="payment-option"
            :class="{ 'selected': selectedPayment === 'paypal' }"
            @click="selectPayment('paypal')"
          >
            <span class="selection-icon-wrap">
              <img 
                :src="require('@/assets/image/match/ic-match-sel@2x.png')" 
                alt="" 
                class="selection-icon sel"
              />
              <img 
                :src="require('@/assets/image/match/ic-match-sel-no@2x.png')" 
                alt="" 
                class="selection-icon sel-no"
              />
            </span>
            <span class="payment-label">PayPal</span>
          </div>
        </div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import store from "@/store";
import { requestPay } from "@/utils/PaymentUtils";
import { hideLoading, showLoading } from "@/components/MLoading";
import { toast } from "@/components/toast";
import clientNative from "@/utils/ClientNative";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";
import { getCurrentUsrPackageName } from "@/utils/Utils";

const THREE_DAYS_SEC = 3 * 24 * 3600;

/** backpackType -> 展示文案，与 getFeatureIcon 的 feed/match/album 匹配 */
const BACKPACK_TYPE_LABELS = {
  2: 'Feed Filters',
  3: 'Match Filters',
  4: 'Album Videos'
};

export default {
  name: 'MRechargePromoDialog',
  components: { MBottomDialog },
  props: {
    onSuccess: { type: Function, default: null }
  },
  data() {
    return {
      selectedOption: 0,
      selectedPayment: 'paypal',
      countdown: 0,
      createTime: null,
      rawList: [],
      countdownTimer: null,
      coinIcons: {
        small: require('@/assets/image/premium/ic-recharge-small@2x.png'),
        'small-no': require('@/assets/image/premium/ic-recharge-small-no@2x.png'),
        mid: require('@/assets/image/premium/ic-recharge-mid@2x.png'),
        'mid-no': require('@/assets/image/premium/ic-recharge-mid-no@2x.png'),
        more: require('@/assets/image/premium/ic-recharge-more@2x.png'),
        'more-no': require('@/assets/image/premium/ic-recharge-more-no@2x.png')
      }
    }
  },
  computed: {
    countdownText() {
      const s = Math.max(0, Math.floor(this.countdown));
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      const sec = s % 60;
      const pad = (n) => String(n).padStart(2, '0');
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
    /** 包名 A0019 时只能用苹果支付，不显示 PayPal，优先级高于 isApplePayDisabled */
    isA0019Package() {
      const name = (getCurrentUsrPackageName() || '').toUpperCase();
      return name === 'A0019';
    },
    /** PAY_LIMIT_TYPE 同时包含 IOS 和 Paypal 且 GetInfo 返回 isRecharge 为 true 时，不可选苹果支付。A0019 包优先，不生效 */
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
  mounted() {
    if (this.isA0019Package) {
      this.selectedPayment = 'apple';
    }
    const user = cache.local.getJSON(key_cache.user_info) || {};
    const ct = user.createTime;
    this.createTime = ct != null && ct !== '' ? Number(ct) : null;
    this.tickCountdown();
    this.startCountdown();
    this.loadFirstRechargeList();
  },
  beforeDestroy() {
    if (this.countdownTimer) clearInterval(this.countdownTimer);
  },
  methods: {
    loadFirstRechargeList() {
      store.dispatch('FetchFirstRechargeList')
        .then((res) => {
          if (res && res.code === 200) {
            this.rawList = Array.isArray(res.data)
              ? res.data.filter((item) => !item?.purchased)
              : [];
            this.setDefaultSelectedOption();
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
    /** 从 rewards 解析出 features 列表，用于卡片展示 */
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
    closeDialog() {
      this.$refs.bottomDialog.closeDialog();
    },
    onSelectOption(index) {
      const opts = this.purchaseOptions;
      if (opts[index] && !opts[index].claimed) this.selectedOption = index;
    },
    selectPayment(payment) {
      const currentIndex = this.selectedOption;
      this.selectedPayment = payment;

      const list = this.filteredListByPayment;
      if (list.length === 0) {
        this.selectedOption = 0;
        return;
      }
      const newIndex = Math.min(currentIndex, list.length - 1);
      const targetItem = list[newIndex];
      if (targetItem && targetItem.purchased) {
        const idx = list.findIndex((item) => !item.purchased);
        this.selectedOption = idx >= 0 ? idx : 0;
      } else {
        this.selectedOption = newIndex;
      }
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
              if (this.onSuccess && typeof this.onSuccess === 'function') this.onSuccess();
              this.closeDialog();
            } else {
              toast((res && res.msg) || 'Payment failed');
            }
          }
        })
        .catch((err) => {
          console.error('Payment request failed:', err);
          toast('Payment request failed');
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
    formatFeatureText(feature) {
      // 将 x1, x3, x5, x10 等数字部分变为白色
      // 匹配 x 后面跟数字的模式（不区分大小写）
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
    getCoinIconKey(index, claimed) {
      // 根据索引和claimed状态返回对应的金币图标key
      // 索引0: small, 索引1: mid, 索引2: more
      let iconType = '';
      if (index === 0) {
        iconType = 'small';
      } else if (index === 1) {
        iconType = 'mid';
      } else if (index === 2) {
        iconType = 'more';
      }
      
      // 如果claimed，使用带no的图片
      return claimed ? `${iconType}-no` : iconType;
    },
    tickCountdown() {
      if (this.createTime == null) return;
      const end = this.createTime + THREE_DAYS_SEC;
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
    }
  }
}
</script>

<style scoped lang="less">
// 全局样式，覆盖底部弹窗的默认样式
</style>

<style lang="less">
// 全局样式，确保 feature-number 样式生效（用于 v-html 动态插入的内容）
.recharge-promo-dialog {
  .purchase-card .feature-item {
    .feature-number {
      color: #fff !important;
    }
    
    span .feature-number {
      color: #fff !important;
    }
  }
  
  // 确保 Claimed 状态下数字也是白色
  .purchase-card.claimed .feature-item {
    .feature-number {
      color: #fff !important;
    }
    
    span .feature-number {
      color: #fff !important;
    }
  }
}
</style>

<style lang="less">
.recharge-promo-dialog {
  &.d-bottom {
    background: rgba(0, 0, 0, 0.8) !important;
    
    .m-dialog {
      height: 100vh !important;
      max-height: 100vh !important;
      border-radius: 0 !important;
      background: transparent !important;
    }
    
    .m-dialog-body {
      height: 100vh !important;
      overflow: hidden !important;
      padding: 0 !important;
    }
  }
}
</style>

<style scoped lang="less">

.recharge-promo-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #141414;
  position: relative;
  overflow: hidden;
}

// 顶部固定区域 - 只保留关闭按钮
.top-fixed-section {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  padding-top: env(safe-area-inset-top, 0);
}

.close-icon {
  position: absolute;
  top: calc(16px + env(safe-area-inset-top, 0));
  left: 20px;
  width: 30px;
  height: 30px;
  object-fit: contain;
  cursor: pointer;
  z-index: 200;
}

.promo-banner {
  position: relative;
  // 距离上面16px（从关闭按钮下方开始计算）
  margin-top: calc(16px - env(safe-area-inset-top, 0));
  margin-bottom: 13px; // 距离下面13px
  padding: 0 20px;
  z-index: 2;
  display: flex;
  justify-content: center; // 水平居中
  
  .banner-content {
    display: inline-flex;
    align-items: center;
    background: #141414;
    border-radius: 20px;
    padding: 8px 16px;
    
    .banner-icon {
      width: 16px;
      height: 16px;
      margin-right: 6px;
      object-fit: contain;
    }
    
    .banner-text {
      color: #fff;
      font-size: 16px;
      font-weight: 500;
    }
  }
}

.countdown-section {
  position: relative;
  padding: 0 20px 16px;
  display: flex;
  align-items: center;
  justify-content: center; // 水平居中
  gap: 8px;
  z-index: 2;
  
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

// 顶部背景图片容器 - 从页面最顶部开始
.top-background-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  width: 100%;
  z-index: 1;
}

// 顶部背景图片
.top-background-image {
  width: 100%;
  height: 300px;
  position: relative;
  overflow: hidden;
  margin: 0;
  padding: 0;
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top;
    display: block;
  }
}

// 中间可滚动区域
.scrollable-content {
  flex: 1;
  overflow-y: auto;
  padding-top: calc(80px + env(safe-area-inset-top, 0)); // 为关闭按钮留出空间
  padding-bottom: calc(180px + env(safe-area-inset-bottom, 0));
  padding-left: 0;
  padding-right: 0;
  -webkit-overflow-scrolling: touch;
  position: relative;
  z-index: 2;
}

.empty-offers {
  padding: 40px 20px;
  text-align: center;
  color: rgba(255, 255, 255, 0.6);
  font-size: 16px;
}

.purchase-options {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0 20px;
}

.purchase-card {
  position: relative;
  background: #141414;
  border: 2px solid rgba(255, 255, 255, 0.10); // #FFFFFF 3% 透明度
  border-radius: 16px;
  padding: 20px 20px 20px 13px;
  cursor: pointer;
  transition: all 0.3s ease;
  overflow: visible; // 确保子元素（如 claimed-badge）可以正确显示

  .card-extra-wrap {
    position: absolute;
    right: 15px;
    bottom: 20px;
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
    top: -5px;
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
  
  &.selected {
    background: rgba(226, 187, 119, 0.1); // #E2BB77 10% 透明度
    border: 2px solid #E2BB77;
  }
  
  &.claimed {
    opacity: 0.6;
    cursor: not-allowed;
    border: 2px solid #BABABA !important; // #FFFFFF 3% 透明度
  }
  
  // 如果同时是selected和claimed，claimed的边框优先级更高
  &.selected.claimed {
    border: 2px solid #BABABA !important;
    background: rgba(255, 255, 255, 0.5); // 恢复默认背景，不使用选中背景
  }
  
  .card-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  
  .coin-section {
    display: flex;
    align-items: center;
    gap: 2px;
    
    .coin-icon {
      width: 34px;
      height: 34px;
      object-fit: contain;
      flex-shrink: 0;
    }
    
    .coin-amount {
      color: #fff; // 默认未选中颜色
      font-size: 22px;
      font-weight: 500;
      
      &.selected {
        color: #E2BB77; // 选中时颜色
      }
      
      &.claimed {
        color: #999999; // Claimed时颜色改为#999999
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
    }
  }
  
  .price-section {
    .originalPrice {
      color: #717171;
      font-size: 14px;
      margin-right: 5px;
      text-decoration: line-through;
    }
    .price {
      color: #717171; // 默认未选中颜色
      font-size: 16px;
      font-weight: 500;
      
      &.selected {
        color: #fff; // 选中时颜色
      }
      
      &.claimed {
        color: #717171; // Claimed时颜色
      }
    }
  }
  
  .card-features {
    display: flex;
    flex-direction: column;

    .feature-item {
      display: flex;
      align-items: center;
      gap: 6px;
      color: #999999; // 非数字部分为#999999
      font-size: 14px;
      white-space: nowrap;
      
      .feature-icon {
        width: 27px;
        height: 27px;
        object-fit: contain;
        flex-shrink: 0;
        margin-left: 2px;
      }
      
      .feature-number {
        color: #fff !important; // 数字部分为白色
      }
    }
  }
  
  .claimed-badge {
    position: absolute;
    bottom: -1px;
    right: -1px;
    background: #BABABA;
    color: #000; // 黑色
    padding: 4px 12px;
    // 左上角16px圆角，右下角16px圆角（与卡片边框圆角完全一致）
    border-top-left-radius: 16px;
    border-bottom-right-radius: 16px;
    font-size: 12px;
    font-weight: 500;
  }
  
}

// 底部固定区域
.bottom-fixed-section {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: linear-gradient(180deg, transparent 0%, rgba(20, 20, 20, 0.98) 30%, #141414 100%);
  padding-bottom: calc(20px + env(safe-area-inset-bottom, 0));
  padding-top: 20px;
}

.continue-button {
  width: calc(100% - 84px); // 左右各42px，总共84px
  margin: 0 42px 16px;
  height: 54px;
  background: url('@/assets/image/premium/ic-recharge-btnbg@2x.png') no-repeat center;
  background-size: cover;
  border: none;
  border-radius: 27px; // 高度的一半，保持圆角
  color: #000;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    box-shadow: 0 4px 20px rgba(255, 215, 0, 0.4);
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

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
    position: relative;

    .selection-icon-wrap {
      position: relative;
      width: 20px;
      height: 20px;
      flex-shrink: 0;
    }
    
    .selection-icon {
      position: absolute;
      left: 0;
      top: 0;
      width: 20px;
      height: 20px;
      object-fit: contain;
      transition: opacity 0.2s ease;
    }
    
    .selection-icon.sel {
      opacity: 0;
    }
    
    .selection-icon.sel-no {
      opacity: 1;
    }
    
    &.selected .selection-icon.sel {
      opacity: 1;
    }
    
    &.selected .selection-icon.sel-no {
      opacity: 0;
    }
    
    .payment-label {
      color: rgba(255, 255, 255, 0.6);
      font-size: 12px;
      font-weight: 400;
      min-width: 64px;
    }
    
    &.selected .payment-label {
      color: #fff;
      font-weight: 600;
    }
  }
}
</style>
