<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'super-match-help-dialog'">
    <div class="help-content">
      <div class="help-title">With Super Match You're</div>
      
      <div class="help-list">
        <div class="help-item">
          <i class="el-icon-warning"></i>
          <span>More likely to chat longer</span>
        </div>
        <div class="help-item">
          <i class="el-icon-warning"></i>
          <span>Less likely to meet camera-off users</span>
        </div>
        <div class="help-item">
          <i class="el-icon-warning"></i>
          <span>Less likely to meet the same person again</span>
        </div>
      </div>

      <div class="action-btn" @click="close">
        OK
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MSuperMatchHelpDialog",
  components: { MBottomDialog },
  methods: {
    close() {
      this.$refs.bottomDialog.closeDialog();
    }
  }
}
</script>

<style scoped lang="less">
.help-content {
  background: #1A1A1A;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 30px 24px;
  color: white;
  padding-bottom: 40px;
}

.help-title {
  font-size: 20px;
  font-weight: bold;
  margin-bottom: 24px;
  text-align: left;
}

.help-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 32px;
}

.help-item {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #999;
  font-size: 14px;
  
  .el-icon-warning {
    color: #999;
    font-size: 16px;
  }
}

.action-btn {
  background: white;
  color: black;
  height: 48px;
  border-radius: 24px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
}
</style>
