<template>
  <m-bottom-dialog ref="bottomDialog">
    <div class="content">
      <div class="head">
        <span>Amount:</span>
        <img src="@/assets/image/sdk/ic-coin-min.png"/>
        <b>{{ userInfo.coin }}</b>
      </div>
      <ul class="center">
        <li :class="['item',it.id===actionItem.id?'action':'']" v-for="(it,index) in items" :key="index"
            @click="()=>{actionItem=it}">
          <div class="value">
            <img :src="it.staticPic"/>
            <div>
              <p>{{ it.name }}</p>
              <b>{{ it.price }} coins</b>
            </div>
          </div>
          <span class="btn-send" @click="onSendClick(it)">Send</span>
        </li>
      </ul>
      <footer>
        <m-button width="auto" size="smail" @click="showRechargeDialog()">
          Recharge
        </m-button>
      </footer>
    </div>
  </m-bottom-dialog>
</template>

<script>

import {getGiftList} from "@/api/sdk/call";
import {showRechargeDialog} from "@/components/dialog/index";
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MGiftChangeDialog",
  props: {
    onChange: {
      type: Function,
      default() {
        return null;
      }
    }
  },
  components: {MBottomDialog},
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo
    }
  },
  data() {
    return {
      items: [],
      actionItem: {}
    }
  },
  mounted() {
    getGiftList().then(({data}) => {
      this.items = data;
    })
  },
  methods: {
    showRechargeDialog,
    onSendClick(it) {
      this.onChange(it);
      this.$refs.bottomDialog.closeDialog();
    }
  }
}
</script>
<style scoped lang="less">
.content {
  background: #333333;
  border-top-right-radius: 10px;
  border-top-left-radius: 10px;
}

.head {
  height: 60px;
  line-height: 60px;
  color: #ffffff;
  text-align: center;
  font-size: @max-big-text-size;
  border-bottom: @theme-line-color solid 1px;

  img, b {
    display: inline-block;
    margin-left: 10px;
  }

  img {
    width: 18px;
    vertical-align: middle;
  }

  b {
    font-size: @text-size;
    vertical-align: middle;
  }

}

.center {
  height: 260px;
  margin-top: 2%;
  padding-left: 2%;
  overflow-y: scroll;

  .item {
    width: 22.5%;
    height: 120px;
    margin-right: 2%;
    vertical-align: top;
    display: inline-block;
    position: relative;
    box-sizing: border-box;
    text-align: center;
    color: #ffffff;

    .value {
      box-sizing: border-box;

      div {
        height: 60px;
      }
    }

    img {
      width: 60px;
      height: 60px;
    }

    b {
      color: @theme-un-select-text-color;
    }

    .btn-send {
      display: none;
    }
  }

  .action {
    .value div {
      display: none;
    }

    .value {
      border: @theme-color solid 2px;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    }

    .btn-send {
      height: 40px;
      display: block;
      margin-top: 5px;
      line-height: 40px;
      color: #fff;
      text-align: center;
      border-bottom-right-radius: 8px;
      border-bottom-left-radius: 8px;
      background: @theme-color;
    }

  }
}

footer {
  border-top: @theme-line-color solid 1px;
  height: 60px;
  padding-right: 15px;
  text-align: right;
  line-height: 60px;
}

</style>

