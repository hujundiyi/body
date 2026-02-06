<template>
  <a class="m-tab-item" :class="{'is-active':isSelect}" @click="goToRouter">
    <div class="m-tab-item-icon">
      <img :src="isSelect?tabData.iconSelect:tabData.icon" draggable="false"/>
      <span class="red-dot" v-if="tabData.dotNum > 0">
        {{ tabData.dotNum > 99 ? '99+' : tabData.dotNum }}
      </span>
    </div>
  </a>
</template>

<script>

export default {
  name: "MTabItem",
  props: {
    tabData: {
      type: Object,
      default() {
        return {
          path: null,
          icon: null,
          iconSelect: null
        };
      }
    }
  },
  computed: {
    isSelect() {
      return this.$route.path.indexOf(this.tabData.path) !== -1
    }
  },
  methods: {
    goToRouter() {
      this.$parent.$emit('tabActionEvent', this.tabData.path)
    }
  }
}
</script>

<style scoped lang="less">
.m-tab-item {
  flex: 1;
  text-align: center;
  background: transparent;
  -webkit-tap-highlight-color: transparent;
  user-select: none;
  -webkit-user-select: none;
  -webkit-user-drag: none;

  .m-tab-item-icon {
    display: inline-block;
    padding-top: 5px;
    padding-bottom: 1px;
    position: relative;

    img {
      width: 35px;
      height: 35px;
      user-select: none;
      -webkit-user-select: none;
      -webkit-user-drag: none;
    }

  }

  .red-dot {
    position: absolute;
    top: -6px;
    right: 0;
    min-width: 20px;
    min-height: 20px;
    padding: 0 5px;
    background: #FE5621;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 500;
    color: #ffffff;
    line-height: 1;
    box-sizing: border-box;
    z-index: 10;
  }

}
</style>

