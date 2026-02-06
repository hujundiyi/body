<template>
  <transition name="el-fade-in">
    <div v-if="pageStatus!==1" class="m-page-status" @click="$emit('click')">
      <div v-if="pageStatus===2">
        <img src="@/assets/image/sdk/ic_empty@2x.png"/>
<!--        <img src="@/assets/image/sdk/ic-empty.png"/>-->
        <p>Nothing here yet.</p>
<!--        <p>Nothing here yet.</p>-->
      </div>
      <div v-if="pageStatus===3">
        <img src="@/assets/image/sdk/ic-error.png"/>
        <p v-if="errorMsg"> {{ errorMsg }}</p>
        <p>Click on the blank space to retry</p>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  props: {
    // 1: 内容页面 2:空页面 3:加载出错页面
    errorMsg: {
      type: String,
      default() {
        return null;
      }
    },
    // 1: 内容页面 2:空页面 3:加载出错页面
    pageStatus: {
      type: Number,
      default() {
        return 1;
      }
    }
  }
}
</script>

<style scoped lang="less">

.m-page-status {
  text-align: center;
  height: 400px;
  padding-top: 120px;
  color: @theme-un-select-text-color;

  div {
    img {
      width: 120px;
      height: 120px;
    }

    p:last-child {
      margin-top: 15px;
      font-size: @min-text-size;
    }
  }
}

</style>

