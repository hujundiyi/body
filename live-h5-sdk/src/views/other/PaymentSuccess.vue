<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="title" :show-back="false"/>
    </template>
    <template #page-content-wrap>
      <div class="payment-result-container">
        <div class="result-content">
          <!-- 成功图标 -->
          <div class="icon-wrapper success">
            <svg class="success-icon" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
              <circle cx="50" cy="50" r="45" fill="none" stroke="#4CAF50" stroke-width="4"/>
              <path d="M30 50 L45 65 L70 35" fill="none" stroke="#4CAF50" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          
          <!-- 标题 -->
          <h2 class="result-title">Payment Successful</h2>
          
          <!-- 描述 -->
          <p class="result-description">Your payment has been processed successfully</p>
          
          <!-- 倒计时 -->
          <p class="countdown-text">Auto close in {{ countdown }}s</p>
          
          <!-- 按钮 -->
          <div class="button-group">
            <button class="btn-primary" @click="handleConfirm">Confirm</button>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import clientNative from "@/utils/ClientNative";

export default {
  name: 'PaymentSuccess',
  data() {
    return {
      title: 'Payment Result',
      countdown: 5,
      countdownTimer: null
    };
  },
  mounted() {
    this.startCountdown();
  },
  beforeDestroy() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = null;
    }
  },
  methods: {
    startCountdown() {
      this.countdownTimer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.countdownTimer);
          this.countdownTimer = null;
          this.closeWebView();
        }
      }, 1000);
    },
    closeWebView() {
      clientNative.closeWebView();
    },
    handleConfirm() {
      // 清除倒计时
      if (this.countdownTimer) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = null;
      }
      // 关闭 WebView
      this.closeWebView();
    }
  }
}
</script>

<style scoped lang="less">
.payment-result-container {
  min-height: calc(100vh - 70px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  background: #f5f5f5;
}

.result-content {
  width: 100%;
  max-width: 400px;
  text-align: center;
  background: #ffffff;
  border-radius: 20px;
  padding: 60px 30px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.icon-wrapper {
  margin: 0 auto 30px;
  width: 120px;
  height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &.success {
    .success-icon {
      width: 100%;
      height: 100%;
      animation: scaleIn 0.5s ease-out;
    }
  }
}

@keyframes scaleIn {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  50% {
    transform: scale(1.1);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.result-title {
  font-size: 28px;
  font-weight: 600;
  color: #333333;
  margin: 0 0 15px;
}

.result-description {
  font-size: 16px;
  color: #666666;
  margin: 0 0 20px;
  line-height: 1.5;
}

.countdown-text {
  font-size: 14px;
  color: #999999;
  margin: 0 0 40px;
}

.button-group {
  margin-top: 40px;
}

.btn-primary {
  width: 100%;
  height: 50px;
  background: #4CAF50;
  color: #ffffff;
  border: none;
  border-radius: 25px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    background: #45a049;
  }
  
  &:hover {
    background: #45a049;
    box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
  }
}
</style>
