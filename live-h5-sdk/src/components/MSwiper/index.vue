<template>
  <div class="m-swiper" :style="swiperStyle">
    <!-- 轮播容器 -->
    <div
      class="m-swiper__container"
      ref="container"
      @mouseenter="pauseAutoPlay"
      @mouseleave="resumeAutoPlay"
      @touchstart="onTouchStart"
      @touchmove="onTouchMove"
      @touchend="onTouchEnd"
    >
      <!-- 空状态显示 -->
      <div
        v-if="list.length === 0"
        class="m-swiper__empty"
      >
        <img
          :src="emptyImage"
          alt="empty"
          class="m-swiper__empty-image"
        />
      </div>

      <!-- 轮播内容 -->
      <div
        v-else
        class="m-swiper__wrapper"
        :style="wrapperStyle"
        @mousedown="onMouseDown"
        @mousemove="onMouseMove"
        @mouseup="onMouseUp"
        @mouseleave="onMouseLeave"
      >
        <div
          v-for="(item, index) in list"
          :key="getItemKey(item, index)"
          class="m-swiper__slide"
        >
          <slot :item="item" :index="index"></slot>
        </div>
      </div>

      <!-- 指示器（只在有内容时显示） -->
      <div
        v-if="showDots && list.length > 1"
        :class="[
          'm-swiper__dots',
          `m-swiper__dots--${dotPosition}`,
          `m-swiper__dots--${dotType}`,
          { 'm-swiper__dots--evenly': dotsEvenly && list.length > 1 }
        ]"
        :style="[
          dotsStyle,
          {
          '--dot-color': dotColor,
          '--dot-active-color': dotActiveColor
          }]"
      >
        <div
          v-for="(item, index) in list"
          :key="getItemKey(item, index)"
          :class="[
            'm-swiper__dot',
            { 'm-swiper__dot--active': currentIndex === index }
          ]"
          @click="handleDotClick(index)"
        ></div>
      </div>
    </div>

    <!-- 点击区域（只在有内容时显示） -->
    <div
      v-if="isClickLeftOrRightScroll && list.length > 0"
      class="touch-wrapper"
    >
      <div class="touch-wrapper-left" @click="prev"></div>
      <div class="touch-wrapper-right" @click="next"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MSwiper',
  props: {
    // 轮播数据源
    list: {
      type: Array,
      default: () => []
    },
    // 轮播间隔时间（毫秒）
    interval: {
      type: Number,
      default: 3000
    },
    // 是否自动轮播
    autoplay: {
      type: Boolean,
      default: false
    },
    // 初始显示项索引
    initialIndex: {
      type: Number,
      default: 0
    },
    // 是否显示指示器
    showDots: {
      type: Boolean,
      default: true
    },
    // 指示器位置
    dotPosition: {
      type: String,
      default: 'bottom', // 'top' 或 'bottom'
      validator: (value) => ['top', 'bottom'].includes(value)
    },
    // 是否循环播放
    loop: {
      type: Boolean,
      default: false
    },
    // 轮播方向
    direction: {
      type: String,
      default: 'horizontal', // 'horizontal' 或 'vertical'
      validator: (value) => ['horizontal', 'vertical'].includes(value)
    },
    // 自定义key字段
    keyField: {
      type: String,
      default: null
    },
    // 滑动阈值（滑动距离超过此值才切换）
    swipeThreshold: {
      type: Number,
      default: 50
    },
    // 是否启用手势滑动
    swipeable: {
      type: Boolean,
      default: true
    },
    // 新增：指示器是否均分宽度
    dotsEvenly: {
      type: Boolean,
      default: false
    },
    // 新增：指示器左右间距（在均分模式下使用）
    dotsGap: {
      type: Number,
      default: 20
    },
    // 新增：指示器样式类型
    dotType: {
      type: String,
      default: 'bar', // 'bar' 或 'dot'
      validator: (value) => ['bar', 'dot'].includes(value)
    },
    // 非选中颜色
    dotColor: {
      type: String,
      default: '#FFFFFF'
    },
    // 选中颜色
    dotActiveColor: {
      type: String,
      default: '#BF6200'
    },
    // 新增：自定义底部距离
    dotsBottom: {
      type: [Number, String],
      default: 50
    },
    isClickLeftOrRightScroll: {
      type: Boolean,
      default: false
    },
    // 新增：空状态图片路径
    emptyImage: {
      type: String,
      default: require('@/assets/image/sdk/ic-empty.png')
    },
    // 新增：容器高度
    height: {
      type: [Number, String],
      default: 300
    },
    // 新增：容器最小高度
    minHeight: {
      type: [Number, String],
      default: 200
    },
    // 新增：容器宽度
    width: {
      type: [Number, String],
      default: '100%'
    },
    transitionEnabled: {
      type: Boolean,
      default: true
    },
    disableTransitionOnUpdate: {
      type: Boolean,
      default: false
    },
    resetIndexOnUpdate: {
      type: Boolean,
      default: true
    },
    pauseOnHover: {
      type: Boolean,
      default: true
    },
    pauseOnTouch: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      currentIndex: this.initialIndex,
      timer: null,
      isPaused: false,
      containerWidth: 0,
      containerHeight: 0,
      isDestroyed: false, // 添加销毁标志
      isUpdating: false,

      // 手势滑动相关
      isDragging: false,
      startX: 0,
      startY: 0,
      currentX: 0,
      currentY: 0,
      dragOffset: 0,

      // 触摸相关
      touchStartX: 0,
      touchStartY: 0,
      touchCurrentX: 0,
      touchCurrentY: 0,
      isTouching: false
    }
  },
  computed: {
    // 轮播容器样式
    swiperStyle() {
      const style = {
        width: typeof this.width === 'number' ? `${this.width}px` : this.width
      }

      // 只有在有内容时才设置高度，空状态时使用固定高度
      if (this.list.length === 0) {
        style.height = typeof this.height === 'number' ? `${this.height}px` : this.height
        style.minHeight = typeof this.minHeight === 'number' ? `${this.minHeight}px` : this.minHeight
      }

      return style
    },
    // 包装器样式
    wrapperStyle() {
      let translateValue

      if (this.isHorizontal) {
        const baseTranslate = -this.currentIndex * 100
        const dragTranslate = (this.dragOffset / this.containerWidth) * 100
        translateValue = `translateX(${baseTranslate + dragTranslate}%)`
      } else {
        const baseTranslate = -this.currentIndex * 100
        const dragTranslate = (this.dragOffset / this.containerHeight) * 100
        translateValue = `translateY(${baseTranslate + dragTranslate}%)`
      }

      const disable = this.isDragging || this.isTouching || !this.transitionEnabled || (this.disableTransitionOnUpdate && this.isUpdating)

      const style = {
        transform: translateValue,
        transition: disable ? 'none' : 'transform 0.3s ease'
      }

      // 竖向滑动时，wrapper 高度 = slide 高度 × 总页数
      if (!this.isHorizontal && this.itemCount > 0) {
        style.height = `${this.containerHeight * this.itemCount}px`
        style.display = 'flex'
        style.flexDirection = 'column'
      }

      return style
    },
    // 轮播项总数
    itemCount() {
      return this.list.length
    },
    // 是否为水平方向
    isHorizontal() {
      return this.direction === 'horizontal'
    },
    // 指示器样式
    dotsStyle() {
      if (!this.dotsEvenly || this.list.length <= 1) {
        // 如果设置了自定义底部距离，返回相应的样式
        if (this.dotPosition === 'bottom' && this.dotsBottom !== 50) {
          return {
            bottom: typeof this.dotsBottom === 'number' ? `${this.dotsBottom}px` : this.dotsBottom
          }
        }
        return {}
      }

      const totalGap = this.dotsGap * 2 // 左右间距
      const availableWidth = `calc(100% - ${totalGap}px)`

      // 如果设置了自定义底部距离，添加到底部样式中
      const style = {
        width: availableWidth,
        left: `${this.dotsGap}px`,
        right: `${this.dotsGap}px`
      }

      if (this.dotPosition === 'bottom' && this.dotsBottom !== 50) {
        style.bottom = typeof this.dotsBottom === 'number' ? `${this.dotsBottom}px` : this.dotsBottom
      }
      return style
    },
  },
  watch: {
    // 监听数据源变化
    list() {
      if (this.isDestroyed) return
      this.isUpdating = true
      this.$nextTick(() => {
        this.updateContainerSize()
        if (this.resetIndexOnUpdate) {
          this.resetCurrentIndex()
        } else {
          const maxIndex = Math.max(0, this.itemCount - 1)
          if (this.currentIndex > maxIndex) {
            this.currentIndex = maxIndex
          }
        }
        setTimeout(() => {
          if (!this.isDestroyed) {
            this.isUpdating = false
          }
        }, 0)
        if (this.autoplay && !this.isPaused) {
          this.startAutoPlay()
        }
      })
    },
    // 监听自动轮播设置变化
    autoplay(newVal) {
      if (this.isDestroyed) return

      if (newVal && !this.isPaused) {
        this.startAutoPlay()
      } else {
        this.stopAutoPlay()
      }
    },
    // 监听轮播间隔变化
    interval() {
      if (this.isDestroyed) return

      if (this.autoplay && !this.isPaused) {
        this.stopAutoPlay()
        this.startAutoPlay()
      }
    }
  },
  mounted() {
    this.updateContainerSize()

    // 监听窗口大小变化
    window.addEventListener('resize', this.handleResize)

    // 开始自动轮播
    if (this.autoplay) {
      this.startAutoPlay()
    }
  },
  beforeDestroy() {
    // 标记组件已销毁
    this.isDestroyed = true

    // 清除定时器
    this.stopAutoPlay()

    // 移除事件监听
    window.removeEventListener('resize', this.handleResize)
  },
  methods: {
    // 更新容器尺寸
    updateContainerSize() {
      if (this.isDestroyed) return

      this.$nextTick(() => {
        if (this.$refs.container && !this.isDestroyed) {
          this.containerWidth = this.$refs.container.offsetWidth
          this.containerHeight = this.$refs.container.offsetHeight
        }
      })
    },

    // 处理窗口大小变化
    handleResize() {
      if (this.isDestroyed) return
      this.updateContainerSize()
    },

    // 重置当前索引
    resetCurrentIndex() {
      if (this.isDestroyed) return

      if (this.initialIndex >= 0 && this.initialIndex < this.itemCount) {
        this.currentIndex = this.initialIndex
      } else {
        this.currentIndex = 0
      }
    },

    // 获取项目唯一key
    getItemKey(item, index) {
      if (this.keyField && item[this.keyField]) {
        return item[this.keyField]
      }
      return 'm-swiper-item-' + index
    },

    // 开始自动轮播 会员权益需要轮播
    startAutoPlay() {
      if (this.isDestroyed || this.itemCount <= 1) return

      this.stopAutoPlay()
      this.timer = setInterval(() => {
        if (this.isDestroyed) {
          this.stopAutoPlay()
          return
        }
        this.next()
      }, this.interval)
    },

    // 停止自动轮播
    stopAutoPlay() {
      if (this.timer) {
        clearInterval(this.timer)
        this.timer = null
      }
    },

    // 暂停自动轮播
    pauseAutoPlay() {
      if (this.isDestroyed) return
      const shouldPause = (this.isTouching && this.pauseOnTouch) || (!this.isTouching && this.pauseOnHover)
      if (!shouldPause) return
      this.isPaused = true
      this.stopAutoPlay()
    },

    // 恢复自动轮播
    resumeAutoPlay() {
      if (this.isDestroyed) return

      this.isPaused = false
      if (this.autoplay && !this.isDestroyed) {
        this.startAutoPlay()
      }
    },

    // 下一项
    next() {
      if (this.isDestroyed || this.itemCount <= 1) return

      if (this.currentIndex >= this.itemCount - 1) {
        this.currentIndex = this.loop ? 0 : this.itemCount - 1
      } else {
        this.currentIndex++
      }

      this.$emit('change', this.currentIndex, this.list[this.currentIndex])
    },

    // 上一项
    prev() {
      if (this.isDestroyed || this.itemCount <= 1) return

      if (this.currentIndex <= 0) {
        this.currentIndex = this.loop ? this.itemCount - 1 : 0
      } else {
        this.currentIndex--
      }

      this.$emit('change', this.currentIndex, this.list[this.currentIndex])
    },

    // 跳转到指定项
    goTo(index) {
      if (this.isDestroyed || index >= 0 && index < this.itemCount && index !== this.currentIndex) {
        this.currentIndex = index
        this.$emit('change', this.currentIndex, this.list[this.currentIndex])
      }
    },

    // 处理指示器点击
    handleDotClick(index) {
      if (this.isDestroyed) return

      // 暂停自动轮播一小段时间，让用户有更好的体验
      this.pauseAutoPlay()
      this.goTo(index)

      // 1秒后恢复自动轮播
      setTimeout(() => {
        if (this.autoplay && !this.isDestroyed) {
          this.resumeAutoPlay()
        }
      }, 1000)
    },

    // 获取当前索引
    getCurrentIndex() {
      return this.currentIndex
    },

    // 获取当前项
    getCurrentItem() {
      return this.list[this.currentIndex]
    },

    // 鼠标事件处理 - 添加销毁检查
    onMouseDown(event) {
      if (this.isDestroyed || !this.swipeable || this.itemCount <= 1) return

      // 手势按压时停止自动轮播
      this.pauseAutoPlay()

      this.isDragging = true
      this.startX = event.clientX
      this.startY = event.clientY
      this.currentX = event.clientX
      this.currentY = event.clientY
      this.dragOffset = 0

      event.preventDefault()
    },

    onMouseMove(event) {
      if (this.isDestroyed || !this.isDragging) return

      this.currentX = event.clientX
      this.currentY = event.clientY

      if (this.isHorizontal) {
        this.dragOffset = this.currentX - this.startX
      } else {
        this.dragOffset = this.currentY - this.startY
      }

      event.preventDefault()
    },

    onMouseUp() {
      if (this.isDestroyed || !this.isDragging) return

      this.handleDragEnd()
      this.isDragging = false

      // 手势结束后恢复自动轮播
      if (this.autoplay && !this.isDestroyed) {
        this.resumeAutoPlay()
      }
    },

    onMouseLeave() {
      if (this.isDestroyed || !this.isDragging) return

      this.handleDragEnd()
      this.isDragging = false

      // 手势结束后恢复自动轮播
      if (this.autoplay && !this.isDestroyed) {
        this.resumeAutoPlay()
      }
    },

    // 触摸事件处理 - 添加销毁检查
    onTouchStart(event) {
      if (this.isDestroyed || !this.swipeable || this.itemCount <= 1) return

      // 手势按压时停止自动轮播
      this.pauseAutoPlay()

      this.isTouching = true
      this.touchStartX = event.touches[0].clientX
      this.touchStartY = event.touches[0].clientY
      this.touchCurrentX = event.touches[0].clientX
      this.touchCurrentY = event.touches[0].clientY
      this.dragOffset = 0
    },

    onTouchMove(event) {
      if (this.isDestroyed || !this.isTouching) return

      this.touchCurrentX = event.touches[0].clientX
      this.touchCurrentY = event.touches[0].clientY

      if (this.isHorizontal) {
        this.dragOffset = this.touchCurrentX - this.touchStartX
      } else {
        this.dragOffset = this.touchCurrentY - this.touchStartY
      }

      event.preventDefault()
    },

    onTouchEnd() {
      if (this.isDestroyed || !this.isTouching) return

      this.handleDragEnd()
      this.isTouching = false

      // 手势结束后恢复自动轮播
      if (this.autoplay && !this.isDestroyed) {
        this.resumeAutoPlay()
      }
    },

    // 处理拖拽结束
    handleDragEnd() {
      if (this.isDestroyed) return

      const threshold = this.isHorizontal ? this.containerWidth * 0.1 : this.containerHeight * 0.1

      if (Math.abs(this.dragOffset) > threshold) {
        if (this.dragOffset > 0) {
          this.prev()
        } else {
          this.next()
        }
      }

      this.dragOffset = 0
    }
  }
}
</script>

<style scoped lang="scss">
.m-swiper {
  width: 100%;
  /* 移除固定高度，由props控制 */
}

.m-swiper__container {
  position: relative;
  width: 100%;
  height: 100%; /* 容器高度100%填充父级 */
  overflow: hidden;
  user-select: none;
}

/* 空状态样式 - 修复高度问题 */
.m-swiper__empty {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  //background: linear-gradient(to bottom,
  //rgba(255, 255, 255, 0.5) 0%,
  //rgba(255, 255, 255, 0) 100%);
}

.m-swiper__empty-image {
  max-width: 120px;
  max-height: 120px;
  object-fit: contain;
  margin-bottom: 16px;

  justify-content: center;
  align-items: center;
  opacity: 0.6;
}

.m-swiper__wrapper {
  display: flex;
  width: 100%;
  height: 100%;
  transition: transform 0.3s ease;
}

.m-swiper__slide {
  flex-shrink: 0;
  width: 100%;
  height: 100%; /* 确保slide填满容器 */
}

/* 水平方向 */
.m-swiper__wrapper {
  flex-direction: row;
}

/* 垂直方向 */
.m-swiper--vertical .m-swiper__wrapper {
  flex-direction: column;
}

.m-swiper--vertical .m-swiper__slide {
  width: 100%;
  height: auto; /* 让高度自适应 wrapper 分配 */
  flex-shrink: 0;
  flex-grow: 0;
}

/* 指示器 - 方条样式 */
.m-swiper__dots {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 10;
  gap: 3px;
  padding: 10px;
}

.m-swiper__dots--top {
  top: 10px;
}

.m-swiper__dots--bottom {
  bottom: 50px; /* 默认值，可通过dotsBottom属性覆盖 */
}

/* 圆点样式在底部时的位置调整 */
.m-swiper__dots--dot.m-swiper__dots--bottom {
  bottom: 0px;
}

.m-swiper__dot {
  width: 20px;
  height: 4px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 2px;
  cursor: pointer;
  transition: all 0.3s ease;
  transform-origin: center;
}

/* 圆点样式 */
.m-swiper__dots--dot .m-swiper__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--dot-color, #FFFFFF);
}

.m-swiper__dots--dot .m-swiper__dot--active {
  background: var(--dot-active-color, #BF6200);
  transform: scale(1.2);
}

.m-swiper__dot:hover {
  background: rgba(255, 255, 255, 0.7);
}

.m-swiper__dot--active {
  background: #fff;
  width: 30px;
}

/* 均分模式样式 */
.m-swiper__dots--evenly {
  justify-content: space-between;
  transform: none !important;
  left: 20px !important;
  right: 20px !important;
  width: auto !important;
}

.m-swiper__dots--evenly .m-swiper__dot {
  flex: 1;
  width: auto !important;
  max-width: none;
  margin: 0 2px;
  transform-origin: center; /* 确保缩放中心点正确 */
}

.m-swiper__dots--evenly .m-swiper__dot--active {
  width: auto !important;
  flex: 1;
}

/* 圆点样式在均分模式下的特殊处理 */
.m-swiper__dots--dot.m-swiper__dots--evenly {
  justify-content: center !important;
  width: auto !important;
  left: 50% !important;
  right: auto !important;
  transform: translateX(-50%) !important;
}

.m-swiper__dots--dot.m-swiper__dots--evenly .m-swiper__dot {
  flex: none !important;
  width: 8px !important;
  height: 8px !important;
  margin: 0 5px;
}

.m-swiper__dots--dot.m-swiper__dots--evenly .m-swiper__dot--active {
  width: 8px !important;
  height: 8px !important;
  flex: none !important;
  transform: scale(1.2);
}

/* 圆点样式在非均分模式下的间距 */
.m-swiper__dots--dot:not(.m-swiper__dots--evenly) {
  gap: 10px;
  justify-content: center;
}

/* 垂直方向指示器位置调整 */
.m-swiper--vertical .m-swiper__dots {
  flex-direction: column;
  top: 50%;
  left: auto;
  right: 10px;
  transform: translateY(-50%);
}

.m-swiper--vertical .m-swiper__dots--top,
.m-swiper--vertical .m-swiper__dots--bottom {
  top: 50%;
  right: 10px;
  bottom: auto;
  transform: translateY(-50%);
}

/* 垂直方向均分模式 */
.m-swiper--vertical .m-swiper__dots--evenly {
  top: 20px !important;
  bottom: 20px !important;
  height: auto !important;
  transform: none !important;
}

.m-swiper--vertical .m-swiper__dots--evenly .m-swiper__dot {
  height: auto;
  flex: 1;
  margin: 2px 0;
  width: 3px; /* 垂直模式下固定宽度 */
}

.m-swiper--vertical .m-swiper__dots--evenly .m-swiper__dot--active {
  width: 3px !important; /* 保持宽度不变，通过缩放实现放大 */
  height: auto;
  flex: 1;
}

.touch-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  display: flex;
  flex-direction: row;
}

.touch-wrapper-left {
  width: 50%;
}

.touch-wrapper-right {
  width: 50%;
}
</style>
