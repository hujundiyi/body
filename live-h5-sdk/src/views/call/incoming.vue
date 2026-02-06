<template>
  <m-page-wrap :scroll-y="false" :show-action-bar="false" :full-status-bar="true" :full-bottom-bar="true">
    <template #page-content-wrap>
      <div class="call-page">
      <div class="call-bg" v-if="!hasVideo || !isVideoReady">
        <div class="call-bg-image" :style="bgStyle"></div>
        <div class="call-bg-mask"></div>
      </div>

      <video
        v-show="hasVideo && videoSrc"
        ref="videoEl"
        class="call-video"
        :src="videoSrc"
        autoplay
        muted
        playsinline
        webkit-playsinline
        preload="auto"
        @canplay="onCanPlay"
        @error="onVideoError"
      ></video>

      <div class="call-content">
        <div v-if="!hasVideo" class="call-avatar-wrap">
          <div class="call-ripple call-ripple-1"></div>
          <div class="call-ripple call-ripple-2"></div>
          <div class="call-ripple call-ripple-3"></div>
          <img class="call-avatar" :src="avatarSrc" alt="" />
        </div>
        <div v-else class="call-spacer"></div>

        <div class="call-bottom">
          <div class="call-info">
            <div class="call-name">{{ displayName }}</div>
            <div class="call-tags">
              <span v-if="countryFlag" class="flag-icon">{{ countryFlag }}</span>
              <div v-if="genderAge" class="call-tag  call-tag-overlay">
                <img class="call-tag-icon" style="width: 54px;" :src="genderIcon" alt="" />
                <span class="call-tag-text">{{ genderAge }}</span>

              </div>
              <div v-if="levelText" class="call-tag call-tag-overlay">
                <img class="call-tag-icon" style="width: 80px;" :src="verifiedIcon" alt="" />
                <span class="call-tag-text" :class="{ 'call-tag-text-level-high': levelNumber >= 100 }">{{ levelText }}</span>
              </div>
              <div v-if="isPremium" class="call-tag">
                <img class="call-tag-icon" :src="premiumIcon" alt="" />
              </div>
            </div>
          </div>

          <div class="call-actions" :class="{ 'call-actions-single': !isIncomingCall }">
            <button class="call-btn call-btn-hangup" type="button" @click="onHangup">
              <img class="call-btn-icon" :src="hangupIcon" alt="" />
            </button>
            <button v-if="isIncomingCall" class="call-btn call-btn-accept" type="button" @click="onAccept" :disabled="isJia && isJiaAcceptWaiting">
              <div v-if="isJia && isJiaAcceptWaiting" class="call-btn-jia-waiting-dots">
                <span class="call-btn-jia-waiting-dot call-btn-jia-waiting-dot-1"></span>
                <span class="call-btn-jia-waiting-dot call-btn-jia-waiting-dot-2"></span>
                <span class="call-btn-jia-waiting-dot call-btn-jia-waiting-dot-3"></span>
              </div>
              <img v-else class="call-btn-icon" :src="acceptIcon" alt="" />
            </button>
          </div>
        </div>
      </div>
    </div>
    </template>
  </m-page-wrap>
</template>

<script>
import {callCreate, callEnd, callStart} from "@/utils/CallUtils"
import {CALL_STATUS, LOCAL_CALL_STATUS} from "@/utils/Constant";
import {getCountryFlagEmojiByCode} from "@/utils/Utils";
import callAudio from "@/assets/audio/call_audio.mp3";
import clientNative from "@/utils/ClientNative";
import {showCallToast} from "@/components/toast/callToast";
import {getAnchorInfo} from "@/api/sdk/anchor";
import store from "@/store";

export default {
  name: 'CallIncoming',
  data() {
    return {
      videoSrc: '',
      isVideoReady: false,
      objectUrl: '',

      timeoutTimer: null,
      audio: null,
      /** isJia 场景下点击接听后的网络等待状态 */
      isJiaAcceptWaiting: false,
    }
  },
  computed: {
    query() {
      return this.$route.query || {};
    },
    isIncomingCall() {
      return this.$store.state.call.incomingCall;
    },
    /** 是否来自 ListIndex 测试入口（query isJia=true），保证为 Boolean */
    isJia() {
      return Boolean(this.$route.query.isJia === 'true');
    },
    anchorData() {
      return this.$store.state.call.anchorInfo || {};
    },
    hasVideo() {
      return Boolean(this.query.videoUrl || this.$store.state.call.playVideoUrl);
    },
    avatarSrc() {
      // 优先使用 anchorData 中的头像
      if (this.anchorData.avatar) {
        return this.anchorData.avatar;
      }
      return this.query.avatar || require('@/assets/image/sdk/ic-call-eval-smile.png');
    },
    bgStyle() {
      return { backgroundImage: `url(${this.avatarSrc})` };
    },
    displayName() {
      // 优先使用 anchorData 中的昵称
      if (this.anchorData.nickname) {
        return this.anchorData.nickname;
      }
      return this.query.name || '';
    },
    countryFlag() {
      // 优先使用 anchorData 中的国家代码
      const countryCode = this.anchorData.country || this.query.country || 'US';
      return getCountryFlagEmojiByCode(countryCode);
    },
    genderAge() {
      // 优先用 age，否则用 birthday 计算
      if (this.anchorData.age != null && this.anchorData.age !== '') {
        return String(this.anchorData.age);
      }
      if (this.anchorData.birthday) {
        const birthYear = new Date(this.anchorData.birthday * 1000).getFullYear();
        const currentYear = new Date().getFullYear();
        return String(currentYear - birthYear);
      }
      return '';
    },
    levelText() {
      // 从 anchorData 获取等级（如果有）
      if (this.anchorData.guildAnchorLevel) {
        return `Lv.${this.anchorData.guildAnchorLevel}`;
      }
      return '';
    },
    /** 等级数值，用于样式判断（如 >=100 时缩小字体） */
    levelNumber() {
      if (this.anchorData.guildAnchorLevel != null) {
        return Number(this.anchorData.guildAnchorLevel) || 0;
      }
      const m = (this.levelText || '').match(/Lv\.?(\d+)/i);
      return m ? parseInt(m[1], 10) : 0;
    },
    isPremium() {
      // 优先使用 query 中的 premium
      if (this.query.premium !== undefined) {
        return String(this.query.premium || '1') === '1';
      }
      // 从 anchorData 判断（如果有相关字段）
      // 目前先返回默认值
      return true;
    },
    isVerified() {
      return String(this.query.verified || '0') === '1';
    },
    acceptIcon() {
      return require('@/assets/image/call/ic_call_accept.png');
    },
    hangupIcon() {
      return require('@/assets/image/call/ic_call_hungup.png');
    },
    premiumIcon() {
      return require('@/assets/image/call/ic_call_premium.png');
    },
    verifiedIcon() {
      return require('@/assets/image/sdk/ic-userdetail-level.png');
    },
    genderIcon() {
      // 根据 anchorData 中的 gender 返回对应的图标
      // gender === 1 表示女性（Female），gender === 2 表示男性（Male）
      if (this.anchorData.gender === 1) {
        return require('@/assets/image/sdk/ic-userdetail-girl.png');
      } else if (this.anchorData.gender === 2) {
        return require('@/assets/image/sdk/ic-userdetail-boy.png');
      }
      // 默认返回男性图标
      return require('@/assets/image/sdk/ic-userdetail-boy.png');
    },
  },
  watch: {
    'query.videoUrl': {
      immediate: true,
      handler() {
        this.resetVideoState();
        if (this.hasVideo) {
          this.initVideo();
        }
      }
    },
    '$store.state.call.playVideoUrl': {
      immediate: true,
      handler() {
        this.resetVideoState();
        if (this.hasVideo) {
          this.initVideo();
        }
      }
    }
  },
  mounted() {
    // 播放来电铃声
    // this.playRingtone(); // 暂时不需要播放音频

    getAnchorInfo(this.$store.state.call.anchorInfo.userId).then(res => {
      if (res.data) {
        store.dispatch('call/setAnchorInfo', res.data);
      }
    });

    // 30秒后检查状态，如果还是等待状态则超时处理
    this.timeoutTimer = setTimeout(() => {
      const localCallStatus = this.$store.state.call.localCallStatus;
      if (localCallStatus.code === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING.code) {
        this.onOutTime();
      }
    }, 60000);
  },
  beforeDestroy() {
    this.cleanupObjectUrl();
    // this.stopRingtone(); // 暂时不需要播放音频
    if (this.timeoutTimer) {
      clearTimeout(this.timeoutTimer);
      this.timeoutTimer = null;
    }
  },
  created() {

  },
  methods: {
    playRingtone() {
      try {
        this.audio = new Audio(callAudio);
        this.audio.loop = true;
        this.audio.play().catch(() => {});
      } catch (e) {
        console.error('播放铃声失败', e);
      }
    },
    stopRingtone() {
      if (this.audio) {
        this.audio.pause();
        this.audio.currentTime = 0;
        this.audio = null;
      }
    },
    cleanupObjectUrl() {
      if (this.objectUrl) {
        URL.revokeObjectURL(this.objectUrl);
        this.objectUrl = '';
      }
    },
    resetVideoState() {
      this.isVideoReady = false;
      this.videoSrc = '';
      this.cleanupObjectUrl();
    },
    async initVideo() {
      // 优先使用 store 中的 playVideoUrl，其次使用 query 中的 videoUrl
      const url = this.$store.state.call.playVideoUrl || this.query.videoUrl;
      if (!url) {
        this.videoSrc = '';
        return;
      }
      const shouldDownload = String(this.query.download || '1') === '1';
      if (!shouldDownload) {
        this.videoSrc = url;
        return;
      }

      try {
        const res = await fetch(url, { mode: 'cors' });
        const blob = await res.blob();
        this.objectUrl = URL.createObjectURL(blob);
        this.videoSrc = this.objectUrl;
      } catch (e) {
        this.videoSrc = url;
      }
    },
    onCanPlay() {
      this.isVideoReady = true;
      this.$nextTick(() => {
        const el = this.$refs.videoEl;
        if (el && el.play) {
          el.play().catch(() => {});
        }
      });
    },
    onVideoError() {
      this.isVideoReady = false;
    },
    onHangup() {
      // this.stopRingtone(); // 暂时不需要播放音频
      callEnd(this.$store.state.call.callData.callNo ?? '',CALL_STATUS.CANCEL_CALL);
      this.$router.back();
      this.$store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
    },
    onOutTime() {
      showCallToast('Call timeout, please try again later');
      // this.stopRingtone(); // 暂时不需要播放音频
      callEnd(this.$store.state.call.callData.callNo ?? '',CALL_STATUS.CALL_TIMEOUT_DONE);
      this.$router.back();
      this.$store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
    },
    async onAccept() {
      // this.stopRingtone(); // 暂时不需要播放音频
      if (this.isJia) {
        this.isJiaAcceptWaiting = true;
        try {
          const res = await callCreate(this.$store.state.call.anchorInfo.userId, '', true);
          if (res && res.code === 200 && res.data) {
            // 成功会跳转，无需重置
          } else {
            this.isJiaAcceptWaiting = false;
          }
        } catch (e) {
          this.isJiaAcceptWaiting = false;
        }
        return;
      }
      const {callNo,rtcType} = this.$store.state.call.callData;
      const res = await callStart(callNo);
      if (res.code === 200) {
        // TODO: 后端接口支持类型后，根据类型判断跳转 PageCalling 或 PageTXCalling
        if (rtcType === 'TRTC') {
          await this.$router.replace({name: "PageTXCalling"})
        }else {
          await this.$router.replace({name: "PageCalling"})
        }

        await this.$store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_CALLING);
      }
    }
  },
}
</script>
<style scoped lang="scss">
.call-page {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: #000;
}
.call-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
}

.call-bg-image {
  position: absolute;
  inset: -40px;
  background-size: cover;
  background-position: center;
  transform: scale(1.2);
  filter: blur(28px);
}

.call-bg-mask {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0.55));
}

.call-video {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  z-index: 0;
  background: #000;
}

.call-content {
  position: relative;
  z-index: 1;
  height: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  padding: 56px 20px 0;
  box-sizing: border-box;
}

.call-spacer {
  flex: 1;
}

.call-bottom {
  position: absolute;
  left: 20px;
  right: 20px;
  bottom: 50px;
}

.call-avatar-wrap {
  position: relative;
  width: 200px;
  height: 200px;
  margin-top: 70px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.call-avatar {
  width: 145px;
  height: 145px;
  border-radius: 999px;
  object-fit: cover;
  border: 4px solid rgba(255, 255, 255, 0.92);
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.28);
  position: relative;
  z-index: 2;
}

.call-ripple {
  position: absolute;
  width: 145px;
  height: 145px;
  border-radius: 999px;
  border: 2px solid rgba(255, 255, 255, 0.35);
  opacity: 0;
  animation: ripple 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}

.call-ripple-1 {
  animation-delay: 0s;
}
.call-ripple-2 {
  animation-delay: 0.83s;
}
.call-ripple-3 {
  animation-delay: 1.66s;
}

@keyframes ripple {
  0% {
    transform: scale(0.95);
    opacity: 0.6;
  }
  50% {
    opacity: 0.3;
  }
  100% {
    transform: scale(2.2);
    opacity: 0;
  }
}

.call-info {
  width: 100%;
  text-align: center;
  margin-top: 14px;
  margin-bottom: 35px;
}

.call-name {
  font-size: 30px;
  line-height: 40px;
  font-weight: 800;
  color: rgba(255, 255, 255, 0.96);
  letter-spacing: 0.2px;

}

.call-tags {
  margin-top: 12px;
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  flex-wrap: nowrap;
  justify-content: center;
}

.call-tag {
  display: inline-flex;
  align-items: center;
  gap: 0px;
  border-radius: 999px;
  color: #fff;
  font-size: 12px;
  line-height: 14px;
  font-weight: 600;
}

.flag-icon {
  display: inline-block;
  font-size: 35px;
  line-height: 1;
  vertical-align: middle;
  border-radius: 50%;
  object-fit: cover;
}

.call-tag-pink {
  background: #FF40A7;
  padding: 6px 10px;
}

.call-tag-icon {
  width: auto;
  height: 25px;
  max-width: 98px;
  object-fit: contain;
  flex-shrink: 0;
}

.call-tag-overlay {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.call-tag-overlay .call-tag-text {
  position: absolute;
  top: 53%;
  left: 65%;
  transform: translate(-50%, -50%);
  font-size: 16px;
  line-height: 14px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  z-index: 1;
}

.call-tag-text-level-high {
  font-size: 12px !important;
}

.call-actions {
  width: 100%;
  display: flex;
  justify-content: space-between;
  padding: 0 26px;
  box-sizing: border-box;
}

.call-actions-single {
  justify-content: center;
}

.call-btn {
  width: 77px;
  height: 77px;
  border-radius: 999px;
  border: none;
  outline: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 18px 46px rgba(0, 0, 0, 0.32);
  position: relative;
}

.call-btn:active {
  transform: scale(0.98);
}

.call-btn-hangup {
  background: #ff3b30;
}

.call-btn-accept {
  background: #34c759;
  will-change: transform;
  animation: acceptPulse 2s ease-in-out infinite;
  overflow: visible;
}

/* isJia 点击接听后：接听按钮内三个点动画 */
.call-btn-jia-waiting-dots {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

.call-btn-jia-waiting-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #fff;
  animation: jiaWaitDot 1.4s ease-in-out infinite both;
}

.call-btn-jia-waiting-dot-1 { animation-delay: 0s; }
.call-btn-jia-waiting-dot-2 { animation-delay: 0.2s; }
.call-btn-jia-waiting-dot-3 { animation-delay: 0.4s; }

@keyframes jiaWaitDot {
  0%, 80%, 100% { opacity: 0.4; transform: scale(0.8); }
  40% { opacity: 1; transform: scale(1.2); }
}

.call-btn-icon {
  width: 77px;
  height: 77px;
  object-fit: contain;
  position: relative;
  z-index: 3;
}

@keyframes acceptPulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 18px 46px rgba(52, 199, 89, 0.4);
  }
  50% {
    transform: scale(1.08);
    box-shadow: 0 18px 46px rgba(52, 199, 89, 0.6), 0 0 0 10px rgba(52, 199, 89, 0.1);
  }
}
</style>
