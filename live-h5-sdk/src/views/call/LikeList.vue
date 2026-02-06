<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="''">
        <template #center>
          <div class="tabs">
            <span :class="['tab', activeIndex === 0 ? 'active' : '']" @click="onTabClick(0)">LikeU</span>
            <span :class="['tab', activeIndex === 1 ? 'active' : '']" @click="onTabClick(1)">My Likes</span>
          </div>
        </template>
      </m-action-bar>
    </template>
    <template #page-content-wrap>
      <div class="page">
        <swiper ref="swiper" class="swiper" :options="swiperOption" @slideChange="onSlideChange">
          <swiper-slide style="background: #141414">
            <m-list-drop-down-refresh :on-refresh="onRefreshLikeMe">
              <m-list-pull-up-reload :on-infinite-load="onInfiniteLoadLikeMe" :parent-pull-up-state="pullUpStateLikeMe" :open-load-more="true">
                <div class="waterfall-container">
                  <div class="waterfall-column">
                    <div
                      v-for="user in likeMeColumns.left"
                      :key="user.userId"
                      class="user-card my-likes-card"
                      :class="{ 'blur-card': !isVip }"
                      @click="!isVip ? null : openAnchorUserDetail(user.userId)"
                    >
                      <div v-if="!isVip" class="blur-overlay" @click.stop="openPremium"></div>
                      <div
                        v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                        class="online-status"
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
                      <div v-if="user.videoUrl" class="video-container left-image">
                        <video
                          class="card-video"
                          :src="user.videoUrl"
                          :poster="user.videoCover || user.image"
                          muted
                          loop
                          playsinline
                          webkit-playsinline
                        ></video>
                      </div>
                      <img v-else class="card-image left-image" :src="user.image"/>
                      <div class="card-bottom my-likes-bottom">
                        <div class="user-info">
                          <div v-if="isVip" class="user-name">{{ user.name }}</div>
                          <div class="user-meta">
                            <span class="flag-icon" v-if="user.country">{{ getCountryFlag(user.country) }}</span>
                            <div class="age-badge" :style="{ backgroundImage: `url(${getGenderBadgeBg(user)})` }">
                              <span class="badge-text">{{ user.age }}</span>
                            </div>
                          </div>
                        </div>
                        <div v-if="isVip" class="call-btn" @click.stop="handleCall(user)">
                          <img
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : require('@/assets/image/sdk/ic-userlist-videochat.png')"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="waterfall-column">
                    <div
                      v-for="user in likeMeColumns.right"
                      :key="user.userId"
                      class="user-card my-likes-card"
                      :class="{ 'blur-card': !isVip }"
                      @click="!isVip ? null : openAnchorUserDetail(user.userId)"
                    >
                      <div v-if="!isVip" class="blur-overlay" @click.stop="openPremium"></div>
                      <div
                        v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                        class="online-status"
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
                      <div v-if="user.videoUrl" class="video-container right-image">
                        <video
                          class="card-video"
                          :src="user.videoUrl"
                          :poster="user.videoCover || user.image"
                          muted
                          loop
                          playsinline
                          webkit-playsinline
                        ></video>
                      </div>
                      <img v-else class="card-image right-image" :src="user.image"/>
                      <div class="card-bottom my-likes-bottom">
                        <div class="user-info">
                          <div v-if="isVip" class="user-name">{{ user.name }}</div>
                          <div class="user-meta">
                            <span class="flag-icon" v-if="user.country">{{ getCountryFlag(user.country) }}</span>
                            <div class="age-badge" :style="{ backgroundImage: `url(${getGenderBadgeBg(user)})` }">
                              <span class="badge-text">{{ user.age }}</span>
                            </div>
                          </div>
                        </div>
                        <div v-if="isVip" class="call-btn" @click.stop="handleCall(user)">
                          <img
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : require('@/assets/image/sdk/ic-userlist-videochat.png')"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <m-network-error 
                  v-if="networkErrorLikeMe && !likeMeList.length" 
                  @retry="handleRetryLikeMe"
                />
              </m-list-pull-up-reload>
            </m-list-drop-down-refresh>
          </swiper-slide>
          <swiper-slide>
            <m-list-drop-down-refresh :on-refresh="onRefreshMyLikes">
              <m-list-pull-up-reload :on-infinite-load="onInfiniteLoadMyLikes" :parent-pull-up-state="pullUpStateMyLikes" :open-load-more="true">
                <div class="waterfall-container">
                  <div class="waterfall-column">
                    <div
                      v-for="user in myLikesColumns.left"
                      :key="user.userId"
                      class="user-card my-likes-card"
                      @click="openAnchorUserDetail(user.userId)"
                    >
                      <div
                        v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                        class="online-status"
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
                      <div v-if="user.videoUrl" class="video-container left-image">
                        <video
                          class="card-video"
                          :src="user.videoUrl"
                          :poster="user.videoCover || user.image"
                          muted
                          loop
                          playsinline
                          webkit-playsinline
                        ></video>
                      </div>
                      <img v-else class="card-image left-image" :src="user.image"/>
                      <div class="card-bottom my-likes-bottom">
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
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : require('@/assets/image/sdk/ic-userlist-videochat.png')"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="waterfall-column">
                    <div
                      v-for="user in myLikesColumns.right"
                      :key="user.userId"
                      class="user-card my-likes-card"
                      @click="openAnchorUserDetail(user.userId)"
                    >
                      <div
                        v-if="user.onlineStatus === 0 || user.onlineStatus === 2"
                        class="online-status"
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
                      <div v-if="user.videoUrl" class="video-container right-image">
                        <video
                          class="card-video"
                          :src="user.videoUrl"
                          :poster="user.videoCover || user.image"
                          muted
                          loop
                          playsinline
                          webkit-playsinline
                        ></video>
                      </div>
                      <img v-else class="card-image right-image" :src="user.image"/>
                      <div class="card-bottom my-likes-bottom">
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
                            :src="user.onlineStatus === 2 ? require('@/assets/image/sdk/ic-listindex-chat.png') : require('@/assets/image/sdk/ic-userlist-videochat.png')"
                            alt="Call"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <m-network-error 
                  v-if="networkErrorMyLikes && !myLikesList.length" 
                  @retry="handleRetryMyLikes"
                />
              </m-list-pull-up-reload>
            </m-list-drop-down-refresh>
          </swiper-slide>
        </swiper>
        <!-- 统一的空状态组件，固定在屏幕中央 -->
        <m-empty-state 
          v-if="shouldShowEmptyState"
          class="global-empty-state"
          message="Nothing Here Yet."
        />
        <!-- VIP升级按钮 - 非VIP用户且LikeU列表有数据时显示 -->
        <button v-if="!isVip && activeIndex === 0 && likeMeList.length > 0" class="upgrade-button" @click="openPremium">
          <span class="upgrade-title">UPGRADE</span>
          <span class="upgrade-subtitle">to View Who Likes You</span>
        </button>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import 'swiper/dist/css/swiper.css'
import {swiper, swiperSlide} from 'vue-awesome-swiper'
import MActionBar from "@/components/MActionBar.vue";
import MPageWrap from "@/components/MPageWrap.vue";
import MListDropDownRefresh from "@/components/MListDropDownRefresh.vue";
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import MNetworkError from "@/components/MNetworkError.vue";
import {openAnchorUserDetail, openChat, openUserInfo} from "@/utils/PageUtils";
import {getFollowList} from "@/api/sdk/user";
import {openPremium} from "@/utils/PageUtils";
import {getCountryFlagEmojiByCode} from "@/utils/Utils";
import {callCreate} from "@/utils/CallUtils";
import store from "@/store";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";

export default {
  name: 'PageLikeList',
  components: {MPageWrap, MActionBar, swiper, swiperSlide, MListDropDownRefresh, MListPullUpReload, MEmptyState, MNetworkError},
  beforeRouteLeave(to, from, next) {
    // 如果跳转到用户详情页，保存当前状态
    if (to.name === 'PageUserDetail') {
      sessionStorage.setItem('likeListActiveIndex', String(this.activeIndex));
      sessionStorage.setItem('likeListFromDetail', 'true');
    } else {
      // 跳转到其他页面，清除状态
      sessionStorage.removeItem('likeListActiveIndex');
      sessionStorage.removeItem('likeListFromDetail');
    }
    next();
  },
  data() {
    return {
      activeIndex: 0,
      savedActiveIndex: 0, // 保存的 activeIndex
      swiperOption: {
        autoplay: false,
        loop: false,
        spaceBetween: 0,
        autoHeight: true
      },
      likeMeList: [],
      myLikesList: [],
      pageMyLikes: 1,
      sizeMyLikes: 20,
      pullUpStateMyLikes: 0,
      pageLikeMe: 1,
      sizeLikeMe: 20,
      pullUpStateLikeMe: 0,
      loadingLikeMe: false,
      loadingMyLikes: false,
      networkErrorLikeMe: false,
      networkErrorMyLikes: false
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    isVip() {
      return this.userInfo.vipCategory !== 0;
    },
    shouldShowEmptyState() {
      // 根据当前活动标签页判断是否显示空状态
      if (this.activeIndex === 0) {
        return !this.likeMeList.length && !this.loadingLikeMe && !this.networkErrorLikeMe;
      } else if (this.activeIndex === 1) {
        return !this.myLikesList.length && !this.loadingMyLikes && !this.networkErrorMyLikes;
      }
      return false;
    },
    likeMeColumns() {
      return this.distributeListToColumns(this.likeMeList);
    },
    myLikesColumns() {
      return this.distributeListToColumns(this.myLikesList);
    }
  },
  methods: {
    openAnchorUserDetail,
    openChat,
    openUserInfo,
    openPremium,
    genderIcon(gender) {
      return gender === 1 ? require('@/assets/image/sdk/ic-male.png') : require('@/assets/image/sdk/ic-woman.png')
    },
    flagEmoji(code) {
      const cc = String(code || '').trim().toUpperCase();
      if (!/^[A-Z]{2}$/.test(cc)) {
        return '🌐'
      }
      const a = cc.charCodeAt(0) - 65 + 0x1F1E6;
      const b = cc.charCodeAt(1) - 65 + 0x1F1E6;
      try {
        return String.fromCodePoint(a, b);
      } catch (e) {
        return cc
      }
    },
    /**
     * 获取国家旗帜图片 URL
     */
    getCountryFlag(country) {
      if (!country) return '🌐';
      return getCountryFlagEmojiByCode(country);
    },
    /**
     * 获取性别徽章背景
     */
    getGenderBadgeBg(user = null) {
      const gender = user && user.gender != null ? Number(user.gender) : null;
      if (gender === 1) {
        return require('@/assets/image/sdk/ic-userdetail-girl.png');
      }
      if (gender === 2) {
        return require('@/assets/image/sdk/ic-userdetail-boy.png');
      }
      return require('@/assets/image/sdk/ic-userdetail-girl.png');
    },
    getOnlineStatusImage(onlineStatus) {
      if (onlineStatus === 0) {
        return require('@/assets/image/sdk/ic-anchor-online.png');
      }
      if (onlineStatus === 2) {
        return require('@/assets/image/sdk/ic-anchor-incall.png');
      }
      return '';
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
    /**
     * 按高度平衡将列表分配到左右两列（左 251px/卡，右 313px/卡），避免最后两条都在同一列
     */
    distributeListToColumns(list) {
      if (!Array.isArray(list) || list.length === 0) {
        return { left: [], right: [] };
      }
      const LEFT_CARD_HEIGHT = 251;
      const RIGHT_CARD_HEIGHT = 313;
      const MAX_HEIGHT_DIFF = LEFT_CARD_HEIGHT;
      const left = [];
      const right = [];
      list.forEach((item) => {
        const leftHeight = left.length * LEFT_CARD_HEIGHT;
        const rightHeight = right.length * RIGHT_CARD_HEIGHT;
        const leftHeightAfter = leftHeight + LEFT_CARD_HEIGHT;
        const diffIfLeft = Math.abs(rightHeight - leftHeightAfter);
        const rightHeightAfter = rightHeight + RIGHT_CARD_HEIGHT;
        const diffIfRight = Math.abs(leftHeight - rightHeightAfter);
        if (diffIfLeft > MAX_HEIGHT_DIFF && diffIfRight <= MAX_HEIGHT_DIFF) {
          right.push(item);
        } else if (diffIfRight > MAX_HEIGHT_DIFF && diffIfLeft <= MAX_HEIGHT_DIFF) {
          left.push(item);
        } else if (diffIfLeft <= diffIfRight) {
          left.push(item);
        } else {
          right.push(item);
        }
      });
      // 强制平衡：若高度差仍超限，从较高列移一项到较低列
      let finalLeftHeight = left.length * LEFT_CARD_HEIGHT;
      let finalRightHeight = right.length * RIGHT_CARD_HEIGHT;
      let diff = Math.abs(finalRightHeight - finalLeftHeight);
      let adjustCount = 0;
      const maxAdjust = 50;
      while (diff > MAX_HEIGHT_DIFF && adjustCount < maxAdjust) {
        adjustCount++;
        if (finalRightHeight > finalLeftHeight && right.length > 0) {
          left.push(right.pop());
          finalRightHeight -= RIGHT_CARD_HEIGHT;
          finalLeftHeight += LEFT_CARD_HEIGHT;
        } else if (finalLeftHeight > finalRightHeight && left.length > 0) {
          right.push(left.pop());
          finalLeftHeight -= LEFT_CARD_HEIGHT;
          finalRightHeight += RIGHT_CARD_HEIGHT;
        } else {
          break;
        }
        diff = Math.abs(finalRightHeight - finalLeftHeight);
      }
      return { left, right };
    },
    onTabClick(index) {
      this.activeIndex = index;
      this.savedActiveIndex = index; // 保存当前索引
      // 保存到 sessionStorage
      sessionStorage.setItem('likeListActiveIndex', String(index));
      const sw = this.$refs.swiper && this.$refs.swiper.swiper;
      if (sw) {
        sw.slideTo(index, 200, false);
      }
      if (index === 0 && this.likeMeList.length === 0) {
        this.loadBothLists(true, 'likeMe');
      } else if (index === 1 && this.myLikesList.length === 0) {
        this.loadBothLists(true, 'myLikes');
      }
    },
    onSlideChange() {
      const sw = this.$refs.swiper && this.$refs.swiper.swiper;
      if (sw) {
        this.activeIndex = sw.activeIndex;
        this.savedActiveIndex = sw.activeIndex; // 保存当前索引
        // 保存到 sessionStorage
        sessionStorage.setItem('likeListActiveIndex', String(sw.activeIndex));
        if (sw.activeIndex === 0 && this.likeMeList.length === 0) {
          this.loadBothLists(true, 'likeMe');
        } else if (sw.activeIndex === 1 && this.myLikesList.length === 0) {
          this.loadBothLists(true, 'myLikes');
        }
      }
    },
    mapDataToFormat(newData) {
      return newData.map(item => ({
        userId: item.userId,
        name: item.nickname || '',
        age: item.age || '',
        image: item.avatar || item.image || '',
        onlineStatus: item.onlineStatus,
        country: item.country || '',
        gender: item.gender || 2,
        follower: item.follower ?? item.likeCount ?? 0,
        videoUrl: item.videoUrl || null,
        videoCover: item.videoCover || null
      }));
    },
    async handleCall(user) {
      if (!user || !user.userId) {
        return;
      }
      await  store.dispatch('call/setAnchorInfo', user);
      callCreate(user.userId).then(() => {}).catch(() => {});
    },
    parseResponseData(rsp) {
      let newData = [];
      if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success) && rsp.data) {
        if (Array.isArray(rsp.data)) {
          newData = rsp.data;
        } else if (rsp.data.list && Array.isArray(rsp.data.list)) {
          newData = rsp.data.list;
        } else {
          console.warn('API 返回的数据格式不符合预期:', rsp.data);
          newData = [];
        }
      } else {
        console.warn('API 返回的 code 不是 200/0 或 success 不是 true:', rsp);
        newData = [];
      }
      return newData;
    },
    loadBothLists(isRefresh = false, loadType) {
      let requestConfig;

      if (loadType === 'likeMe') {
        if (isRefresh) {
          this.pageLikeMe = 1;
          this.loadingLikeMe = true;
          this.networkErrorLikeMe = false;
          this.likeMeList = []; // 刷新时立即清空旧数据
        } else {
          this.pageLikeMe++;
          this.pullUpStateLikeMe = 2;
        }
        requestConfig = {
          type: 'FOLLOW_ME',
          page: this.pageLikeMe,
          size: this.sizeLikeMe,
          listKey: 'likeMeList',
          pageKey: 'pageLikeMe',
          stateKey: 'pullUpStateLikeMe',
          loadingKey: 'loadingLikeMe',
          sizeKey: 'sizeLikeMe'
        };
      } else if (loadType === 'myLikes') {
        if (isRefresh) {
          this.pageMyLikes = 1;
          this.loadingMyLikes = true;
          this.networkErrorMyLikes = false;
          this.myLikesList = []; // 刷新时立即清空旧数据
        } else {
          this.pageMyLikes++;
          this.pullUpStateMyLikes = 2;
        }
        requestConfig = {
          type: 'FOLLOW',
          page: this.pageMyLikes,
          size: this.sizeMyLikes,
          listKey: 'myLikesList',
          pageKey: 'pageMyLikes',
          stateKey: 'pullUpStateMyLikes',
          loadingKey: 'loadingMyLikes',
          sizeKey: 'sizeMyLikes'
        };
      } else {
        return Promise.reject(new Error('Invalid loadType'));
      }

      return getFollowList({
        page: requestConfig.page,
        size: requestConfig.size,
        type: requestConfig.type
      }).then(rsp => {
        const newData = this.parseResponseData(rsp);
        const mappedData = this.mapDataToFormat(newData);

        if (isRefresh) {
          this[requestConfig.listKey] = mappedData;
        } else {
          this[requestConfig.listKey] = [...this[requestConfig.listKey], ...mappedData];
        }

        // 如果列表为空，不显示"没有更多数据"提示
        if (this[requestConfig.listKey].length === 0) {
          this[requestConfig.stateKey] = 0;
        } else if (newData.length < this[requestConfig.sizeKey]) {
          this[requestConfig.stateKey] = 3;
        } else {
          this[requestConfig.stateKey] = 1;
        }
        this[requestConfig.loadingKey] = false;
        
        // 清除网络错误状态
        if (loadType === 'likeMe') {
          this.networkErrorLikeMe = false;
        } else if (loadType === 'myLikes') {
          this.networkErrorMyLikes = false;
        }
      }).catch((error) => {
        console.error('加载列表失败:', error);
        if (!isRefresh) {
          this[requestConfig.pageKey]--;
        }
        this[requestConfig.stateKey] = 0;
        this[requestConfig.loadingKey] = false;
        
        // 检测网络错误
        const isNetworkError = error && (
          error.message === "Network Error" || 
          error.message === "Error api error" ||
          (error.request && !error.response)
        );
        
        if (isNetworkError) {
          if (loadType === 'likeMe') {
            this.networkErrorLikeMe = true;
          } else if (loadType === 'myLikes') {
            this.networkErrorMyLikes = true;
          }
        }
        
        throw error;
      });
    },
    onRefreshLikeMe(refreshDone) {
      this.loadBothLists(true, 'likeMe').then(() => {
        if (refreshDone) {
          refreshDone(true);
        }
      }).catch(() => {
        if (refreshDone) {
          refreshDone(false);
        }
      });
    },
    onInfiniteLoadLikeMe() {
      this.loadBothLists(false, 'likeMe');
    },
    onRefreshMyLikes(refreshDone) {
      this.loadBothLists(true, 'myLikes').then(() => {
        if (refreshDone) {
          refreshDone(true);
        }
      }).catch(() => {
        if (refreshDone) {
          refreshDone(false);
        }
      });
    },
    onInfiniteLoadMyLikes() {
      this.loadBothLists(false, 'myLikes');
    },
    handleRetryLikeMe() {
      this.networkErrorLikeMe = false;
      this.loadBothLists(true, 'likeMe');
    },
    handleRetryMyLikes() {
      this.networkErrorMyLikes = false;
      this.loadBothLists(true, 'myLikes');
    },
    clearUnreadLikeCount() {
      cache.local.set(key_cache.unread_like_count, '0');
      document.dispatchEvent(new CustomEvent('unreadLikeCountUpdated', { detail: 0 }));
    }
  },
  mounted() {
    // 进入喜欢列表时清除喜欢消息未读数（持久化 + 通知会话页更新）
    this.clearUnreadLikeCount();
    // 检查是否从详情页返回
    const fromDetail = sessionStorage.getItem('likeListFromDetail') === 'true';
    const savedIndex = sessionStorage.getItem('likeListActiveIndex');
    
    if (fromDetail && savedIndex !== null) {
      const index = parseInt(savedIndex, 10);
      if (index === 0 || index === 1) {
        this.savedActiveIndex = index;
        this.activeIndex = index;
        // 等待 swiper 初始化后再设置位置
        this.$nextTick(() => {
          const sw = this.$refs.swiper && this.$refs.swiper.swiper;
          if (sw) {
            sw.slideTo(index, 0, false);
          }
          // 加载对应的列表数据
          if (index === 0 && this.likeMeList.length === 0) {
            this.loadBothLists(true, 'likeMe');
          } else if (index === 1 && this.myLikesList.length === 0) {
            this.loadBothLists(true, 'myLikes');
          }
        });
        // 清除标记，下次进入时重置
        sessionStorage.removeItem('likeListFromDetail');
        return;
      }
    }
    
    // 首次进入或非从详情页返回，重置为默认值
    this.activeIndex = 0;
    this.savedActiveIndex = 0;
    sessionStorage.removeItem('likeListActiveIndex');
    sessionStorage.removeItem('likeListFromDetail');
    this.loadBothLists(true, 'likeMe');
  },
  activated() {
    // keep-alive 下再次进入页面时也清除未读数
    this.clearUnreadLikeCount();
  },
  beforeDestroy() {
    // 页面销毁时清除状态（除非是从详情页返回）
    const fromDetail = sessionStorage.getItem('likeListFromDetail') === 'true';
    if (!fromDetail) {
      sessionStorage.removeItem('likeListActiveIndex');
      sessionStorage.removeItem('likeListFromDetail');
    }
  }
}
</script>

<style scoped lang="less">
/deep/ .m-page-head {
  background: #141414;
  z-index: 1000;
}

/deep/ .m-action-bar {
  background: #141414;
}

.page {
  height: 100%;
  position: relative;
  z-index: 1;
}

.tabs {
  display: inline-flex;
  gap: 26px;
  align-items: center;
  justify-content: center;
}

.tab {
  font-size: 20px;
  font-weight: 700;
  color: #999999;
  padding: 6px 0;
}

.tab.active {
  color: #FFFFFF;
}

:deep(.swiper-container) {
  height: auto;
  min-height: calc(100vh - 60px);
}

:deep(.swiper-slide) {
  overflow: hidden;
  -webkit-overflow-scrolling: touch;
}

:deep(.swiper-slide > *) {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

// 全局空状态组件，固定在屏幕中央，避免切换时的横向移动
.global-empty-state {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 100;
  pointer-events: none;
}

.waterfall-container {
  display: flex;
  gap: 10px;
  padding: 0 12px 100px;
  box-sizing: border-box;
  position: relative;
}

.user-card.blur-card {
  pointer-events: auto;
}

.user-card.blur-card .card-image {
  filter: blur(8px);
}

.user-card.blur-card .user-name {
  filter: blur(8px);
  user-select: none;
}

.user-card.blur-card .age-badge {
  visibility: hidden;
}

.waterfall-column {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.user-card {
  position: relative;
  border-radius: 15px;
  overflow: hidden;
  background-color: rgba(255, 255, 255, 0.06);
}

.my-likes-card {
  border-radius: 20px;
  background-color: #141414;
}

.blur-overlay {
  position: absolute;
  inset: 0;
  z-index: 3;
  background: rgba(0, 0, 0, 0.25);
  cursor: pointer;
}

.online-status {
  position: absolute;
  top: 10px;
  left: 10px;
  padding: 3px 5px;
  border-radius: 5px;
  font-size: 14px;
  font-weight: 800;
  color: #ffffff;
  z-index: 2;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  background: rgba(0, 0, 0, 0.70);
}

.my-likes-card .online-status {
  padding: 0;
  background: transparent;
}

.my-likes-card .status-icon {
  max-width: 80px;
  max-height: 30px;
  width: auto;
  height: auto;
  object-fit: contain;
}

.online-status.available {
  color: #2DFF5C;
}

.online-status.in-call {
  color: #FFB020;
}

.status-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: currentColor;
  flex-shrink: 0;
}

.my-likes-card .online-status--likes {
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

.my-likes-card .online-status--likes .status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #3CFF72;
}

.my-likes-card .online-status--likes .status-text {
  color: #3CFF72;
  font-weight: 700;
}

.my-likes-card .online-status--likes .status-likes {
  color: #3CFF72;
  font-weight: 600;
  white-space: nowrap;
  font-size: 10px;
}

.my-likes-card .online-status--likes .status-divider {
  width: 1px;
  height: 12px;
}

.card-image {
  width: 100%;
  object-fit: cover;
  display: block;
}

.video-container {
  width: 100%;
  position: relative;
  overflow: hidden;
  background-color: #000;
  display: block;
}

.video-container.left-image {
  height: 251px;
}

.video-container.right-image {
  height: 313px;
}

.video-container .card-video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.left-image {
  height: 251px;
}

.right-image {
  height: 313px;
}

.card-bottom {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 12px 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0));
}

.my-likes-card .card-bottom {
  height: 97px;
  align-items: flex-end;
  padding-top: 10px;
  padding-bottom: 10px;
  padding-left: 10px;
  padding-right: 10px;
  background: none;
  border-radius: 0 0 15px 15px;
  z-index: 1;
}

.my-likes-card .card-bottom::before {
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

.my-likes-card .user-info {
  position: relative;
  z-index: 1;
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  gap: 4px;
}

.my-likes-card .user-name {
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}

.my-likes-card .user-meta {
  display: flex;
  align-items: center;
  gap: 6px;
}

.my-likes-card .flag-icon {
  display: inline-flex;
  width: 22px;
  height: 18px;
  font-size: 22px;
  line-height: 1;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.my-likes-card .age-badge {
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
}

.my-likes-card .age-badge .badge-text {
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

.my-likes-card .call-btn {
  position: relative;
  z-index: 1;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.my-likes-card .call-btn img {
  width: 44px;
  height: 44px;
  object-fit: contain;
}

.user-name {
  color: white;
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 4px;
}

.user-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.tag {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 1px;
  line-height: 16px;
  padding: 3pt 5pt;
  border-radius: 5px;
  font-size: 14px;
  font-weight: 800;
  color: white;
  background: rgba(255, 255, 255, 0.18);
}

.tag-flag {
  display: inline-block;
  font-size: 22px;
  line-height: 1;
  padding: 0;
  background: transparent;
}

.age-badge {
  padding: 0;
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center center;
  height: 20px;
  min-width: 41px;
  display: flex;
  align-items: center;
  justify-content: center;

  .badge-text {
    margin-left: 3px;
    font-size: 14px;
    font-weight: 700;
    color: #ffffff;
    line-height: 1;
  }
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
