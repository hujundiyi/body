<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar title="Expenses record"/>
    </template>
    <template #page-content-wrap>
      <m-list ref="MList" :url="'charge/businessList'">
        <template v-slot:m-list-item="{items}">
          <div class="list-items" v-for="(it,index) in items" :key="index">
            <img :src="it.pic"/>
            <div class="center">
              <p>{{ it.bizTypeDesc }}</p>
              <span>{{ it.time }}</span>
            </div>
            <div class="coin">
              <span :style="{color:(it.coin<=0?'#FF2B69':'#07E987')}">{{ it.coin }}</span>
              <img src="@/assets/image/sdk/ic-coin-min.png"/>
            </div>
          </div>
        </template>
      </m-list>
    </template>
  </m-page-wrap>
</template>

<script>

import MList from "@/components/MList.vue";
import {statusBlack} from "@/api/sdk/user";

export default {
  name: 'ExpensesRecord',
  components: {MList},
  data() {
    return {}
  },
  methods: {
    async statusBlackClick(it) {
      const {success} = await statusBlack(it.userId);
      if (success) {
        this.$refs.MList.refresh();
      }
    }
  }
}
</script>

<style scoped lang="less">

.list-items {
  margin-top: 35px;
  display: flex;
  padding: 0 20px;
  align-content: center;
  align-items: center;

  img:first-child {
    width: 60px;
    height: 60px;
    border-radius: 30px;
    border: @theme-color solid 1px;
  }

  .center {
    flex: 1;
    margin-left: 20px;

    p {
      margin-top: 10px;
      color: white;
    }

    span {
      margin-top: 5px;
      display: block;
      color: #777777;
    }
  }

  .coin {
    display: inline-block;
    font-size: @max-text-size;
    margin: 0 10px;

    img {
      margin-left: 5px;
      vertical-align: middle;
    }

    span {
      vertical-align: middle;
    }
  }
}

.content {
  margin-top: 40px;
}

</style>
