<template>
  <div class="m-tab" :class="{'is-first-selected': isFirstTabSelected}">
    <slot></slot>
  </div>
</template>

<script>
export default {
  name: "MTab",
  computed: {
    isFirstTabSelected() {
      return this.$route.path.indexOf('/sdk/match') !== -1;
    }
  }
}
</script>

<style scoped lang="less">
.m-tab {
  display: flex;
  flex-direction: row;
  position: fixed;
  bottom: 25px;
  left: 12%;
  background: #333333; // 默认背景色 #333333FF
  border-radius: 32.5px;
  right: 12%;
  overflow: hidden;
  align-items: center;
  height: 65px;
  z-index: 1000;
  transition: background-color 0.3s;

  &.is-first-selected {
    background-color: transparent;
  }
}
</style>
