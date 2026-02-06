<template>
  <div class="tag-warp">
    <div :key="index" v-for="(it,index) in items" :class="[it.abbr==checkCode?'action':'']" @click="()=>{
      $emit('change',it)
    }">
      <span>{{ it.desc }}</span>
    </div>
  </div>
</template>

<script>

export default {
  name: "MDictTagCheck",
  props: {
    items: {
      type: Array,
      default() {
        return null
      }
    },
    checkCode: null
  },
  methods: {}
}
</script>

<style scoped lang="less">
.tag-warp {
  padding-left: 14px;
  padding-top: 14px;

  div {
    display: inline-block;
    margin-right: 14px;
    margin-bottom: 14px;
    text-align: center;
    padding: 5px 10px;
    height: 25px;
    line-height: 25px;
    background: #363330;
    color: #ffffff;
    border-radius: 10px;

    span {
      vertical-align: middle;
    }

  }

  .action {
    background: linear-gradient(270deg, #F6C084 0%, #FADEBF 100%);;
  }
}
</style>

