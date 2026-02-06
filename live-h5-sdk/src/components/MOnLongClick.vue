<template>
  <div @touchstart="startLongPress"
       @touchend="endLongPress"
       @touchcancel="endLongPress">
    <slot></slot>
  </div>
</template>

<script>

export default {
  name: "MOnLongClick",
  props: {
    longPressTime: {
      type: Number,
      default() {
        return 1000;
      }
    },
  },

  methods: {
    startLongPress() {
      // 开始长按时，设置一个计时器
      this.timer = setTimeout(() => {
        this.$emit('onLongClick')
      }, this.longPressTime);
    },
    endLongPress() {
      // 结束长按时，清除计时器
      clearTimeout(this.timer);
    }
  }
}
</script>

<style scoped lang="less">
.m-button {
  height: 48px;
  border-radius: 24px;
  border: none;
  background: linear-gradient(135deg, #F6C084 0%, #FADEBF 100%);

  .text {
    flex: 1;
    color: @theme-select-text-color;
    text-align: center;
    font-size: @max-text-size;
    font-weight: bold;
  }
}

.m-width-full {
  width: 80%;
  margin-left: 10%;
}

.m-width-auto {
  padding: 0 20px;
  margin: auto;
}

.m-type-info {
  background: linear-gradient(135deg, #f8f8f8 0%, #dedede 100%);
}

.m-type-warning {
  background: #FF5C3C;

  .text {
    color: white
  }

}
</style>

