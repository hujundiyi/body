<template>
  <div class="call-waiting-status">
    <div class="content">
      <div class="user-info">
        <img :src="userInfo.headImage"/>
        <h3>{{ userInfo.nickname }}</h3>
        <call-coin :coin="userInfo.price"/>
        <p>
          <span>Calling...</span>
          <b> {{ wantingTime }}</b>S
        </p>
      </div>
      <div class="footer-btn">
        <div :class="['footer-content',status===1?'btn-big':'']">
          <div @click="()=>{$emit('onHangupClick')}">
            <img class="btn-hangup" src="@/assets/image/sdk/ic-hang-up.png"/>
          </div>
          <div class="btn-answer" v-if="status===2" @click="()=>{$emit('onAnswerClick')}">
            <img src="@/assets/image/sdk/ic-call-microphone.png"/>
            <span>Pick up</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CallCoin from "@/components/sdk/CallCoin.vue";

export default {
  components: {CallCoin},
  props: {
    //  1 发出邀请 2 收到邀请
    status: {
      type: Number,
      default() {
        return 1;
      }
    },
    userInfo: {
      type: Object,
      default() {
        return null;
      }
    }
  },
  mounted() {
    this.timerCallback()
    this.timeTaskId = setInterval(this.timerCallback, 1000);
  },
  data() {
    return {
      timeTaskId: null,
      // 等待倒计时
      wantingTime: 45,
    }
  },
  methods: {
    timerCallback() {
      --this.wantingTime;
      if (this.wantingTime <= 0) {
        clearInterval(this.timeTaskId);
        this.$emit('onWantingTimeout')
      }
    }
  }
}
</script>

<style scoped lang="less">
@keyframes wave-animation {
  0% {
    box-shadow: 0 0 10px red;
  }
  50% {
    box-shadow: 0 0 50px red;
  }
  100% {
    box-shadow: 0 0 10px red;
  }
}

.call-waiting-status {
  position: fixed;
  z-index: 999;
  display: inline-block;
  width: 100%;
  height: 100%;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  background: @theme-bg-color;

  .content {
    position: relative;
    width: 100%;
    height: 100%;
    text-align: center;

    .user-info {
      margin-top: 50px;

      img {
        width: 120px;
        height: 120px;
        border-radius: 50%;
        border: @theme-color solid 1px;
        box-shadow: 0 0 10px rgba(255, 0, 0, 0.53); /* 初始的阴影效果 */
        animation: wave-animation 2s infinite, 4.5s ease 0s infinite normal none running anim-scale; /* 应用动画 */
      }

      h3 {
        margin: 20px 0 10px 0;
        font-size: @max-big-text-size;
        font-weight: bold;
      }

      p {
        color: @theme-color;
        margin: 50px 0 30px 0;
      }
    }
  }

  .footer-btn {
    position: absolute;
    bottom: 35%;
    width: 100%;

    .footer-content {
      position: relative;
      width: 100%;
      height: 80px;


      div {
        display: inline-block;
        vertical-align: top;
      }

      .btn-hangup {
        width: 55px;
        height: 55px;
      }

      .btn-answer {
        margin-left: 50px;
        width: 120px;
        height: 50px;
        background: linear-gradient(to right, #28CA56, #29CB56);
        box-sizing: border-box;
        border-radius: 25px;
        border: #B2FFBA solid 2px;
        line-height: 46px;
        text-align: left;

        img {
          vertical-align: middle;
          width: 25px;
          display: inline-block;
          margin-left: 10px;
          height: 25px;
        }

        span {
          display: inline-block;
          margin-left: 10px;
          vertical-align: middle;
        }
      }
    }

    .btn-big {
      .btn-hangup {
        width: 60px;
        height: 60px;
      }
    }

  }
}


</style>

