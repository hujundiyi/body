<template>
  <m-page-wrap :scroll-y="false" :show-action-bar="false" :full-status-bar="true" :full-bottom-bar="true">
    <template #page-content-wrap>
<div class="end-page">
      <div class="end-bg">
        <div class="end-bg-image" :style="bgStyle"></div>
        <div class="end-bg-mask"></div>
      </div>

      <div class="end-sheet">
        <div class="end-avatar-wrapper">
          <img class="end-avatar" :src="avatarSrc" alt="" />
        </div>
        <div class="end-profile">
          <div class="call-info">
            <div class="call-name">{{ displayName }}</div>
            <div class="call-tags">
              <span v-if="countryFlag" class="flag-icon">{{ countryFlag }}</span>
              <div v-if="genderAge" class="call-tag  call-tag-overlay">
                <img class="call-tag-icon" style="width: 54px;" :src="genderIcon" alt="" />
                <span class="call-tag-text">{{ genderAge }}</span>

              </div>
              <div v-if="levelText" class="call-tag call-tag-overlay">
                <img class="call-tag-icon" style="width: 65px;" :src="verifiedIcon" alt="" />
                <span class="call-tag-text">{{ levelText }}</span>
              </div>
              <div v-if="isPremium" class="call-tag">
                <img class="call-tag-icon" :src="premiumIcon" alt="" />
              </div>
            </div>
          </div>

          <div class="end-stats">
            <div class="end-stat">
              <div class="end-stat-value">
                <img class="end-coin-icon" :src="coinIcon" alt="" />
                <span>{{ spendCoin }}</span>
              </div>
              <div class="end-stat-label">Consumed</div>
            </div>
            <div class="end-stat-divider"></div>
            <div class="end-stat">
              <div class="end-stat-value">{{ durationText }}</div>
              <div class="end-stat-label">Duration</div>
            </div>
          </div>

          <div class="end-actions">
            <div class="end-action-btn" @click="onChat">
              <img class="end-action-icon" :src="chatIcon" alt="" />
            </div>
            <div class="end-action-btn" @click="onLike">
              <img class="end-action-icon" :src="likeIcon" alt="" />
            </div>
            <div class="end-action-btn" @click="onCallback">
              <img class="end-action-icon-callback" :src="callbackIcon" alt="" />
            </div>
          </div>
        </div>
      </div>

      <div class="end-bottom">
        <img class="end-close-icon" :src="closeIcon" alt="Close" @click="onClose" />
      </div>
    </div>
    </template>

  </m-page-wrap>
</template>

<script>
import { followStatus } from "@/api/sdk/user";
import store from "@/store";
import { router } from "@/router";
import {LOCAL_CALL_STATUS, key_cache} from "@/utils/Constant";
import {openChat, requestCall} from "@/utils/PageUtils";
import {getCountryFlagEmojiByCode} from "@/utils/Utils";
import cache from "@/utils/cache";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'CallEnd',
  props: {

  },
  data() {
    return {
    }
  },
  computed: {
    // 从 store 获取 callData 中的对方用户信息
    callDataOtherUser() {
      const anchorInfo = this.$store.state.call.anchorInfo || {};
      return anchorInfo;
    },

    endCallData() {
      return this.$store.state.call.endCallData || {};
    },

    spendCoin() {
      return this.endCallData.spendCoin || 0;
    },

    // 获取对方用户ID
    remoteUserId() {
      return this.callDataOtherUser?.userId || null;
    },
    // 是否已关注（followStatus !== 1 表示已关注）
    isFollowed() {
      const followStatus = this.callDataOtherUser?.followStatus;
      return followStatus && followStatus !== 1;
    },
    avatarSrc() {
      return this.callDataOtherUser.avatar || require('@/assets/image/call/ic_call_accept.png');
    },
    bgStyle() {
      return { backgroundImage: `url(${this.avatarSrc})` };
    },
    displayName() {
      return this.callDataOtherUser.nickname || '';
    },
    countryFlag() {
      const countryCode = this.callDataOtherUser.country || 'US';
      return getCountryFlagEmojiByCode(countryCode);
    },
    genderAge() {
      let age = '23';
      if (this.callDataOtherUser.birthday) {
        // birthday 是时间戳（秒），计算年龄
        const birthYear = new Date(this.callDataOtherUser.birthday * 1000).getFullYear();
        const currentYear = new Date().getFullYear();
        age = currentYear - birthYear;
      }
      return `${age || 23}`;
    },
    levelText() {
      if (this.callDataOtherUser.guildAnchorLevel) return `Lv.${this.callDataOtherUser.guildAnchorLevel}`;
      return 'Lv.5';
    },
    isPremium() {
      return String(this.callDataOtherUser.premium || '1') === '1';
    },
    premiumIcon() {
      return require('@/assets/image/call/ic_call_premium.png');
    },
    verifiedIcon() {
      return require('@/assets/image/sdk/ic-userdetail-level.png');
    },
    genderIcon() {
      // gender === 1 是女性，gender === 2 是男性
      const gender = this.callDataOtherUser?.gender;
      const isGirl = gender === 1;
      return isGirl
        ? require('@/assets/image/sdk/ic-userdetail-girl.png')
        : require('@/assets/image/sdk/ic-userdetail-boy.png');
    },
    chatIcon() {
      return require('@/assets/image/call/ic_call_chat@2x.png');
    },
    likeIcon() {
      return this.isFollowed
        ? require('@/assets/image/sdk/ic-userdetail-like.png')
        : require('@/assets/image/sdk/ic-userdetail-unlike.png');
    },
    callbackIcon() {
      return require('@/assets/image/call/ic-call-callback@2x.png');
    },
    coinIcon() {
      return require('@/assets/image/call/ic_call_coin@2x.png');
    },
    closeIcon() {
      return require('@/assets/image/call/ic-call-close.png');
    },
    durationText() {
      // const callTime = this.endCallData.callTime;
      // if (callTime) return String(callTime);
      const seconds = Number(this.endCallData.callTime || 0);
      console.log('durationText', seconds)
      if (!Number.isFinite(seconds) || seconds <= 0) return '00:00:00';
      const s = Math.floor(seconds % 60);
      const m = Math.floor((seconds / 60) % 60);
      const h = Math.floor(seconds / 3600);
      const pad = v => String(v).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(s)}`;
    }
  },
  created() {
    this.initF();
    // 存储已通话标记
    cache.local.set(key_cache.has_called, '1');
  },
  methods: {
    initF() {
      store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END);
    },
    onChat() {
      openChat(this.remoteUserId,true);
    },
    async onLike() {
      const userId = this.remoteUserId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        const follow = !this.isFollowed; // 如果当前未关注，则关注；如果已关注，则取消关注
        const { success } = await followStatus(userId, follow);

        if (success) {
          // 更新 store 中的 followStatus（1 表示未关注，2 表示已关注）
          const callData = this.$store.state.call.callData || {};
          this.callDataOtherUser.followStatus = follow ? 2 : 1;
          this.isFollowed = follow;
          showCallToast(follow ? 'Liked' : 'Unliked');
        } else {
          showCallToast('Operation failed');
        }
      } catch (error) {
        showCallToast('Operation failed');
      }
    },
    onCallback() {
      const userId = this.remoteUserId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }
      requestCall(userId);
    },
    onClose() {
      store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
      // 触发关闭事件，让父组件处理（嵌入在 TXCalling/calling 时）
      this.$emit('close');
      // 若当前是独立通话结束页路由，则直接返回上一页
      if (this.$route.name === 'PageCallEnd') {
        router.back();
      }
    },
  },
  mounted() {
    // 初始化关注状态（如果有用户ID，可以查询当前关注状态）
    // 这里可以根据需要从API获取初始状态
  }
}
</script>

<style scoped lang="scss">
.end-page {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

.end-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
}

.end-bg-image {
  position: absolute;
  inset: -40px;
  background-size: cover;
  background-position: center;
  transform: scale(1.22);
  filter: blur(28px);
}

.end-bg-mask {
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.1);
}

.end-avatar-wrapper {
  position: absolute;
  left: 50%;
  top: 0;
  transform: translate(-50%, calc(-50% + 40px)); /* 头像中心在卡片顶部上方122.5px (50px超出 + 72.5px头像半径) */
  z-index: 2;
}

.end-avatar {
  width: 145px;
  height: 145px;
  border-radius: 999px;
  object-fit: cover;
  border: 3px solid rgba(255, 255, 255, 0.95);
}

.end-sheet {
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: calc(100% - 70px);
  max-width: 400px;
  z-index: 1;
  padding: 115px 24px 24px; /* 顶部 padding: 头像底部位置(145-50=95px) + 昵称间距20px = 115px */
  box-sizing: border-box;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.end-profile {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.call-info {
  width: 100%;
  text-align: center;
  margin-top: 0; /* 昵称位置由卡片padding控制，确保在头像下方20px */
}

.call-name {
  font-size: 24px;
  line-height: 32px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.98);
  letter-spacing: 0.2px;
  margin-top: 12px;
}

.call-tags {
  margin-top: 12px;
  display: inline-flex;
  align-items: center;
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
  font-size: 32px;
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
  padding-top: 2px;
  position: absolute;
  top: 53%;
  left: 65%;
  transform: translate(-50%, -50%);
  font-size: 14px;
  line-height: 14px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  z-index: 1;
}

.end-stats {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 20px;
  gap: 0;
}

.end-stat {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin-top: 10px;
  padding: 12px 8px;
}

.end-stat-divider {
  width: 2px;
  height: 27px;
  background: rgba(255, 255, 255, 0.2);
  margin: 0 8px;
  align-self: center;
  margin-top: 10px;
}

.end-stat-value {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 20px;
  line-height: 24px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.98);
}

.end-coin-icon {
  width: 20px;
  height: 20px;
  object-fit: contain;
}

.end-stat-label {
  margin-top: 6px;
  font-size: 12px;
  line-height: 14px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.6);
}

.end-actions {
  margin-top: 30px;
  margin-bottom: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
}

.end-action-btn {
  border: none;
  outline: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.2s;
}

.end-action-btn:active {
  transform: scale(0.95);
}


.end-action-btn.is-liked {
  background: #FF40A7;
}

.end-action-icon {
  width: 43px;
  height: 43px;
  object-fit: contain;
}

.end-action-icon-callback {
  width: 161px;
  height: 43px;
}

.end-bottom {
  position: absolute;
  left: 50%;
  bottom: 60px; /* 距离底部 40px */
  transform: translateX(-50%);
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.end-close-btn {
  width: 50px;
  height: 50px;
  border-radius: 999px;
  border: none;
  outline: none;
  background: rgba(40, 40, 40, 0.5);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.2s;
}

.end-close-btn:active {
  transform: scale(0.95);
}

.end-close-icon {
  width: 53px;
  height: 53px;
  object-fit: contain;
}
</style>

