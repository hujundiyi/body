<template>
  <m-bottom-dialog ref="bottomDialog" :enable-swipe-close="false" dialog-class="premium-dialog-wrapper">
    <div class="premium-dialog-container">
      <!-- 关闭按钮（样式与 premium 页返回按钮一致） -->
      <img class="close-button" :src="closeIcon" alt="Close" @click="closeDialog"/>

      <!-- 直接引用 premium/index.vue 组件 -->
      <page-premium ref="premiumPage" :is-dialog="true" @close="closeDialog" />
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import PagePremium from "@/views/premium/index.vue";

export default {
  name: 'MPremiumDialog',
  components: { MBottomDialog, PagePremium },
  computed: {
    closeIcon() {
      return require('@/assets/image/ic-common-back.png');
    }
  },
  beforeDestroy() {
    this.$store.commit('PageCache/SET_PREMIUM_DIALOG_VISIBLE', false);
  },
  methods: {
    closeDialog() {
      this.$store.commit('PageCache/SET_PREMIUM_DIALOG_VISIBLE', false);
      this.$refs.bottomDialog.closeDialog();
    }
  }
};
</script>

<style lang="scss">
.premium-dialog-wrapper {
  .el-dialog__body {
    padding: 0 !important;
  }

  // 全屏样式
  &.m-bottom-dialog-wrap {
    .m-bottom-dialog-content {
      height: 100vh !important;
      max-height: 100vh !important;
      border-radius: 0 !important;
    }
  }
}
</style>

<style scoped lang="scss">
.premium-dialog-container {
  background: #141414;
  border-radius: 0;
  padding-bottom: calc(20px + env(safe-area-inset-bottom));
  height: 100vh;
  overflow-y: auto;
  position: relative;
}

.close-button {
  position: fixed;
  top: calc(30px + constant(safe-area-inset-top));
  top: calc(30px + env(safe-area-inset-top));
  left: 10px;
  z-index: 1000;
  width: 30px;
  height: 30px;
  padding: 3px;
  box-sizing: content-box;
  object-fit: contain;
  background: rgba(0, 0, 0, 0.5);
  border-radius: 18px;
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background: rgba(0, 0, 0, 0.7);
  }

  &:active {
    transform: scale(0.95);
  }
}
</style>
