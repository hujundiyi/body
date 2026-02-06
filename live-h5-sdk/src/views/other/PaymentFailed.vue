<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="title" :show-back="false"/>
    </template>
    <template #page-content-wrap>
      <div class="payment-result-container">
        <div class="result-content">
          <!-- 失败图标 -->
          <div class="icon-wrapper failed">
            <svg class="failed-icon" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
              <circle cx="50" cy="50" r="45" fill="none" stroke="#f44336" stroke-width="4"/>
              <path d="M35 35 L65 65 M65 35 L35 65" stroke="#f44336" stroke-width="6" stroke-linecap="round"/>
            </svg>
          </div>
          
          <!-- 标题 -->
          <h2 class="result-title">Payment Failed</h2>
          
          <!-- 描述 -->
          <p class="result-description">{{ errorMessage }}</p>
          
          <!-- 倒计时 -->
          <p class="countdown-text">Auto close in {{ countdown }}s</p>
          
          <!-- 按钮 -->
          <div class="button-group">
            <button class="btn-secondary" @click="handleCancel">Cancel</button>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import clientNative from "@/utils/ClientNative";

export default {
  name: 'PaymentFailed',
  data() {
    return {
      title: 'Payment Result',
      errorMessage: 'Your payment could not be processed. Please try again.',
      countdown: 5,
      countdownTimer: null
    };
  },
  mounted() {
    // 从路由参数获取错误信息
    if (this.$route.query.message) {
      this.errorMessage = decodeURIComponent(this.$route.query.message);
    }
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
    handleCancel() {
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
  
  &.failed {
    .failed-icon {
      width: 100%;
      height: 100%;
      animation: shake 0.5s ease-out;
    }
  }
}

@keyframes shake {
  0%, 100% {
    transform: translateX(0);
  }
  10%, 30%, 50%, 70%, 90% {
    transform: translateX(-5px);
  }
  20%, 40%, 60%, 80% {
    transform: translateX(5px);
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
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.btn-primary {
  width: 100%;
  height: 50px;
  background: #f44336;
  color: #ffffff;
  border: none;
  border-radius: 25px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    background: #da190b;
  }
  
  &:hover {
    background: #da190b;
    box-shadow: 0 4px 12px rgba(244, 67, 54, 0.3);
  }
}

.btn-secondary {
  width: 100%;
  height: 50px;
  background: transparent;
  color: #666666;
  border: 2px solid #e0e0e0;
  border-radius: 25px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    background: #f5f5f5;
  }
  
  &:hover {
    background: #f5f5f5;
    border-color: #bdbdbd;
  }
}
</style>
