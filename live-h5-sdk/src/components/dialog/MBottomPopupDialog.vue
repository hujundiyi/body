<template>
  <m-bottom-dialog ref="bottomDialog">
    <div class="content">
      <div class="center">

        <ul>
          <li class="item" v-for="(it,index) in items" :key="index" @click="()=>{it.onClick();closeDialog()}">
            {{ it.text }}
          </li>
        </ul>
        <div class="item cancel" @click="closeDialog">Cancel</div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>

import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MRechargeDialog",
  components: {MBottomDialog},
  props: {
    items: {
      type: Array,
      default() {
        return [];
      }
    }
  },
  data() {
    return {}
  },
  methods: {
    closeDialog() {
      console.log( '点击了')
      this.$refs.bottomDialog.closeDialog()
    }
  }
}
</script>
<style scoped lang="less">
.content {
  padding-left: 20px;
  padding-right: 20px;
  box-sizing: border-box;
}

.item {
  width: 100%;
  height: 48px;
  line-height: 48px;
  text-align: center;
  background: #333;
  color: #FFFFFF;
}

.cancel {
  border-radius: 16px;
  margin: 20px 0;
}

ul {
  li:first-child {
    border-top-left-radius: 14px;
    border-top-right-radius: 14px;
  }

  li:last-child {
    border-bottom-left-radius: 14px;
    border-bottom-right-radius: 14px;
  }
}

</style>

