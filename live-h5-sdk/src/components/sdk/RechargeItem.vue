<template>
  <div>
    <page-status :page-status="pageStatus" :error-msg="errorMsg" @click="loadData"/>
    <div v-if="pageStatus===1" class="list">
      <div class="items" v-for="(it,index) in items" :key="index">
        <div class="coin">
          <img src="@/assets/image/sdk/ic-coin-max.png"/>
          <div>
            <p>{{ it.coin }}</p>
            <span>Coins</span>
          </div>
        </div>
        <p class="money">$ {{ it.price }}</p>
      </div>
    </div>
  </div>
</template>

<script>
import {productList} from "@/api/sdk/system";
import PageStatus from "@/components/sdk/PageStatus.vue";

export default {
  name: "RechargeItem",
  components: {PageStatus},
  data() {
    return {
      pageStatus: 1,
      errorMsg: null,
      items: []
    }
  },
  mounted() {
    this.loadData();
  },
  methods: {
    loadData() {
      productList().then(({data}) => {
        this.items = data;
        this.pageStatus = this.items.length <= 0 ? 2 : 1;
        this.pageStatus = 1;
      }).catch((e) => {
        this.errorMsg = e;
        setTimeout(() => {
          // 显示状态页面
          this.pageStatus = 3;
        }, 500)
      });
    }
  }
}
</script>

<style scoped lang="less">

.list {
  position: relative;
  margin-top: 20px;
  box-sizing: border-box;
  padding-left: 4%;
  height: 600px;

  .items {
    display: inline-block;
    height: 120px;
    background: white;
    border-radius: 8px;
    padding: 10px;
    box-sizing: border-box;
    margin-bottom: 4%;
    margin-right: 4%;
    width: 46%;

    .coin {
      display: flex;
      align-items: center;
      justify-content: center;
      color: @theme-bg-color;
      text-align: center;
      margin-top: 10px;

      img {
        height: 40px;
        width: 40px;
      }

      div {
        margin-left: 8px;

        p {
          font-weight: bold;
          font-size: @max-text-size;
        }

      }
    }

    .money {
      height: 30px;
      line-height: 30px;
      text-align: center;
      margin-top: 10px;
      margin-left: 5%;
      margin-right: 5%;
      color: @theme-bg-color;
      border: @theme-bg-color solid 2px;
      border-radius: 20px;
    }

  }

}

</style>

