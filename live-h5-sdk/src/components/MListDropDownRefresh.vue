<template lang="html">
  <div class="refresh-mobile" @touchstart="touchStart($event)" @touchmove="touchMove($event)"
       @touchend="touchEnd($event)" :style="{transform: 'translate3d(0,' + top + 'px, 0)'}">
    <div class="pull-refresh">
      <slot name="pull-refresh">
        <div class="down-tip" v-if="dropDownState===1">
          <img class="down-img" src="@/assets/image/components/ic-mlist-up.png">
          <p>Pull to refresh</p>
        </div>
        <div class="up-tip" v-if="dropDownState===2">
          <img class="up-img" src="@/assets/image/components/ic-mlist-dow.png">
          <p>Release refresh</p>
        </div>
        <div class="refresh-tip" v-if="dropDownState===3">
          <img class="refresh-img" src="@/assets/image/components/ic-mlist-loading.png">
          <p>Loading</p>
        </div>
        <div class="refresh-tip" v-if="dropDownState===4">
          <img src="@/assets/image/components/ic-mlist-success.png"/>
          <p>Success</p>
        </div>
      </slot>
    </div>
    <slot></slot>
  </div>
</template>
<script>
export default {
  name: 'MListDropDownRefresh',
  props: {
    onRefresh: {
      type: Function,
      required: false
    }
  },
  data() {
    return {
      // 默认高度, 相应的修改.releshmobile的margin-top和.down-tip, .up-tip, .refresh-tip的height
      defaultOffset: 75,
      top: 0,
      scrollIsToTop: 0,
      startY: 0,
      // 是否下拉
      isDropDown: false,
      // 是否正在刷新
      isRefreshing: false,
      // 显示1:下拉可以刷新, 2:松开立即刷新, 3:正在刷新数据中...
      dropDownState: 1,
      dropDownInfo: {
        downImg: 'ic-mlist-up.png',
      }
    }
  },
  created() {
    if (document.querySelector('.down-tip')) {
      // 获取不同手机的物理像素（dpr）,以便适配rem
      this.defaultOffset = document.querySelector('.down-tip').clientHeight || this.defaultOffset
    }
  },
  methods: {
    /**
     * 触摸开始，手指点击屏幕时
     * @param {object} e Touch 对象包含的属性
     */
    touchStart(e) {
      this.startY = e.targetTouches[0].pageY
    },

    /**
     * 接触点改变，滑动时
     * @param {object} e Touch 对象包含的属性
     */
    touchMove(e) {
      // 检测页面滚动
      const pageScrollTop = document.documentElement.scrollTop || window.pageYOffset || document.body.scrollTop
      // 检测容器滚动：查找父级滚动容器（.list-wrap 或父级有 overflow-y: auto/scroll 的元素）
      const refreshEl = e.currentTarget || this.$el
      let containerScrollTop = 0
      
      // 向上查找滚动容器
      let parent = refreshEl.parentElement
      while (parent && containerScrollTop === 0) {
        const computedStyle = window.getComputedStyle(parent)
        const overflowY = computedStyle.overflowY
        if ((overflowY === 'auto' || overflowY === 'scroll') && parent.scrollTop !== undefined) {
          containerScrollTop = parent.scrollTop
          break
        }
        parent = parent.parentElement
      }

      // 使用容器滚动位置或页面滚动位置（避免 0 被 || 覆盖）
      this.scrollIsToTop = containerScrollTop || pageScrollTop

      if (e.targetTouches[0].pageY > this.startY) {
        // 下拉
        this.isDropDown = true
        // 只有在滚动到顶部且不在刷新状态时，才允许下拉刷新
        if (this.scrollIsToTop === 0 && !this.isRefreshing) {
          // 拉动的距离
          let diff = e.targetTouches[0].pageY - this.startY - this.scrollIsToTop
          this.top = Math.pow(diff, 0.8) + (this.dropDownState === 3 ? this.defaultOffset : 0)
          if (this.top >= this.defaultOffset) {
            this.dropDownState = 2
            e.preventDefault()
          } else {
            this.dropDownState = 1
            // 去掉会导致ios无法刷新
            e.preventDefault()
          }
        }
        // 如果不在顶部，不阻止默认行为，允许正常滚动
      } else {
        // 上滑 - 不阻止默认行为，允许正常滚动
        this.isDropDown = false
        this.dropDownState = 1
        // 如果 top > 0，立即重置，避免 transform 影响滚动
        if (this.top > 0 && !this.isRefreshing) {
          this.top = 0
        }
      }
    },

    /**
     * 触摸结束，手指离开屏幕时
     * @param {object} e Touch 对象包含的属性
     */
    touchEnd() {
      if (this.isDropDown && !this.isRefreshing) {
        if (this.top >= this.defaultOffset) {
          // do refresh
          this.refresh()
          this.isRefreshing = true
        } else {
          // cancel refresh
          this.isRefreshing = false
          this.isDropDown = false
          this.dropDownState = 1
          this.top = 0
        }
      }
    },

    /**
     * 刷新
     */
    refresh() {
      this.dropDownState = 3
      this.top = this.defaultOffset
      this.onRefresh(this.refreshDone)
    },

    /**
     * 刷新完成
     */
    refreshDone(isSuccess) {
      isSuccess && setTimeout(() => {
        this.dropDownState = 4
      }, 200)
      setTimeout(() => {
        this.isRefreshing = false
        this.isDropDown = false
        this.dropDownState = 1
        this.top = 0
      }, 400)
    }
  }
}
</script>

<style scoped lang="less">
.refresh-mobile {
  width: 100%;
  margin-top: -130px;
  -webkit-overflow-scrolling: touch;
}

.pull-refresh {
  width: 100%;
  color: #858484;
  transition-duration: 200ms;
  font-size: 16px;
}

.pull-refresh {
  height: 130px;

  div {
    padding-top: 70px;
    text-align: center;

    img {
      height: 25px;
      width: 25px;
    }
  }

}

.down-img {
  transform: rotate(0deg);
  animation: anticlockwise 0.8s ease;
}

@keyframes anticlockwise {
  0% {
    transform: rotate(-180deg);
  }
  100% {
    transform: rotate(0deg);
  }
}

.up-img, .down-img {
  transform: rotate(180deg);
  animation: clockwise 0.8s ease;
}

@keyframes clockwise {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(-180deg);
  }
}

.refresh-img {
  animation: rotating 1.5s linear infinite;
}

@keyframes rotating {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(1turn);
  }
}
</style>
