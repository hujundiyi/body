<template>
  <m-base-dialog ref="baseDialog" :click-mask-close-dialog="true" dialog-class="purchase-success-dialog">
    <template #content>
      <div class="purchase-success-container">
        <!-- 右上角金币图标 -->
        <div class="coin-decoration">
          <img src="@/assets/image/premium/ic-recharge-top-get@2x.png" alt="Coin" class="coin-decoration-icon" />
        </div>

        <!-- 标题 -->
        <div class="success-title">
          <div>PURCHASE</div>
          <div>SUCCESSFUL!</div>
        </div>

        <!-- 主消息 -->
        <div class="success-message">You've received:</div>

        <!-- 收到的金额 -->
        <div class="received-amount">
          <img 
            :src="coinIcons.more" 
            alt="Coin" 
            class="received-coin-icon"
          />
          <span class="amount-text">{{ formatNumber(receivedData.coins) }}</span>
        </div>

        <!-- 功能列表：固定 Feed Filters / Match Filters / Album Videos，仅数量由外部传入 -->
        <div class="benefits-list">
          <div 
            v-for="(item, index) in benefitItems" 
            :key="index" 
            class="benefit-item"
            :class="{ 'clickable': index === 0 || index === 1 || index === 2 }"
            @click="handleBenefitClick(index, item.text)"
          >
            <img 
              v-if="item.icon" 
              :src="item.icon" 
              alt="Benefit Icon" 
              class="benefit-icon"
            />
            <span v-html="formatBenefitText(item.text)"></span>
          </div>
        </div>

        <!-- 提示文字 -->
        <div class="instruction">
          <span>👆Click above to use your benefits!</span>
        </div>

        <!-- OK 按钮 -->
        <button class="ok-button" @click="closeDialog">
          OK
        </button>
      </div>
    </template>
  </m-base-dialog>
</template>

<script>
import MBaseDialog from "@/components/dialog/MBaseDialog.vue";
import {closeAllDialogs, showUserListFilterDialog, showCountryFilterDialog} from "@/components/dialog";

export default {
  name: 'MPurchaseSuccessDialog',
  components: { MBaseDialog },
  props: {
    receivedData: {
      type: Object,
      default() {
        return { coins: 96000, quantities: [5, 5, 10] };
      }
    }
  },
  data() {
    return {
      coinIcons: {
        more: require('@/assets/image/premium/ic-recharge-more@2x.png')
      },
      labels: ['Feed Filters', 'Match Filters', 'Album Videos'],
      icons: [
        require('@/assets/image/premium/ic-recharge-feed-get@2x.png'),
        require('@/assets/image/premium/ic-recharge-match-get@2x.png'),
        require('@/assets/image/premium/ic-recharge-alum-get@2x.png')
      ]
    }
  },
  computed: {
    benefitItems() {
      const q = this.receivedData.quantities || [];
      return this.labels.map((label, i) => {
        const n = Math.max(0, Number(q[i]) || 0);
        return {
          text: `${label} x${n}>>>`,
          icon: this.icons[i] || null
        };
      });
    }
  },
  methods: {
    closeDialog() {
      this.$refs.baseDialog.handleClose();
    },
    formatNumber(num) {
      return num.toLocaleString();
    },
    formatBenefitText(benefit) {
      // 将 x5>>>, x10>>> 等数字和箭头部分添加下划线
      return benefit.replace(/([xX]\d+>>>)/g, '<span class="benefit-arrow">$1</span>');
    },
    handleBenefitClick(index, benefit) {
      closeAllDialogs();
      this.$refs.baseDialog.dialogVisible = false;

      const run = (fn) => {
        this.$nextTick(() => {
          setTimeout(fn, 200);
        });
      };

      if (index === 0) {
        run(() => {
          this.$router.push('/sdk/me').then(() => {
            this.$nextTick(() => {
              setTimeout(() => {
                showUserListFilterDialog({ onConfirm: () => {}, onCancel: () => {} });
              }, 300);
            });
          }).catch(() => {});
        });
      } else if (index === 1) {
        run(() => {
          this.$router.push('/sdk/match').then(() => {
            this.$nextTick(() => {
              setTimeout(() => showCountryFilterDialog(() => {}), 300);
            });
          }).catch(() => {});
        });
      } else if (index === 2) {
        run(() => {
          this.$router.push('/sdk/me').catch(() => {});
        });
      }
    }
  }
}
</script>

<style scoped lang="scss">
.purchase-success-container {
  position: relative;
  background: linear-gradient(180deg, #FFE9AE 0%, #FFFFFF 100%); // 从#FFE9AE 100%到#FFFFFF 100%的渐变
  border-radius: 24px;
  padding: 32px 24px 24px;
  box-sizing: border-box;
  width: 100%;
  max-width: 375px;
  margin: 0 auto;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  overflow: visible; // 确保装饰图标不被裁切
  min-height: 400px;
}

// 右上角金币装饰
.coin-decoration {
  position: absolute;
  top: -40px; // 调整位置，确保图标不被裁切
  right: -20px; // 调整位置，确保图标不被裁切
  z-index: 10;
  
  .coin-decoration-icon {
    width: 145px;
    height: 120px;
    object-fit: contain;
    display: block;
  }
}

// 标题
.success-title {
  font-size: 24px;
  font-weight: 700;
  color: #8B6914; // 金色文字
  text-align: left; // 左对齐
  margin-bottom: 16px;
  letter-spacing: 0.5px;
  line-height: 1.2; // 行高，确保两行之间有适当间距
}

// 主消息
.success-message {
  font-size: 16px;
  font-weight: 400;
  color: #B99756; // 改为#B99756
  text-align: left; // 左对齐
  margin-bottom: 12px;
}

// 收到的金额
.received-amount {
  display: flex;
  align-items: center;
  justify-content: flex-start; // 左对齐
  gap: 8px;
  margin-bottom: 24px;
  
  .received-coin-icon {
    width: 32px;
    height: 32px;
    object-fit: contain;
  }
  
  .amount-text {
    font-size: 22px; // 字号改为22
    font-weight: 700;
    color: #000; // 改为黑色
  }
}

// 功能列表
.benefits-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 20px;
  
  .benefit-item {
    display: flex;
    align-items: center;
    gap: 8px;
    color: #000; // 改为黑色
    font-size: 16px; // 字号改为16
    text-decoration: underline; // 整个文字都加上下划线
    font-weight: 500;
    
    &.clickable {
      cursor: pointer;
      transition: opacity 0.2s;
      
      &:active {
        opacity: 0.7;
      }
    }
    
    .benefit-icon {
      width: 30px;
      height: 30px;
      object-fit: contain;
      flex-shrink: 0;
    }
  }
}

// 提示文字
.instruction {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
  color: #B99756; // 改为#B99756
  font-size: 14px;
}

// OK 按钮
.ok-button {
  width: 100%;
  height: 50px;
  background: url('@/assets/image/premium/ic-recharge-btnbg@2x.png') no-repeat center;
  background-size: cover;
  border: none;
  border-radius: 25px;
  color: #000;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    box-shadow: 0 4px 20px rgba(212, 175, 55, 0.4);
  }
}
</style>

<style lang="scss">
// 全局样式，确保弹窗居中显示
.purchase-success-dialog {
  .m-dialog {
    position: absolute !important;
    top: 50% !important;
    left: 50% !important;
    transform: translate(-50%, -50%) !important;
    bottom: auto !important;
    max-width: 375px !important;
    width: calc(100% - 40px) !important;
    border-radius: 24px !important;
    overflow: visible !important; // 确保装饰图标不被裁切
  }
  
  .m-dialog-body {
    padding: 0 !important;
    border-radius: 24px !important;
    overflow: visible !important; // 确保装饰图标不被裁切
  }
  
  .benefit-item {
    .benefit-arrow {
      text-decoration: underline;
      color: #000; // 下划线改为黑色
    }
  }
}
</style>
