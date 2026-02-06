<template>
  <transition name="call-toast-fade">
    <div class="m-call-toast" v-if="isShow">
      <div class="call-toast-content">
        <img class="call-toast-icon" src="@/assets/image/call/ic_call_tip@2x.png" alt="" />
        <span class="call-toast-text">{{ message }}</span>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'MCallToast',
  props: {
    message: {
      type: String,
      default: 'The person is not online at the moment.'
    },
    duration: {
      type: Number,
      default: 3000
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
      if (this.duration > 0) {
        setTimeout(() => {
          this.close()
        }, this.duration)
      }
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
.call-toast-fade-enter-active,
.call-toast-fade-leave-active {
  transition: opacity 0.3s ease;
}

.call-toast-fade-enter,
.call-toast-fade-leave-to {
  opacity: 0;
}

.m-call-toast {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.call-toast-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px 32px;
  background: rgba(132, 132, 132, 0.75);
  border-radius: 16px;
  min-width: 120px;
  max-width: 200px;
  backdrop-filter: blur(50px);
  -webkit-backdrop-filter: blur(50px);
}

.call-toast-icon {
  width: 40px;
  height: 40px;
  margin-bottom: 12px;
}

.call-toast-text {
  color: #ffffff;
  font-size: 14px;
  line-height: 1.5;
  text-align: center;
  word-break: break-word;
  font-weight: 700;
}
</style>
