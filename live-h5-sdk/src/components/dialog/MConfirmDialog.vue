<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'confirm-dialog'">
    <div class="dialog-content">
      <div class="dialog-title" v-if="title">{{ title }}</div>
      <div class="dialog-message">
        {{ message }}
      </div>
      <div class="dialog-actions">
        <div class="cancel-btn" @click="handleCancel">
          {{ cancelText || 'Cancel' }}
        </div>
        <div class="confirm-text" @click="handleConfirm">
          {{ confirmText || 'End Video Chat' }}
        </div>
      </div>
    </div>
    <!-- 底部透明占位，用于间距和安全区域 -->
    <div class="bottom-spacer"></div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MConfirmDialog",
  components: { MBottomDialog },
  props: {
    title: {
      type: String,
      default: ''
    },
    message: {
      type: String,
      default: ''
    },
    confirmText: {
      type: String,
      default: 'End Video Chat'
    },
    cancelText: {
      type: String,
      default: 'Cancel'
    },
    onConfirm: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    }
  },
  methods: {
    handleConfirm() {
      if (this.onConfirm) {
        this.onConfirm();
      }
      this.closeDialog();
    },
    handleCancel() {
      if (this.onCancel) {
        this.onCancel();
      }
      this.closeDialog();
    },
    closeDialog() {
      this.$refs.bottomDialog.closeDialog();
    }
  }
}
</script>

<style scoped lang="less">
.dialog-content {
  background: #282828;
  border-radius: 30px;
  padding: 20px;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  text-align: center;
  margin: 0 20px;
  box-sizing: border-box;
  overflow: hidden;
  position: relative;
  z-index: 1;
}

.bottom-spacer {
  width: 100%;
  height: calc(15px + constant(safe-area-inset-bottom)); /* iOS < 11.2，底部间距 15px + 安全区域 */
  height: calc(15px + env(safe-area-inset-bottom)); /* 底部间距 15px + 安全区域 */
  flex-shrink: 0;
  background: transparent;
}

.dialog-title {
  font-size: 22px;
  font-weight: bold;
  color: #FFFFFF;
  margin-bottom: 16px;
  text-align: center;
}

.dialog-message {
  font-size: 16px;
  color: #999999;
  line-height: 1.5;
  margin-bottom: 28px;
  text-align: center;
  word-break: normal;
  overflow-wrap: break-word;
}

.dialog-actions {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: 0;
}

.cancel-btn {
  width: 100%;
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  background-color: white;
  border-radius: 27px;
  font-size: 16px;
  font-weight: 500;
  color: #000;
  cursor: pointer;
  transition: background-color 0.2s;
  box-sizing: border-box;
  
  &:active {
    background-color: #f0f0f0;
  }
}

.confirm-text {
  width: 100%;
  text-align: center;
  padding: 14px;
  background-color: transparent;
  font-size: 16px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.6);
  cursor: pointer;
  transition: color 0.2s;
  box-sizing: border-box;
  
  &:active {
    color: rgba(255, 255, 255, 0.8);
  }
}
</style>

<style lang="less">
/* 覆盖 MBottomDialog 的 border-radius: 0，让 confirm-dialog 的圆角生效 */
.confirm-dialog.d-bottom {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.confirm-dialog.d-bottom .el-dialog {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.confirm-dialog.d-bottom .el-dialog__body {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.confirm-dialog.d-bottom .move-wrap {
  border-radius: 30px !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
}
</style>
