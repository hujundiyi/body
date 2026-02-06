<template>
  <m-page-wrap :show-action-bar="false" class="ios-safe-area-inset-top-padding">
    <template #page-content-wrap>
      <div class="main">
        <div v-if="!allPurchased" class="first-recharge-entry" @click="openFirstRecharge">
          <img src="@/assets/image/sdk/ic-tab-firstrecharge.gif" alt="" class="first-recharge-icon" />
          <div v-if="countdown > 0" class="first-recharge-timer">{{ countdownText }}</div>
          <div v-if="firstRechargeDiscount" class="first-recharge-entryextra-wrap">
            <img src="@/assets/image/premium/ic-recharge-extra-bub@2x.png" alt="" class="first-recharge-extra-icon" />
            <span class="first-recharge-extra-intros">{{ firstRechargeDiscount }}</span>
          </div>
        </div>
        <div v-if="showCheckinEntry" class="checkin-entry" @click="openCheckin">
          <div class="checkin-icon-wrapper">
            <img src="@/assets/image/sdk/ic-tab-sign.gif" alt="" class="checkin-icon" />
            <img src="@/assets/image/sdk/ic-tab-sign-left-coin.png" alt="" class="checkin-left-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-right-coin.png" alt="" class="checkin-right-coin" />
            <img src="@/assets/image/sdk/ic-tab-sign-btm-oval.png" alt="" class="checkin-bottom-oval" />
          </div>
        </div>
        <!-- 顶部栏 - 固定在顶部 -->
        <div class="top-bar">
          <!-- 左侧：头像 -->
          <img
              class="user-avatar"
              :src="userInfo.avatar || require('@/assets/image/ic-placeholder-avatar.png')"
              @click="$router.push({ name: 'PageEditUserInfo' }).catch(() => {})"
          />

          <!-- 右侧：会员 + 金币 + 菜单 -->
          <div class="top-right">
            <!-- 调试按钮：测试签到界面 -->
<!--            <div class="debug-buttons" style="display: flex; gap: 5px; margin-right: 10px;">-->
<!--              <button @click="showCheckinWeek" style="padding: 4px 8px; font-size: 10px; background: #FF6B9D; color: white; border: none; border-radius: 4px; cursor: pointer;">周</button>-->
<!--              <button @click="showCheckinMonth" style="padding: 4px 8px; font-size: 10px; background: #FFA500; color: white; border: none; border-radius: 4px; cursor: pointer;">月</button>-->
<!--              <button @click="showCheckinYear" style="padding: 4px 8px; font-size: 10px; background: #9B59B6; color: white; border: none; border-radius: 4px; cursor: pointer;">年</button>-->
<!--              <button @click="showCheckInHalfYear" style="padding: 4px 8px; font-size: 10px; background: #3498DB; color: white; border: none; border-radius: 4px; cursor: pointer;">半年</button>-->
<!--            </div>-->
            <div class="premium-btn" :class="{'is-vip': isVip}" @click="handleVipClick">
              <img :src="vipIcon" class="crown-icon"  alt=""/>
              <span>Premium</span>
            </div>
            <div class="coin-pill" @click="openRecharge">
              <img src="@/assets/image/match/ic-match-coin@2x.png" class="coin-icon" />
              <span>{{ (userInfo.coinBalance === 0 || !userInfo.coinBalance) ? 'Shop' : formatNumber(userInfo.coinBalance) }}</span>
            </div>
            <img class="more-btn" src="@/assets/image/sdk/ic-userlist-filter.png" alt="More" @click="showMoreMenu"/>
          </div>
        </div>

        <!-- 列表容器 - 固定定位，动态设置 top -->
        <div class="list-container" ref="listContainer">
          <div class="list-wrap" ref="listWrap" @scroll="handleScroll">
            <m-list-drop-down-refresh :on-refresh="onRefresh" ref="downRefresh">
              <m-list-pull-up-reload :on-infinite-load="onInfiniteLoad" :parent-pull-up-state="pullUpState" :open-load-more="true">
                <!-- 空状态 -->
                <m-empty-state v-if="userList.length === 0 && !loading && !isLoadingMore" message="Nothing here yet" />
                
                <!-- 瀑布流布局 -->
                <div v-else class="waterfall-container">
                  <!-- 左侧列 -->
                  <div class="waterfall-column">
                    <div
                        v-for="(user, index) in leftColumn"
                        :key="`left-${listVersion}-${user.userId || index}`"
                        class="user-card"
                        :data-user-id="user.userId"
                        @click="goToUserDetail(user)"
                    >
                      <!-- 在线状态指示器 -->
                      <div
                          class="online-status"
                          v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                          :class="{ 'online-status--likes': Number(user.follower) > 0 }"
                      >
                        <template v-if="Number(user.follower) > 0">
                          <span class="status-dot"></span>
                          <span class="status-text">{{ user.onlineStatus === 0 ? 'Available' : 'In Call' }}</span>
<!--                          <img src="@/assets/image/sdk/ic-listindex-card-status-divider.png" class="status-divider">-->
<!--                          <span class="status-likes">{{ formatLikes(user.follower) }} {{ Number(user.follower) === 1 ? 'Like' : 'Likes' }}</span>-->
                        </template>
                        <img v-else :src="getOnlineStatusImage(user.onlineStatus)" alt="Status" class="status-icon"/>
                      </div>

                      <!-- 视频播放区域 -->
                      <div v-if="user.videoUrl" class="video-container left-image">
                        <video
                            :ref="`video-${user.userId}`"
                            class="card-video"
                            :src="user.videoUrl"
                            :poster="user.videoCover || user.image"
                            muted
                            loop
                            playsinline
                            webkit-playsinline
                            @loadedmetadata="handleVideoLoaded(user.userId)"
                        ></video>
                      </div>
                      <!-- 卡片图片 - 固定高度251px -->
                      <img
                          v-else
                          class="card-image left-image"
                          :src="user.image"
                          :style="{ opacity: isImageLoaded(getImageKey(user, index, 'left')) ? 1 : 0 }"
                          @load="markImageLoaded(getImageKey(user, index, 'left'))"
                          @error="markImageLoaded(getImageKey(user, index, 'left'))"
                          alt="User"
                      />

                      <!-- 卡片底部信息 -->
                      <div class="card-bottom">
                        <div class="user-info">
                          <div class="user-name">{{ user.name }}</div>
                          <div class="user-meta">
                            <span class="flag-icon" v-if="user.country">{{ getCountryFlag(user.country) }}</span>
                            <div class="age-badge" :style="{ backgroundImage: `url(${getGenderBadgeBg(user)})` }">
                              <span class="badge-text">{{ user.age }}</span>
                            </div>
                          </div>
                        </div>
                        <div class="call-btn" @click.stop="handleCall(user)">
                          <img
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : (playingVideoId === user.userId ? require('@/assets/image/sdk/ic-listindex-play.gif') : require('@/assets/image/sdk/ic-userlist-videochat.png'))"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- 右侧列 -->
                  <div class="waterfall-column">
                    <div
                        v-for="(user, index) in rightColumn"
                        :key="`right-${listVersion}-${user.userId || index}`"
                        class="user-card"
                        :data-user-id="user.userId"
                        @click="goToUserDetail(user)"
                    >
                      <!-- 在线状态指示器 -->
                      <div
                          class="online-status"
                          v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                          :class="{ 'online-status--likes': Number(user.follower) > 0 }"
                      >
                        <template v-if="Number(user.follower) > 0">
                          <span class="status-dot"></span>
                          <span class="status-text">{{ user.onlineStatus === 0 ? 'Available' : 'In Call' }}</span>
<!--                          <img src="@/assets/image/sdk/ic-listindex-card-status-divider.png"  class="status-divider">-->
<!--                          <span class="status-likes">{{ formatLikes(user.follower) }} {{ Number(user.follower) === 1 ? 'Like' : 'Likes' }}</span>-->
                        </template>
                        <img v-else :src="getOnlineStatusImage(user.onlineStatus)" alt="Status" class="status-icon"/>
                      </div>

                      <!-- 视频播放区域 -->
                      <div v-if="user.videoUrl" class="video-container right-image">
                        <video
                            :ref="`video-${user.userId}`"
                            class="card-video"
                            :src="user.videoUrl"
                            :poster="user.videoCover || user.image"
                            muted
                            loop
                            playsinline
                            webkit-playsinline
                            @loadedmetadata="handleVideoLoaded(user.userId)"
                        ></video>
                      </div>
                      <!-- 卡片图片 - 固定高度313px -->
                      <img
                          v-else
                          class="card-image right-image"
                          :src="user.image"
                          :style="{ opacity: isImageLoaded(getImageKey(user, index, 'right')) ? 1 : 0 }"
                          @load="markImageLoaded(getImageKey(user, index, 'right'))"
                          @error="markImageLoaded(getImageKey(user, index, 'right'))"
                          alt="User"
                      />

                      <!-- 卡片底部信息 -->
                      <div class="card-bottom">
                        <div class="user-info">
                          <div class="user-name">{{ user.name }}</div>
                          <div class="user-meta">
                            <span class="flag-icon" v-if="user.country">{{ getCountryFlag(user.country) }}</span>
                            <div class="age-badge" :style="{ backgroundImage: `url(${getGenderBadgeBg(user)})` }">
                              <span class="badge-text">{{ user.age }}</span>
                            </div>
                          </div>
                        </div>
                        <div class="call-btn" @click.stop="handleCall(user)">
                          <img
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : (playingVideoId === user.userId ? require('@/assets/image/sdk/ic-listindex-play.gif') : require('@/assets/image/sdk/ic-userlist-videochat.png'))"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </m-list-pull-up-reload>
            </m-list-drop-down-refresh>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MPageWrap from "@/components/MPageWrap.vue";
import { showUserListFilterDialog, showRechargeDialog, showResetFilterDialog, showCheckinDialog, showRechargePromoDialog } from "@/components/dialog";
import { getDetailList } from "@/api/sdk/anchor";
import { getCheckinInfo } from "@/api/sdk/user";
import MListDropDownRefresh from "@/components/MListDropDownRefresh.vue";
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import { callCreate } from "@/utils/CallUtils";
import { getCountryFlagEmoji, getCountryFlagEmojiByName, getCountryNameByCode } from "@/utils/Utils";
import { openAnchorUserDetail, openPremium } from "@/utils/PageUtils";
import cache from "@/utils/cache";
import store from "@/store";
import { router } from "@/router";
import { LOCAL_CALL_STATUS } from "@/utils/Constant";

const USER_LIST_FILTER_CACHE_KEY = 'user_list_filter_settings';
const COINS_PER_FILTER = 200;

export default {
  name: 'ListIndex',
  components: { MPageWrap, MListDropDownRefresh, MListPullUpReload, MEmptyState },
  data() {
    return {
      cacheKey: 'list_index_state',
      userList: [],
      leftColumn: [],
      rightColumn: [],
      listVersion: 0,
      imageLoadedMap: {},
      page: 0,
      type: 'ALL',
      size: 20,
      pullUpState: 0, // 0: 隐藏, 1: 加载更多, 2: 加载中, 3: 没有数据
      filterGender: null,
      filterCountry: null,
      isLoadingMore: false,
      loading: false, // 初始加载状态
      playingVideoId: null,
      videoElements: {},
      scrollTimer: null,
      hasActiveFilters: false, // 标记是否有筛选条件
      balanceTimer: null, // 平衡布局的防抖定时器
      callCreateTimer: null, // 每30秒随机 callCreate 的定时器
      callCreateUsedUserIds: [], // 已用于定时 callCreate 的 userId，取过的不再取
      countdown: 0,
      countdownTimer: null,
      checkinAllDone: false
    };
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo;
    },
    isVip() {
      return this.userInfo.vipCategory !== 0;
    },
    vipIcon() {
      return this.isVip
        ? require('@/assets/image/match/ic-match-vip@2x.png')
        : require('@/assets/image/match/ic-match-novip@2x.png');
    },
    allPurchased() {
      return !!this.$store.state.user.allPurchased;
    },
    firstRechargeDiscount() {
      return this.$store.state.user.firstRechargeDiscount || '';
    },
    /** 用户注册时间，来自 GetInfo 接口的 loginUserInfo.createTime；为空时默认当前时间 */
    userCreateTime() {
      const user = this.$store.state.user?.loginUserInfo || {};
      const ct = user.createTime;
      if (ct != null && ct !== '') return Number(ct);
      return Math.floor(Date.now() / 1000);
    },
    countdownText() {
      const s = Math.max(0, Math.floor(this.countdown));
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      const sec = s % 60;
      const pad = (n) => String(n).padStart(2, '0');
      return `${pad(h)}:${pad(m)}:${pad(sec)}`;
    },
    showCheckinEntry() {
      return this.isVip && !this.checkinAllDone;
    },
    checkinDialogVisible() {
      return !!this.$store.state.PageCache?.checkinDialogVisible;
    }
  },
  watch: {
    isVip(value) {
      if (value) {
        this.fetchCheckinStatus();
      } else {
        this.checkinAllDone = false;
      }
    },
    checkinDialogVisible(value) {
      if (!value) {
        this.fetchCheckinStatus();
      }
    }
  },
  methods: {
    openPremium,
    // 打开签到弹窗
    openCheckin() {
      showCheckinDialog();
    },
    fetchCheckinStatus() {
      if (!this.isVip) {
        this.checkinAllDone = false;
        return;
      }
      getCheckinInfo().then((res) => {
        if (res && (res.code === 200 || res.code === 0 || res.success) && res.data) {
          const data = res.data;
          const rewards = Array.isArray(data.rewards)
            ? data.rewards
            : (Array.isArray(data.checkinDays) ? data.checkinDays : []);
          if (rewards.length === 0) {
            this.checkinAllDone = false;
            return;
          }
          this.checkinAllDone = rewards.every((day) => {
            const checked = day.checked ?? day.isCheckin ?? day.isCheckIn ?? day.is_checkin ?? day.is_check_in;
            return !!checked;
          });
        } else {
          this.checkinAllDone = false;
        }
      }).catch(() => {
        this.checkinAllDone = false;
      });
    },
    cacheListState() {
      cache.session.setJSON(this.cacheKey, {
        userList: this.userList,
        page: this.page,
        pullUpState: this.pullUpState,
        filterGender: this.filterGender,
        filterCountry: this.filterCountry,
        scrollTop: this.$refs.listWrap ? this.$refs.listWrap.scrollTop : 0
      });
    },
    restoreListState() {
      const cached = cache.session.getJSON(this.cacheKey);
      if (!cached || !Array.isArray(cached.userList) || cached.userList.length === 0) {
        return false;
      }
      this.userList = cached.userList;
      this.page = cached.page || 0;
      this.pullUpState = cached.pullUpState || 0;
      this.filterGender = cached.filterGender ?? null;
      this.filterCountry = cached.filterCountry ?? null;
      this.distributeToColumns(this.userList, true);
      this.$nextTick(() => {
        if (this.$refs.listWrap) {
          this.$refs.listWrap.scrollTop = cached.scrollTop || 0;
        }
      });
      return true;
    },
    getGenderBadgeBg(user) {
      const gender = user.gender;
      const isGirl = gender === 1;
      return isGirl
          ? require('@/assets/image/sdk/ic-userdetail-girl.png')
          : require('@/assets/image/sdk/ic-userdetail-boy.png');
    },
    getCountryFlag(country) {
      if (!country) return '';
      const value = String(country).trim();
      if (!value || value === 'N/A') return '';
      const upper = value.toUpperCase();
      if (/^[A-Z]{2}$/.test(upper)) {
        const countryName = getCountryNameByCode(upper);
        if (countryName) {
          return getCountryFlagEmojiByName(countryName);
        }
        return getCountryFlagEmoji(upper);
      }
      return getCountryFlagEmojiByName(value);
    },
    getOnlineStatusImage(onlineStatus) {
      if (onlineStatus === 0) {
        return require('@/assets/image/sdk/ic-anchor-online.png');
      } else if (onlineStatus === 2) {
        return require('@/assets/image/sdk/ic-anchor-incall.png');
      }
      return '';
    },
    calculateAndLogHeightDiff() {},

    // ✅ 强制平衡左右列高度（彻底重写）
    // 目标：左右高度尽量均衡，高度差不超过左侧一个item的高度（341px）
    forceBalanceColumns() {
      const LEFT_CARD_HEIGHT = 251;
      const RIGHT_CARD_HEIGHT = 313;
      const MAX_HEIGHT_DIFF = LEFT_CARD_HEIGHT;

      // 合并所有item
      const allItems = [...this.leftColumn, ...this.rightColumn];
      if (allItems.length === 0) {
        return;
      }

      // 先检查当前高度差，如果已经在允许范围内，就不需要重新平衡
      const currentLeftHeight = this.leftColumn.length * LEFT_CARD_HEIGHT;
      const currentRightHeight = this.rightColumn.length * RIGHT_CARD_HEIGHT;
      const currentHeightDiff = Math.abs(currentRightHeight - currentLeftHeight);

      if (currentHeightDiff <= MAX_HEIGHT_DIFF) {
        return;
      }

      // 重新分配：使用贪心算法，始终选择放入后高度差更小的一侧
      let leftColumn = [];
      let rightColumn = [];
      let leftHeight = 0;
      let rightHeight = 0;

      allItems.forEach((item) => {
        // 计算放入左侧后的高度和高度差
        const leftHeightAfter = leftHeight + LEFT_CARD_HEIGHT;
        const diffIfLeft = Math.abs(rightHeight - leftHeightAfter);

        // 计算放入右侧后的高度和高度差
        const rightHeightAfter = rightHeight + RIGHT_CARD_HEIGHT;
        const diffIfRight = Math.abs(leftHeight - rightHeightAfter);

        // 优先检查：如果放入某一侧会导致高度差超过限制，必须放入另一侧
        if (diffIfLeft > MAX_HEIGHT_DIFF && diffIfRight <= MAX_HEIGHT_DIFF) {
          rightColumn.push(item);
          rightHeight = rightHeightAfter;
        } else if (diffIfRight > MAX_HEIGHT_DIFF && diffIfLeft <= MAX_HEIGHT_DIFF) {
          leftColumn.push(item);
          leftHeight = leftHeightAfter;
        } else {
          // 两侧都不会超过限制或都会超过限制，选择放入后高度差更小的一侧
          if (diffIfLeft < diffIfRight) {
            leftColumn.push(item);
            leftHeight = leftHeightAfter;
          } else {
            rightColumn.push(item);
            rightHeight = rightHeightAfter;
          }
        }
      });

      // 检查最终高度差，如果超过限制则强制调整
      let finalHeightDiff = Math.abs(rightHeight - leftHeight);
      let adjustCount = 0;
      const MAX_ADJUST_COUNT = 50; // 最大调整次数，防止无限循环（50次足够平衡大部分情况）
      
      // 强制调整直到满足条件
      while (finalHeightDiff > MAX_HEIGHT_DIFF && adjustCount < MAX_ADJUST_COUNT) {
        adjustCount++;
        
        if (rightHeight > leftHeight && rightColumn.length > 0) {
          // 右侧更高，从右侧移动item到左侧
          const item = rightColumn.pop();
          leftColumn.push(item);
          rightHeight -= RIGHT_CARD_HEIGHT;
          leftHeight += LEFT_CARD_HEIGHT;
        } else if (leftHeight > rightHeight && leftColumn.length > 0) {
          // 左侧更高，从左侧移动item到右侧
          const item = leftColumn.pop();
          rightColumn.push(item);
          leftHeight -= LEFT_CARD_HEIGHT;
          rightHeight += RIGHT_CARD_HEIGHT;
        } else {
          // 无法继续调整，退出循环
          break;
        }
        
        finalHeightDiff = Math.abs(rightHeight - leftHeight);
        
        // 安全退出：防止无限循环
        if (leftColumn.length === 0 || rightColumn.length === 0) {
          break;
        }
      }

      this.leftColumn = leftColumn;
      this.rightColumn = rightColumn;
    },

    distributeToColumns(newData, isRefresh) {
      if (isRefresh) {
        this.leftColumn = [];
        this.rightColumn = [];
      }

      const LEFT_CARD_HEIGHT = 251;
      const RIGHT_CARD_HEIGHT = 313;
      const MAX_HEIGHT_DIFF = LEFT_CARD_HEIGHT;

      const tempLeftColumn = [...this.leftColumn];
      const tempRightColumn = [...this.rightColumn];

      newData.forEach((item) => {
        const leftHeight = tempLeftColumn.length * LEFT_CARD_HEIGHT;
        const rightHeight = tempRightColumn.length * RIGHT_CARD_HEIGHT;

        // 计算放入左侧后的高度和高度差
        const leftHeightAfter = leftHeight + LEFT_CARD_HEIGHT;
        const diffIfLeft = Math.abs(rightHeight - leftHeightAfter);

        // 计算放入右侧后的高度和高度差
        const rightHeightAfter = rightHeight + RIGHT_CARD_HEIGHT;
        const diffIfRight = Math.abs(leftHeight - rightHeightAfter);

        // 严格检查：如果放入某一侧会导致高度差超过限制，必须放入另一侧
        if (diffIfLeft > MAX_HEIGHT_DIFF && diffIfRight <= MAX_HEIGHT_DIFF) {
          // 放入左侧会超过限制，放入右侧不会，放入右侧
          tempRightColumn.push(item);
        } else if (diffIfRight > MAX_HEIGHT_DIFF && diffIfLeft <= MAX_HEIGHT_DIFF) {
          // 放入右侧会超过限制，放入左侧不会，放入左侧
          tempLeftColumn.push(item);
        } else {
          // 两侧都不会超过限制或都会超过限制，选择放入后高度差更小的一侧（实现均衡）
          if (diffIfLeft < diffIfRight) {
            tempLeftColumn.push(item);
          } else {
            tempRightColumn.push(item);
          }
        }
      });

      // 分配完成后，强制检查并调整以确保高度差不超过限制
      let finalLeftHeight = tempLeftColumn.length * LEFT_CARD_HEIGHT;
      let finalRightHeight = tempRightColumn.length * RIGHT_CARD_HEIGHT;
      let finalHeightDiff = Math.abs(finalRightHeight - finalLeftHeight);
      let adjustCount = 0;
      const MAX_ADJUST_COUNT = 50; // 最大调整次数，防止无限循环（50次足够平衡大部分情况）
      
      // 如果高度差超过限制，进行强制调整
      while (finalHeightDiff > MAX_HEIGHT_DIFF && adjustCount < MAX_ADJUST_COUNT) {
        adjustCount++;
        
        if (finalRightHeight > finalLeftHeight && tempRightColumn.length > 0) {
          // 右侧更高，从右侧移动item到左侧
          const movedItem = tempRightColumn.pop();
          tempLeftColumn.push(movedItem);
          finalRightHeight -= RIGHT_CARD_HEIGHT;
          finalLeftHeight += LEFT_CARD_HEIGHT;
        } else if (finalLeftHeight > finalRightHeight && tempLeftColumn.length > 0) {
          // 左侧更高，从左侧移动item到右侧
          const movedItem = tempLeftColumn.pop();
          tempRightColumn.push(movedItem);
          finalLeftHeight -= LEFT_CARD_HEIGHT;
          finalRightHeight += RIGHT_CARD_HEIGHT;
        } else {
          // 无法继续调整，退出循环
          break;
        }
        
        finalHeightDiff = Math.abs(finalRightHeight - finalLeftHeight);
        
        // 安全退出：防止无限循环
        if (tempLeftColumn.length === 0 || tempRightColumn.length === 0) {
          break;
        }
      }

      this.leftColumn = tempLeftColumn;
      this.rightColumn = tempRightColumn;
    },

    async handleCall(user) {
      if (!user || !user.userId) {
        return;
      }
      await  store.dispatch('call/setAnchorInfo', user);
      callCreate(user.userId).then(() => {}).catch(() => {});
    },
    /** 将列表 user 转为来电页所需的 userInfo 格式 */
    userToPushCallAnchor(user) {
      if (!user || !user.userId) return null;
      return {
        userId: user.userId,
        avatar: user.avatar || user.image || '',
        nickname: user.nickname || user.name || 'Unknown',
        country: user.country,
        age: user.age,
        gender: user.gender,
        guildAnchorLevel:user.guildAnchorLevel
      };
    },
    async onJiaCallPushToIncomeing(userInfo) {
      await store.dispatch('call/setIncomingCall', true);
      await store.dispatch('call/setAnchorInfo', userInfo);
      await this.$router.push({ name: 'PageCallIncoming', query: { isJia: 'true' } });
    },
    /** 是否允许定时 callCreate：不在通话中，且不在聊天/会员/会员弹窗页 */
    shouldRunCallCreateTimer() {
      const localCallStatus = store.state.call?.localCallStatus;
      if (
        localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING ||
        localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING
      ) {
        return false;
      }
      const currentRoute = router.currentRoute;
      if (currentRoute && (currentRoute.name === 'PageChat' || currentRoute.path === '/sdk/page/chat')) {
        return false;
      }
      if (currentRoute && (currentRoute.name === 'PagePremium' || currentRoute.path === '/sdk/page/pagePremium')) {
        return false;
      }
      if (store.state.PageCache && store.state.PageCache.premiumDialogVisible) {
        return false;
      }
      if (store.state.PageCache && store.state.PageCache.rechargePromoDialogVisible) {
        return false;
      }
      if (store.state.PageCache && store.state.PageCache.rechargeDialogVisible) {
        return false;
      }
      if (store.state.PageCache && store.state.PageCache.checkinDialogVisible) {
        return false;
      }
      return true;
    },
    /** 从 loadAnchorList 数据中随机取一个未用过的 userId 执行 callCreate，排除 anchorVirtual === 1 的用户 */
    runCallCreateTimer() {
      if (!this.shouldRunCallCreateTimer()) return;
      const list = (this.userList || []).filter((u) => u && u.userId && Number(u.anchorVirtual) !== 1);
      if (list.length === 0) return;
      const usedSet = new Set(this.callCreateUsedUserIds);
      let candidates = list.filter((u) => !usedSet.has(String(u.userId)));
      if (candidates.length === 0) {
        this.callCreateUsedUserIds = [];
        candidates = list;
      }
      if (candidates.length === 0) return;
      const picked = candidates[Math.floor(Math.random() * candidates.length)];
      const userId = picked.userId;
      this.callCreateUsedUserIds.push(String(userId));
      const userInfo = this.userToPushCallAnchor(picked);
      if (userInfo) {
        console.error("来电信息:",userInfo);
        this.onJiaCallPushToIncomeing(userInfo);
      }
    },
    startCallCreateTimer() {
      this.stopCallCreateTimer();
      this.callCreateTimer = setInterval(() => {
        this.runCallCreateTimer();
      }, 120 * 1000);
    },
    stopCallCreateTimer() {
      if (this.callCreateTimer) {
        clearInterval(this.callCreateTimer);
        this.callCreateTimer = null;
      }
    },
    openRecharge() {
      showRechargeDialog();
    },
    openFirstRecharge() {
      showRechargePromoDialog();
    },
    handleVipClick() {
      this.openPremium();
    },
    showMoreMenu() {
      showUserListFilterDialog({
        onConfirm: (filterData) => {
          if (filterData.gender === 0) {
            this.filterGender = null;
          } else if (filterData.gender === 2) {
            this.filterGender = 1;
          } else if (filterData.gender === 1) {
            this.filterGender = 2;
          }

          if (filterData.country === 'all') {
            this.filterCountry = null;
          } else {
            this.filterCountry = filterData.country;
          }

          // 检查是否有筛选条件
          this.hasActiveFilters = this.filterGender !== null || this.filterCountry !== null;

          this.page = 0;
          // 立即清空列表并重置图片加载状态，避免旧图闪现
          this.loading = true;
          this.userList = [];
          this.leftColumn = [];
          this.rightColumn = [];
          this.pullUpState = 0;
          this.resetImageLoadState();
          this.loadAnchorList(true, true);
        },
        onCancel: () => {}
      });
    },
    goToUserDetail(user) {
      const userId = user?.userId || user?.uid;
      if (userId) {
        const userPayload = {
          userId: userId,
          name: user?.name || user?.nickname || '',
          nickname: user?.nickname || user?.name || '',
          age: user?.age,
          gender: user?.gender,
          likeCount: user?.likeCount,
          status: user?.status,
          onlineStatus: user?.onlineStatus,
          country: user?.country,
          signature: user?.signature,
          level: user?.level,
          isPremium: user?.isPremium,
          image: user?.image || user?.avatar,
          avatar: user?.avatar || user?.image,
          userPictures: user?.userPictures || [],
          videos: user?.videos || [],
          type: user?.videoUrl ? 'video' : (user?.type || 'image'),
          videoUrl: user?.videoUrl || null,
          coverUrl: user?.videoCover || user?.coverUrl || user?.image || null,
          duration: user?.duration,
          buyId: user?.buyId,
          videoPrice: user?.videoPrice,
          locked: user?.locked,
          followStatus: user?.followStatus
        };
        cache.session.setJSON(`user_detail_payload_${userId}`, userPayload);
        openAnchorUserDetail(userId);
      }
    },
    loadAnchorList(isRefresh = false, fromFilterConfirm = false) {
      if (isRefresh) {
        this.page = 1;
      } else {
        this.page++;
      }

      const params = {
        page: this.page,
        size: this.size,
        type: this.type
      };

      if (this.filterGender !== null) params.gender = this.filterGender;
      if (this.filterCountry !== null) params.country = this.filterCountry;

      if (isRefresh && fromFilterConfirm) {
        const cached = cache.local.getJSON(USER_LIST_FILTER_CACHE_KEY) || {};
        const country = cached.country;
        const aroundMyAge = !!cached.aroundMyAge;
        const selectedIsAll = country === 'all' || country == null || country === '';

        const loginUserInfo = this.$store.state.user.loginUserInfo || {};
        const isVip = loginUserInfo.vipCategory != null && loginUserInfo.vipCategory !== 0;
        const backpack = this.$store.state.user.userBackpack || [];
        const feedFilterFreeCount = backpack
          .filter((item) => item && Number(item.backpackType) === 2)
          .reduce((sum, item) => sum + Math.max(0, Number(item.quantity) || 0), 0);

        let coins = 0;
        let feedFilterConsume = 0;

        if (isVip) {
          coins = 0;
          feedFilterConsume = 0;
        } else if (feedFilterFreeCount > 0) {
          coins = 0;
          feedFilterConsume = 1;
        } else {
          if (aroundMyAge) coins += COINS_PER_FILTER;
          if (!selectedIsAll) coins += COINS_PER_FILTER;
          feedFilterConsume = 0;
        }

        if (!selectedIsAll && country != null && country !== '') {
          params.country = typeof country === 'object' ? (country.code ?? country.value) : country;
        } else if (selectedIsAll && params.country != null) {
          delete params.country;
        }
        if (coins !== 0 || feedFilterConsume !== 0) {
          if (feedFilterConsume > 0) {
            params.consumeType = 0;
            params.consumeQuantity = feedFilterConsume;
          } else {
            params.consumeType = 2;
            params.consumeQuantity = coins;
          }
        }
      }

      if (!isRefresh) {
        this.pullUpState = 2;
      }
      return getDetailList(params).then((detailRsp) => {
        let newData = [];
        const videoDataMap = {};
        let firstVideoData = null;

        if (detailRsp && (detailRsp.code === 200 || detailRsp.code === 0 || detailRsp.success) && detailRsp.data) {
          if (isRefresh && fromFilterConfirm) {
            store.dispatch('GetUserBackpack');
          }

          let detailList = Array.isArray(detailRsp.data) ? detailRsp.data : (detailRsp.data.list || []);
          newData = detailList;
          
          // 同时提取视频信息
          for (const item of detailList) {
            if (item.userId) {
              let videoUrl = null;
              let videoCover = null;
              if (item.videos && Array.isArray(item.videos) && item.videos.length > 0) {
                const firstVideo = item.videos[0];
                videoUrl = firstVideo.videoUrl || firstVideo.url || null;
                videoCover = firstVideo.cover || firstVideo.videoCover || item.videoCover || null;
              } else if (item.videoUrl) {
                videoUrl = item.videoUrl;
                videoCover = item.videoCover || null;
              }
              if (videoUrl) {
                videoDataMap[item.userId] = { videoUrl, videoCover };
                if (!firstVideoData) firstVideoData = { ...item, videoUrl, videoCover };
              }
            }
          }
        }

        const mappedData = newData.map(item => ({
          userId: item.userId,
          name: item.nickname || '',
          nickname: item.nickname || '',
          age: item.age || '',
          image: item.avatar || '',
          avatar: item.avatar || '',
          status: item.onlineStatus === 0 ? 'available' : 'in-call',
          onlineStatus: item.onlineStatus,
          country: item.country,
          gender: item.gender,
          signature: item.signature || '',
          callPrice: item.callPrice,
          followStatus: item.followStatus,
          blackStatus: item.blackStatus,
          follower: item.follower ?? item.likeCount ?? 0,
          userPictures: item.userPictures || [],
          videos: item.videos || [],
          videoUrl: videoDataMap[item.userId]?.videoUrl || null,
          videoCover: videoDataMap[item.userId]?.videoCover || null,
          anchorVirtual: item.anchorVirtual
        }));

        if (firstVideoData && isRefresh) {
          const existingIndex = mappedData.findIndex(item => item.userId === firstVideoData.userId);
          if (existingIndex === -1) {
            mappedData.unshift({
              userId: firstVideoData.userId,
              name: firstVideoData.nickname || '',
              age: firstVideoData.age || '',
              image: firstVideoData.avatar || firstVideoData.videoCover || '',
              avatar: firstVideoData.avatar || '',
              status: firstVideoData.onlineStatus === 0 ? 'available' : 'in-call',
              onlineStatus: firstVideoData.onlineStatus,
              country: firstVideoData.country,
              gender: firstVideoData.gender,
              signature: firstVideoData.signature || '',
              callPrice: firstVideoData.callPrice,
              followStatus: firstVideoData.followStatus,
              blackStatus: firstVideoData.blackStatus,
              follower: firstVideoData.follower ?? firstVideoData.likeCount ?? 0,
              videoUrl: firstVideoData.videoUrl || null,
              videoCover: firstVideoData.videoCover || firstVideoData.avatar || '',
              anchorVirtual: firstVideoData.anchorVirtual
            });
          } else {
            const existingItem = mappedData.splice(existingIndex, 1)[0];
            mappedData.unshift(existingItem);
          }
        }

        if (isRefresh) {
          this.userList = mappedData;
          this.distributeToColumns(mappedData, true);
        } else {
          this.userList = [...this.userList, ...mappedData];
          this.distributeToColumns(mappedData, false);
        }

        this.$nextTick(() => {
          setTimeout(() => this.checkAndPlayVideo(), 100);
        });

        this.calculateAndLogHeightDiff();

        const hasNoMoreData = newData.length === 0 || newData.length < this.size;

        if (hasNoMoreData) {
          this.pullUpState = 3;
          this.$nextTick(() => {
            requestAnimationFrame(() => {
              setTimeout(() => {
                this.forceBalanceColumns();
                this.calculateAndLogHeightDiff();
              }, 200);
            });
          });
          
          // 如果是筛选操作且没有数据，显示重置筛选弹窗
          if (isRefresh && this.hasActiveFilters && mappedData.length === 0) {
            this.$nextTick(() => {
              showResetFilterDialog({
                onReset: () => {
                  // 重置所有筛选条件
                  this.filterGender = null;
                  this.filterCountry = null;
                  this.hasActiveFilters = false;
                  // 清空缓存的筛选条件
                  this.cacheListState();
                  // 清空筛选对话框的缓存，确保国家默认选择 'all'
                  // 设置缓存中的 country 为 'all'，gender 为 0（All）
                  cache.local.setJSON('user_list_filter_settings', {
                    gender: 0,
                    country: 'all',
                    aroundMyAge: false
                  });
                  // 重新加载数据
                  this.loadAnchorList(true);
                },
                onCancel: () => {
                  // 取消操作，不做任何事
                }
              });
            });
          }
        } else {
          this.pullUpState = 1;
        }

      }).catch((error) => {
        if (!isRefresh) {
          this.page--;
        }
        if (this.pullUpState === 2) {
          this.pullUpState = 1;
        }
        throw error;
      }).finally(() => {
        this.isLoadingMore = false;
        this.loading = false;
        if (this.pullUpState === 2) {
          this.pullUpState = 1;
        }
      });
    },
    onRefresh(refreshDone) {
      this.loadAnchorList(true).then(() => {
        if (refreshDone) refreshDone(true);
      }).catch(() => {
        if (refreshDone) refreshDone(false);
      });
    },
    onInfiniteLoad() {
      if (this.isLoadingMore || this.pullUpState === 2 || this.pullUpState === 3) {
        return;
      }
      this.isLoadingMore = true;
      this.loadAnchorList(false);
    },
    handleScroll(event) {
      const scrollContainer = event.target;
      if (!scrollContainer) return;

      const scrollTop = scrollContainer.scrollTop;
      const scrollHeight = scrollContainer.scrollHeight;
      const clientHeight = scrollContainer.clientHeight;
      const threshold = 50;
      const isNearBottom = scrollTop + clientHeight >= scrollHeight - threshold;

      if (isNearBottom && this.pullUpState === 1 && !this.isLoadingMore) {
        this.onInfiniteLoad();
      }

      if (this.scrollTimer) clearTimeout(this.scrollTimer);
      this.scrollTimer = setTimeout(() => this.checkAndPlayVideo(), 150);
    },
    checkAndPlayVideo() {
      const scrollContainer = this.$refs.listWrap;
      if (!scrollContainer) return;

      const containerHeight = scrollContainer.clientHeight;
      const containerRect = scrollContainer.getBoundingClientRect();
      const centerY = containerRect.top + containerHeight / 2;

      const videoCards = [];
      this.userList.forEach(user => {
        if (user.videoUrl) {
          const cardElement = this.$el.querySelector(`[data-user-id="${user.userId}"]`);
          if (cardElement) {
            const videoElement = cardElement.querySelector('video');
            if (videoElement) {
              const rect = cardElement.getBoundingClientRect();
              const isVisible = rect.top < containerRect.bottom && rect.bottom > containerRect.top;
              if (isVisible) {
                const cardCenterY = rect.top + rect.height / 2;
                const distanceFromCenter = Math.abs(cardCenterY - centerY);
                videoCards.push({ user, element: cardElement, videoElement, distance: distanceFromCenter });
              }
            }
          }
        }
      });

      if (videoCards.length === 0) {
        if (this.playingVideoId) this.stopVideo(this.playingVideoId);
        return;
      }

      videoCards.sort((a, b) => a.distance - b.distance);
      const nearestVideo = videoCards[0];

      if (this.playingVideoId !== nearestVideo.user.userId) {
        videoCards.forEach(item => {
          if (item.videoElement && !item.videoElement.paused) {
            item.videoElement.pause();
            item.videoElement.currentTime = 0;
          }
        });
        this.playVideo(nearestVideo.user.userId, nearestVideo.videoElement);
      }
    },
    playVideo(userId, videoElement = null) {
      if (!videoElement) {
        const cardElement = this.$el.querySelector(`[data-user-id="${userId}"]`);
        if (cardElement) videoElement = cardElement.querySelector('video');
      }
      if (videoElement) {
        if (videoElement.paused) {
          videoElement.play().catch(() => {});
        }
        this.playingVideoId = userId;
        this.videoElements[userId] = videoElement;
      }
    },
    stopVideo(userId) {
      let videoElement = this.videoElements[userId];
      if (!videoElement) {
        const cardElement = this.$el.querySelector(`[data-user-id="${userId}"]`);
        if (cardElement) videoElement = cardElement.querySelector('video');
      }
      if (videoElement && !videoElement.paused) {
        videoElement.pause();
        videoElement.currentTime = 0;
      }
      if (this.playingVideoId === userId) this.playingVideoId = null;
    },
    handleVideoLoaded(userId) {
      const cardElement = this.$el.querySelector(`[data-user-id="${userId}"]`);
      if (cardElement) {
        const videoElement = cardElement.querySelector('video');
        if (videoElement) this.videoElements[userId] = videoElement;
      }
    },
    getImageKey(user, index, side) {
      const id = user && user.userId ? user.userId : index;
      return `${this.listVersion}-${side}-${id}`;
    },
    isImageLoaded(key) {
      return !!this.imageLoadedMap[key];
    },
    markImageLoaded(key) {
      if (!this.imageLoadedMap[key]) {
        this.$set(this.imageLoadedMap, key, true);
      }
    },
    resetImageLoadState() {
      this.listVersion += 1;
      this.imageLoadedMap = {};
    },
    updateListTop() {
      const apply = () => {
        const topBar = this.$el && this.$el.querySelector('.top-bar');
        const listContainer = this.$refs.listContainer;
        if (topBar && listContainer) {
          const topBarHeight = topBar.offsetHeight;
          listContainer.style.top = `${topBarHeight}px`;
        }
      };
      this.$nextTick(() => {
        apply();
        // 首次加载时 safe-area / 布局可能尚未就绪，再在下一帧和短延迟后各算一次，避免列表顶被遮挡
        requestAnimationFrame(() => {
          apply();
          setTimeout(apply, 80);
        });
      });
    },
    checkAndShowCheckinDialog() {
      // 检查用户是否是会员（vipCategory !== 0）
      const loginUserInfo = this.$store.state.user.loginUserInfo || {};
      const isVip = loginUserInfo.vipCategory !== undefined && 
                    loginUserInfo.vipCategory !== null && 
                    loginUserInfo.vipCategory !== 0;
      
      if (isVip) {
        // 延迟显示，确保页面已加载完成
        setTimeout(() => {
          showCheckinDialog();
        }, 500);
      }
    },
    // 调试方法：显示周会员签到界面
    showCheckinWeek() {
      showCheckinDialog({ testVipCategory: 1 });
    },
    // 调试方法：显示月会员签到界面
    showCheckinMonth() {
      showCheckinDialog({ testVipCategory: 2 });
    },
    // 调试方法：显示年度会员签到界面
    showCheckinYear() {
      showCheckinDialog({ testVipCategory: 3 });
    },
    // 调试方法：显示半年会员签到界面
    showCheckinHalfYear() {
      showCheckinDialog({ testVipCategory: 4 });
    },
    // 兼容旧/误写的命名：showCheckInHalfYear
    showCheckInHalfYear() {
      this.showCheckinHalfYear();
    },
    formatNumber(value) {
      if (value === null || value === undefined) {
        return '';
      }
      const number = Number(value);
      if (Number.isNaN(number)) {
        return value;
      }
      return number.toLocaleString();
    },
    formatLikes(value) {
      const num = Number(value) || 0;
      if (num >= 1000000) {
        return `${(num / 1000000).toFixed(1).replace(/\.0$/, '')}M`;
      }
      if (num >= 1000) {
        return `${(num / 1000).toFixed(1).replace(/\.0$/, '')}k`;
      }
      return String(num);
    },
    tickCountdown() {
      if (this.userCreateTime == null) return;
      const end = this.userCreateTime + 3 * 24 * 3600;
      const now = Math.floor(Date.now() / 1000);
      this.countdown = Math.max(0, end - now);
    },
    startCountdown() {
      this.countdownTimer = setInterval(() => {
        this.tickCountdown();
        if (this.countdown <= 0 && this.countdownTimer) {
          clearInterval(this.countdownTimer);
          this.countdownTimer = null;
        }
      }, 1000);
    },
  },
  mounted() {
    this.updateListTop();
    this.startCallCreateTimer();
    this.tickCountdown();
    this.startCountdown();
    this.fetchCheckinStatus();
    this.$nextTick(() => {
      if (this.restoreListState()) return;
      if (this.$refs.downRefresh) {
        this.$refs.downRefresh.refresh();
      } else {
        this.loadAnchorList(true);
      }
      
      // 检查是否是会员，如果是则显示签到对话框
      // this.checkAndShowCheckinDialog();
      
      // 调试：默认显示周会员签到界面（可以修改 testVipCategory 为 1/2/3 来测试不同界面）
      setTimeout(() => {
        // showCheckinDialog({ testVipCategory: 3 }); // 1=周, 2=月, 3=年
      }, 1000);
    });
  },
  updated() {
    this.$nextTick(() => {
      setTimeout(() => {
        this.checkAndPlayVideo();
        // 可选：再次确保平衡（增强鲁棒性）
        // 使用防抖，避免频繁调用导致性能问题
        if (this.pullUpState === 3) {
          if (this.balanceTimer) {
            clearTimeout(this.balanceTimer);
          }
          this.balanceTimer = setTimeout(() => {
            this.forceBalanceColumns();
            this.balanceTimer = null;
          }, 500);
        }
      }, 100);
    });
  },
  beforeDestroy() {
    this.cacheListState();
    this.stopCallCreateTimer();
    if (this.scrollTimer) clearTimeout(this.scrollTimer);
    if (this.balanceTimer) clearTimeout(this.balanceTimer);
    if (this.playingVideoId) this.stopVideo(this.playingVideoId);
    if (this.countdownTimer) clearInterval(this.countdownTimer);
  },
  activated() {
    this.updateListTop();
  },
  beforeRouteLeave(to, from, next) {
    this.cacheListState();
    next();
  }
};
</script>

<style scoped lang="less">
.main {
  background-color: #141414;
  min-height: 100vh;
  padding: 0 0 20px;
  box-sizing: border-box;
  position: relative;
  height: 100vh;
  overflow: hidden;
}

.first-recharge-entry {
  position: fixed;
  right: 10px;
  bottom: calc(180px + constant(safe-area-inset-bottom));
  bottom: calc(180px + env(safe-area-inset-bottom));
  width: 72px;
  z-index: 99;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  -webkit-tap-highlight-color: transparent;
  tap-highlight-color: transparent;
}

.first-recharge-icon {
  width: 64px;
  height: 64px;
  display: block;
  object-fit: contain;
}

.first-recharge-timer {
  margin-top: -7px;
  min-width: 55px;
  height: 20px;
  padding-top: 2px;
  padding-left: 3px;
  padding-right: 3px;
  border-radius: 10px;
  background: #000000;
  color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.first-recharge-entryextra-wrap {
  position: absolute;
  left: -5px;
  top: 8px;
  transform: rotate(-15deg);
  transform-origin: left top;
  display: inline-block;
}

.first-recharge-extra-icon {
  display: block;
  width: auto;
  height: 20px;
  object-fit: contain;
}

.first-recharge-extra-intros {
  position: absolute;
  left: 0;
  top: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  pointer-events: none;
}

.checkin-entry {
  position: fixed;
  right: 14px;
  bottom: calc(90px + constant(safe-area-inset-bottom));
  bottom: calc(90px + env(safe-area-inset-bottom));
  width: 64px;
  z-index: 99;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.checkin-icon-wrapper {
  position: relative;
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.checkin-icon {
  width: 64px;
  height: 64px;
  display: block;
  object-fit: contain;
  z-index: 1;
}

.checkin-left-coin {
  position: absolute;
  bottom: 7px;
  left: 5px;
  width: 20px;
  height: 20px;
  z-index: 2;
}

.checkin-right-coin {
  position: absolute;
  bottom: 4px;
  right: 10px;
  width: 20px;
  height: 20px;
  z-index: 2;
}

.checkin-bottom-oval {
  position: absolute;
  bottom: 4px;
  left: 50%;
  transform: translateX(-50%);
  width: 60px;
  height: 15px;
  z-index: 0;
}

.top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  padding-top: constant(safe-area-inset-top);
  padding-top: env(safe-area-inset-top);
  padding-bottom: 15px;
  background-color: #141414;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  box-sizing: border-box;

  .user-avatar {
    width: 45px;
    height: 45px;
    border-radius: 50%;
    overflow: hidden;
    object-fit: cover;
    display: block;
  }

  .top-right {
    display: flex;
    align-items: center;
    gap: 15px;

    .premium-btn {
      background: rgba(255, 255, 255, 0.10);
      color: black;
      border-radius: 20px;
      padding: 4px 12px;
      display: flex;
      align-items: center;
      font-weight: bold;
      font-size: 14px;
      border: 1px solid rgba(255, 255, 255, 0.05);
      transition: all 0.3s;
      cursor: pointer;

      .crown-icon {
        width: 22px;
        height: 22px;
        margin-right: 4px;
      }

      span {
        color: white;
      }

      &.is-vip {
        span {
          color: #FEE98A;
        }
      }
    }

    .coin-pill {
      background: rgba(255, 255, 255, 0.10);
      border-radius: 20px;
      padding: 4px 12px;
      display: flex;
      align-items: center;
      font-size: 14px;
      font-weight: bold;
      cursor: pointer;

      .coin-icon {
        width: 22px;
        height: 22px;
        margin-right: 4px;
      }

      span {
        color: white;
      }
    }

    .more-btn {
      cursor: pointer;
      width: 30px;
      height: 30px;
    }
  }
}

.list-container {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  box-sizing: border-box;
  overflow: hidden;

  .list-wrap {
    height: 100%;
    overflow-y: auto;
    overflow-x: hidden;
    -webkit-overflow-scrolling: touch;
  }

  /deep/ .refresh-mobile {
    background: transparent;
    min-height: 100%;
  }

  /deep/ .load-mobile {
    background: transparent;
  }
}

.waterfall-container {
  display: flex;
  gap: 10px;
  padding: 10px 10px 20px;
  box-sizing: border-box;
}

.waterfall-column {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.user-card {
  position: relative;
  border-radius: 20px;
  overflow: hidden;
  cursor: pointer;
  background-color: #141414;

  .online-status {
    position: absolute;
    top: 10px;
    left: 10px;
    z-index: 2;
    .status-icon {
      max-width: 80px;
      max-height: 30px;
      width: auto;
      height: auto;
      object-fit: contain;
    }
  }

.online-status--likes {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 16px;
  background: rgba(0, 0, 0, 0.7);
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
}

.online-status--likes .status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #3CFF72;
}

.online-status--likes .status-text {
  color: #3CFF72;
  font-weight: 700;
}

.online-status--likes .status-likes {
  color: #3CFF72;
  font-weight: 600;
  white-space: nowrap;
  font-size: 10px;
}

  .online-status--likes .status-divider {
    width: 1px;
    height: 12px;
  }

  .card-image {
    width: 100%;
    display: block;
    object-fit: cover;
    &.left-image { height: 251px; }
    &.right-image { height: 313px; }
  }

  .video-container {
    width: 100%;
    position: relative;
    overflow: hidden;
    background-color: #000;
    display: block;
    &.left-image { height: 251px; }
    &.right-image { height: 313px; }
    .card-video {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }

  .card-bottom {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 97px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    padding-top: 10px;
    padding-bottom: 10px;
    padding-left: 10px;
    padding-right: 10px;
    background-position: center bottom;
    border-radius: 0 0 15px 15px;
    z-index: 1;

    &::before {
      content: '';
      position: absolute;
      inset: 0;
      background-image: url('~@/assets/image/sdk/ic-listindex-card-bottom-bg.png');
      background-size: 100% 100%;
      background-repeat: no-repeat;
      background-position: center bottom;
      border-radius: 0 0 15px 15px;
      z-index: 0;
    }

    .user-info {
      position: relative;
      z-index: 1;
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      gap: 4px;
      .user-name {
        color: white;
        font-size: 16px;
        font-weight: 700;
        margin: 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
      }
      .user-meta {
        display: flex;
        align-items: center;
        gap: 6px;
        .flag-icon {
          display: inline-flex;
          width: 22px;
          height: 18px;
          font-size: 22px;
          line-height: 1;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }
        .age-badge {
          padding: 0;
          background-size: 100% 100%;
          background-repeat: no-repeat;
          background-position: center center;
          height: 20px;
          min-width: 42px;
          display: inline-flex;
          align-items: center;
          position: relative;
          overflow: hidden;
          flex-shrink: 0;
          .badge-text {
            color: white;
            font-size: 13px;
            font-weight: 600;
            white-space: nowrap;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
            position: relative;
            z-index: 1;
            padding-left: 20px;
            padding-right: 6px;
            padding-top: 2px;
            box-sizing: border-box;
          }
        }
      }
    }

    .call-btn {
      position: relative;
      z-index: 1;
      width: 44px;
      height: 44px;
      border-radius: 50%;
      flex-shrink: 0;
      background: transparent;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      //box-shadow: 0 2px 8px rgba(255, 87, 219, 0.4);
      img {
        width: 44px;
        height: 44px;
        object-fit: contain;
      }
    }
  }
}

/deep/ .load-more {
  height: 100px !important;
  padding-top: 10px !important;
  padding-bottom: 10px !important;
}
</style>