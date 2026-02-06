import Vue from 'vue'
import Router from 'vue-router'
import {envIsProd} from "@/utils/Constant";
import store from "@/store";
import {DialogTaskArray} from "@/components/dialog/DialogTaskArray";
// import store from '@/store'

Vue.use(Router)

// SDK路由
export const constantSdkRoutes = [
  {
    path: '/',
    component: () => import('@/views/index'),
    redirect: '/sdk/me',
    meta: {title: 'Home', keepAlive: true}
  },
  {
    name: 'PageSdkIndex',
    path: '/sdk/index',
    component: () => import('@/views/index'),
    meta: {title: 'Match', keepAlive: true},
    children: [
        {
            name: 'PageMatch',
            path: '/sdk/match',
            component: () => import('@/views/home/match'),
            meta: {title: 'Match', keepAlive: true, openPageSwitchAnimation: false}
        },
        {
            name: 'PageMainIndex',
            path: '/sdk/home',
            component: () => import('@/views/home/index'),
            meta: {title: 'Home', keepAlive: true, openPageSwitchAnimation: false}
        },
        {
            name: 'PageMsgList',
            path: '/sdk/msg',
            component: () => import('@/views/home/msg'),
            meta: {title: 'Message', keepAlive: true, openPageSwitchAnimation: false}
        },
        {
            name: 'PageMe',
            path: '/sdk/me',
            component: () => import('@/views/home/me/ListIndex'),
            meta: {title: 'Me', keepAlive: true, openPageSwitchAnimation: false}
        }
    ]
  },
  {
    name: 'PageEditUserInfo',
    path: '/sdk/page/edit-info',
    component: () => import('@/views/home/me/page/EditUserInfo'),
    meta: {title: 'Edit Profile', keepAlive: true, openPageSwitchAnimation: false}
  },
  {
    name: 'PageFavouriteList',
    path: '/sdk/page/favourite-list',
    component: () => import('@/views/home/me/page/FavouriteList'),
    meta: {title: 'Favourite List', keepAlive: true}
  },
  {
    name: 'PageBlackList',
    path: '/sdk/page/black-list',
    component: () => import('@/views/home/me/page/BlackList'),
    meta: {title: 'Black List', keepAlive: true}
  },
  {
    name: 'PageExpensesRecord',
    path: '/sdk/page/expenses-record',
    component: () => import('@/views/home/me/page/ExpensesRecord'),
    meta: {title: 'Expenses Record', keepAlive: true}
  },
  {
    name: 'PageCustomerService',
    path: '/sdk/page/customer-service',
    component: () => import('@/views/home/me/page/CustomerService'),
    meta: {title: 'Customer Service', keepAlive: true}
  },
  {
    name: 'PageFeedBack',
    path: '/sdk/page/feedback',
    component: () => import('@/views/home/me/page/FeedBack'),
    meta: {title: 'Feed Back', keepAlive: true}
  },
  {
    name: 'PageReport',
    path: '/sdk/page/report',
    component: () => import('@/views/home/me/page/Report'),
    meta: {title: 'Report', keepAlive: true}
  },
  {
    name: 'PageSetting',
    path: '/sdk/page/setting',
    component: () => import('@/views/home/me/page/SettingPage.vue'),
    meta: {title: 'Setting', keepAlive: true}
  },
  {
    name: 'PageDeleteAccount',
    path: '/sdk/page/delete-account',
    component: () => import('@/views/home/me/page/DeleteAccount.vue'),
    meta: {title: 'Delete Account', keepAlive: true}
  },
  {
    name: 'PageVersion',
    path: '/sdk/page/version',
    component: () => import('@/views/home/me/page/VersionPage.vue'),
    meta: {title: 'Version', keepAlive: true}
  },
  {
    name: 'PageWebView',
    path: '/sdk/page/webview',
    component: () => import('@/views/other/WebView.vue'),
    meta: {title: 'Version', keepAlive: false} // 支付页面不使用缓存，避免状态问题
  },
  {
    name: 'PaymentSuccess',
    path: '/sdk/page/payment-success',
    component: () => import('@/views/other/PaymentSuccess.vue'),
    meta: {title: 'Payment Result', keepAlive: false}
  },
  {
    name: 'PaymentFailed',
    path: '/sdk/page/payment-failed',
    component: () => import('@/views/other/PaymentFailed.vue'),
    meta: {title: 'Payment Result', keepAlive: false}
  },
  {
    name: 'PicturePreview',
    path: '/sdk/page/picture-preview',
    component: () => import('@/views/other/PicturePreview.vue'),
    meta: {title: 'Version', keepAlive: true, openPageSwitchAnimation: false}
  },
  {
    name: 'PageRechargeStudio',
    path: '/sdk/page/recharge-studio',
    component: () => import('@/views/other/RechargeStudio.vue'),
    meta: {title: 'Recharge Studio', keepAlive: true}
  },
  {
    name: 'PageGiftRecord',
    path: '/sdk/page/gift-record',
    component: () => import('@/views/other/GiftRecord.vue'),
    meta: {title: 'Gift Record', keepAlive: false}
  },
  {
    name: 'PageUserInformation',
    path: '/sdk/page/user-information',
    component: () => import('@/views/user/UserInformation.vue'),
    meta: {title: 'User Information', keepAlive: true}
  },
  {
    name: 'PageUserDetail',
    path: '/sdk/page/user-detail',
    component: () => import('@/views/user/UserDetail.vue'),
    meta: {title: 'User Detail', keepAlive: false}
  },
  {
    name: 'PageChat',
    path: '/sdk/page/chat',
    component: () => import('@/views/chat/ChatPage.vue'),
    meta: {title: 'Chat', keepAlive: false}
  },
  {
    name: 'PageCallEnd',
    path: '/sdk/page/call-end',
    component: () => import('@/views/call/end.vue'),
    meta: {title: 'Call End', keepAlive: false}
  },
  {
    name: 'PageCallIncoming',
    path: '/sdk/page/call-incoming',
    component: () => import('@/views/call/incoming.vue'),
    meta: {title: 'Call Incoming', keepAlive: false}
  },
  {
    name: 'PageCalling',
    path: '/sdk/page/calling',
    component: () => import('@/views/call/calling.vue'),
    meta: {title: 'Calling', keepAlive: false}
  },
  {
    name: 'PageTXCalling',
    path: '/sdk/page/tx-calling',
    component: () => import('@/views/call/TXCalling.vue'),
    meta: {title: 'TX Calling', keepAlive: false}
  },
  {
    name: 'PageCallRecord',
    path: '/sdk/page/call-record',
    component: () => import('@/views/call/CallRecord.vue'),
    meta: {title: 'Call records', keepAlive: true}
  },
  {
    name: 'PageLikeList',
    path: '/sdk/page/like-list',
    component: () => import('@/views/call/LikeList.vue'),
    meta: {title: 'Likes', keepAlive: false}
  },
  {
    name: 'PageAgoraDemo',
    path: '/sdk/page/agora-demo',
    component: () => import('@/views/call/AgoraDemo.vue'),
    meta: {title: 'Agora Demo', keepAlive: false}
  },
  {
    name: 'PageVideoPlay',
    path: '/sdk/page/video-play',
    component: () => import('@/views/user/VideoPlay.vue'),
    meta: {title: 'Video play', keepAlive: true}
  },
  {
    name: 'PageMatching',
    path: '/sdk/page/matching',
    component: () => import('@/views/home/match/matching.vue'),
    meta: {title: 'Matching', keepAlive: false}
  },
  {
    name: 'PagePremium',
    path: '/sdk/page/pagePremium',
    component: () => import('@/views/premium/index.vue'),
    meta: {title: 'Premium', keepAlive: false}
  },
  {
    name: 'CoinDetails',
    path: '/sdk/page/coin-details',
    component: () => import('@/views/home/me/CoinDetails.vue'),
    meta: {title: 'Coin Transactions', keepAlive: false}
  },
]

// 路由
export const constantRoutes = [
  ...constantSdkRoutes
]

// 防止重复点击跳转报错
let routerPush = Router.prototype.push;
Router.prototype.push = function push(location) {
  return routerPush.call(this, location).catch(err => err)
}

const router = new Router({
  // 去掉url中的#
  mode: 'history',
  scrollBehavior: () => ({y: 0}),
  routes: constantRoutes
})

router.beforeEach((to, from, next) => {
  if (to.meta.title) {
    if (envIsProd) {
      document.title = to.meta.title + ' ' + process.env.VUE_APP_TITLE
    } else {
      document.title = to.meta.title + ' ' + process.env.VUE_APP_TITLE + ' ' + process.env.NODE_ENV;
    }
  }

  store.dispatch('PageCache/addView', {name: to.name}).then();
  if (next) {
    // 全局弹框关闭
    if (DialogTaskArray.closeDialog()) {
      router.go(1)
      return;
    }
    // 页面切换动画
    store.dispatch('PageCache/addPageSwitchAnimationName', {from, to}).then();
    next();
  }
})

export {router}
