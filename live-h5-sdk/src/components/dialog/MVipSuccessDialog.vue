<template>
  <m-base-dialog
    ref="baseDialog"
    :click-mask-close-dialog="true"
    :width="dialogWidth"
    dialog-class="vip-success-dialog"
  >
    <template #content>
      <div class="vip-success-content-wrap">
        <!-- 顶部插画：皇冠+金币（绝对定位悬浮在弹窗顶部，不占流） -->
        <div class="header-graphic-wrapper">
          <img
            src="@/assets/image/premium/ic-recharge-suc-top@2x.png"
            alt="VIP"
            class="crown-coins-img"
          />
        </div>

        <div class="vip-success-container">
        <!-- 标题 CONGRATS + 左右两侧装饰图 -->
        <div class="title-row">
          <img src="@/assets/image/premium/ic-recharge-suc-left@2x.png" alt="" class="title-decoration-img title-left" />
          <h2 class="main-title">CONGRATS</h2>
          <img src="@/assets/image/premium/ic-recharge-suc-right@2x.png" alt="" class="title-decoration-img title-right" />
        </div>

        <!-- 说明文案 -->
        <p class="subtitle">You're a Premium Member.</p>
        <p class="subtitle">{{ benefitsCount }} Benefits Activated.</p>
        <p class="reward-line">
          Check in for
          <span class="highlight">{{ consecutiveDays }} Consecutive Days</span>
          to fully claim your
          <span class="highlight">FREE {{ formatCoins(freeCoins) }} COINS</span>
          reward.
        </p>

        <!-- 按钮 -->
        <button class="go-checkin-btn" @click="handleGoCheckIn">
          Go Check In
        </button>
        </div>
      </div>
    </template>
  </m-base-dialog>
</template>

<script>
import MBaseDialog from '@/components/dialog/MBaseDialog.vue';
import { showCheckinDialog } from '@/components/dialog';

export default {
  name: 'MVipSuccessDialog',
  components: { MBaseDialog },
  props: {
    benefitsCount: {
      type: Number,
      default: 15
    },
    consecutiveDays: {
      type: Number,
      default: 0
    },
    freeCoins: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      dialogWidth: '90%'
    };
  },
  methods: {
    formatCoins(num) {
      if (num >= 1000) {
        return (num / 1000).toFixed(num % 1000 === 0 ? 0 : 1) + ',' + (num % 1000).toString().padStart(3, '0');
      }
      return String(num);
    },
    closeDialog() {
      if (this.$refs.baseDialog) {
        this.$refs.baseDialog.handleClose();
      }
    },
    handleGoCheckIn() {
      this.closeDialog();
      // 打开签到弹窗
      this.$nextTick(() => {
        setTimeout(() => {
          showCheckinDialog();
        }, 300);
      });
    }
  }
};
</script>

<style scoped lang="less">
.vip-success-content-wrap {
  position: relative;
  width: 100%;
  background: #fff;
  border-radius: 24px;
}

.header-graphic-wrapper {
  position: absolute;
  top: -100px;
  left: 0;
  right: 0;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: flex-end;
  z-index: 10;
  pointer-events: none;
}

.vip-success-container {
  position: relative;
  text-align: center;
  padding: 100px 0 24px 0;
  background: #fff;
  border-radius: 24px;
  overflow: hidden;
}

.crown-coins-img {
  max-width: 260px;
  width: 100%;
  height: auto;
  object-fit: contain;
  display: block;
}

.title-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-bottom: 8px;
  margin-top: 0px;
}

.title-decoration-img {
  height: 16px;
  width: auto;
  object-fit: contain;
  flex-shrink: 0;
}

.title-left {
  flex-shrink: 0;
}

.title-right {
  flex-shrink: 0;
}

.main-title {
  font-size: 26px;
  font-weight: 900;
  color: #333;
  margin: 0;
}

.subtitle {
  font-size: 15px;
  color: #888;
  margin: 0 0 6px;
}

.reward-line {
  font-size: 16px;
  color: #000;
  margin: 8px 16px 20px;
  line-height: 1.5;
  font-weight: 600;
}

.highlight {
  color: #D38900;
  font-weight: 600;
}

.go-checkin-btn {
  display: block;
  width: calc(100% - 40px);
  max-width: 280px;
  margin: 0 auto;
  height: 50px;
  border: none;
  border-radius: 25px;
  background: url('@/assets/image/premium/ic-recharge-btnbg@2x.png') no-repeat center;
  background-size: 100% 100%;
  color: #333;
  font-size: 17px;
  font-weight: 700;
  cursor: pointer;
}

.go-checkin-btn:active {
  opacity: 0.9;
  transform: scale(0.98);
}
</style>

<style lang="less">
.vip-success-dialog.m-dialog-wrapper {
  overflow: visible;
}
.vip-success-dialog.m-dialog-wrapper .m-dialog {
  border-radius: 24px;
  overflow: visible !important; /* 允许皇冠图超出弹窗顶部 */
  background: #fff;
}
.vip-success-dialog .m-dialog-body {
  padding: 0;
  overflow: visible !important;
  display: block;
  background: #fff; /* 与弹窗内容区统一为白色 */
}
</style>
