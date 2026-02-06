<template>
  <m-base-dialog ref="baseDialog" :click-mask-close-dialog="true">
    <template #content>
      <p class="content"> {{ message }}</p>
    </template>
    <template #footer>
      <m-button width="auto" @click="onClick(true)">YES</m-button>
      <m-button width="auto" type="info" style="margin-left: 20px" @click="onClick(false)">NO</m-button>
    </template>
  </m-base-dialog>
</template>

<script>

import MBaseDialog from "@/components/dialog/MBaseDialog.vue";

export default {
  name: "MHintDialog",
  components: {MBaseDialog},
  props: {
    message: {
      type: String,
      default() {
        return null
      }
    },
    onButtonClick: {
      type: Function,
      default() {
        return null;
      }
    }
  },
  data() {
    return {}
  },
  methods: {
    onClick(isConfirm) {
      if (this.onButtonClick(isConfirm)) {
        console.log('关闭')
        this.$refs.baseDialog.handleClose();
      }
    }
  }
}
</script>
<style scoped lang="less">
.content {
  color: @theme-bg-color;
  font-size: @max-text-size;
}
</style>

