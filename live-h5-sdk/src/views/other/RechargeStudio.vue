<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div>
        <div class="head">
          <m-action-bar/>
          <div class="head-card">
            <img src="@/assets/image/sdk/ic-coin-max.png"/>
            <div>
              <p>{{ coin }}</p>
              <span>Available Coins</span>
            </div>
          </div>
        </div>
        <recharge-item/>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>


import RechargeItem from "@/components/sdk/RechargeItem.vue";

export default {
  name: 'RechargeStudio',
  components: {RechargeItem},
  data() {
    return {}
  },
  computed: {
    coin() {
      let {coin} = this.$store.state.user.loginUserInfo;
      return coin
    }
  },
  methods: {}
}
</script>

<style scoped lang="less">
.head {
  background-image: url("@/assets/image/sdk/ic-recharge-head-bg.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;

  .head-card {
    display: flex;
    height: 90px;
    align-items: center;
    align-self: center;
    justify-content: center;

    img {
      height: 60px;
      width: 60px;
    }

    div {
      margin-left: 20px;

      p {
        margin-top: 15px;
        margin-bottom: 5px;
        font-size: @max-big-text-size;
      }

    }
  }

}

</style>
