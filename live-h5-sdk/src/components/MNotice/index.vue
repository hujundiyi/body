<template>
  <div
    v-if="visible"
    ref="noticeEl"
    class="m-notice"
    :class="noticeClasses"
    :style="noticeStyle"
    @click="handleClick"
    @touchstart="handleTouchStart"
    @touchmove="handleTouchMove"
    @touchend="handleTouchEnd"
  >
    <!-- 左侧头像 -->
    <div class="m-notice__avatar">
      <img class="avatar" :src="avatar" alt=""/>
    </div>

    <!-- 中间内容 -->
    <div class="m-notice__content">
      <!-- 喜欢消息类型：显示 "[Username] Liked you." -->
      <div v-if="isLikeNotice" class="m-notice__online-title">
        <span class="username">{{ title }}</span>
        <span class="online-text"> Liked you. </span>
      </div>
      <!-- 在线通知类型：显示 "[Username] is online now." -->
      <div v-else-if="isOnlineNotice" class="m-notice__online-title">
        <span class="username">{{ title }}</span>
        <span class="online-text"> is online now.</span>
      </div>
      <!-- 普通类型：显示标题和用户信息 -->
      <div v-else class="m-notice__title-wrapper">
        <div class="m-notice__title">{{ title }}</div>
        <div class="user-meta" v-if="country || age">
          <span class="flag-icon" v-if="country">{{ getCountryFlag(country) }}</span>
          <div class="age-badge" v-if="age" :style="{ backgroundImage: `url(${getGenderBadgeBg()})` }">
            <span class="badge-text">{{ age }}</span>
          </div>
        </div>
      </div>
      <div class="m-notice__message" v-html="message"></div>
    </div>

    <!-- 右侧图标：只有传入有效的 rightImage 时才显示 -->
    <div class="m-notice__action" v-if="rightImage">
      <img :src="rightImage" class="m-notice__right-img" alt=""/>
    </div>
  </div>
</template>

<script>
import {getCountryFlagEmojiByCode} from "@/utils/Utils";

export default {
  name: 'MNotice',
  props: {
    // 显示/隐藏
    show: {
      type: Boolean,
      default: false
    },
    isBlur:{
      type:Boolean,
      default:false
    },
    // 标题
    title: {
      type: String,
      default: ''
    },
    // 消息内容
    message: {
      type: String,
      default: ''
    },
    // 头像URL
    avatar: {
      type: String,
      default: ''
    },
    // 右侧图片 - 传 null 或空字符串时不显示
    rightImage: {
      type: String,
      default: null
    },
    // 背景颜色
    backgroundColor: {
      type: String,
      default: ''
    },
    // 自动关闭时间（毫秒），0表示不自动关闭
    duration: {
      type: Number,
      default: 3000
    },
    // 通知宽度
    width: {
      type: [String, Number],
      default: 'calc(100vw - 40px)'
    },
    // 通知高度
    height: {
      type: [String, Number],
      default: 'auto'
    },
    // 层级
    zIndex: {
      type: Number,
      default: 5000
    },
    // 国家代码
    country: {
      type: [String, Number],
      default: null
    },
    // 年龄
    age: {
      type: [String, Number],
      default: null
    },
    // 是否是在线通知类型（显示 "[Username] is online now." 格式）
    isOnlineNotice: {
      type: Boolean,
      default: false
    },
    // 是否是喜欢消息类型（显示 "[Username] Say hi now >>>" 格式）
    isLikeNotice: {
      type: Boolean,
      default: false
    }
  },
  emits: ['update:show', 'close', 'click', 'swipe'],
  data() {
    return {
      visible: false,
      isEntering: false,
      isLeaving: false,
      autoCloseTimer: null,
      // 触摸相关 - 支持任意方向拖动
      touchStartX: 0,
      touchStartY: 0,
      isDragging: false,
      dragOffsetX: 0,
      dragOffsetY: 0,
      initialTop: 0,
      initialLeft: 0,
    };
  },
  computed: {
    noticeClasses() {
      return {
        'm-notice-enter': this.isEntering,
        'm-notice-leave': this.isLeaving,
        'm-notice--dragging': this.isDragging
      };
    },
    noticeStyle() {
      const transform = [];

      // 拖动偏移
      if (this.isDragging) {
        transform.push(`translate(${this.dragOffsetX}px, ${this.dragOffsetY}px)`);
      }

      return {
        width: this.getCorrectedWidth(),
        height: typeof this.height === 'number' ? `${this.height}px` : this.height,
        backgroundColor: this.backgroundColor,
        zIndex: this.zIndex,
        transform: transform.join(' '),
        opacity: this.isDragging ? this.getOpacityByDistance() : 1,
        top: this.isDragging ? `${this.initialTop}px` : 'calc(20px + env(safe-area-inset-top))',
        left: this.isDragging ? `${this.initialLeft}px` : '50%'
      };
    }
  },
  watch: {
    show: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.visible = true;
          this.isEntering = true; // 立即设置为进入状态
          this.$nextTick(() => {
            // 强制重绘，确保动画开始前应用了初始样式
            this.$refs.noticeEl && this.$refs.noticeEl.offsetHeight;
            // 开始进入动画
            setTimeout(() => {
              this.isEntering = false;
              this.startAutoClose();
            }, 10);
          });
        } else {
          this.startLeaveAnimation();
        }
      }
    }
  },
  mounted() {
    if (this.show) {
      this.visible = true;
      this.isEntering = true;
      this.$nextTick(() => {
        this.$refs.noticeEl && this.$refs.noticeEl.offsetHeight;
        setTimeout(() => {
          this.isEntering = false;
          this.startAutoClose();
        }, 10);
      });
    }
  },
  beforeUnmount() {
    this.clearTimers();
  },
  methods: {
    // 修复宽度计算
    getCorrectedWidth() {
      let width = this.width;
      if (typeof width === 'string' && width.includes('calc(-40px + 100vw)')) {
        return 'calc(100vw - 40px)';
      }
      return typeof width === 'number' ? `${width}px` : width;
    },

    // 根据拖动距离计算透明度
    getOpacityByDistance() {
      const distance = Math.sqrt(this.dragOffsetX * this.dragOffsetX + this.dragOffsetY * this.dragOffsetY);
      const threshold = 100; // 拖动100px时完全透明
      return Math.max(0, 1 - distance / threshold);
    },

    // 检查是否应该触发关闭
    shouldCloseByDistance() {
      const distance = Math.sqrt(this.dragOffsetX * this.dragOffsetX + this.dragOffsetY * this.dragOffsetY);
      const threshold = 80; // 拖动80px时触发关闭
      return distance > threshold;
    },

    // 开始离开动画
    startLeaveAnimation() {
      this.isLeaving = true;
      this.clearTimers();

      // 动画结束后隐藏
      setTimeout(() => {
        this.isLeaving = false;
        this.visible = false;
        this.$emit('update:show', false);
        this.$emit('close');
      }, 300);
    },

    // 开始自动关闭计时
    startAutoClose() {
      if (this.duration <= 0) return;

      this.clearTimers();

      // 自动关闭定时器
      this.autoCloseTimer = setTimeout(() => {
        this.handleClose();
      }, this.duration);
    },

    // 清理所有定时器
    clearTimers() {
      if (this.autoCloseTimer) {
        clearTimeout(this.autoCloseTimer);
        this.autoCloseTimer = null;
      }
    },

    // 处理关闭
    handleClose() {
      this.startLeaveAnimation();
    },

    // 手动关闭方法（供外部调用）
    close() {
      this.handleClose();
    },

    // 点击通知
    handleClick() {
      this.$emit('click');
    },

    // 触摸开始
    handleTouchStart(event) {
      const touch = event.touches[0];
      this.touchStartX = touch.clientX;
      this.touchStartY = touch.clientY;
      this.isDragging = false;
      this.dragOffsetX = 0;
      this.dragOffsetY = 0;

      // 记录初始位置
      if (this.$refs.noticeEl) {
        const rect = this.$refs.noticeEl.getBoundingClientRect();
        this.initialTop = rect.top;
        this.initialLeft = rect.left;
      }
    },

    // 触摸移动
    handleTouchMove(event) {
      if (!this.touchStartX) return;

      const touch = event.touches[0];
      const deltaX = touch.clientX - this.touchStartX;
      const deltaY = touch.clientY - this.touchStartY;

      // 开始拖动
      if (!this.isDragging && (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5)) {
        this.isDragging = true;
      }

      if (this.isDragging) {
        event.preventDefault();
        this.dragOffsetX = deltaX;
        this.dragOffsetY = deltaY;
      }
    },

    // 触摸结束
    handleTouchEnd() {
      if (this.isDragging) {
        // 检查是否应该关闭
        if (this.shouldCloseByDistance()) {
          this.$emit('swipe', 'drag');
          this.handleClose();
        } else {
          // 回弹到原位
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.isDragging = false;
        }
      }

      this.touchStartX = 0;
      this.touchStartY = 0;
    },
    /**
     * 获取国家旗帜
     */
    getCountryFlag(country) {
      if (!country) return '🌐';
      return getCountryFlagEmojiByCode(country);
    },
    /**
     * 获取性别徽章背景（固定显示女性）
     */
    getGenderBadgeBg() {
      // 固定显示女性徽章
      return require('@/assets/image/sdk/ic-userdetail-girl.png');
    }
  }
};
</script>

<style scoped lang="scss">
.m-notice {
  position: fixed;
  top: calc(20px + env(safe-area-inset-top)); /* 处理苹果设备安全区域 */
  left: 50%;
  transform: translateX(-50%) translateY(0);
  margin: 0 auto;
  padding: 12px 0;
  background-image: url('@/assets/image/message/ic-message-notice-bg.png');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  display: flex;
  align-items: center;
  gap: 12px;
  overflow: hidden;
  cursor: pointer;
  width: calc(100vw - 40px); /* 修复宽度计算 */
  max-width: 400px; /* 在大屏设备上限制最大宽度 */
  transition: all 0.3s ease;

  .avatar {
    margin-left: 10px;
    width: 48px;
    height: 48px;
    border-radius: 24px;
    align-content: center;
    display: flex;
  }

  &:hover {
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
  }

  &.m-notice--dragging {
    transition: transform 0.1s ease, opacity 0.1s ease;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  }
}

/* 进入动画状态 - 初始状态完全不可见 */
.m-notice-enter {
  transform: translateX(-50%) translateY(-100%);
  opacity: 0;
}

/* 离开动画状态 */
.m-notice-leave {
  transform: translateX(-50%) translateY(-100%);
  opacity: 0;
}

.m-notice__content {
  flex: 1;
  min-width: 0;
}

.m-notice__title-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
  min-width: 0;
  flex-wrap: wrap;
}

.m-notice__title {
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 14px;
  font-weight: bold;
  color: black;
  margin-right: 10px;
}

.m-notice__online-title {
  font-size: 14px;
  font-weight: bold;
  line-height: 1.2;
  margin-bottom: 5px;

  .username {
    font-weight: bold;
    color: black;
  }

  .online-text {
    color: black;
  }
}

.user-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;

  .flag-icon {
    display: inline-block;
    font-size: 20px;
    line-height: 1;
    vertical-align: middle;
  }

  .age-badge {
    padding: 0;
    background-size: 100% 100%;
    background-repeat: no-repeat;
    background-position: center center;
    height: 20px;
    min-width: 41px;
    display: flex;
    align-items: center;
    justify-content: center;

    .badge-text {
      margin-left: 15px;
      font-size: 14px;
      font-weight: 700;
      color: #ffffff;
      line-height: 1;
    }
  }
}

.m-notice__message {
  font-size: 14px;
  font-weight: 400;
  color: #999999;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.m-notice__action {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.m-notice__right-img {
  width: 60px;
  height: 60px;
  object-fit: cover;
  margin-right: 10px;
}
</style>
