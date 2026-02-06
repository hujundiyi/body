<template>
  <div class="delete">
    <div class="slider">
      <div
        class="content"
        @touchstart="touchStart"
        @touchmove="touchMove"
        @touchend="touchEnd"
        :style="deleteSlider">
        <slot name="content"></slot>
      </div>
      <div class="right-more" ref="rightMore" v-show="showRight">
        <slot name="right"></slot>
      </div>
    </div>
  </div>
</template>
<script>
// https://blog.csdn.net/huaqishen123/article/details/111299823
export default {
  name: 'MSlideTo',
  props: {
    // 父组件当前移动的组件id
    sensitivity: {
      // 灵敏度（1 ~ 10）1 => 最细腻（跟手） 10 => 最灵敏
      type: Number,
      default() {
        return 5;
      }
    }
  },
  data() {
    return {
      //触摸开始位置
      startX: 0,
      //结束位置
      endX: 0,
      //滑动时的位置
      moveX: 0,
      //移动距离
      disX: 0,
      //滑动时的效果
      deleteSlider: "",
      // 左滑后显示出来的remove元素的宽度，设定为最大左滑距离
      wd: 0,
      showRight: true
    };
  },
  mounted() {
    this.ready();
    // 左滑后显示出来的remove元素的宽度，设定为最大左滑距离
    this.wd = this.$refs.rightMore.offsetWidth
    // eslint-disable-next-line vue/no-mutating-props
    this.sensitivity = this.sensitivity > 10 ? 10 : (this.sensitivity < 1 ? 5 : this.sensitivity)
  },
  methods: {
    touchStart(ev) {
      ev = ev || event;
      //tounches类数组，等于1时表示此时有只有一只手指在触摸屏幕（在touchend时，此属性为空）
      if (ev.touches.length === 1) {
        // 记录开始位置
        this.startX = ev.touches[0].clientX;
      }
    },
    touchMove(ev) {
      ev = ev || event;
      if (ev.touches.length === 1) {
        // 滑动时距离浏览器左侧实时距离
        this.moveX = ev.touches[0].clientX;
        //起始位置减去 实时的滑动的距离，得到手指实时偏移距离
        this.disX = this.startX - this.moveX;
        // 如果是向右滑动或者不滑动，不改变滑块的位置
        if (this.disX < 0 || this.disX === 0) {
          this.deleteSlider = "transform:translateX(0px)";
          // 大于0，表示左滑了，此时滑块开始滑动
        } else if (this.disX > 0) {
          //具体滑动距离取的是 手指偏移距离 * sensitivity。
          this.deleteSlider = "transform:translateX(-" + this.disX * this.sensitivity + "px)";
          // 最大也只能等于删除按钮宽度
          if (this.disX * this.sensitivity >= this.wd) {
            this.deleteSlider = "transform:translateX(-" + this.wd + "px)";
          }
        }
      }
    },
    touchEnd(ev) {
      ev = ev || event;
      // touchEnd获取值为changedTouches，因为当touchend时，touches的值会被清空，详情可参考https://www.cnblogs.com/mengff/p/6005516.html
      if (ev.changedTouches.length === 1) {
        let endX = ev.changedTouches[0].clientX;
        this.disX = this.startX - endX;
        //如果距离小于删除按钮一半,强行回到起点
        if (this.disX * this.sensitivity < this.wd / 2) {
          this.deleteSlider = "transform:translateX(0px)";
        } else {
          //大于一半 滑动到最大值
          this.deleteSlider = "transform:translateX(-" + this.wd + "px)";
        }
      }
    },
    ready() {
      document.addEventListener("click", (e) => {
        // this.$el.contains(e.target) === 除了自己意外的其他元素，此处的作用是当用户点击其他组件，隐藏当前左滑的组件
        if (!this.$el.contains(e.target) && this.disX !== 0) {
          this.deleteSlider = "transform:translateX(-" + "0px)";
        }
      });
    },
    deleteItem(callBack) {
      this.showRight = false;
      this.deleteSlider = "transform:translateX(-1000px)";
      if (callBack) {
        callBack();
      }
    }
  },

};
</script>
<style scoped lang="less">
.delete {
  height: 100%;
}

.slider {
  width: 100%;
  height: 100%;
  position: relative;
  user-select: none;
}

.content {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  z-index: 100;
  transition: 0.3s;
  background: @theme-bg-color;
}

.right-more {
  position: absolute;
  min-width: 60px;
  max-width: 150px;
  height: 100%;
  right: 0;
  top: 0;
  color: #fff;
  text-align: center;
  font-size: 16px;
}
</style>
