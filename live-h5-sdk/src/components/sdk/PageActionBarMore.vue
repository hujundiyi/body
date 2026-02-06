<template>
  <img @click="showUserReportPopup(userId,
  ()=>{$emit('onBlackSuccess')})"
       class="el-report" src="@/assets/image/sdk/ic-more.png"/>
</template>

<script>
import {showUserReportPopup} from "@/components/dialog";

export default {
  props: {
    userId: {
      type: [Number, String],
      default() {
        return null;
      }
    }
  },
  methods: {showUserReportPopup}
}
</script>

<style scoped lang="less">
.el-report {
  width: 25px;
  margin-right: 10px;
  display: inline-block;
}
</style>

