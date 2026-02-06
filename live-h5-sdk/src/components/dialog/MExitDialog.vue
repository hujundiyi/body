<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'exit-dialog'">
    <div class="dialog-content">
      <div class="dialog-title">Exit</div>
      <div class="dialog-message">
        Are you sure you want to log out?
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
    <!-- 底部透明占位，用于间距和安全区域 -->
    <div class="bottom-spacer"></div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import store from "@/store";
import clientNative from "@/utils/ClientNative";

export default {
  name: "MExitDialog",
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

      // 调用原生 toLogin 方法
      clientNative.toLogin();
    },
    clearAllCache() {
      // 清除 localStorage 中的缓存
      cache.local.remove(key_cache.user_info);
      cache.local.remove(key_cache.user_backpack);
      cache.local.remove(key_cache.dict_data);
      cache.local.remove(key_cache.config_data);
      cache.local.remove(key_cache.launch_h5_data);

      // 清除 sessionStorage 中的所有缓存
      if (sessionStorage) {
        sessionStorage.clear();
      }

      // 清除 store 中的用户信息与背包
      if (store.state.user) {
        store.commit('user/SET_USERINFO', {msgNum: 0});
        store.commit('user/SET_USER_BACKPACK', []);
      }

      // 清除 store 中的页面缓存数据
      if (store.state.PageCache) {
        store.commit('PageCache/ADD_DICT', {});
        store.commit('PageCache/ADD_CONFIG', {});
      }
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
  color: white;
  margin-bottom: 6px;
}

.dialog-message {
  font-size: 16px;
  color: #999999;
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
/* 覆盖 MBottomDialog 的 border-radius: 0，让 exit-dialog 的圆角生效 */
.exit-dialog.d-bottom {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.exit-dialog.d-bottom .el-dialog {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.exit-dialog.d-bottom .el-dialog__body {
  border-radius: 30px !important;
  overflow: hidden !important;
}

.exit-dialog.d-bottom .move-wrap {
  border-radius: 30px !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
}

</style>
