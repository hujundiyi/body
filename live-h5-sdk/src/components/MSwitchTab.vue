<template>
  <div class="tab">
    <div :class="[(action===tab.title?'action':''),avgWidth?'avg-width':'']" :key="tab.title" v-for="tab in tabs"
         @click="onClick(tab)">
      <img v-if="tab.icon"
           :src="(action===tab.title?tab.icon:tab.iconSelect)"/>
      <span>{{ tab.title }}</span>
    </div>
  </div>
</template>

<script>


export default {
  name: "MSwitchTab",
  props: {
    tabs: {
      type: Array,
      default() {
        return []
      }
    },
    action: {
      type: String,
      default() {
        return null
      }
    },
    avgWidth: {
      type: Boolean,
      default() {
        return false;
      }
    }
  },
  data() {
    return {}
  },
  methods: {
    onClick(item) {
      this.$emit('change', item)
    }
  }
}
</script>

<style scoped lang="less">
.tab {
  display: flex;
  background: #363330;
  border-radius: 24px;
  align-content: center;
  height: 40px;
  margin: 0 20px;
  box-sizing: border-box;

  div {
    height: 40px;
    padding: 0 20px;
    box-sizing: border-box;
    line-height: 40px;
    color: @theme-un-select-text-color;

    img {
      margin-right: 5px;
      width: 22px;
      vertical-align: middle;
      height: 22px;
    }

  }

  .avg-width {
    flex: 1;
    text-align: center;
  }

  .action {
    background: linear-gradient(45deg, #FADEBF 0%, #F9B466 100%);
    border-radius: 24px;
    color: @theme-select-text-color
  }
}
</style>

