<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar title=""/>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <div class="content">
          <h1 class="page-title">Delete Account</h1>
          <div class="warning-text white-text">
            <p>
              Once confirmed, your account will be permanently deactivated and cannot be recovered. All data, including
              your profile, messages, friends, and memberships, will be permanently deleted.
              This action cannot be undone.
            </p>
          </div>

          <div class="warning-text red-text">
            <p>
              For platform safety and user authenticity, you cannot re-register within 30 days after deleting your
              account.
            </p>
          </div>
        </div>

        <!-- 底部固定区域 -->
        <div class="bottom-section">
          <div class="acknowledge-section">
            <div class="checkbox-wrapper" @click="toggleAcknowledge">
              <img
                :src="isAcknowledged ? getSelectIcon : getUnselectIcon"
                class="checkbox-icon"
                alt="checkbox"
              />
              <span class="acknowledge-text">I understand this will permanently delete my account.</span>
            </div>
          </div>

          <div class="action-buttons">
            <div
                class="confirm-btn"
                :class="{ disabled: !canConfirm }"
                @click="handleConfirm"
            >
              {{ confirmButtonText }}
            </div>
            <div class="cancel-btn" @click="handleCancel">
              Cancel
            </div>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import { delUser } from "@/api/sdk/user";
import clientNative from "@/utils/ClientNative";
import cache from "@/utils/cache";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'DeleteAccount',
  data() {
    return {
      isAcknowledged: false,
      countdown: 0,
      countdownTimer: null,
      reason: 1, // 默认删除原因
      desc: '' // 删除描述
    }
  },
  computed: {
    getSelectIcon() {
      return require('@/assets/image/edit/ic-ed-d-select.png');
    },
    getUnselectIcon() {
      return require('@/assets/image/edit/ic-ed-d-unselect.png');
    },
    canConfirm() {
      return this.isAcknowledged && this.countdown === 0;
    },
    confirmButtonText() {
      if (this.countdown > 0) {
        return `Confirm(${this.countdown}s)`;
      }
      return 'Confirm';
    }
  },
  activated() {
    this.resetState();
  },
  beforeDestroy() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = null;
    }
  },
  methods: {
    resetState() {
      if (this.countdownTimer) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = null;
      }
      this.isAcknowledged = false;
      this.countdown = 0;
    },
    toggleAcknowledge() {
      this.isAcknowledged = !this.isAcknowledged;
      if (this.isAcknowledged) {
        if (this.countdownTimer) {
          clearInterval(this.countdownTimer);
        }
        this.countdown = 10;
        this.startCountdown();
      } else {
        if (this.countdownTimer) {
          clearInterval(this.countdownTimer);
          this.countdownTimer = null;
        }
        this.countdown = 0;
      }
    },
    startCountdown() {
      this.countdownTimer = setInterval(() => {
        if (this.countdown > 0) {
          this.countdown--;
        } else {
          clearInterval(this.countdownTimer);
          this.countdownTimer = null;
        }
      }, 1000);
    },
    handleConfirm() {
      if (!this.canConfirm) return;

      // 直接调用删除账号 API
      const params = {
        reason: this.reason,
        desc: this.desc || 'User requested account deletion'
      };

      delUser(params).then((rsp) => {
        if (rsp && (rsp.success || rsp.code === 200 || rsp.code === 0)) {
          showCallToast('Account deleted successfully');
          // 调用原生 toLogin 方法
          setTimeout(() => {
            clientNative.toLogin();
            cache.local.clearAllCache();
          }, 1500);
        } else {
          showCallToast('Failed to delete account');
        }
      }).catch((err) => {
        console.error('Delete account error:', err);
        showCallToast('Failed to delete account');
      });
    },
    handleCancel() {
      this.$router.back();
    }
  }
}
</script>

<style scoped lang="less">
/* 顶部安全区域适配 */
/deep/ .m-action-bar {
  padding-top: constant(safe-area-inset-top); /* iOS < 11.2，状态栏高度 */
  padding-top: env(safe-area-inset-top); /* 状态栏高度 */
}

.main {
  padding: 0;
  background-color: #141414;
  min-height: calc(100vh - 70px);
  box-sizing: border-box;
  position: relative;
}

.content {
  padding: 42px 24px 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  text-align: center;
  box-sizing: border-box;
}

.page-title {
  font-size: 18px;
  font-weight: bold;
  color: white;
  margin: 0;
  margin-bottom: 4px;
}

.warning-text {
  line-height: 1.5;
  p {
    margin: 0 0 8px;
    font-size: 14px;
    &:last-child {
      margin-bottom: 0;
    }
  }

  &.white-text {
    color: white;
  }

  &.red-text {
    color: #ff4d4f;
    font-weight: 500;
    margin-top: 4px;
  }
}

// 底部固定区域：从底部往上布局
.bottom-section {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #141414;
  padding: 20px 42px;
  padding-bottom: max(20px, calc(20px + env(safe-area-inset-bottom)));
  box-sizing: border-box;
  z-index: 1;
}

.acknowledge-section {
  margin-bottom: 20px;

  .checkbox-wrapper {
    display: flex;
    align-items: flex-start;
    cursor: pointer;
    gap: 12px;
    padding: 8px 0;

    .checkbox-icon {
      width: 20px;
      height: 20px;
      flex-shrink: 0;
      margin-top: 2px;
      object-fit: contain;
    }

    .acknowledge-text {
      flex: 1;
      color: white;
      font-size: 14px;
      line-height: 1.5;
      word-break: break-word;
    }
  }
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 12px;

  .confirm-btn {
    width: 100%;
    text-align: center;
    padding: 14px 0;
    border-radius: 27px;
    font-size: 16px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;

    &.disabled {
      background-color: #2a2a2a;
      color: white;
      opacity: 0.5;
      cursor: not-allowed;
    }

    &:not(.disabled) {
      background-color: white;
      color: #000000;

      &:active {
        background-color: #f0f0f0;
      }
    }
  }

  .cancel-btn {
    width: 100%;
    text-align: center;
    padding: 14px 0;
    background-color: #2a2a2a;
    border-radius: 27px;
    font-size: 16px;
    font-weight: 500;
    color: white;
    cursor: pointer;
    transition: background-color 0.2s;

    &:active {
      background-color: #333;
    }
  }
}
</style>

<style lang="less">
/* 防止 DeleteAccount 页面滚动 */
:deep(.m-page-content) {
  overflow: hidden !important;
  box-sizing: border-box !important;
}

:deep(.m-page-wrap) {
  overflow: hidden !important;
}
</style>


