<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div class="main">
        <div class="head">
          <div class="left">
            <p class="nick-name">{{ userInfo.nickname }}</p>
            <div class="base-info">
              <img :src="require('@/assets/image/sdk/'+(userInfo.gender===1?'ic-woman.png':'ic-male.png'))"/>
              <span>ID:{{ userInfo.userId }}</span>
            </div>
          </div>
          <img class="head-image"
               :src="userInfo.headImage||'@/assets/image/sdk/ic-logo.png'"
               @click="menuClick({name:'PageEditUserInfo'})"/>
          <i class="ic-right el-icon-arrow-right"
             @click="menuClick({name:'PageEditUserInfo'})"/>
        </div>
        <div class="recharge-card">
          <img src="@/assets/image/sdk/ic-coin-max.png"/>
          <div>
            <p>{{ coinDisplay }}</p>
            <span>Available Coins</span>
          </div>
          <button @click="menuClick({name:'PageRechargeStudio'})">Recharge</button>
        </div>
        <ul class="menu-items">
          <li v-for="(it ,index) in menuItems" :key="index" @click="menuClick(it)">
            <img class="icon" :src="require('@/assets/image/sdk/'+it.icon)"/>
            <p>{{ it.title }}</p>
            <img class="switch" v-if="it.right==='switch'"
                 @click.stop="menuSwitchClick(it)"
                 :src="require('@/assets/image/sdk/'+'ic-switch-open.png')"/>
            <i class="ic-right el-icon-arrow-right" v-else/>
          </li>
        </ul>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MPageWrap from "@/components/MPageWrap.vue";
import {showFeedbackDialog} from "@/components/dialog";

export default {
  name: 'PageMe',
  components: {MPageWrap},
  data() {
    return {
      menuItems: [
        /* {
           name: null,
           icon: 'ic-me-no-call.png',
           title: 'Do not disturb-Call',
           right: 'switch',
         },
         {
           name: null,
           icon: 'ic-me-no-chat.png',
           title: 'Do not disturb-Message',
           right: 'switch',
         },*/
        {
          name: 'CoinDetail',
          icon: 'ic-me-favourite.png',
          title: 'Favourite list',
          right: 'next',
        },
        {
          name: 'PageExpensesRecord',
          icon: 'ic-me-expenses-record.png',
          title: 'Expenses record',
          right: 'next',
        },
        {
          name: 'PageCallRecord',
          icon: 'ic-call.png',
          title: 'Call records',
          right: 'next',
        },
        {
          name: 'PageLikeList',
          icon: 'ic-video-like.png',
          title: 'Likes',
          right: 'next',
        },

        {
          name: 'PageBlackList',
          icon: 'ic-me-ban-user.png',
          title: 'Black list',
          right: 'next',
        },
        {
          name: 'PageFeedBack',
          icon: 'ic-me-feedback.png',
          title: 'Feedback',
          right: 'next',
        },
        {
          name: 'PageSetting',
          icon: 'ic-me-setting.png',
          title: 'Setting',
          right: 'next',
        },
        {
          name: 'PageCustomerService',
          icon: 'ic-me-customer-service.png',
          title: 'Customer service',
          right: 'next',
        }
      ]
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo
    },
    coinDisplay() {
      const balance = this.userInfo.coin || 0;
      return balance <= 0 ? 'Shop' : balance;
    }
  },
  methods: {
    menuClick({name}) {
      if (name) {
        // 特殊处理 Feedback，使用底部弹出对话框
        if (name === 'PageFeedBack') {
          showFeedbackDialog();
        } else {
        this.$router.push({name: name})
        }
      }
    },
    menuSwitchClick() {

    },
  }
}
</script>

<style scoped lang="less">
.main {
  padding-left: 20px;
  box-sizing: border-box;
  padding-right: 20px;
}

.head {
  display: flex;
  height: 90px;
  align-content: center;
  align-items: center;
  width: 100%;

  .left {
    flex: 1;
    color: white;
    margin-left: 20px;

    .nick-name {
      font-size: @max-big-text-size;
    }

    .base-info {
      display: flex;
      margin-top: 15px;
      align-content: center;
      align-items: center;;

      img {
        width: 20px;
        height: 20px;
      }

      span {
        display: inline-block;
        height: 20px;
        line-height: 20px;
        background: #363330;
        border-radius: 15px;
        text-align: center;
        padding: 2px 15px;
        margin-left: 10px;
        font-size: @min-text-size;
      }
    }
  }

  .head-image {
    width: 70px;
    height: 70px;
    border-radius: 35px;
    border: @theme-color solid 1px;
    object-fit: cover;
  }

  .ic-right {
    width: 20px;
    font-weight: bold;
    font-size: @max-text-size;
  }
}

.recharge-card {
  width: 100%;
  height: 80px;
  display: flex;
  align-content: center;
  align-items: center;
  box-sizing: border-box;
  background: linear-gradient(270deg, #FCB866 0%, #FADEBF 100%);
  border-radius: 20px;
  padding-left: 20px;
  margin-top: 20px;
  padding-right: 20px;

  img {
    width: 50px;
    height: 50px;
  }

  div {
    flex: 1;
    margin-left: 20px;

    p {
      font-size: 18px;
      font-weight: bold;
      color: @theme-select-text-color;
    }

    span {
      font-size: @min-text-size;
      color: @theme-line-color;
    }
  }

  button {
    padding: 0 15px;
    height: 32px;
    background: @theme-select-text-color;
    border-radius: 16px;
    color: #F6C084;
    border: none;
    opacity: 1;
  }
}

.menu-items {
  padding: 0 15px;
  margin-top: 20px;

  li {
    height: 50px;
    display: flex;
    align-content: center;
    align-items: center;
    box-sizing: border-box;
    border-bottom: @theme-line-color solid 1px;

    .icon {
      width: 22px;
      height: 22px;
    }

    p {
      color: @theme-un-select-text-color;
      flex: 1;
      margin-left: 15px;
    }

    .switch {
      width: 50px;
    }

    .ic-right {
      opacity: 0.5;
    }

  }
}

.ic-right {
  height: 18px;
  margin-left: 10px;
  width: 22px;
}
</style>
