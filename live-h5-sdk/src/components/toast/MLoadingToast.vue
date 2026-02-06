<template>
  <transition name="loading-toast-fade">
    <div class="m-loading-toast" v-if="isShow">
      <div class="loading-toast-content">
        <div class="loading-spinner"></div>
        <span class="loading-toast-text" v-if="message">{{ message }}</span>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'MLoadingToast',
  props: {
    message: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      isShow: false
    }
  },
  methods: {
    show() {
      this.isShow = true
    },
    close() {
      this.isShow = false
      this.$emit('close')
      setTimeout(() => {
        this.$destroy()
        if (this.$el && this.$el.parentNode) {
          this.$el.parentNode.removeChild(this.$el)
        }
      }, 300)
    }
  },
  mounted() {
    document.body.appendChild(this.$el)
    this.show()
  }
}
</script>

<style scoped lang="less">
.loading-toast-fade-enter-active,
.loading-toast-fade-leave-active {
  transition: opacity 0.3s ease;
}

.loading-toast-fade-enter,
.loading-toast-fade-leave-to {
  opacity: 0;
}

.m-loading-toast {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.5);
  pointer-events: auto;
}

.loading-toast-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px 32px;
  background: #ffffff;
  border-radius: 16px;
  min-width: 120px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

/* 菊花动画 */
.loading-spinner {
  width: 36px;
  height: 36px;
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-top-color: #333333;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.loading-toast-text {
  color: #333333;
  font-size: 14px;
  line-height: 1.5;
  text-align: center;
  word-break: break-word;
  font-weight: 500;
  margin-top: 12px;
}
</style>
