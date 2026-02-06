<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <div class="head">
        <m-switch-tab :tabs="tabs" :action="actionName" @change="(tab)=>{actionName=tab.title}"/>
        <div class="recharge-inlet" @click="()=>{$router.push({name:'PageRechargeStudio'})}">
          <img src="@/assets/image/sdk/ic-recharge-coins.png"/>
          <span>Recharge</span>
        </div>
      </div>
    </template>
    <template #page-content-wrap>
      <div>
        <m-list ref="hotList" v-show="actionName==='Hot'" :on-load-success="onLoadSuccess"
                :url="'/anchor/getGotList'">
          <template v-slot:m-list-item="{items}">
            <div class="list-items">
              <user-info-card v-for="(it,index) in items" :key="index" :info="it"/>
            </div>
          </template>
        </m-list>
        <m-list v-show="actionName==='Follow'" :url="'/anchor/getFollowList'">
          <template v-slot:m-list-item="{items}">
            <div class="list-items">
              <user-info-card v-for="(it,index) in items" :key="index" :info="it"/>
            </div>
          </template>
        </m-list> 
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MList from "@/components/MList.vue";
import MSwitchTab from "@/components/MSwitchTab.vue";
import UserInfoCard from "@/components/sdk/UserInfoCard.vue";
import {getFirstRechargeConfig} from "@/api/sdk/user";
import {showRechargePromoDialog} from "@/components/dialog";

export default {
  name: 'PageMainIndex',
  components: {UserInfoCard, MSwitchTab, MList},
  data() {
    const actionName = 'Hot'
    return {
      actionName: actionName,
      tabs: [
        {
          title: actionName,
          icon: require('@/assets/image/tab/ic-hot.png'),
          iconSelect: require('@/assets/image/tab/ic-hot-select.png')
        },
        {
          title: 'Follow'
        }
      ]
    }
  },
  mounted() {
    console.log('PageMainIndex mounted, 路径:', this.$route.path);
    // 页面加载完成后显示充值促销弹窗
    this.showPromoDialog();
  },
  activated() {
    console.log('PageMainIndex activated, 路径:', this.$route.path);
    // 当页面被 keepAlive 缓存后再次激活时，也显示弹窗
    this.showPromoDialog();
  },
  methods: {
    showPromoDialog() {
      // 延迟一下确保页面完全渲染
      this.$nextTick(() => {
        setTimeout(() => {
          console.log('PageMainIndex: 显示充值促销弹窗');
          try {
            const dialog = showRechargePromoDialog();
            console.log('PageMainIndex: 弹窗已调用，返回结果:', dialog);
          } catch (error) {
            console.error('PageMainIndex: 显示弹窗失败:', error);
          }
        }, 500);
      });
    },
    onLoadSuccess(isRefresh) {
      if (isRefresh) {
        getFirstRechargeConfig().then(({data}) => {
          if (data) {
            data.rechargeItem = true;
            this.$refs.hotList.listData.splice(1, 0, data)
            data = this.$refs.hotList.listData[1]
          }
        })
      }
    }
  }
}
</script>
<style scoped lang="less">
.head {
  width: auto;
  display: flex;
  align-content: center;
  margin-top: 15px;

  .recharge-inlet {
    color: #F9D09E;
    line-height: 40px;
    position: absolute;
    background: #363330;
    right: 0;
    border-top-left-radius: 20px;
    border-bottom-left-radius: 20px;

    img {
      width: 47px;
      vertical-align: middle;
    }

    span {
      margin-left: 10px;
      margin-right: 10px;
      display: inline-block;
    }
  }
}

.list-items {
  padding-left: 6%;
}

</style>
