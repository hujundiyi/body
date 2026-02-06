<template>
  <div>
    <m-bottom-dialog ref="bottomDialog" :dialog-class="'recharge-dialog'" :enable-swipe-close="false">
      <div class="recharge-content" :class="{ 'has-gift-float': showRewardsFloat }">
        <!-- 选中项 rewards 有数据时显示顶部浮窗，顶部区域透明 -->
        <div v-if="showRewardsFloat" class="recharge-top-gift-float">
          <div class="gift-float-bg">
            <div class="gift-float-left">
              <img src="@/assets/image/coins/ic-coins-header-coin-icon@2x.png" class="gift-float-coin-icon" alt=""/>
              <span class="gift-float-coin-num">{{ formatNumber(rewardFloatBonusCoins) }}</span>
            </div>
            <div class="gift-float-plus">
              <img src="@/assets/image/coins/ic-coins-gift-add@2x.png" class="gift-float-plus-icon" alt=""/>
            </div>
            <div class="gift-float-right">
              <div v-for="(feature, idx) in rewardFloatFeatures" :key="idx" class="gift-float-feature">
                <img v-if="getRewardFeatureIcon(feature)" :src="getRewardFeatureIcon(feature)"
                     class="gift-float-feature-icon" alt=""/>
                <span>{{ feature }}</span>
              </div>
            </div>
          </div>
          <div class="recharge-top-gift-extra">
            <img src="@/assets/image/premium/ic-recharge-extra@2x.png" alt="" class="card-extra-icon"/>
            <span v-if="selectedPackData && selectedPackData.intros" class="card-extra-intros">{{ selectedPackData.intros }}</span>
          </div>
        </div>
        <!-- 主内容区，有浮窗时顶部透明、此区有背景 -->
        <div class="recharge-body">
          <!-- Header -->
          <div class="recharge-header">
            <div class="coin-balance">
              <img src="@/assets/image/match/ic-match-coin@2x.png" class="coin-icon"/>
              <span class="coin-label">Coins:</span>
              <span>{{ formatNumber(userInfo.coinBalance || 0) }}</span>
            </div>
            <div class="close-btn" @click="closeDialog">
              <img src="@/assets/image/global/ic-global-close@2x.png" class="close-icon"/>
            </div>
          </div>

          <!-- Message -->
          <div class="recharge-message" v-if="selectedPayment === 'paypal'">
            <div class="recharge-message-title">Use PayPal for more savings.</div>
          </div>

          <!-- Coin Packs Grid -->
          <div class="coin-packs-scroll">
            <div class="coin-packs-grid">
              <div
                  v-for="(pack, index) in displayPacks"
                  :key="index"
                  class="coin-pack-card"
                  :class="{ selected: selectedPack === index, hot: pack.hot, popular: pack.isRecommend }"
                  @click="selectPack(index)"
              >
                <div class="pack-amount">{{ formatNumber(pack.displayBase) }}</div>
                <div class="pack-bonus" v-if="pack.words && String(pack.words).trim()">{{ pack.words }}</div>
                <img v-if="Array.isArray(pack.rewards) && pack.rewards.length > 1" class="pack-gift-icon"
                     src="@/assets/image/coins/ic-coins-first-gift@2x.png" alt="Gift"/>
                <div class="pack-price">${{ pack.displayPrice }}</div>
              </div>
            </div>
          </div>

          <div class="payment-section">
            <div
                v-for="method in displayPaymentMethods"
                :key="method.id"
                class="payment-option"
                :class="{ 'payment-option--disabled': effectiveIsApplePayDisabled && method.id === 'apple' }"
                @click="onPaymentOptionClick(method)"
            >
              <div class="payment-left">
                <img :src="method.icon" class="payment-icon"/>
                <span class="payment-label">{{ method.label }}</span>
                <img v-if="getPaymentBadgeIcon(method)" :src="getPaymentBadgeIcon(method)" class="payment-badge-icon"/>
                <img
                    v-else-if="effectiveIsApplePayDisabled && method.id === 'apple'"
                    :src="require('@/assets/image/coins/ic-coin-ap-un@2x.png')"
                    class="payment-badge-icon"
                />
              </div>
              <div class="payment-right">
                <div
                    class="payment-coins"
                    :class="{
                  'payment-coins--apple': method.id === 'apple',
                  'payment-coins--paypal': method.id === 'paypal'
                }"
                    v-if="paymentCoinTotals"
                >
                  <img
                      v-if="method.id === 'paypal'"
                      src="@/assets/image/match/ic-match-coin@2x.png"
                      class="payment-coin-icon"
                  />
                  <span>{{ formatNumber(getDisplayPaymentCoins(method)) }}</span>
                </div>
                <img
                    class="payment-radio-icon"
                    :class="{ 'payment-radio-icon--hidden': effectiveIsApplePayDisabled && method.id === 'apple' }"
                    :src="selectedPayment === method.id ? paymentSelectedIcon : paymentUnselectedIcon"
                />
              </div>
            </div>
          </div>

          <!-- Continue Button -->
          <div class="continue-btn" :class="{ disabled: selectedPack === null }" @click="handleContinue">Continue</div>
        </div>
      </div>
    </m-bottom-dialog>

  </div>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import {getRechargeList} from "@/api/sdk/commodity";
import cache from "@/utils/cache";
import {hideLoading, showLoading} from "@/components/MLoading";
import {requestPay} from "@/utils/PaymentUtils";
import {toast} from "@/components/toast";
import clientNative from "@/utils/ClientNative";
import {key_cache} from "@/utils/Constant";
import {tdTrack, EVENT_NAME} from "@/utils/TdTrack";
import {getCurrentUsrPackageName} from "@/utils/Utils";

export default {
  name: "MRechargeDialog",
  components: {MBottomDialog},
  props: {
    showMessage: {
      type: Boolean,
      default: false
    },
    onSuccess: {
      type: Function,
      default: null
    },
    // 来源，表示从哪个地方进入的
    from: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      rechargeCacheKey: 'recharge_list_cache',
      selectedPack: null,
      allCoinPacks: [],
      coinPacks: [],
      selectedPayment: 'paypal',
      animatedPacks: [],
      animationFrameIds: {},
      paymentMethods: [
        {
          id: 'paypal',
          label: 'PayPal',
          icon: require('@/assets/image/global/ic-common-paypal@2x.png'),
          badgeIcon: require('@/assets/image/global/ic-common-double@2x.png')
        },
        {
          id: 'apple',
          label: 'Apple Pay',
          icon: require('@/assets/image/global/ic-common-apple@2x.png'),
          badgeIcon: ''
        }
      ],
      paymentSelectedIcon: require('@/assets/image/match/ic-match-sel@2x.png'),
      paymentUnselectedIcon: require('@/assets/image/match/ic-match-sel-no@2x.png'),
      paymentCoinDisplay: {paypal: null, apple: null}
    };
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    selectedPackData() {
      if (this.selectedPack === null) {
        return null;
      }
      return this.coinPacks[this.selectedPack] || null;
    },
    showRewardsFloat() {
      const pack = this.selectedPackData;
      return pack && Array.isArray(pack.rewards) && pack.rewards.length > 0;
    },
    rewardFloatBonusCoins() {
      const pack = this.selectedPackData;
      if (!pack || !Array.isArray(pack.rewards)) return 0;
      return pack.rewards.reduce((sum, r) => {
        if (r && Number(r.backpackType) === 5) {
          return sum + (Number(r.quantity) || 0);
        }
        return sum;
      }, 0);
    },
    rewardFloatFeatures() {
      const pack = this.selectedPackData;
      if (!pack || !Array.isArray(pack.rewards)) return [];
      const LABELS = {2: 'Feed Filters', 3: 'Match Filters', 4: 'Album Videos'};
      return pack.rewards
          .filter((r) => r && Number(r.backpackType) !== 5)
          .map((r) => {
            const label = LABELS[r.backpackType] ?? (r.remark || 'Reward');
            const q = Math.max(1, Number(r.quantity) || 1);
            return `${label} x${q}`;
          });
    },
    paymentCoinTotals() {
      const pack = this.selectedPackData;
      if (!pack) {
        return null;
      }
      const productCode = pack.productCode;
      const paypalPack = this.findPackByProductCode(productCode, 2);
      const applePack = this.findPackByProductCode(productCode, 0);
      return {
        paypal: paypalPack ? this.getBaseCoin(paypalPack) + this.getBonusCoin(paypalPack) : null,
        apple: applePack ? this.getBaseCoin(applePack) + this.getBonusCoin(applePack) : null
      };
    },
    /** 包名 A0019 时只能用苹果支付，不显示 PayPal，优先级高于 isApplePayDisabled */
    isA0019Package() {
      const name = (getCurrentUsrPackageName() || '').toUpperCase();
      return name === 'A0019';
    },
    /** 实际显示的支付方式：A0019 包只显示 Apple Pay */
    displayPaymentMethods() {
      if (this.isA0019Package) {
        return this.paymentMethods.filter((m) => m.id === 'apple');
      }
      return this.paymentMethods;
    },
    /** PAY_LIMIT_TYPE 同时包含 IOS 和 Paypal 且 GetInfo 返回 isRecharge 为 true 时，不可选苹果支付。A0019 包优先，不生效 */
    isApplePayDisabled() {
      const configData = this.$store.state.PageCache?.configData || {};
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
      const userInfo = this.$store.state.user?.loginUserInfo || {};
      return userInfo.isRecharge === true || userInfo.hasSubscribed === true;
    },
    /** 实际生效的苹果禁用状态：A0019 包不禁用苹果支付 */
    effectiveIsApplePayDisabled() {
      return this.isApplePayDisabled && !this.isA0019Package;
    },
    displayPacks() {
      return this.coinPacks.map((pack, index) => {
        const animated = this.animatedPacks[index] || {};
        const base = animated.base !== undefined ? animated.base : this.getBaseCoin(pack);
        const bonus = animated.bonus !== undefined ? animated.bonus : this.getBonusCoin(pack);
        const price = animated.price !== undefined && animated.price !== null
            ? this.formatPrice(animated.price, pack.price)
            : pack.price;
        return {
          ...pack,
          displayBase: base,
          displayBonus: bonus,
          displayPrice: price,
          showBonus: this.getBonusCoin(pack) > 0
        };
      });
    }
  },
  watch: {
    selectedPayment(newVal, oldVal) {
      this.switchPaymentList(newVal, oldVal);
    },
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
    if (this.isA0019Package) {
      this.selectedPayment = 'apple';
    }
    this.loadRechargeList();
  },
  mounted() {
    document.addEventListener('firstRechargeListRefreshed', this.handleFirstRechargeListRefreshed);
    // 发送金币购买弹窗展示埋点
    this.$nextTick(() => {
      tdTrack(EVENT_NAME.coinspopup_show, {from: this.from})
    })
  },
  beforeDestroy() {
    document.removeEventListener('firstRechargeListRefreshed', this.handleFirstRechargeListRefreshed);
    Object.values(this.animationFrameIds).forEach((id) => cancelAnimationFrame(id));
    this.animationFrameIds = {};
  },
  methods: {
    getRewardFeatureIcon(feature) {
      if (!feature || typeof feature !== 'string') return null;
      const s = feature.toLowerCase();
      if (s.includes('feed')) return require('@/assets/image/premium/ic-recharge-feed-1@2x.png');
      if (s.includes('match')) return require('@/assets/image/premium/ic-recharge-match-1@2x.png');
      if (s.includes('album')) return require('@/assets/image/premium/ic-recharge-alum-1@2x.png');
      return null;
    },
    onPaymentOptionClick(method) {
      if (this.effectiveIsApplePayDisabled && method.id === 'apple') {
        return;
      }
      this.selectedPayment = method.id;
    },
    getPaymentBadgeIcon(method) {
      if (!method) return '';
      if (method.id !== 'paypal') return method.badgeIcon || '';
      if (this.selectedPayment === 'apple') {
        return require('@/assets/image/global/ic-common-double-un@2x@2x.png');
      }
      return method.badgeIcon || '';
    },
    getDisplayPaymentCoins(method) {
      if (!this.paymentCoinTotals) return null;
      const total = this.paymentCoinTotals[method.id];
      if (method.id === 'paypal' && this.selectedPayment === 'paypal' && this.paymentCoinDisplay.paypal != null) {
        return this.paymentCoinDisplay.paypal;
      }
      if (method.id === 'apple' && this.selectedPayment === 'apple' && this.paymentCoinDisplay.apple != null) {
        return this.paymentCoinDisplay.apple;
      }
      return total;
    },
    startPaymentCoinAnimation() {
      const payment = this.selectedPayment;
      if ((payment !== 'paypal' && payment !== 'apple') || this.selectedPack == null || !this.paymentCoinTotals || !this.selectedPackData) {
        return;
      }
      const toVal = this.paymentCoinTotals[payment];
      if (toVal == null) return;
      const pack = this.displayPacks[this.selectedPack];
      const fromVal = pack ? (pack.displayBase ?? this.getBaseCoin(this.selectedPackData)) : this.getBaseCoin(this.selectedPackData);
      this.paymentCoinDisplay[payment] = fromVal;
      const animKey = `payment${payment === 'paypal' ? 'Paypal' : 'Apple'}Coin`;
      this.animateValue(animKey, fromVal, toVal, 800, (value) => {
        this.paymentCoinDisplay[payment] = value;
        if (value >= toVal) {
          this.paymentCoinDisplay[payment] = null;
        }
      });
    },
    filterRechargeList(list) {
      if (!Array.isArray(list)) {
        return [];
      }
      return list.filter(item => item && item.activityType !== 1);
    },
    getRechargeTypeByPayment(paymentId) {
      return paymentId === 'paypal' ? 2 : 0;
    },
    getPacksByPayment(paymentId) {
      const rechargeType = this.getRechargeTypeByPayment(paymentId);
      return this.allCoinPacks.filter(item => item && Number(item.rechargeType) === rechargeType);
    },
    buildPackMap(list) {
      const map = {};
      if (!Array.isArray(list)) {
        return map;
      }
      list.forEach((pack) => {
        if (pack && pack.productCode !== undefined && pack.productCode !== null) {
          map[pack.productCode] = pack;
        }
      });
      return map;
    },
    findPackByProductCode(productCode, rechargeType) {
      if (productCode === undefined || productCode === null) {
        return null;
      }
      return this.allCoinPacks.find(item => item && item.productCode === productCode && Number(item.rechargeType) === rechargeType) || null;
    },
    getPriceNumber(packOrPrice) {
      const raw = packOrPrice && packOrPrice.price !== undefined ? packOrPrice.price : packOrPrice;
      const number = Number(raw);
      return Number.isNaN(number) ? null : number;
    },
    getPricePrecision(price) {
      const raw = price !== undefined && price !== null ? String(price) : '';
      const dotIndex = raw.indexOf('.');
      return dotIndex === -1 ? 0 : raw.length - dotIndex - 1;
    },
    formatPrice(value, referencePrice) {
      const precision = this.getPricePrecision(referencePrice);
      if (precision <= 0) {
        return Math.round(value).toString();
      }
      return value.toFixed(precision);
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
    getBaseCoin(pack) {
      const value = pack.originalCoin !== undefined ? pack.originalCoin : pack.totaltCoin;
      const number = Number(value || 0);
      return Number.isNaN(number) ? 0 : number;
    },
    getBonusCoin(pack) {
      // rewards 中存在 backpackType===5 时取 quantity 之和，否则取 extraCoin
      if (pack.rewards && Array.isArray(pack.rewards)) {
        const bonusFromRewards = pack.rewards
            .filter((r) => r && Number(r.backpackType) === 5)
            .reduce((sum, r) => sum + (Number(r.quantity) || 0), 0);
        if (bonusFromRewards > 0) {
          return bonusFromRewards;
        }
      }
      const number = Number(pack.extraCoin || 0);
      return Number.isNaN(number) ? 0 : number;
    },
    initAnimatedValues(list) {
      this.animatedPacks = list.map(() => ({base: 0, bonus: 0, price: null}));
    },
    setAnimatedValue(index, key, value) {
      if (!this.animatedPacks[index]) {
        this.$set(this.animatedPacks, index, {base: 0, bonus: 0});
      }
      this.$set(this.animatedPacks[index], key, value);
    },
    cancelAnimation(key) {
      if (this.animationFrameIds[key]) {
        cancelAnimationFrame(this.animationFrameIds[key]);
        delete this.animationFrameIds[key];
      }
    },
    animateValue(key, from, to, duration, onUpdate, precision = 0) {
      this.cancelAnimation(key);
      if (from === to) {
        onUpdate(to);
        return;
      }
      const start = performance.now();
      const step = (now) => {
        const progress = Math.min((now - start) / duration, 1);
        const rawValue = from + (to - from) * progress;
        const factor = Math.pow(10, precision);
        const value = factor > 1 ? Math.round(rawValue * factor) / factor : Math.round(rawValue);
        onUpdate(value);
        if (progress < 1) {
          this.animationFrameIds[key] = requestAnimationFrame(step);
        } else {
          delete this.animationFrameIds[key];
        }
      };
      this.animationFrameIds[key] = requestAnimationFrame(step);
    },
    updateAnimatedValues(animate, newList, oldMap) {
      const previousMap = oldMap || {};
      newList.forEach((pack, index) => {
        const targetBase = this.getBaseCoin(pack);
        const targetBonus = this.getBonusCoin(pack);
        const targetPrice = this.getPriceNumber(pack);
        const oldPack = previousMap[pack.productCode];
        const startBase = oldPack ? this.getBaseCoin(oldPack) : targetBase;
        const startBonus = oldPack ? this.getBonusCoin(oldPack) : targetBonus;
        const startPrice = oldPack ? this.getPriceNumber(oldPack) : targetPrice;
        if (!animate) {
          this.setAnimatedValue(index, 'base', targetBase);
          this.setAnimatedValue(index, 'bonus', targetBonus);
          this.setAnimatedValue(index, 'price', targetPrice);
          return;
        }
        this.animateValue(`base-${index}`, startBase, targetBase, 300, (value) => {
          this.setAnimatedValue(index, 'base', value);
        });
        this.animateValue(`bonus-${index}`, startBonus, targetBonus, 300, (value) => {
          this.setAnimatedValue(index, 'bonus', value);
        });
        if (targetPrice !== null && startPrice !== null) {
          const precision = this.getPricePrecision(pack.price);
          this.animateValue(`price-${index}`, startPrice, targetPrice, 300, (value) => {
            this.setAnimatedValue(index, 'price', value);
          }, precision);
        } else {
          this.setAnimatedValue(index, 'price', targetPrice);
        }
      });
    },
    switchPaymentList(newPayment, oldPayment, animate = true) {
      if (newPayment !== 'paypal') {
        this.paymentCoinDisplay.paypal = null;
        this.cancelAnimation('paymentPaypalCoin');
      }
      if (newPayment !== 'apple') {
        this.paymentCoinDisplay.apple = null;
        this.cancelAnimation('paymentAppleCoin');
      }
      const newList = this.getPacksByPayment(newPayment);
      const oldList = oldPayment ? this.getPacksByPayment(oldPayment) : [];
      const oldMap = this.buildPackMap(oldList);
      const previousProductCode = this.selectedPackData && this.selectedPackData.productCode;

      this.coinPacks = newList.length ? newList.map(pack => ({...pack})) : [];
      this.initAnimatedValues(newList);
      this.updateAnimatedValues(animate, newList, oldMap);

      this.$nextTick(() => {
        if (previousProductCode !== undefined && previousProductCode !== null) {
          const newIndex = newList.findIndex(pack => pack.productCode === previousProductCode);
          this.selectedPack = newIndex !== -1 ? newIndex : null;
        }
        if (newPayment === 'paypal' || newPayment === 'apple') {
          this.startPaymentCoinAnimation();
        }
      });
    },
    setDefaultSelectedPack() {
      if (!Array.isArray(this.coinPacks) || this.coinPacks.length === 0) {
        return;
      }

      // 查找 isRecommend 为 true 的项
      const recommendIndex = this.coinPacks.findIndex(pack => pack.isRecommend === true);

      if (recommendIndex !== -1) {
        // 如果找到 isRecommend 为 true 的项，选中它
        this.selectedPack = recommendIndex;
      } else {
        // 如果没有找到，选中第四个元素（索引为3）
        // 确保数组长度足够
        if (this.coinPacks.length > 3) {
          this.selectedPack = 3;
        } else if (this.coinPacks.length > 0) {
          // 如果数组长度不足4，选中最后一个
          this.selectedPack = this.coinPacks.length - 1;
        }
      }
    },
    handleFirstRechargeListRefreshed() {
      this.loadRechargeList();
    },
    loadRechargeList() {
      const cachedList = cache.local.getJSON(this.rechargeCacheKey);
      if (cachedList && Array.isArray(cachedList) && cachedList.length > 0) {
        this.allCoinPacks = this.filterRechargeList(cachedList).map(p => ({...p}));
        this.switchPaymentList(this.selectedPayment, null, false);
        this.$nextTick(() => {
          this.setDefaultSelectedPack();
          this.startPaymentCoinAnimation();
        });
      }
      getRechargeList([0, 2], 0).then((response) => {
        if (response && response.data && Array.isArray(response.data)) {
          const nextList = this.filterRechargeList(response.data);
          // 始终用接口数据更新，避免缓存数据污染（如 words 被错误覆盖）
          this.allCoinPacks = nextList.map(p => ({...p}));
          cache.local.setJSON(this.rechargeCacheKey, this.allCoinPacks);
          this.switchPaymentList(this.selectedPayment, null, false);
          this.$nextTick(() => {
            this.setDefaultSelectedPack();
            this.startPaymentCoinAnimation();
          });
        }
      }).catch((error) => {
        console.error('加载充值列表失败:', error);
      });
    },
    selectPack(index) {
      this.selectedPack = index;
      this.$nextTick(() => {
        this.startPaymentCoinAnimation();
      });
    },
    handleContinue() {
      if (this.selectedPack === null) {
        return;
      }
      const pack = this.coinPacks[this.selectedPack];
      // 移除 showLoading()，现在在内部统一调用
      if (this.selectedPayment === 'paypal' && (!pack || !pack.rechargeId)) {
        toast("Recharge info error");
        return;
      }

      /// 埋点
      const payType = this.selectedPayment === 'paypal' ? 'paypal' : 'apple';
      tdTrack(EVENT_NAME.coinspopup_buy, {'from': this.from, 'price': pack.price, 'paymethod': payType})
      requestPay(pack.productCode, this.selectedPayment, pack.rechargeId, 'Coin').then((response) => {
        // 移除 PayPal 的外部处理，现在在内部统一处理
        if (this.selectedPayment !== 'paypal') {
          if (response.code === 0) {
            tdTrack(EVENT_NAME.client_coinspopup_buy_suc,{"price":pack.price,"from":this.from,"paymethod":payType,"coins_status":true})
            // 充值成功回调
            if (this.onSuccess && typeof this.onSuccess === 'function') {
              this.onSuccess();
              // 关闭弹窗
              this.closeDialog();
            }
          } else {
            toast(response.msg || "Payment failed");
          }
        }
      }).catch((error) => {
        console.error('支付请求失败:', error);
        toast("Payment request failed");
      }).finally(() => {
        // 统一在 finally 中执行 hideLoading
        hideLoading();
        // 注意：PayPal 支付时不要重置 selectedPack，因为用户可能还在支付页面
        if (this.selectedPayment !== 'paypal') {
          this.selectedPack = null;
        }
      });
    },
    closeDialog() {
      if (this.$refs.bottomDialog) {
        this.$refs.bottomDialog.closeDialog();
      }
    }
  }
}
</script>

<style scoped lang="less">
/* 最外层贴屏：左、右、下无内边距，仅顶部保留 */
.recharge-content {
  background: #282828;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 20px 0 0 0;
  color: white;
  max-height: 95vh;
  display: flex;
  flex-direction: column;

  &.has-gift-float {
    background: transparent;
    padding-top: 0;
  }
}

.recharge-body {
  flex: 1;
  padding: 0 20px 20px 20px;

  .recharge-content.has-gift-float & {
    background: #282828;
    border-top-left-radius: 20px;
    border-top-right-radius: 20px;
    padding: 10px 20px 20px 20px;
    margin-top: -8px;
  }
}

.recharge-top-gift-float {
  position: relative;
  margin-bottom: 20px;
  //background: transparent;
  padding: 0 20px;
}

.recharge-top-gift-extra {
  position: absolute;
  left: 0;
  top: 0;
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

/* 左右距父视图各 8px，两个 item 边框相距 13px（中间占位 13px），加号在间隙中 */
.gift-float-bg {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 35px 15px 12px 15px;
  width: 100%;
  min-height: 135px;
  box-sizing: border-box;
  background: url('@/assets/image/coins/ic-coin-top-gift-bg@2x.png') no-repeat center / 100% 100%;
  border-radius: 20px;
}

/* 两个 item 中间固定 13px，加号 28px 居中叠在间隙上 */
.gift-float-plus {
  flex-shrink: 0;
  width: 13px;
  min-width: 13px;
  max-width: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: visible;
}

.gift-float-plus-icon {
  width: 28px;
  height: 28px;
  object-fit: contain;
  position: relative;
  z-index: 1;
}

.gift-float-left {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
  border: 1px solid rgba(255, 255, 255, 0.35);
  border-radius: 12px;
  box-sizing: border-box;
}

.gift-float-coin-icon {
  width: 38px;
  height: 38px;
  object-fit: contain;
}

.gift-float-coin-num {
  font-size: 16px;
  font-weight: 700;
  color: #fff;
}

.gift-float-right {
  flex: 2;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
  padding: 8px 12px 8px 20px;
  border: 1px solid rgba(255, 255, 255, 0.35);
  border-radius: 12px;
  box-sizing: border-box;
}

.gift-float-feature {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #fff;
}

.gift-float-feature-icon {
  width: 18px;
  height: 18px;
  object-fit: contain;
}

.recharge-header {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 4px;
  position: relative;
  min-height: 40px;
}

.coin-balance {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 20px;
  font-weight: 600;
  color: #FFFFFF;
}

.coin-label {
  color: #9a9a9a;
  font-size: 20px;
  font-weight: 600;
}

.coin-icon {
  width: 20px;
  height: 20px;
  object-fit: contain;
}

.close-btn {
  position: absolute;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.close-icon {
  width: 100%;
  height: 100%;
}

.recharge-message {
  text-align: center;
  margin-bottom: 14px;
}

.recharge-message-title {
  font-size: 14px;
  color: #8a8a8a;
}

.coin-packs-scroll {
  margin-top: 6px;
  max-height: calc(130px * 2 + 10px);
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
  margin-bottom: 16px;
}

.coin-packs-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}

.coin-pack-card {
  background: #2f2f2f;
  border-radius: 12px;
  padding: 14px 8px 10px;
  text-align: center;
  position: relative;
  cursor: pointer;
  border: 1px solid #3a3a3a;
  box-sizing: border-box;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
  height: 130px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.coin-pack-card.selected {
  border: 2px solid #E2BB77;
  box-shadow: none;
}

.pack-amount {
  color: #ffffff;
  font-weight: 700;
  font-size: 18px;
}

.pack-bonus {
  color: #f5c04b;
  font-size: 18px;
  font-weight: 600;
  margin-top: 4px;
}

.pack-gift-icon {
  width: 37px;
  height: 37px;
  margin-top: 6px;
  align-self: center;
  object-fit: contain;
}

.pack-price {
  margin-top: auto;
  color: #999999;
  font-size: 18px;
  font-weight: 600;
  height: 26px;
  line-height: 26px;
  margin-left: 8px;
  margin-right: 8px;
}

.payment-section {
  padding-top: 12px;
  margin-bottom: 14px;
}

.payment-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 4px;

  &.payment-option--disabled {
    opacity: 0.5;
    pointer-events: none;
  }
}

.payment-left {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  flex: 1;
  min-width: 0;
}

.payment-label {
  white-space: nowrap;
}

.payment-icon {
  width: 30px;
  height: 30px;
  object-fit: contain;
}

.payment-badge-icon {
  height: 22px;
  object-fit: contain;
}

.payment-right {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #ffffff;
  font-size: 15px;
  flex-shrink: 0;
}

.payment-coins {
  display: flex;
  align-items: center;
  gap: 4px;
  color: #f5c04b;
  font-size: 18px;
  font-weight: 600;
}

.payment-coins--paypal {
  color: #ffffff;
  background: #5C4E36;
  border-radius: 5px;
  padding: 2px 5px;
}

.payment-coins--apple {
  color: #999999;
}

.payment-coin-icon {
  width: 16px;
  height: 16px;
  object-fit: contain;
}

.payment-radio-icon {
  width: 18px;
  height: 18px;
  object-fit: contain;

  &.payment-radio-icon--hidden {
    visibility: hidden;
  }
}

.continue-btn {
  background: #ffffff;
  color: #000000;
  height: 54px;
  border-radius: 27px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: 600;
  font-size: 18px;
  cursor: pointer;
  width: calc(100% - 80px);
  margin: 0 40px 20px;
}

.continue-btn.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
