<template>
  <transition name="dialog-fade">
    <div v-if="dialogVisible" class="m-dialog-wrapper" :class="dialogClass" @click.self="handleMaskClick">
      <div class="m-dialog" :class="{'d-bottom': isBottomDialog}" :style="dialogStyle">
        <div v-if="$slots.title" class="m-dialog-header">
          <slot name="title"></slot>
        </div>
        <div class="m-dialog-body">
          <slot name="content"></slot>
        </div>
        <div v-if="$slots.footer" class="m-dialog-footer">
          <slot name="footer"></slot>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import {DialogTaskArray} from "@/components/dialog/DialogTaskArray";

export default {
  name: "MBaseDialog",
  props: {
    width: {
      type: [Number, String],
      default() {
        return '95%';
      }
    },
    dialogClass: {
      type: String,
      default() {
        return null;
      }
    },
    clickMaskCloseDialog: {
      type: Boolean,
      default() {
        return true;
      }
    }
  },
  data() {
    return {
      dialogVisible: false
    }
  },
  computed: {
    isBottomDialog() {
      return this.dialogClass && this.dialogClass.includes('d-bottom');
    },
    dialogStyle() {
      const style = {};
      if (this.width) {
        if (typeof this.width === 'number') {
          style.width = this.width + 'px';
        } else {
          style.width = this.width;
        }
      }
      return style;
    }
  },
  watch: {
    dialogVisible(newVal) {
      if (newVal) {
        // 打开时禁止 body 滚动
        document.body.style.overflow = 'hidden';
      } else {
        // 关闭时恢复 body 滚动
        document.body.style.overflow = '';
      }
    }
  },
  methods: {
    handleClose() {
      if (this.clickMaskCloseDialog) {
        this.dialogVisible = false;
        DialogTaskArray.pop();
      }
    },
    handleMaskClick() {
      if (this.clickMaskCloseDialog) {
        this.handleClose();
      }
    }
  },
  beforeDestroy() {
    // 组件销毁时恢复 body 滚动
    document.body.style.overflow = '';
  }
}
</script>
<style>
.hint-dialog {
  border-radius: 14px !important;
}
</style>

<style scoped lang="less">
.m-dialog-wrapper {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
   background: rgba(0, 0, 0, 0.5);
  
  &.d-bottom {
    align-items: flex-end;
    background: rgba(0, 0, 0, 0.5);
  }
}

.m-dialog {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: #fff;
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  max-height: calc(100% - 30px);
  max-width: calc(100% - 25px);
  margin: 0;
  overflow: hidden;
  
  &.d-bottom {
    position: fixed;
    top: auto;
    bottom: 0;
    left: 0;
    right: 0;
    max-width: 100%;
    max-height: 100%;
    width: 100%;
    border-radius: 0;
    margin: 0;
    transform: none;
  }
}

.m-dialog-header {
  padding: 20px 20px 0;
  flex-shrink: 0;
}

.m-dialog-body {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  min-height: 0;
  border-radius: 30px;
}

.m-dialog-footer {
  padding: 0 20px 20px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

// 动画效果
.dialog-fade-enter-active,
.dialog-fade-leave-active {
  transition: opacity 0.3s;
}

.dialog-fade-enter-active .m-dialog:not(.d-bottom),
.dialog-fade-leave-active .m-dialog:not(.d-bottom) {
  transition: transform 0.3s, opacity 0.3s;
}

.dialog-fade-enter-active .m-dialog.d-bottom,
.dialog-fade-leave-active .m-dialog.d-bottom {
  transition: transform 0.3s, opacity 0.3s;
}

.dialog-fade-enter,
.dialog-fade-leave-to {
  opacity: 0;
}

.dialog-fade-enter .m-dialog:not(.d-bottom),
.dialog-fade-leave-to .m-dialog:not(.d-bottom) {
  transform: translate(-50%, -50%) scale(0.9);
  opacity: 0;
}

.dialog-fade-enter .m-dialog.d-bottom,
.dialog-fade-leave-to .m-dialog.d-bottom {
  transform: translateY(100%);
  opacity: 0;
}

.dialog-fade-enter-active .m-dialog:not(.d-bottom),
.dialog-fade-leave-active .m-dialog:not(.d-bottom) {
  transform: translate(-50%, -50%) scale(1);
  opacity: 1;
}

.dialog-fade-enter-active .m-dialog.d-bottom,
.dialog-fade-leave-active .m-dialog.d-bottom {
  transform: translateY(0);
  opacity: 1;
}
</style>

