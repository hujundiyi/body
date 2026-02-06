<template>
  <m-base-dialog ref="baseDialog" :click-mask-close-dialog="true">
    <template #title>
      <h2 class="title">Report</h2>
    </template>
    <template #content>
      <ul class="content">
        <li v-for="(it,index) in items" :key="index">
          <el-radio v-model="reason" :label="it">{{ it }}</el-radio>
        </li>
      </ul>
    </template>
    <template #footer>
      <m-button width="auto" type="info" @click="onClick(false)">Cancel</m-button>
      <m-button width="auto" style="margin-left: 20px" @click="onClick(true)">Report</m-button>
    </template>
  </m-base-dialog>
</template>

<script>

import MBaseDialog from "@/components/dialog/MBaseDialog.vue";
import {statusReport} from "@/api/sdk/user";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: "MReportDialog",
  components: {MBaseDialog},
  props: {
    reportedUserId: {
      type: [Number, String],
      default() {
        return null
      }
    },
    onReportedSuccess: {
      type: Function,
      default() {
        return null;
      }
    }
  },
  data() {
    const items = [
      'Incorrect information',
      'Sexual content',
      'Harassment or repulsive language',
      'Unreasonable demands'
    ];
    return {
      items: items,
      reason: items[0]
    }
  },
  methods: {
    onClick(isConfirm) {
      if (!isConfirm) {
        this.$refs.baseDialog.handleClose();
        return
      }
      statusReport({reportedUserId: this.reportedUserId, reason: this.reason}).then((rsp) => {
        if (rsp.success) {
          this.onReportedSuccess();
          showCallToast('Success.', 'success');
          this.$refs.baseDialog.handleClose();
        }
      });
    }
  }
}
</script>
<style scoped lang="less">
.title {
  color: @theme-bg-color;
}

.content {
  li {
    height: 30px;
    line-height: 30px;
  }
}
</style>

