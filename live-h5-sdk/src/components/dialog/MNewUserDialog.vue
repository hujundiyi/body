<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'new-user-dialog'">
    <div class="new-user-content">
      <!-- 主图形 -->
      <div class="graphic-container">
        <div class="graphic-wrapper">
          <img class="graphic-icon" src="@/assets/image/dialog/ic-dialog-new-user-icon.png" alt="">
        </div>
      </div>

      <!-- 标题 -->
      <div class="title-section">
        <img class="title-section-img" src="@/assets/image/dialog/ic-dialog-new-user-title.png" alt="">
      </div>

      <!-- 特性卡片 -->
      <div class="features-section">
        <img src="@/assets/image/dialog/ic-dialog-new-user-item-1.png" alt="Match Instantly" class="feature-image"/>
        <img src="@/assets/image/dialog/ic-dialog-new-user-item-2.png" alt="Faster Matching" class="feature-image"/>
        <img src="@/assets/image/dialog/ic-dialog-new-user-item-3.png" alt="Video Quality" class="feature-image"/>
      </div>

      <!-- 底部按钮和信息 -->
      <div class="bottom-section">
        <button class="match-button" @click="handleMatchNow">Match Now</button>
        <p class="info-text">
          <span class="highlight-number">{{ randomNumber }}</span> people ready<br>for 1-on-1 video chats
        </p>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";

export default {
  name: "MNewUserDialog",
  components: { MBottomDialog },
  props: {
    onMatch: {
      type: Function,
      default: null
    }
  },
  data() {
    return {
      randomNumber: '',
      randomTimer: null
    }
  },
  created() {
    this.generateRandomNumber();
  },
  mounted() {
    // 每3秒更新一次随机数
    this.randomTimer = setInterval(() => {
      this.generateRandomNumber();
    }, 3000);
  },
  beforeDestroy() {
    // 清理定时器
    if (this.randomTimer) {
      clearInterval(this.randomTimer);
      this.randomTimer = null;
    }
    console.error("存储缓存标记，表示已经显示过")
    // 存储缓存标记，表示已经显示过
    cache.local.set(key_cache.dialog_show_new_user, '1');
  },
  methods: {
    generateRandomNumber() {
      const min = 1500;
      const max = 1600;
      const number = Math.floor(Math.random() * (max - min + 1)) + min;
      this.randomNumber = number.toLocaleString();
    },
    handleMatchNow() {
      if (this.onMatch) {
        this.onMatch();
      }
      this.closeDialog();
    },
    closeDialog() {
      // 存储缓存标记，表示已经显示过
      cache.local.set(key_cache.dialog_show_new_user, '1');

      if (this.$refs.bottomDialog) {
        this.$refs.bottomDialog.closeDialog();
      }
    }
  }
}
</script>

<style scoped lang="less">
.new-user-content {
  width: 100%;
  padding: 40px 20px 30px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 500px;
}

.graphic-container {
  margin-bottom: 30px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.graphic-wrapper {
  position: relative;
  width: 120px;
  height: 120px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.graphic-icon {
  width: 185px;
  height: 146px;
}

.play-button {
  width: 0;
  height: 0;
  border-left: 20px solid #ff6b35;
  border-top: 12px solid transparent;
  border-bottom: 12px solid transparent;
  margin-left: 4px;
  z-index: 1;
}

.title-section {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 40px;
  width: 100%;

  .title-section-img {
    width: 323px;
    height: 18px;
  }
}

.features-section {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
  margin-bottom: 50px;
  padding: 0 10px;
}

.feature-image {
  width: 105px;
  height: 133px;
  object-fit: contain;
}

.bottom-section {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding-bottom: calc(30px + constant(safe-area-inset-bottom));
  padding-bottom: calc(30px + env(safe-area-inset-bottom));
}

.match-button {
  width: 100%;
  max-width: 290px;
  height: 54px;
  background: #ffffff;
  color: #000000;
  font-size: 18px;
  font-weight: 700;
  border: 2px solid transparent;
  border-radius: 28px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: visible;
  box-shadow: 0 4px 20px rgba(118, 75, 162, 0.3);
  
  &::before {
    content: '';
    position: absolute;
    left: 0px;
    right: 0px;
    border-radius: 32px;
    border: 2px solid rgba(255, 255, 255, 0.5);
    z-index: -1;
    animation: buttonPulse 2s ease-in-out infinite;
  }
  
  &::after {
    content: '';
    position: absolute;
    left: -4px;
    right: -4px;
    border: 2px solid rgba(255, 255, 255, 0.2);
    border-radius: 34px;
    z-index: -2;
    animation: buttonGlow 2s ease-in-out infinite;
  }
  
  &:active {
    transform: scale(0.98);
    opacity: 0.9;
  }
}

@keyframes buttonPulse {
  0%, 100% {
    top: -2px;
    bottom: -2px;
    left: 0px;
    right: 0px;
    opacity: 1;
    transform: scaleX(1) scaleY(1);
  }
  50% {
    top: -9px;
    bottom: -9px;
    left: 0px;
    right: 0px;
    opacity: 0.8;
    transform: scaleX(1.08) scaleY(1.08);
  }
}

@keyframes buttonGlow {
  0%, 100% {
    top: -6px;
    bottom: -6px;
    left: -4px;
    right: -4px;
    opacity: 0.3;
    transform: scaleX(1) scaleY(1);
  }
  50% {
    top: -16px;
    bottom: -16px;
    left: -4px;
    right: -4px;
    opacity: 0.6;
    transform: scaleX(1.12) scaleY(1.12);
  }
}

.info-text {
  margin-top: 10px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  text-align: center;
}

.highlight-number {
  color: #ffa500;
  font-weight: 700;
}
</style>

<style>
.new-user-dialog {
  background-image: url('@/assets/image/dialog/ic-dialog-new-user-bg.png') !important;
  background-size: cover !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  backdrop-filter: blur(20px);
}

.new-user-dialog.d-bottom {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.new-user-dialog.d-bottom .el-dialog {
  background: transparent !important;
  box-shadow: none !important;
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.new-user-dialog.d-bottom .el-dialog__body {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.new-user-dialog.d-bottom .move-wrap {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.new-user-dialog .v-modal {
  background: rgba(0, 0, 0, 0.3) !important;
}
</style>
