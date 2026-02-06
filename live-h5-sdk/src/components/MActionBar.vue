<template>
  <div class="m-action-bar">
    <img v-show="showBack" class="ic-back" :src="backIcon" alt="Back" @click="backClick" />
    <p v-if="title">{{ title }}</p>
    <div v-else>
      <slot name="center"></slot>
    </div>
    <span class="right">
      <slot name="right"></slot>
    </span>
  </div>
</template>

<script>
export default {
  name: "MActionBar",
  props: {
    showBack: {
      type: Boolean,
      default() {
        return true;
      }
    },
    title: {
      type: String,
      default() {
        return this.$route.meta.title;
      }
    }
  },
  computed: {
    backIcon() {
      return require('@/assets/image/ic-common-back.png');
    }
  },
  methods: {
    backClick() {
      this.$router.back();
    },
  }
}
</script>

<style scoped lang="less">
.m-action-bar {
  height: 60px;
  display: flex;
  align-content: center;
  align-items: center;

  .ic-back {
    margin-left: 20px;
    display: inline-block;
    width: 30px;
    height: 30px;
    object-fit: contain;
    cursor: pointer;
    position: absolute;
  }

  p, div {
    flex: 1;
    text-align: center;
    font-size: @max-text-size
  }

  .right {
    font-size: @max-big-text-size;
    font-weight: bold;
  }
}
</style>

