<template>
  <m-page-wrap class="premium-page" :class="{ 'is-dialog-mode': isDialog }" :show-action-bar="false">
    <template #page-content-wrap>
      <div class="premium-container" :class="{ 'dialog-container': isDialog }">
        <!-- 返回按钮（弹窗模式下隐藏） -->
        <div v-if="!isDialog" class="back-button" @click="goBack">
          <img class="back-icon" :src="backIcon" alt="Back"/>
        </div>
        <section class="hero-section">
          <div class="top-features">
            <m-swiper
                ref="featureSwiper"
                :list="features"
                :interval="3000"
                :autoplay="true"
                :swipeable="true"
                :show-dots="false"
                :loop="true"
                class="premium-detail-swiper"
                @change="onFeatureChange"
            >
              <template #default="{ item }">
                <div class="top-grid">
                  <div class="hero-icon">
                    <img :src="item.bigIcon" :alt="item.title" class="hero-icon-img"/>
                  </div>
                  <h1 class="hero-title">{{ item.title }}</h1>
                  <p class="hero-subtitle">{{ item.description }}</p>
                </div>
              </template>
            </m-swiper>
            <div v-if="features.length > 1" class="premium-swiper-dots">
              <div
                  v-for="(item, index) in features"
                  :key="item.id || index"
                  :class="['premium-swiper-dot', { 'premium-swiper-dot-active': currentFeatureIndex === index }]"
                  @click="onFeatureDotClick(index)"
              ></div>
            </div>
          </div>

          <div class="plan-carousel" ref="planCarousel">
            <div class="plan-carousel-padding-left"></div>
            <div
                v-for="(plan, index) in plans"
                :key="plan.rechargeId"
                :class="['plan-card', { 'plan-card-selected': plan.rechargeId === selectedPlan.rechargeId }]"
                @click="selectPlan(plan, index)"
            >
              <div class="plan-card-item">
                <p class="item-desc"> {{ plan.words }} </p>
                <img v-if="plan.rechargeId === selectedPlan.rechargeId" class="item-sel-img"
                     src="@/assets/image/premium/ic-premium-item-sel.png" alt="">
                <div v-if="plan.discount"
                     :class="['savings-badge', { 'savings-badge-selected': plan.rechargeId === selectedPlan.rechargeId }]">
                  <span>{{ plan.discount }}</span>
                </div>
                <p :class="['plan-duration', {'plan-duration-selected': plan.rechargeId === selectedPlan.rechargeId }]">
                  {{ plan.vipName }}</p>
                <p :class="['plan-price-week',{'plan-price-week-selected' : plan.rechargeId === selectedPlan.rechargeId}]">
                  {{ plan.intros }}</p>
                <div
                    :class="['plan-get-free', { 'plan-get-free-selected': plan.rechargeId === selectedPlan.rechargeId }]"
                >
                  <img :src="getPlanCoinIcon(plan, index)" class="plan-get-free-coin-icon" alt="" />
                  <div class="plan-get-free-text-wrap">
                    <span class="plan-get-free-text">Get Free</span>
                    <span class="plan-get-free-amount">{{ formatPlanFreeCoins(getPlanFreeCoins(plan)) }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="plan-carousel-padding-right"></div>
          </div>

          <div class="cta-button" @click="onContinue">
            {{ buttonTitle }}
          </div>
        </section>

        <section class="feature-section">
          <div v-for="category in featureCategories" :key="category.title" class="feature-category">
            <div class="category-title-wrapper">
              <h3 class="category-title">{{ category.title }}</h3>
            </div>
            <div class="feature-list">
              <div v-for="featureId in category.features" :key="featureId" class="feature-item">
                <div class="feature-icon">
                  <img src="@/assets/image/premium/ic-premium-right.png" alt="checkmark" class="checkmark-img"/>
                </div>
                <div class="feature-content">
                  <p class="feature-name">{{ getFeatureTitle(featureId) }}</p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MSwiper from "@/components/MSwiper/index.vue";
import {requestPay} from "@/utils/PaymentUtils";
import {toast} from "@/components/toast";
import {getRechargeList} from "@/api/sdk/commodity";
import {hideLoading, showLoading} from "@/components/MLoading";
import store from "@/store";
import clientNative from "@/utils/ClientNative";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import {tdTrack, EVENT_NAME} from "@/utils/TdTrack";
import {getCurrentUsrPackageName} from "@/utils/Utils";


export default {
  name: 'PagePremium',
  components: {MSwiper},
  props: {
    // 是否在弹窗中显示
    isDialog: {
      type: Boolean,
      default: false
    },
    // 来源，表示从哪个地方进入的
    from: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      dat: Object,
      plans: [],
      selectedPlan: {},
      currentFeatureIndex: 0,
      features: [
        {
          id: '1',
          bigIcon: require('@/assets/image/premium/ic-premium-extra-coin.png'),
          title: 'Extra Free Coins',
          description: 'Exclusive perks, get up to 100,000 free coins!'
        },
        {
          id: '2',
          bigIcon: require('@/assets/image/premium/ic-premium-per-min.png'),
          title: '10% Off Per Minute',
          description: 'Enjoy 10% off per minute on all video calls, giving you more time for your likes.'
        },
        {
          id: '3',
          bigIcon: require('@/assets/image/premium/ic-premium-private-filter.png'),
          title: 'Private Filter',
          description: 'Premium-exclusive, tailored to fulfill your bold, customized privacy desires.'
        },
        {
          id: '4',
          bigIcon: require('@/assets/image/premium/ic-premium-country-filter.png'),
          title: 'Advanced Country Filter',
          description: 'Use smarter country-based matching to connect with nearby users.'
        },
        {
          id: '5',
          bigIcon: require('@/assets/image/premium/ic-premium-global-match.png'),
          title: 'Global Match Pass',
          description: 'Connect with people worldwide you’re drawn to.'
        },
        {
          id: '6',
          bigIcon: require('@/assets/image/premium/ic-premium-super-match.png'),
          title: 'Super Match',
          description: 'Fewer blank screens and repeat matches for better video chats.'
        },
        {
          id: '7',
          bigIcon: require('@/assets/image/premium/ic-premium-age-based.png'),
          title: 'Age-Based Matching',
          description: 'Meet people around your age for more natural conversations.'
        },
        {
          id: '8',
          bigIcon: require('@/assets/image/premium/ic-premium-exclusive-albums.png'),
          title: 'Exclusive Albums',
          description: 'Unlock private photos and videos from people you’re interested in.'
        },
        {
          id: '9',
          bigIcon: require('@/assets/image/premium/ic-premium-see-like.png'),
          title: 'See Who Liked You',
          description: 'See who’s into you — don’t miss a real connection.'
        },
        {
          id: '10',
          bigIcon: require('@/assets/image/premium/ic-premium-view-gift.png'),
          title: 'View Gift History',
          description: 'View your gift interactions and find your favorites.'
        },
        {
          id: '11',
          bigIcon: require('@/assets/image/premium/ic-premium-more-video.png'),
          title: '3× More Video Chat Invites',
          description: 'Enjoy over 7× more exposure to receive more invitations.'
        },
        {
          id: '12',
          bigIcon: require('@/assets/image/premium/ic-premium-priority-match.png'),
          title: 'Priority Matching',
          description: 'Skip the line and connect up to 2× faster.'
        },
        {
          id: '13',
          bigIcon: require('@/assets/image/premium/ic-premium-rear-camera.png'),
          title: 'Rear Camera',
          description: 'Switch between front and rear cameras for more dynamic video calls.'
        },
        {
          id: '14',
          bigIcon: require('@/assets/image/premium/ic-premium-hd-video.png'),
          title: 'HD Video Quality',
          description: 'Enjoy clearer, more stable video calls with premium servers.'
        },
        {
          id: '15',
          bigIcon: require('@/assets/image/premium/ic-premium-premium-badge.png'),
          title: 'Premium Badge',
          description: 'Stand out with a badge that sets you apart.'
        },
      ],
      featureCategories: [
        {
          title: 'Advanced Matching',
          features: ['1', '2', '3', '4', '5','6', '7']
        },
        {
          title: 'Deep Interactions',
          features: ['8', '9', '10', '11']
        },
        {
          title: 'Premium Experience',
          features: ['12', '13', '14', '15']
        }
      ]
    }
  },
  computed: {
    backIcon() {
      return require('@/assets/image/ic-common-back.png');
    },
    buttonTitle() {
      if (this.selectedPlan && Object.keys(this.selectedPlan).length > 0) {
        return "Continue" + " - " + "$" + this.selectedPlan.price
      } else {
        return "Continue"
      }
    }
  },
  created() {
    this.onGoodsSearch()
  },
  mounted() {
    // 发送会员页展示埋点
    tdTrack(EVENT_NAME.vip_show, {from: this.from})
  },
  methods: {
    onFeatureChange(index) {
      this.currentFeatureIndex = index
    },
    onFeatureDotClick(index) {
      this.currentFeatureIndex = index
      const swiper = this.$refs.featureSwiper
      if (swiper && typeof swiper.goTo === 'function') {
        swiper.goTo(index)
      }
    },
    getFeatureTitle(featureId) {
      const feature = this.features.find(f => f.id === featureId);
      return feature ? feature.title : '';
    },
    /** 按套餐顺序返回金币图标：0=small, 1=mid, 2=more；选中用金色，未选中用 -no */
    getPlanCoinIcon(plan, index) {
      const isSelected = plan.rechargeId === this.selectedPlan.rechargeId;
      const icons = [
        [require('@/assets/image/premium/ic-recharge-small@2x.png'), require('@/assets/image/premium/ic-recharge-small-no@2x.png')],
        [require('@/assets/image/premium/ic-recharge-mid@2x.png'), require('@/assets/image/premium/ic-recharge-mid-no@2x.png')],
        [require('@/assets/image/premium/ic-recharge-more@2x.png'), require('@/assets/image/premium/ic-recharge-more-no@2x.png')]
      ];
      const pair = icons[index % 3] || icons[0];
      return isSelected ? pair[0] : pair[1];
    },
    /** 套餐赠送金币数 */
    getPlanFreeCoins(plan) {
      return  Number(plan.checkinTotalCoin);
    },
    formatPlanFreeCoins(num) {
      const n = Number(num);
      if (Number.isNaN(n)) return '0';
      return n.toLocaleString();
    },
    goBack() {
      this.$router.back();
    },
    selectPlan(plan, index) {
      if (this.selectedPlan.rechargeId === plan.rechargeId) {
        // 即使选中同一个，也要滚动到中间
        this.scrollToPlan(index)
        return
      }
      this.selectedPlan = plan
      this.scrollToPlan(index)
    },
    scrollToPlan(index) {
      this.$nextTick(() => {
        const container = this.$refs.planCarousel
        if (!container) {
          // 如果容器还没准备好，延迟重试
          setTimeout(() => this.scrollToPlan(index), 100)
          return
        }
        const cards = container.querySelectorAll('.plan-card')
        const card = cards[index]
        if (!card) {
          // 如果卡片还没准备好，延迟重试
          setTimeout(() => this.scrollToPlan(index), 100)
          return
        }
        const containerWidth = container.clientWidth
        const cardWidth = card.clientWidth
        const cardLeft = card.offsetLeft
        let target = cardLeft - (containerWidth - cardWidth) / 2
        const max = container.scrollWidth - containerWidth
        if (target < 0) target = 0
        if (target > max) target = max
        if (container.scrollTo) {
          container.scrollTo({left: target, behavior: 'smooth'})
        } else {
          container.scrollLeft = target
        }
      })
    },
    onContinue() {
      // 判断是否选择了
      if (!this.selectedPlan || !this.selectedPlan.rechargeId || !this.selectedPlan.productCode) {
        toast("Please select a plan");
        return;
      }

      // 移除 showLoading()，现在在内部统一调用
      const rechargeType = Number(this.selectedPlan && this.selectedPlan.rechargeType) || 0;
      const payType = rechargeType === 2 ? 'paypal' : 'apple';

      /// 埋点
      tdTrack(EVENT_NAME.vip_buy, {'from':this.from,'price':this.selectedPlan.price,'paymethod':payType})
      requestPay(this.selectedPlan.productCode, payType, this.selectedPlan.rechargeId).then((dat) => {
        // 移除 PayPal 的外部处理，现在在内部统一处理
        if (payType !== 'paypal') {
          if (dat && dat.code === 0) {
            toast("Success");
            store.dispatch('GetInfo');
            // 弹窗模式下触发 close 事件，页面模式下返回上一页
            if (this.isDialog) {
              this.$emit('close');
            } else {
              this.$router.back();
            }
          }
        }
      }).catch(() => {
        // 错误处理
      }).finally(() => {
        // 统一在 finally 中执行 hideLoading
        hideLoading();
      });
    },
    onGoodsSearch() {
      const packageName = (getCurrentUsrPackageName() || '').toUpperCase();
      const rechargeTypes = packageName === 'A0019' ? [0] : [0, 2];
      getRechargeList(rechargeTypes, 1).then(res => {
        if (res.code === 200 && res.data !== null) {
          this.plans = res.data
          // 优先选择 isRecommend 为 true 的计划
          const recommendPlan = this.plans.find(plan => plan.isRecommend)
          let selectedPlan
          if (recommendPlan) {
            selectedPlan = recommendPlan
          } else {
            // 如果没有推荐计划，尝试保持之前选中的计划，否则选择第一个
            selectedPlan = this.plans.find(plan => plan.rechargeId === this.selectedPlan.rechargeId) || this.plans[0]
          }
          this.selectedPlan = selectedPlan

          // 自动滚动到选中的计划
          this.$nextTick(() => {
            this.$nextTick(() => {
              setTimeout(() => {
                const index = this.plans.findIndex(plan => plan.rechargeId === selectedPlan.rechargeId)
                if (index !== -1) {
                  this.scrollToPlan(index)
                }
              }, 150)
            })
          })
        }
      })
    },
  },
}
</script>

<style scoped lang="scss">
// 弹窗模式样式
.is-dialog-mode {
  background: transparent !important;
  min-height: auto !important;
}

.premium-container {
  min-height: calc(100vh - 60px);
  box-sizing: border-box;
  margin-top: 0;
  padding-top: 0;
  position: relative;
}

// 弹窗模式下的容器样式
.dialog-container {
  min-height: auto;
  padding-bottom: 20px;
}

.back-button {
  position: fixed;
  top: calc(30px + constant(safe-area-inset-top)); /* iOS < 11.2，顶部间距 + 安全区域 */
  top: calc(30px + env(safe-area-inset-top)); /* 顶部间距 + 安全区域 */
  left: 10px;
  z-index: 1000;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;

  .back-icon {
    width: 30px;
    height: 30px;
    object-fit: contain;
  }

  background: rgba(0, 0, 0, 0.5);
  border-radius: 18px;
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background: rgba(0, 0, 0, 0.7);
  }

  &:active {
    transform: scale(0.95);
  }

  i {
    font-size: 20px;
    color: #ffffff;
    font-weight: bold;
  }
}

.plan-carousel {
  margin-top: 10px;
  width: 100%;
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  gap: 16px;
}

.plan-carousel::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

.plan-carousel-padding-left,
.plan-carousel-padding-right {
  flex: 0 0 8px;
}

.plan-card {
  position: relative;
  flex: 0 0 252px;
  height: 249px;
  border-radius: 20px;
  background: transparent;
  border: 2px solid #333333;
  scroll-snap-align: center;
  transition: all 0.25s ease;
  text-align: start;
}

.plan-card-item {
  margin: 0 20px;
  color: #666666;
  font-size: 15px;
}

.item-desc {
  margin-top: 22px;
  font-size: 15px;
  font-weight: 500;
}

.item-sel-img {
  position: absolute;
  top: 18px;
  right: 16px;
  width: 26px;
  height: 26px;
}

.plan-card-selected {
  background: #141414;
  border: 2px solid #E2BB77;
}

.savings-badge {
  position: absolute;
  right: 16px;
  bottom: 30px;
  padding: 4px 8px;
  border-radius: 4px;
  background: #333333;
  color: #999999;
  text-align: center;

  span {
    font-size: 16px;
    font-weight: 600;
  }
}

.savings-badge-selected {
  background: #FD8303;
  color: #fff;
}

.plan-duration {
  position: absolute;
  top: 60px;
  font-size: 36px;
  font-weight: 600;
  line-height: 1.2;
  color: #999999;
}

.plan-duration-selected {
  color: white;
}

/* 距离 vipName(plan-duration) 底部 10px：60px + 36px*1.2 + 10px ≈ 113px */
.plan-price-week {
  position: absolute;
  top: 113px;
  font-size: 16px;
  font-weight: 500;
  color: #999999;
  color: rgba(255, 255, 255, 0.6);
}

.plan-price-week-selected {
  color: #FFFFFF;
}

/* Get Free：内容撑开宽高，与上方文字左对齐 */
.plan-get-free {
  position: absolute;
  left: 20px;
  bottom: 12px;
  width: max-content;
  min-height: 44px;
  border-radius: 10px;
  background: linear-gradient(to right, rgb(20, 20, 20) 0%, rgb(113, 113, 113) 100%);
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 14px 4px 0;
  box-sizing: border-box;
  transition: background 0.25s ease;
}

.plan-get-free-selected {
  background: linear-gradient(to right, rgb(20, 20, 20) 0%, rgb(157, 97, 8) 100%);
}

.plan-get-free-coin-icon {
  width: 36px;
  height: 36px;
  object-fit: contain;
  flex-shrink: 0;
}

.plan-get-free-text-wrap {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
}

.plan-get-free-text {
  font-size: 10px;
  font-weight: 500;
  color: #ffffffb7;
  line-height: 1.2;
}

.plan-get-free-amount {
  font-size: 16px;
  font-weight: 500;
  color: #fff;
  line-height: 1.2;
}

.cta-button {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  width: 80%;
  height: 54px;
  border-radius: 20px;
  background-image: url('@/assets/image/global/ic-pre-button-bg.png');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 20px;
}

.hero-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 10px;
  margin-top: 0;
  padding-top: 0;
}

.top-features {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  margin-top: 0;
  padding-top: 0;
}

.premium-detail-swiper {
  width: 100%;
  height: 380px;
  display: flex;
  justify-content: flex-start;
  align-items: center;
  box-sizing: border-box;
}

.premium-detail-swiper ::v-deep .m-swiper__container {
  padding-bottom: 0;
  box-sizing: border-box;
}

.premium-detail-swiper ::v-deep .m-swiper__wrapper,
.premium-detail-swiper ::v-deep .m-swiper__slide {
  align-items: flex-start;
  justify-content: flex-start;
}

.premium-swiper-dots {
  flex-shrink: 0;
  margin-top: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.premium-swiper-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #4B4B4B;
  opacity: 0.8;
}

.premium-swiper-dot-active {
  background: #FFFFFF;
  opacity: 1;
  transform: scale(1.2);
}

.top-grid {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.hero-icon {
  width: 100%;
  height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hero-icon-img {
  width: 100%;
  height: 300px;
  object-fit: cover;
}

.hero-title {
  margin: 8px 0 0;
  font-size: 24px;
  line-height: 1.2;
  font-weight: 700;
  padding-left: 20px;
  padding-right: 20px;
  color: white;
}

.hero-subtitle {
  margin-top: 6px;
  margin-bottom: 0;
  color: #666666;
  font-size: 14px;
  line-height: 1.4;
  max-width: 260px;
  padding-left: 20px;
  padding-right: 20px;
}

@media (max-width: 360px) {
  .premium-detail-swiper {
    height: 360px;
  }

  .premium-detail-swiper ::v-deep .m-swiper__container {
    padding-bottom: 0;
  }

  .hero-icon,
  .hero-icon-img {
    height: 260px;
  }

  .hero-title {
    font-size: 18px;
  }

  .hero-subtitle {
    font-size: 12px;
    margin-bottom: 0;
    max-width: 240px;
  }

}


.feature-section {
  margin: 40px 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 40px;
}

.feature-category {
  position: relative;
  border: 2px dashed #272727;
  border-radius: 12px;
  padding: 20px;
  background: transparent;
}

.category-title-wrapper {
  position: absolute;
  top: -12px;
  left: 50%;
  transform: translateX(-50%);
  background: #141414;
  padding: 0 12px;
}

.category-title {
  margin: 0;
  font-size: 14px;
  color: #666666;
  text-align: center;
  white-space: nowrap;
}

.feature-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
}

.feature-icon {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.checkmark-img {
  width: 20px;
  height: 20px;
  object-fit: contain;
}

.feature-content {
  flex: 1;
  text-align: left;
}

.feature-name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #717171;
  line-height: 1.4;
}

.feature-desc {
  display: none;
}

</style>
