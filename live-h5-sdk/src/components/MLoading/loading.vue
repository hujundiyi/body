<!-- Loading.vue -->
<template>
  <transition name="m-loading-fade">
      <div
      v-if="isShow"
      class="m-loading"
      :style="{'z-index': VIEW_Z_INDEX}"
    >
      <div class="m-loading__card">
        <!-- 关闭按钮 -->
        <div class="m-loading__close" v-if="closable" @click="hide">
          <div class="m-loading__close-icon">
            <span class="m-loading__close-line m-loading__close-line--1"></span>
            <span class="m-loading__close-line m-loading__close-line--2"></span>
          </div>
        </div>
        <img
          :src="loadingImage"
          alt="loading"
          class="m-loading__image"
        />
        <span class="m-loading__text" v-if="text">{{ text }}</span>
      </div>
    </div>
  </transition>
</template>

<script>

export default {
  name: 'MLoading',
  props: {
    text: {
      type: String,
      default: 'loading...'
    },
    closable: {
      type: Boolean,
      default: true
    }
  },

  data() {
    return {
      VIEW_Z_INDEX: 9999999, // 设置一个非常高的 z-index，确保在所有弹窗之上
      isShow: false,
      loadingImage: require('@/assets/image/ic-loading.gif')
    }
  },

  methods: {
    show() {
      this.isShow = true
    },

    hide() {
      this.isShow = false
      this.$emit('close')
    }
  },

  mounted() {
    document.body.appendChild(this.$el)
    this.show()
  },

  beforeDestroy() {
    if (this.$el && this.$el.parentNode) {
      this.$el.parentNode.removeChild(this.$el)
    }
  }
}
</script>

<style scoped lang="scss">
// 动画定义
@keyframes m-loading-fade-in {
  0% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}

@keyframes m-loading-fade-out {
  0% {
    opacity: 1;
  }
  100% {
    opacity: 0;
  }
}

// 图片旋转动画
@keyframes m-loading-rotate {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

// 过渡动画
.m-loading-fade-enter-active {
  animation: m-loading-fade-in 0.3s ease forwards;
}

.m-loading-fade-leave-active {
  animation: m-loading-fade-out 0.25s ease forwards;
}

// 基础样式
.m-loading {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.4);

  &__card {
    position: relative;
    background: #282828;
    border-radius: 12px;
    padding: 20px 16px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-width: 80px;
    min-height: 80px;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4),
    0 2px 6px rgba(0, 0, 0, 0.2);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid #837066;
  }

  // 关闭按钮样式
  &__close {
    position: absolute;
    top: 8px;
    right: 8px;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid #837066;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    z-index: 1;

    &:active {
      background: rgba(255, 255, 255, 0.15);
      transform: scale(0.95);
    }
  }

  &__close-icon {
    position: relative;
    width: 12px;
    height: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  &__close-line {
    position: absolute;
    display: block;
    width: 100%;
    height: 1.5px;
    background: #FFFFFF;
    border-radius: 1px;
    transition: all 0.2s ease;

    &--1 {
      transform: rotate(45deg) translateY(0);
    }

    &--2 {
      transform: rotate(-45deg) translateY(0);
    }
  }

  &__image {
    width: 32px;
    height: 32px;
    margin-bottom: 12px;
    object-fit: contain;
  }

  &__text {
    font-size: 15px;
    font-weight: 500;
    text-align: center;
    line-height: 1.4;
  }
}

// 如果不可关闭，隐藏关闭按钮
.m-loading__card:has(.m-loading__close[style*="display: none"]) {
  .m-loading__close {
    display: none;
  }
}
</style>
