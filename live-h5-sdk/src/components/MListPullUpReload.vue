<template lang="html">
  <div class="load-mobile" @touchstart="touchStart($event)" @touchmove="touchMove($event)" @touchend="touchend($event)">
    <slot></slot>
    <footer class="load-more" v-if="openLoadMore&&pullUpState>0">
      <slot name="load-more">
        <div class="more-tip" v-if="pullUpState===1">
          <span class="more-text">{{ pullUpInfo.moreText }}</span>
        </div>
        <div class="loading-tip" v-if="pullUpState===2">
          <span class="loading-icon"></span>
          <span class="loading-text">{{ pullUpInfo.loadingText }}</span>
        </div>
        <div class="no-more-tip" v-if="pullUpState===3">
          <span class="connecting-line"></span>
          <span class="no-more-text">{{ pullUpInfo.noMoreText }}</span>
          <span class="connecting-line"></span>
        </div>
      </slot>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'MListPullUpReload',
  props: {
    parentPullUpState: {
      default: 0
    },
    onInfiniteLoad: {
      type: Function,
      require: false
    },
    // 是否支持加载更多
    openLoadMore:
      {
        type: Boolean,
        default
          () {
          return true
        }
      }
  },
  data() {
    return {
      top: 0,
      startX: 0,
      startY: 0,
      endX: 0,
      endY: 0,
      // 1:加载更多, 2:加载中……, 3:没有数据
      pullUpState: 0,
      // 是否正在加载
      isLoading: false,
      pullUpInfo: {
        noMoreText: 'No more',
        loadingText: 'Loading...',
        moreText: 'Load more'
      }
    }
  },
  methods: {
    /**
     * 触摸开始，手指点击屏幕时
     * @param {object} e Touch 对象包含的属性
     */
    touchStart(e) {
      this.startX = e.touches[0].pageX
      this.startY = e.touches[0].pageY
    },

    /**
     * 接触点改变，滑动时
     * @param {object} e Touch 对象包含的属性
     */
    touchMove(e) {
      this.endX = e.changedTouches[0].pageX
      this.endY = e.changedTouches[0].pageY
      let direction = this.getSlideDirection(this.startX, this.startY, this.endX, this.endY)
      switch (direction) {
        case 0:
          // console.log('没滑动')
          break
        case 1:
          // console.log('向上')
          this.scrollToTheEnd()
          break
        case 2:
          // console.log('向下')
          break
        case 3:
          // console.log('向左')
          break
        case 4:
          // console.log('向右')
          break
        default:
      }
    },

    /**
     * 触摸结束，手指离开屏幕时
     * @param {object} e Touch 对象包含的属性
     */
    touchend() {
      this.isLoading = false
    },

    /**
     * 判断滚动条是否到底
     */
    scrollToTheEnd() {
      let innerHeight = document.querySelector('.load-mobile').clientHeight
      // 变量scrollTop是滚动条滚动时，距离顶部的距离
      let scrollTop = document.documentElement.scrollTop || window.pageYOffset || document.body.scrollTop
      // 变量scrollHeight是滚动条的总高度
      let scrollHeight = document.documentElement.clientHeight || document.body.scrollHeight
      // 滚动条到底部的条件
      if (scrollTop + scrollHeight >= innerHeight) {
        if (this.pullUpState !== 3 && !this.isLoading) {
          this.infiniteLoad()
        }
      }
    },

    /**
     * 上拉加载数据
     */
    infiniteLoad() {
      if (this.pullUpState !== 0) {
        this.pullUpState = 2
        this.isLoading = true
        this.onInfiniteLoad()
      }
    },
    /**
     * 返回角度
     */
    getSlideAngle(dx, dy) {
      return Math.atan2(dy, dx) * 180 / Math.PI
    },

    /**
     * 根据起点和终点返回方向 1：向上，2：向下，3：向左，4：向右,0：未滑动
     * @param {number} startX X轴开始位置
     * @param {number} startY X轴结束位置
     * @param {number} endX Y轴开始位置
     * @param {number} endY Y轴结束位置
     */
    getSlideDirection(startX, startY, endX, endY) {
      let dy = startY - endY
      let dx = endX - startX
      let result = 0
      // 如果滑动距离太短
      if (Math.abs(dx) < 2 && Math.abs(dy) < 2) {
        return result
      }
      let angle = this.getSlideAngle(dx, dy)
      if (angle >= -45 && angle < 45) {
        result = 4
      } else if (angle >= 45 && angle < 135) {
        result = 1
      } else if (angle >= -135 && angle < -45) {
        result = 2
      } else if ((angle >= 135 && angle <= 180) || (angle >= -180 && angle < -135)) {
        result = 3
      }
      return result
    }
  },
  watch: {
    parentPullUpState(curVal) {
      this.pullUpState = curVal
    }
  }
}
</script>

<style scoped lang="less">
.load-more {
  width: 100%;
  height: 200px;
  padding-top: 50px;
  color: #858484;
  font-size: @min-text-size;
}

.more-tip,
.loading-tip,
.no-more-tip {
  display: flex;
  align-items: center;
  justify-content: center;
}

.load-mobile .loading-icon {
  display: inline-flex;
  width: 30px;
  height: 30px;
  background: url(@/assets/image/components/ic-mlist-loading.png) no-repeat;
  background-size: cover;
  margin-right: 5px;
  animation: rotating 2s linear infinite;
}

@keyframes rotating {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(1turn);
  }
}

.no-more-tip {
  display: flex;

  .connecting-line {
    display: inline-flex;
    flex: 1;
    height: 1px;
    border-radius: 1px;
    margin-left: 20px;
    margin-right: 20px;
  }

  .connecting-line:first-child {
    background: linear-gradient(to right, @theme-inline-line-color, @theme-line-color);
  }

  .connecting-line:last-child {
    background: linear-gradient(to left, @theme-inline-line-color, @theme-line-color);
  }
}


</style>
