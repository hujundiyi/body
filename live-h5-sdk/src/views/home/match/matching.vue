<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div class="matching-container">
        <!-- Match success: Full screen anchor avatar -->
        <template v-if="showAnchorModal && matchedAnchor">
          <!-- Full screen background -->
          <div class="matched-bg">
            <img
              :src="matchedAnchor.avatar"
              class="matched-avatar-img"
              alt=""
            />
          </div>

          <!-- Bottom info area -->
          <div class="matched-bottom">
            <!-- Matched with label -->
            <div class="matched-with-label">
              <img
                src="@/assets/image/call/calling/ic_matched_with@2x.png"
                class="matched-with-img"
                alt="Matched with"
              />
            </div>

            <!-- Anchor name -->
            <div class="matched-name">{{ matchedAnchor.nickname || 'Unknown' }}</div>

            <!-- Country flag and age tags -->
            <div class="matched-tags">
              <span class="flag-icon">{{ countryFlag }}</span>
              <div v-if="matchedAnchor.age" class="call-tag call-tag-overlay">
                <img class="call-tag-icon" style="width: 54px;" :src="genderIcon" alt="" />
                <span class="call-tag-text">{{ matchedAnchor.age || 23 }}</span>
              </div>
            </div>

            <!-- Next and Accept buttons -->
            <div class="matched-buttons">
              <button class="btn-next" @click="handleNextAnchor">Next {{ nextCountdown }}</button>
              <button class="btn-accept" @click="handleAcceptAnchor">Accept</button>
            </div>
          </div>
        </template>

        <!-- Connecting status -->
        <template v-else-if="showConnecting">
          <!-- Blur background -->
          <div class="background-blur"></div>

          <!-- Matched person avatar -->
          <div class="matched-avatar-container">
            <img
              :src="matchedAnchor && matchedAnchor.avatar ? matchedAnchor.avatar : defaultAvatar"
              :alt="matchedAnchor && matchedAnchor.nickname ? matchedAnchor.nickname : 'Matched'"
              class="matched-single-avatar"
            />
          </div>

          <!-- Connecting text -->
          <div class="connecting-text">Connecting</div>

          <!-- Three dots animation -->
          <div class="dots-container">
            <span
              v-for="(dot, index) in 3"
              :key="index"
              class="dot"
              :class="`dot-${index}`"
            ></span>
          </div>
        </template>

        <!-- Matching status -->
        <template v-else>
          <!-- Blur background -->
          <!-- <div class="background-blur"></div> -->
          <div class="matched-bg">
            <img
              src="@/assets/image/match/ic_match_bg@2x.png"
              class="matched-bg-img"
              alt=""
            />
          </div>
          <!-- Three avatars -->
          <div class="avatars-container">
            <div
              v-for="(anchor, index) in displayAnchors"
              :key="index"
              class="avatar-wrapper"
              :class="`avatar-${index}`"
            >
              <img
                :src="anchor.avatar || defaultAvatar"
                :alt="anchor.nickname || 'Anchor'"
                class="avatar-img"
              />
            </div>
          </div>

          <!-- Matching text -->
          <div class="matching-text">Matching</div>

          <!-- Three dots animation -->
          <div class="dots-container">
            <span
              v-for="(dot, index) in 3"
              :key="index"
              class="dot"
              :class="`dot-${index}`"
              :style="{ animationDelay: `${index * 0.2}s` }"
            ></span>
          </div>

          <!-- Exit match button -->
          <div class="exit-button" @click="handleExitMatch">
            <img src="@/assets/image/sdk/ic-call-end.png" class="exit-icon" alt="Exit match" />
          </div>
        </template>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MPageWrap from "@/components/MPageWrap.vue";
import { matcherAnchor } from "@/api/sdk/match";
import { callCreate } from "@/utils/CallUtils";
import { getCountryFlagEmojiByCode } from "@/utils/Utils";
import clientNative from "@/utils/ClientNative";
import { showCallToast } from "@/components/toast/callToast";
import cache from "@/utils/cache";
import store from "@/store";

const selectedCountryCacheKey = 'country_filter_selected';
const countryModeCacheKey = 'country_filter_mode';
const superMatchCacheKey = 'country_filter_super_match';
const COINS_PER_FILTER = 200;

export default {
  name: 'PageMatching',
  components: { MPageWrap },
  data() {
    return {
      displayAnchors: [],
      defaultAvatar: require('@/assets/image/ic-placeholder-avatar.png'),
      isMatching: false,
      matchedAnchor: null,
      showAnchorModal: false,
      showConnecting: false,
      isPageDestroyed: false, // 页面是否已销毁
      connectingTimer: null, // 连接超时定时器
      nextCountdown: 15,
      nextCountdownTimer: null,
      callInfo: null,
      // 铃声音频对象
      ringAudio: null,
    }
  },
  computed: {
    // 监听 store 中匹配通话被拒绝的状态
    matchCallRejected() {
      return this.$store.state.call.matchCallRejected
    },
    genderIcon() {
      if (!this.matchedAnchor) {
        return require('@/assets/image/sdk/ic-userdetail-boy.png');
      }
      const gender = this.matchedAnchor.gender;
      // gender === 1 means Female, gender === 2 means Male
      const isGirl = gender === 1;
      return isGirl
        ? require('@/assets/image/sdk/ic-userdetail-girl.png')
        : require('@/assets/image/sdk/ic-userdetail-boy.png');
    },
    genderText() {
      if (!this.matchedAnchor) {
        return 'Unknown';
      }
      const gender = this.matchedAnchor.gender;
      return gender === 1 ? 'Female' : gender === 2 ? 'Male' : 'Unknown';
    },
    // Get country flag image URL based on country field
    countryFlag() {
      const countryCode = this.matchedAnchor?.country || 'US';
      return getCountryFlagEmojiByCode(countryCode);
    }
  },
  watch: {
    // 监听匹配通话被拒绝的状态变化
    matchCallRejected(newVal, oldVal) {
      if (newVal && newVal !== oldVal && this.showConnecting) {
        // 匹配通话被拒绝，重新匹配
        this.clearConnectingTimer()
        this.showConnecting = false
        this.callInfo = null
        this.matchedAnchor = null
        // 继续匹配
        this.startMatch()
      }
    },
    // 监听 showConnecting 变化，播放/停止铃声
    showConnecting(newVal) {
      if (newVal) {
        this.playRingAudio()
      } else {
        this.stopRingAudio()
      }
    },
    showAnchorModal(newVal) {
      if (newVal) {
        this.startNextCountdown()
      } else {
        this.clearNextCountdown()
      }
    }
  },
  created() {
    this.loadRecommendAnchors()
    this.startMatch()
  },
  beforeDestroy() {
    // 标记页面已销毁，阻止后续异步操作
    this.isPageDestroyed = true
    // 清除连接超时定时器
    this.clearConnectingTimer()
    // 清除自动匹配倒计时
    this.clearNextCountdown()
    // 停止并清理铃声
    this.stopRingAudio()
    this.ringAudio = null
  },
  methods: {
    /**
     * Load recommended anchors list (from store)
     */
    async loadRecommendAnchors() {
      try {
        await this.$store.dispatch('anchor/loadRecommendAnchors')
        this.selectRandomAnchors()
      } catch (error) {
        console.error('Failed to load recommended anchors:', error)
        // Use default data
        this.displayAnchors = [
          { avatar: this.defaultAvatar, nickname: 'Anchor 1' },
          { avatar: this.defaultAvatar, nickname: 'Anchor 2' },
          { avatar: this.defaultAvatar, nickname: 'Anchor 3' }
        ]
      }
    },
    /**
     * Randomly select 3 from recommended anchors
     */
    selectRandomAnchors() {
      const randomAnchors = this.$store.getters['anchor/getRandomAnchors'](3)
      if (randomAnchors && randomAnchors.length > 0) {
        this.displayAnchors = randomAnchors
      } else {
        // Use default data
        this.displayAnchors = [
          { avatar: this.defaultAvatar, nickname: 'Anchor 1' },
          { avatar: this.defaultAvatar, nickname: 'Anchor 2' },
          { avatar: this.defaultAvatar, nickname: 'Anchor 3' }
        ]
      }
    },
    /**
     * Start matching
     */
    async startMatch() {
      if (this.isMatching) {
        return
      }
      this.isMatching = true
      this.showConnecting = false
      this.showAnchorModal = false
      try {
        // 延时5秒再请求接口
        await new Promise(resolve => setTimeout(resolve, 5000))
        // 如果页面已销毁，不再继续执行
        if (this.isPageDestroyed) {
          return
        }

        /**
         * 匹配前计算金币扣减与道具消耗，传入 matcherAnchor 接口。
         * 规则：VIP 不扣；有 Match Filters 免费次数则消耗 1 个道具、不扣金币；
         * 否则按 countryMode=us / Super Match 开 / 选了具体国家 各扣 10 金币。
         */

        // ----- 从 MCountryFilterDialog 缓存读取筛选状态 -----
        const countryMode = cache.local.get(countryModeCacheKey) || '';
        const superMatchRaw = cache.local.get(superMatchCacheKey);
        const superMatch = superMatchRaw === true || superMatchRaw === 'true';
        const cachedCountry = cache.local.getJSON(selectedCountryCacheKey);
        const selectedIsAll = cachedCountry === 'all' || !cachedCountry;
        // countryMode: 'balanced' | 'global' | 'us'，选 us 时匹配需额外扣 10 金币
        // superMatch: 是否开启 Super Match，开启时需额外扣 10 金币
        // selectedIsAll: 是否选了 All；若选了具体国家需额外扣 10 金币

        // ----- 用户身份与背包 -----
        const loginUserInfo = this.$store.state.user.loginUserInfo || {};
        const isVip = loginUserInfo.vipCategory != null && loginUserInfo.vipCategory !== 0;
        const backpack = this.$store.state.user.userBackpack || [];
        const matchFilterFreeCount = backpack
          .filter((item) => item && Number(item.backpackType) === 3)
          .reduce((sum, item) => sum + Math.max(0, Number(item.quantity) || 0), 0);
        // backpackType 3 = Match Filters；数量 > 0 时可抵一次匹配，不扣金币、消耗 1 个道具

        let coins = 0;
        let matchFilterConsume = 0;

        if (isVip) {
          coins = 0;
          matchFilterConsume = 0;
        } else if (matchFilterFreeCount > 0) {
          coins = 0;
          matchFilterConsume = 1;
        } else {
          // 非 VIP 且无免费次数：按筛选条件累计扣金币
          if (countryMode === 'us') coins += COINS_PER_FILTER;       // United States & More
          if (superMatch) coins += COINS_PER_FILTER;                 // Super Match 开启
          if (!selectedIsAll) coins += COINS_PER_FILTER;             // 选了具体国家（非 All）
          matchFilterConsume = 0;
        }
        // VIP：不扣不耗；有免费次数：不扣金币、消耗 1 道具；否则按上三条件各 +10 金币

        const params = {};
        if (!selectedIsAll && cachedCountry && typeof cachedCountry === 'object') {
          const code = cachedCountry.code ?? cachedCountry.value;
          if (code != null && code !== '') params.country = code;
        }
        if (coins !== 0 || matchFilterConsume !== 0) {
          if (matchFilterConsume > 0) {
            params.consumeType = 1;
            params.consumeQuantity = matchFilterConsume;
          } else {
            params.consumeType = 2;
            params.consumeQuantity = coins;
          }
        }
        console.error('matcherAnchor 入参', { cachedCountry, coins, matchFilterConsume, params });
        const res = await matcherAnchor(params);
        // 再次检查，防止接口返回时页面已退出
        if (this.isPageDestroyed) {
          return
        }
        if (res.success && res.data) {
          // Show anchor info modal
          this.matchedAnchor = res.data
          this.showAnchorModal = true
          await this.$store.dispatch('GetUserBackpack');
        } else {
          // showCallToast && showCallToast(res.msg || 'Match failed, please try again')
        }
      } catch (error) {
        // 页面已销毁时不显示 toast
        if (!this.isPageDestroyed) {
          showCallToast(error)
        }
      } finally {
        this.isMatching = false
      }
    },
    /**
     * Accept match, call callCreate API
     */
    async handleAcceptAnchor() {
      if (!this.matchedAnchor || !this.matchedAnchor.userId) {
        showCallToast('Anchor info incomplete')
        return
      }




      try {
        // Call CallUtils callCreate, it will auto save data to store and navigate
        const  res = await callCreate(this.matchedAnchor.userId, '', true)
        if (res.code === 200 && res.data) {
           // Hide match success interface
          this.showAnchorModal = false
          this.clearNextCountdown()
          // Show Connecting status
          this.showConnecting = true
          // 启动30秒超时定时器
          this.callInfo = res.data;
          this.startConnectingTimer()
        }else {
          this.clearConnectingTimer()
          if (res.code === 1001) {
            this.$router.back();
          }
        }
      } catch (error) {
        this.clearConnectingTimer()
        this.showConnecting = false
        // showCallToast(error)
      }
    },
    /**
     * Next anchor (continue matching)
     */
    handleNextAnchor() {
      // Hide modal
      this.showAnchorModal = false
      this.clearNextCountdown()
      this.matchedAnchor = null
      // Continue matching
      this.startMatch()
    },
    startNextCountdown() {
      this.clearNextCountdown()
      this.nextCountdown = 15
      this.nextCountdownTimer = setInterval(() => {
        if (this.isPageDestroyed || !this.showAnchorModal) {
          this.clearNextCountdown()
          return
        }
        this.nextCountdown -= 1
        if (this.nextCountdown <= 0) {
          this.clearNextCountdown()
          this.handleNextAnchor()
        }
      }, 1000)
    },
    clearNextCountdown() {
      if (this.nextCountdownTimer) {
        clearInterval(this.nextCountdownTimer)
        this.nextCountdownTimer = null
      }
    },
    /**
     * Exit matching
     */
    handleExitMatch() {
      this.$router.go(-1)
    },
    /**
     * 启动连接超时定时器（30秒）
     */
    startConnectingTimer() {
      this.clearConnectingTimer()
      this.connectingTimer = setTimeout(() => {
        // 如果页面已销毁，不执行任何操作
        if (this.isPageDestroyed) {
          return
        }
        // 如果仍在连接状态，提示失败并继续匹配
        if (this.showConnecting) {
          this.showConnecting = false
          this.callInfo = null
          this.matchedAnchor = null

          showCallToast('Connection timeout, try matching again')
          // 继续匹配
          this.startMatch()
        }
      }, 60000) // 60秒超时
    },
    /**
     * 清除连接超时定时器
     */
    clearConnectingTimer() {
      if (this.connectingTimer) {
        clearTimeout(this.connectingTimer)
        this.connectingTimer = null
      }
    },
    /**
     * 播放铃声
     */
    playRingAudio() {
      try {
        if (!this.ringAudio) {
          this.ringAudio = new Audio(require('@/assets/audio/call_matching.mp3'))
          this.ringAudio.loop = true // 循环播放
        }
        this.ringAudio.currentTime = 0
        this.ringAudio.play().catch(err => {
          console.warn('铃声播放失败:', err)
        })
      } catch (err) {
        console.warn('铃声加载失败:', err)
      }
    },
    /**
     * 停止铃声
     */
    stopRingAudio() {
      if (this.ringAudio) {
        this.ringAudio.pause()
        this.ringAudio.currentTime = 0
      }
    }
  }
}
</script>

<style scoped lang="less">
.matching-container {
  position: relative;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(180deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

// ============ Match success page styles ============
.matched-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
}

.matched-bg-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.matched-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.matched-bottom {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 10;
  padding: 0 24px 60px;
  display: flex;
  flex-direction: column;
  align-items: center;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.7) 0%, transparent 100%);
  padding-top: 100px;
}

.matched-with-label {
  margin-bottom: 12px;
}

.matched-with-img {
  height: 20px;
  width: 269px;
  object-fit: contain;
}

.matched-name {
  font-size: 30px;
  font-weight: 900;
  color: #fff;
  margin-bottom: 15px;
  text-align: center;
}

.matched-tags {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-bottom: 30px;
}

.flag-icon {
  display: inline-block;
  font-size: 40px;
  line-height: 1;
  vertical-align: middle;
  border-radius: 50%;
  object-fit: contain;
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

.call-tag-overlay {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.call-tag-icon {
  width: auto;
  height: 25px;
  max-width: 98px;
  object-fit: contain;
  flex-shrink: 0;
}

.call-tag-overlay .call-tag-text {
  position: absolute;
  top: 53%;
  left: 65%;
  transform: translate(-50%, -50%);
  font-size: 12px;
  line-height: 14px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  z-index: 1;
}

.matched-buttons {
  display: flex;
  gap: 16px;
  width: 100%;
  max-width: 360px;
}

.btn-next {
  flex: 0 0 120px;
  height: 56px;
  background: #1C1C1E;
  border-radius: 28px;
  border: none;
  color: #fff;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: flex;
  align-items: center;
  justify-content: center;

  &:active {
    transform: scale(0.95);
    opacity: 0.8;
  }
}

.btn-accept {
  flex: 1;
  height: 56px;
  background: #4FD860;
  border-radius: 28px;
  border: none;
  color: #fff;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;

  &:active {
    transform: scale(0.95);
    opacity: 0.9;
  }
}

// ============ Common background styles ============
.background-blur {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, rgba(26, 26, 46, 0.8) 0%, rgba(22, 33, 62, 0.9) 50%, rgba(15, 52, 96, 0.95) 100%);
  backdrop-filter: blur(20px);
  z-index: 1;
}

/* Matched single avatar container */
.matched-avatar-container {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: -180px;
  z-index: 2;
}

.matched-single-avatar {
  width: 145px;
  height: 145px;
  border-radius: 50%;
  border: 3px solid rgba(255, 255, 255, 0.8);
  object-fit: cover;
  background: rgba(255, 255, 255, 0.1);
}

.avatars-container {
  position: relative;
  width: 100%;
  height: 160px;
  margin-top: -180px;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar-wrapper {
  position: absolute;
  width: 110px;
  height: 110px;
  border-radius: 50%;
  border: 3px solid rgba(255, 255, 255, 0.8);
  overflow: hidden;
  background: rgba(255, 255, 255, 0.1);
  animation: circleRotate 4s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;

  &.avatar-0 {
    animation-name: circleRotate0;
  }

  &.avatar-1 {
    animation-name: circleRotate1;
  }

  &.avatar-2 {
    animation-name: circleRotate2;
  }
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: blur(3px);
  transform: scale(1.1);
}

// 三个头像轮流到达中间位置，始终有一个最大的在中间
// 相位差 33.33%，确保每个时刻中间都有最大头像

// avatar-0: 中间 → 右边 → 左边 → 中间
@keyframes circleRotate0 {
  0%, 100% {
    transform: translateX(0) scale(1.3);
    z-index: 3;
    opacity: 1;
  }
  33.33% {
    transform: translateX(80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
  66.66% {
    transform: translateX(-80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
}

// avatar-1: 右边 → 左边 → 中间 → 右边
@keyframes circleRotate1 {
  0%, 100% {
    transform: translateX(80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
  33.33% {
    transform: translateX(-80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
  66.66% {
    transform: translateX(0) scale(1.3);
    z-index: 3;
    opacity: 1;
  }
}

// avatar-2: 左边 → 中间 → 右边 → 左边
@keyframes circleRotate2 {
  0%, 100% {
    transform: translateX(-80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
  33.33% {
    transform: translateX(0) scale(1.3);
    z-index: 3;
    opacity: 1;
  }
  66.66% {
    transform: translateX(80px) scale(0.85);
    z-index: 1;
    opacity: 0.7;
  }
}


.matching-text {
  margin-top: 40px;
  font-size: 24px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: 4px;
  z-index: 2;
  position: relative;
}

.connecting-text {
  margin-top: 40px;
  font-size: 24px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: 2px;
  z-index: 2;
  position: relative;
}

.dots-container {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 30px;
  z-index: 2;
  position: relative;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  animation: dotPulse 1.4s ease-in-out infinite;

  &.dot-0 {
    background: #ffffff;
    animation-delay: 0s;
  }

  &.dot-1 {
    background: rgba(255, 255, 255, 0.5);
    animation-delay: 0.2s;
  }

  &.dot-2 {
    background: rgba(255, 255, 255, 0.5);
    animation-delay: 0.4s;
  }
}

@keyframes dotPulse {
  0%, 100% {
    opacity: 0.5;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.3);
  }
}

.exit-button {
  position: absolute;
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
  width: 70px;
  height: 70px;
  background: #FF3B30;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 10;
  box-shadow: 0 4px 12px rgba(255, 59, 48, 0.4);
  transition: all 0.3s ease;

  &:active {
    transform: translateX(-50%) scale(0.95);
    box-shadow: 0 2px 8px rgba(255, 59, 48, 0.3);
  }

  .exit-icon {
    width: 32px;
    height: 32px;
    object-fit: contain;
    filter: brightness(0) invert(1);
  }
}


</style>
