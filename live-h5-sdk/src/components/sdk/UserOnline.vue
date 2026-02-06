<template>
  <div :class="['online','size-'+size]">
    <span v-if="info.online===2" class="dot"/>
    <span>{{ info.statusDesc }}</span>
  </div>
</template>

<script>
export default {
  name: "UserOnline",
  props: {
    size: {
      type: String,
      default() {
        // min max
        return 'min';
      }
    },
    info: {
      type: Object,
      default() {
        return {online: 1, statusDesc: 'Online'}
      }
    }
  }
}
</script>

<style scoped lang="less">

.online {
  display: inline-block;
  background: rgba(0, 0, 0, 0.35);
  padding-left: 8px;
  padding-right: 8px;

  .dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    vertical-align: middle;
    background: #13ce66;
    margin-top: -2px;
    margin-right: 4px;
    border-radius: 3px;
  }
}

.size-min {
  height: 20px;
  line-height: 20px;
  border-radius: 10px;
}

.size-max {
  height: 25px;
  line-height: 25px;
  border-radius: 12.5px;
}
</style>

