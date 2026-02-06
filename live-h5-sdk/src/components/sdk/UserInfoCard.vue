<template>
  <div class="list-item" @click="onclick">
    <div style="height: 100%;" v-if="!info.rechargeItem">
      <img class="head-image" :src="info.headImage|| require('@/assets/image/sdk/ic-pic.png')"/>
      <div class="ic-call-mask">
        <div @click.stop="requestCall(info.userId)">
          <img class="ic-call" src="@/assets/image/sdk/ic-call.png"/>
        </div>
      </div>
      <div class="info">
        <div class="nickname">
          <span>{{ info.nickname }},{{ info.age }}</span>
        </div>
        <user-online style="margin-top: 10px" :info="{online:info.status,statusDesc:info.statusDesc }"/>
        <br/>
        <call-coin style="margin-top: 10px" :coin="info.price"/>
      </div>
    </div>
    <div v-else class="list-item recharge-item">
      <div class="wrap">
        <h2>+{{ info.coin }} Coins</h2>
        <p><span>{{ info.rate }}</span><span class="price-tag">${{ info.price }}</span></p>
        <span class="btn-recharge">Recharge</span>
      </div>
    </div>
  </div>
</template>

<script>
import UserOnline from "@/components/sdk/UserOnline.vue";
import {openUserInfo, requestCall} from "@/utils/PageUtils";
import CallCoin from "@/components/sdk/CallCoin.vue";

export default {
  name: "UserInfoCard",
  components: {CallCoin, UserOnline},
  props: {
    info: {
      type: Object
    }
  },
  computed: {
    isActive() {
      return this.isSelect
    }
  },
  methods: {
    requestCall,
    onclick() {
      openUserInfo(this.info.userId)
    }
  }
}
</script>

<style scoped lang="less">
.list-item {
  vertical-align: top;
  display: inline-block;
  position: relative;
  width: 45%;
  box-sizing: border-box;
  height: 200px;
  margin-bottom: 15px;
  border-radius: 10px;
  margin-right: 4%;
  flex: 1;
  color: white;

  .head-image {
    outline: none;
    box-shadow: none;
    width: 100%;
    border-radius: 10px;
    height: 100%;
  }

  .ic-call-mask {
    position: absolute;
    height: 80px;
    bottom: 0;
    width: 100%;
    background: linear-gradient(180deg, rgba(46, 35, 31, 0) 0%, #2E231F 100%);
    border-radius: 0 0 10px 10px;

    div {
      width: 100%;
      height: 100%;
      text-align: center;

      .ic-call {
        margin-top: 20px;
        width: 50px;
        height: 50px;
      }
    }

  }

  .info {
    position: absolute;
    top: 0;
    width: 100%;
    box-sizing: border-box;
    padding: 4px;

    .nickname {
      font-style: italic;
    }
  }
}

.recharge-item {
  width: 100%;
  height: 100%;
  background-image: url("@/assets/image/sdk/ic-first-recharge-bg.png");
  background-size: 100% 100%;
  position: relative;
  text-align: center;
  color: #F6C994;

  .wrap {
    width: 100%;
    position: absolute;
    bottom: 8px;

    p {
      margin-top: 5px;
    }

    .price-tag {
      display: inline-block;
      border-radius: 8px;
      margin-left: 10px;
      padding: 0 5px;
      color: @theme-select-text-color;
      background: linear-gradient(316deg, #FCDDBC 0%, #F5BB7A 100%);
    }

    .btn-recharge {
      display: inline-block;
      margin: 10px auto 0 auto;
      height: 24px;
      padding: 0 8px 0 8px;
      border-radius: 12px;
      color: #FFF7B0;
      background: linear-gradient(180deg, #FF5C3C 0%, #F54421 100%);
    }
  }

}

</style>

