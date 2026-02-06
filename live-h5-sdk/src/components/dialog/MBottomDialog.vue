<template>
  <m-base-dialog ref="baseDialog" :dialog-class="'d-bottom '+(dialogClass?dialogClass:'')"
                 :click-mask-close-dialog="true">
    <template #content>
      <div class="move-wrap" move-tag="tag" ref="modalRef" 
           v-swipe-close="enableSwipeClose ? closeDialog : null"
           :style="{ transform: `translateY(${scrollTop}px)` }">
        <slot></slot>
      </div>
    </template>
  </m-base-dialog>
</template>

<script>

import MBaseDialog from "@/components/dialog/MBaseDialog.vue";

export default {
  components: {MBaseDialog},
  props: {
    dialogClass: {
      type: String,
      default() {
        return null;
      }
    },
    enableSwipeClose: {
      type: Boolean,
      default() {
        return true;
      }
    },
  },
  data() {
    return {
      scrollTop: 0
    }
  },
  methods: {
    closeDialog() {
      this.$refs.baseDialog.handleClose()
    }
  }
}
</script>
<style>
/* 底部弹窗样式 - 确保全屏铺满 */
.d-bottom {
  position: fixed !important;
  display: flex !important;
  align-items: flex-end !important;
  width: 100% !important;
  max-width: 100% !important;
  top: 0 !important;
  bottom: 0 !important;
  left: 0 !important;
  right: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  background: rgba(0, 0, 0, 0.5) !important;
  border-radius: 30px !important;
}

.d-bottom .m-dialog {
  margin: 0 !important;
  padding: 0 !important;
  width: 100% !important;
  max-width: 100% !important;
  max-height: 100% !important;
  position: relative !important;
  bottom: 0 !important;
  left: 0 !important;
  right: 0 !important;
  top: auto !important;
  transform: none !important;
  border-radius: 30px !important;
}

.d-bottom .m-dialog-body {
  padding: 0 !important;
  margin: 0 !important;
  overflow-y: auto;
  width: 100% !important;
}

.d-bottom .m-dialog-footer, 
.d-bottom .m-dialog-header {
  display: none;
}
</style>
<style scoped lang="less">

</style>

