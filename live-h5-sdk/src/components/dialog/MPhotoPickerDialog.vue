<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'photo-picker-dialog'">
    <div class="dialog-content">
      <div class="action-buttons-group">
        <div class="action-btn" @click="handleTakePhoto">
          Take Photo
        </div>
        <div class="action-btn" @click="handlePhotoLibrary">
          Photo Library
        </div>
      </div>
      <div class="action-btn cancel-btn" @click="handleCancel">
        Cancel
      </div>
    </div>
    <!-- 底部透明占位，用于间距和安全区域 -->
    <div class="bottom-spacer"></div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MPhotoPickerDialog",
  components: { MBottomDialog },
  props: {
    onTakePhoto: {
      type: Function,
      default: () => {}
    },
    onPhotoLibrary: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    }
  },
  methods: {
    handleTakePhoto() {
      if (this.onTakePhoto) {
        this.onTakePhoto();
      }
      this.closeDialog();
    },
    handlePhotoLibrary() {
      if (this.onPhotoLibrary) {
        this.onPhotoLibrary();
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
  display: flex;
  flex-direction: column;
  align-items: center;
}

.action-buttons-group {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 20px;
  width: 100%;
  margin-bottom: 12px;
}

.bottom-spacer {
  width: 100%;
  height: calc(15px + constant(safe-area-inset-bottom)); /* iOS < 11.2，底部间距 15px + 安全区域 */
  height: calc(15px + env(safe-area-inset-bottom)); /* 底部间距 15px + 安全区域 */
  flex-shrink: 0;
  background: transparent;
}

.action-buttons-group .action-btn {
  width: 100%;
  text-align: center;
  background-color: #404040;
  height: 54px;
  font-size: 16px;
  font-weight: 500;
  color: white;
  cursor: pointer;
  transition: background-color 0.2s;
  border: none;
  box-sizing: border-box;
  border-radius: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:active {
    background-color: #2a2a2a;
  }
}

.action-btn.cancel-btn {
  width: 100%;
  text-align: center;
  background-color: #282828;
  height: 54px;
  font-size: 16px;
  font-weight: 500;
  color: white;
  cursor: pointer;
  transition: background-color 0.2s;
  border: none;
  box-sizing: border-box;
  border-radius: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:active {
    background-color: #333;
  }
}
</style>

<style lang="less">
/* 覆盖 MBottomDialog 的 border-radius: 0，让 photo-picker-dialog 的圆角生效 */
.photo-picker-dialog.d-bottom {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.photo-picker-dialog.d-bottom .el-dialog {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.photo-picker-dialog.d-bottom .el-dialog__body {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
}

.photo-picker-dialog.d-bottom .move-wrap {
  border-radius: 20px 20px 0 0 !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
}

</style>
