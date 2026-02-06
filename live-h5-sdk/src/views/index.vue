<template>
  <div class="page-sdk-index">
    <m-router-view/>
    <m-tab @tabActionEvent='changeSelectedValue'>
      <m-tab-item v-for="tab in tabs" :key="tab.title" :tab-data='tab'/>
    </m-tab>
  </div>
</template>

<script>
import mTab from '@/components/MTab.vue'
import mTabItem from '@/components/MTabItem.vue'
import MRouterView from "@/components/MRouterView.vue";
import {TencentImUtils} from "@/utils/TencentImUtils";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import clientNative from "@/utils/ClientNative";
import {requestToHome} from "@/api/sdk/user";
import store from "@/store";
import {showRechargePromoDialog, showPurchaseSuccessDialog} from "@/components/dialog";
import RechargeCallEnd from "@/views/call/RechargeCallEnd.vue";

let hasRunFirstRechargeCheck = false;

export default {
  name: 'PageSdkIndex',
  components: {
    MRouterView,
    mTab,
    mTabItem,
  },
  data() {
    return {
    }
  },
  created() {
    requestToHome();
    if (hasRunFirstRechargeCheck) return;
    hasRunFirstRechargeCheck = true;
    store.dispatch('FetchFirstRechargeList')
      .then((res) => {
        if (!res || res.code !== 200) return;
        if (store.state.user.allPurchased) return;
        this.showPromoOnFirstLoad();
      })
      .catch(() => {});
  },
  computed: {
    tabs() {
      return [
        {
          path: '/sdk/me',
          title: 'Me',
          icon: require('@/assets/image/tab/ic-party@2x.png'),
          iconSelect: require('@/assets/image/tab/ic-party-select@2x.png')
        },
        {
          path: '/sdk/match',
          title: 'Match',
          icon: require('@/assets/image/tab/ic-match@2x.png'),
          iconSelect: require('@/assets/image/tab/ic-match-select@2x.png')
        },
        // {
        //   path: '/sdk/home',
        //   title: 'Home',
        //   icon: require('@/assets/image/tab/ic-match@2x.png'),
        //   iconSelect: require('@/assets/image/tab/ic-match-select@2x.png')
        // },

        {
          path: '/sdk/msg',
          title: 'Message',
          dotNum: this.$store.state.PageCache.unreadMsgCount,
          icon: require('@/assets/image/tab/ic-message@2x.png'),
          iconSelect: require('@/assets/image/tab/ic-message-select@2x.png')
        },

      ]
    },
  },
  methods: {
    showPromoOnFirstLoad() {
      const today = new Date().toISOString().slice(0, 10);
      /// 只显示注册后三天内
      const user = cache.local.getJSON(key_cache.user_info) || {};
      const createTime = user.createTime;
      const now = Math.floor(Date.now() / 1000);
      const threeDaysSec = 3 * 24 * 3600;
      if (createTime == null || createTime === '' || now - createTime > threeDaysSec) return;

      const key = key_cache.first_recharge_promo_daily;
      let state = cache.local.getJSON(key) || { date: '', visitCount: 0, hasShownToday: false };
      if (state.date !== today) {
        state = { date: today, visitCount: 0, hasShownToday: false };
      }
      state.visitCount = (state.visitCount || 0) + 1;
      cache.local.setJSON(key, state);

      /// 当天第一次打开不弹，第二次及以后才弹，每天最多弹一次
      if (state.visitCount < 2 || state.hasShownToday) return;

      this.$nextTick(() => {
        setTimeout(() => {
          const dialog = showRechargePromoDialog();
          if (dialog) {
            state.hasShownToday = true;
            cache.local.setJSON(key, state);
          }
        }, 800);
      });
    },
    changeSelectedValue: function (path) {
      this.$router.push(path)

      cache.local.set(key_cache.dialog_show_new_user, '1');

      if (path === '/sdk/msg') {
        store.dispatch('PageCache/loadChatConversationList').then()
        clientNative.requestPermission(0);
      }
    },
  }
}
</script>

<style scoped>
.page-sdk-index {
  height: 100%;
}
</style>
