<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'clean-cache-dialog'">
    <div class="dialog-content">
      <div class="dialog-title">Clean Cache</div>
      <div class="dialog-message">
        Are you sure you want to clear the cache?
      </div>
      <div class="dialog-actions">
        <div class="confirm-btn" @click="handleConfirm">
          Yes
        </div>
        <div class="cancel-btn" @click="handleCancel">
          Cancel
        </div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MCleanCacheDialog",
  components: { MBottomDialog },
  props: {
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
  padding-bottom: calc(30px + constant(safe-area-inset-bottom)) !important; /* iOS < 11.2 */
  padding-bottom: calc(30px + env(safe-area-inset-bottom)) !important;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  text-align: center;
  margin: 0 20px;
  box-sizing: border-box;
  overflow: hidden;
  position: relative;
  z-index: 1;
}

.dialog-title {
  font-size: 18px;
  font-weight: bold;
  color: white;
  margin-bottom: 16px;
}

.dialog-message {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.5;
  margin-bottom: 24px;
  text-align: center;
}

.dialog-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0 22px;
}

.confirm-btn {
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

.cancel-btn {
  width: 100%;
  text-align: center;
  padding: 14px;
  background-color: transparent;
  border-radius: 12px;
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
/* 覆盖 MBottomDialog 的 border-radius: 0，让 clean-cache-dialog 的圆角生效 */
.clean-cache-dialog.d-bottom {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.clean-cache-dialog.d-bottom .el-dialog {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.clean-cache-dialog.d-bottom .el-dialog__body {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.clean-cache-dialog.d-bottom .move-wrap {
  border-radius: 30px !important;
  overflow: hidden !important;
}

/* 确保 padding-bottom 生效 */
.clean-cache-dialog .dialog-content {
  padding-bottom: calc(30px + constant(safe-area-inset-bottom)) !important; /* iOS < 11.2 */
  padding-bottom: calc(30px + env(safe-area-inset-bottom)) !important;
}
</style>
