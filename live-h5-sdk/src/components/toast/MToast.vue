<template>
  <div class="m-toast">
    <i :class="['toast-icon', 'el-icon-' + icon]" v-if="icon"></i>
    <span class="toast-text">{{ message }}</span>
  </div>
</template>
<script>
export default {
  props: {
    message: {
      type: String,
      default: ''
    },
    type: {
      type: String,
      default: 'info'
    },
    icon: {
      type: String,
      default: ''
    },
    position: {
      type: String,
      default: 'top'
    },
    duration: {
      type: Number,
      default: 2000
    }
  },
  data() {
    return {
      isShow: false
    }
  },
  watch: {
    isShow(isShow) {
      if (isShow) {
        setTimeout(() => {
          this.close()
        }, this.duration)
      }
    }
  },
  methods: {
    show() {
      this.isShow = true
    },
    close() {
      this.isShow = false
      this.$destroy()
      this.$el.parentNode.removeChild(this.$el)
    }
  },
  mounted() {
    document.body.appendChild(this.$el)
    this.show()
  }
}
</script>
<style scoped lang="less">
@keyframes slideDown {
  0% {
    opacity: 0;
    transform: translate(-50%, -100%);
  }
  100% {
    opacity: 1;
    transform: translate(-50%, 0);
  }
}

.m-toast {
  position: fixed;
  top: 60px;
  left: 50%;
  transform: translate(-50%, 0);
  z-index: 9999;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  background: rgba(0, 0, 0, 0.8);
  color: #fff;
  font-size: 14px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  animation: slideDown 0.3s ease-out forwards;
}

.toast-icon {
  font-size: 16px;
  
  &.el-icon-success {
    color: #52c41a;
  }
  
  &.el-icon-warning {
    color: #faad14;
  }
  
  &.el-icon-error {
    color: #ff4d4f;
  }
  
  &.el-icon-info {
    color: #1890ff;
  }
}

.toast-text {
  line-height: 1.4;
  max-width: 280px;
  word-break: break-word;
}
</style>
