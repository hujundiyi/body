<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="'Gift History'" style="font-weight: 700;font-size: 18px" />
    </template>
    <template #page-content-wrap>
      <div class="page">
        <div class="gift-list">
          <div v-for="(item, index) in receivedGiftList" :key="item.consumeId || index" class="gift-item" @click="openAnchorUserDetail(item.userId, 'gift')">
            <!-- 左侧：发件人信息 -->
            <div class="sender-info">
              <div class="avatar-wrapper" :class="{ 'avatar-blur': !isVip }">
                <img class="avatar" :src="item.avatar" alt=""/>
                <img 
                  v-if="item.isOnline" class="online-indicator" :src="require('@/assets/image/sdk/ic_gift_online@2x.png')"
                />
                <div v-if="!isVip" class="avatar-mask" @click.stop="openPremium"></div>
              </div>
              <div class="sender-details">
                <div class="name-row">
                  <span class="name">{{ isVip ? item.name : '*****' }}</span>
                  <span class="country-flag">{{ item.countryFlag || '🇺🇸' }}</span>
                  <div v-if="getGenderAge(item)" class="call-tag call-tag-overlay">
                    <img class="call-tag-icon" style="width: 54px;" :src="getGenderIcon(item.gender)" alt="" />
                    <span class="call-tag-text">{{ getGenderAge(item) }}</span>
                  </div>
                </div>
                <div class="time-row">
                  <img class="time-icon" src="@/assets/image/sdk/ic-userdetail-time.png" alt="" />
                  <span class="time">{{ formatTime(item.time) }}</span>
                </div>
              </div>
            </div>
            <!-- 右侧：礼物信息 -->
            <div class="gift-info">
              <img class="gift-icon" :src="item.giftUrl" alt=""/>
            </div>
          </div>
          <m-empty-state v-if="!receivedGiftList.length" message="Nothing Here Yet." />
        </div>
        <!-- 底部升级按钮（非VIP显示） -->
        <button v-if="!isVip" class="upgrade-button" @click="openPremium">
          <span class="upgrade-title">UPGRADE</span>
          <span class="upgrade-subtitle">to Check Gift History</span>
        </button>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MActionBar from "@/components/MActionBar.vue";
import MPageWrap from "@/components/MPageWrap.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import { getGiftHistortList } from "@/api/sdk/commodity";
import { getCountryFlagEmojiByCode } from "@/utils/Utils";
import {openAnchorUserDetail, openPremium, openUserInfo} from "@/utils/PageUtils";

export default {
  name: 'GiftRecord',
  components: { MPageWrap, MActionBar, MEmptyState },
  data() {
    return {
      receivedGiftList: []
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    isVip() {
      return this.userInfo.vipCategory !== undefined &&
             this.userInfo.vipCategory !== null &&
             this.userInfo.vipCategory !== 0;
    }
  },
  methods: {
    openAnchorUserDetail,
    openUserInfo,
    openPremium,
    async loadGiftList() {
      try {
        const res = await getGiftHistortList(1, 20, 3);
        let list = [];
        if (res && res.data && Array.isArray(res.data)) {
          list = res.data;
        }
        this.receivedGiftList = list.map((item) => this.mapGiftItem(item));
      } catch (error) {
        console.error('加载礼物记录失败:', error);
        this.receivedGiftList = [];
      }
    },
    mapGiftItem(item) {
      const info = item.toUserInfo || {};
      const time = item.createTime != null ? (item.createTime < 1e12 ? item.createTime * 1000 : item.createTime) : Date.now();
      const countryCode = info.country != null ? info.country : item.country;
      return {
        consumeId: item.consumeId,
        name: info.nickname || item.name || '',
        avatar: info.avatar || item.avatar || null,
        countryFlag: countryCode != null ? getCountryFlagEmojiByCode(countryCode) : '🇺🇸',
        gender: info.gender != null ? Number(info.gender) : 0,
        age: info.age != null ? Number(info.age) : 0,
        time,
        giftType: item.coinChangeType === 4 ? 'online' : 'gift',
        giftUrl: item.giftUrl || null,
        isOnline: info.onlineStatus === 0 || info.onlineStatus === 2
      };
    },
    formatTime(timestamp) {
      const date = new Date(timestamp);
      const hours = date.getHours();
      const minutes = date.getMinutes();
      const ampm = hours >= 12 ? 'PM' : 'AM';
      const displayHours = hours % 12 || 12;
      const displayMinutes = minutes < 10 ? '0' + minutes : minutes;
      return `${displayHours}:${displayMinutes} ${ampm}`;
    },
    getGenderIcon(gender) {
      return require('@/assets/image/sdk/ic-userdetail-girl.png');
    },
    getGenderAge(item) {
      return this.isVip ? String(item.age || '') : '**';
    }
  },
  mounted() {
    this.loadGiftList();
  }
}
</script>

<style scoped lang="less">
.page {
  height: 100%;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  display: flex;
  flex-direction: column;
}

.gift-list {
  flex: 1;
  padding: 0 18px 18px;
  box-sizing: border-box;
  padding-bottom: 20px;
}

.gift-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.sender-info {
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 0;
  gap: 12px;
}

.avatar-wrapper {
  position: relative;
  flex-shrink: 0;
}

.avatar {
  width: 56px;
  height: 56px;
  border-radius: 28px;
  object-fit: cover;
  border: 1px solid @theme-color;
}

.avatar-wrapper.avatar-blur .avatar {
  filter: blur(8px);
}

.avatar-mask {
  position: absolute;
  inset: 0;
  z-index: 2;
  border-radius: 28px;
  background: rgba(0, 0, 0, 0.25);
  cursor: pointer;
}

.online-indicator {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 16px;
  height: 16px;
  border-radius: 8px;
  border: 2px solid @theme-bg-color;
}

.sender-details {
  flex: 1;
  min-width: 0;
}

.name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
  flex-wrap: wrap;
}

.name {
  font-size: 16px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
}

.country-flag {
  font-size: 16px;
  line-height: 1;
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

.call-tag-icon {
  width: auto;
  height: 20px;
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
  left: 62%;
  transform: translate(-50%, -50%);
  font-size: 12px;
  line-height: 14px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  z-index: 1;
}

.time-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.time-icon {
  width: 13px;
  height: 13px;
  flex-shrink: 0;
}

.time {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.55);
}

.gift-info {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  margin-left: 12px;
}

.gift-icon {
  width: 40px;
  height: 40px;
  object-fit: contain;
}

.gift-count {
  font-size: 16px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
}

.empty {
  padding: 60px 20px;
  text-align: center;
  color: rgba(255, 255, 255, 0.45);
  font-size: 14px;
}

.upgrade-button {
  position: fixed;
  bottom: calc(20px + constant(safe-area-inset-bottom));
  bottom: calc(20px + env(safe-area-inset-bottom));
  left: 50%;
  transform: translateX(-50%);
  width: 280px;
  height: 54px;
  background-image: url('@/assets/image/global/ic-pre-button-bg.png');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  border: none;
  border-radius: 27px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 0;
  z-index: 1000;
  transition: all 0.3s ease;

  &:active {
    transform: translateX(-50%) scale(0.98);
  }
}

.upgrade-title {
  font-size: 18px;
  font-weight: 700;
  color: #333333;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.upgrade-subtitle {
  font-size: 12px;
  font-weight: 500;
  color: #333333;
  letter-spacing: 0.3px;
}
</style>
