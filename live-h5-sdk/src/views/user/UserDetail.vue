<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div class="user-detail">
        <!-- 顶部图片区域 -->
        <div class="head-section">
          <swiper ref="photoSwiper" class="photo-swiper" :class="{'swiper-hidden': hideSwiperOnNavigate}" :options="swiperOption">
            <swiper-slide v-for="(item, index) in picList" :key="index">
              <!-- 会员遮罩：非会员，picList > 1，从第二张开始（index > 0）显示遮罩 -->
              <!-- 如果是视频，遮罩上会显示视频按钮 -->
              <!-- index 0 是第一张，永远不显示遮罩；index > 0 是第二张及之后，显示遮罩 -->
              <!-- 遮罩：使用 v-show 确保条件正确执行 -->
              <div v-show="shouldShowOverlay(index, item)" class="premium-overlay" @click.stop="handlePremiumOverlayClick($event, item, index)">
                <div class="premium-lock-content">
                  <img :src="getOverlayIcon(item)" alt="Lock" class="premium-lock-icon"/>
                  <span v-if="albumFilterFreeCount > 0 && (item.type === 'video' || item.videoUrl)" class="album-free-badge">Free x{{ albumFilterFreeCount }}</span>
                </div>
              </div>
              <!-- 视频预览 -->
              <div v-if="item.type === 'video' || item.videoUrl" class="video-slide" @click="handleVideoClick($event, item, index)">
                <video
                  v-if="item.videoUrl"
                  class="video-preview"
                  :src="item.videoUrl"
                  muted
                  loop
                  :poster="item.coverUrl || item.url"
                ></video>
                <img
                  v-else
                  class="photo video-blur"
                  :src="item.coverUrl || item.url"
                  :data-preview="item.url"
                />
                <!-- 视频播放按钮：没有遮罩时显示 -->
                <div v-show="!shouldShowOverlay(index, item)" class="video-play-button">
                  <img src="@/assets/image/sdk/ic-userdetail-big-play.png" alt="Play" class="play-big-icon"/>
                </div>
              </div>
              <!-- 普通图片 -->
              <img v-else class="photo" :src="item.url" :data-preview="item.url"/>
            </swiper-slide>
            <div class="swiper-pagination" slot="pagination"></div>
          </swiper>
          <!-- 顶部导航栏 -->
          <div class="top-nav">
            <div class="nav-back" @click="$router.back()">
              <img class="back-icon" :src="backIcon" alt="Back" />
            </div>
            <div class="nav-more" @click="showMoreMenu">
              <img class="more-icon" :src="moreIcon" alt=""/>
            </div>
          </div>

          <!-- 在线状态 -->
          <img
            v-if="userInfo.onlineStatus === 0 || userInfo.onlineStatus === 2"
            class="online-badge"
            :src="getOnlineStatusImage"
            alt="Status"
          />
        </div>

        <!-- 用户信息区域 -->
        <div class="info-section">
          <!-- 用户基本信息 -->
          <div class="user-header">
            <h1 class="user-name">{{ userInfo.nickname || userInfo.name }}</h1>
            <div class="user-meta">
              <span class="call-price" v-if="userInfo.callPrice">
                <img src="@/assets/image/match/ic-match-coin@2x.png" alt="Coin" class="coin-icon" />
                {{ userInfo.callPrice }}/min
              </span>
              <span class="divider" v-if="userInfo.callPrice">|</span>
              <span>ID:{{ userInfo.userId || userInfo.id }}</span>
              <span class="divider" v-if="userInfo.likeCount > 0">|</span>
<!--              <span v-if="userInfo.likeCount > 0">Got {{ userInfo.likeCount }} {{ Number(userInfo.likeCount) === 1 ? 'Like' : 'Likes' }}</span>-->
            </div>
          </div>

          <!-- 徽章标签 -->
          <div class="badges">
            <div class="badge-item flag-badge" v-if="userInfo.country">
              <span class="flag-icon">{{ getCountryFlag(userInfo.country) }}</span>
            </div>
            <div class="badge-item age-badge" v-if="getGenderBadgeBg" :style="{ backgroundImage: `url(${getGenderBadgeBg})` }">
              <span class="badge-text">{{ userInfo.age || 23 }}</span>
            </div>
            <div class="badge-item level-badge" :style="levelBadgeStyle" v-if="userInfo.level && userInfo.level > 0">
              <span class="badge-text">Lv.{{ userInfo.level}}</span>
            </div>
            <div class="badge-item premium-badge" v-if="userInfo.isPremium">
              <img src="../../assets/image/sdk/ic-userdetail-pre.png" alt="Premium" class="premium-icon"/>
            </div>
          </div>

          <!-- 个人简介 -->
          <div class="bio-section" v-if="userInfo.signature">
            <h3 class="bio-title">Bio</h3>
            <p class="bio-text">{{ userInfo.signature}}</p>
          </div>
        </div>

        <!-- 底部操作按钮 -->
        <div class="action-footer">
          <div class="action-btn chat-btn" @click="onChatButtonClick">
            <img :src="isInCall ? require('@/assets/image/sdk/ic-userdetail-call.png') : require('@/assets/image/sdk/ic-userdetail-msg.png')" alt="Chat"/>
          </div>
          <div class="action-btn like-btn" :class="{'is-Liked': isFollowed}" @click="handleLike">
            <img :src="isFollowed ? require('@/assets/image/sdk/ic-userdetail-like.png') : require('@/assets/image/sdk/ic-userdetail-unlike.png')" alt="Like"/>
          </div>
          <div class="action-btn video-btn" :class="{ 'is-chat': isInCall }" @click="onVideoButtonClick">
            <img :src="isInCall ? require('@/assets/image/sdk/ic-userdetail-chat.png') : require('@/assets/image/sdk/ic-userdetail-play.gif')" alt="Video"/>
            <span>{{ isInCall ? 'Chat' : 'Video Chat' }}</span>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import 'swiper/dist/css/swiper.css'
import {swiper, swiperSlide} from 'vue-awesome-swiper'
import {getUserInfo} from "@/api";
import {openChat, requestCall, openPremium} from "@/utils/PageUtils";
import {getAnchorInfo} from "@/api/sdk/anchor";
import {userBackpack} from "@/api/sdk/commodity";
import {getCountryFlagEmojiByCode} from "@/utils/Utils";
import {followStatus, statusBlack} from "@/api/sdk/user";
import {showUserDetailMoreDialog, showUserReportPopup, showFeedbackDialog, showReportDialog} from "@/components/dialog";
import {showCallToast} from "@/components/toast/callToast";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";
import store from "@/store";

export default {
  name: 'UserDetail',
  components: {swiper, swiperSlide},
  data() {
    return {
      userId: null,
      userInfo: {},
      picList: [],
      isFollowed: false, // 关注状态
      swiperReachEndBound: false,
      swiperAutoplayResetTimer: null,
      currentSlideIndex: 0, // 当前显示的 slide 索引
      swiperInitialized: false, // 标记 swiper 是否已初始化
      isNavigating: false, // 标记是否正在导航跳转
      hideSwiperOnNavigate: false, // 标记是否在导航时隐藏 swiper
      unlockedAlbumMediaKeys: [], // 仅当前页有效，不持久化；离开时清空，下次进入需重新消耗
      swiperOption: {
        pagination: {
          el: '.swiper-pagination',
          clickable: true,
          type: 'bullets'
        },
        autoplay: {
          delay: 5000,
          disableOnInteraction: false,
          stopOnLastSlide: false
        },
        // loop 模式需要至少 2 张图片才能正常工作
        loop: true,
        loopAdditionalSlides: 1,
        spaceBetween: 0,
        centeredSlides: true,
        slideToClickedSlide: true,
        // 当图片数量不足时，禁用 loop
        on: {
          init: function() {
            if (this.slides.length <= 1) {
              this.params.loop = false;
              this.update();
            }
          }
        }
      }
    }
  },
  beforeRouteEnter(to, from, next) {
    next(vm => {
      vm.pageReady = false;
      vm.$nextTick(() => {
        vm.pageReady = true;
      });
    });
  },
  beforeRouteLeave(to, from, next) {
    this.unlockedAlbumMediaKeys = [];
    next();
  },
  mounted() {
    console.log('=== UserDetail: 组件已挂载 ===');
    console.log('路由查询参数:', this.$route.query);

    // 组件重新挂载时，显示 swiper
    this.hideSwiperOnNavigate = false;
    this.isNavigating = false;

    // 尝试从 query 中获取 userId 或 uid（仅接受有效数字，避免 "null" 等导致误请求）
    const userIdFromQuery = this.$route.query.userId || this.$route.query.uid;
    const parsed = userIdFromQuery != null && userIdFromQuery !== '' ? parseInt(userIdFromQuery, 10) : NaN;
    this.userId = Number.isNaN(parsed) || parsed <= 0 ? null : parsed;
    // this.userId = 10103;
    console.log('解析后的 userId:', this.userId);

    const userDataRaw = this.$route.query.userData;
    if (!this.userId && userDataRaw) {
      // 仅用于补全 userId，不使用透传数据渲染
      try {
        const userData = JSON.parse(userDataRaw);
        const fromPayload = userData?.userId != null ? parseInt(userData.userId, 10) : NaN;
        this.userId = Number.isNaN(fromPayload) || fromPayload <= 0 ? null : fromPayload;
      } catch (error) {
        console.error('解析 userData 失败:', error);
      }
    }

    if (this.userId) {
      const cached = cache.session.getJSON(this.getCacheKey(this.userId));
      if (cached) {
        this.applyCachedData(cached);
      } else {
        const payload = cache.session.getJSON(this.getPayloadKey(this.userId));
        if (payload) {
          this.applyUserData(payload);
          cache.session.remove(this.getPayloadKey(this.userId));
        }
      }
      // 如果有 userId，调用 API 加载数据
      console.log('检测到 userId，开始加载用户数据...');
      this.loadData();
    } else {
      // 如果既没有 userId 也没有 userData，使用默认数据
      console.warn('未检测到 userId 和 userData，使用默认数据');
    }
  },
  computed: {
    backIcon() {
      return require('@/assets/image/ic-common-back.png');
    },
    moreIcon() {
      return require('@/assets/image/ic-common-more.png');
    },
    isVip() {
      // 判断当前登录用户是否是会员（从 store 中获取）
      const loginUserInfo = this.$store.state.user.loginUserInfo || {};
      const isVip = loginUserInfo.vipCategory !== 0;
      console.log('=== isVip 计算 ===', {
        loginUserInfo,
        vipCategory: loginUserInfo.vipCategory,
        isVip: isVip
      });
      return isVip;
    },
    getOnlineStatusImage() {
      // 根据 onlineStatus 返回对应的状态图片（参考 ListIndex.vue）
      // 0: 在线 (ic-anchor-online)
      // 2: 通话中 (ic-anchor-incall)
      // 1: 不需要图片（不显示）
      const onlineStatus = this.userInfo.onlineStatus;
      if (onlineStatus === 0) {
        return require('@/assets/image/sdk/ic-anchor-online.png');
      } else if (onlineStatus === 2) {
        return require('@/assets/image/sdk/ic-anchor-incall.png');
      }
      return '';
    },
    isInCall() {
      return this.userInfo && this.userInfo.onlineStatus === 2;
    },
    albumFilterFreeCount() {
      const list = this.$store.state.user.userBackpack || [];
      if (!Array.isArray(list)) return 0;
      return list
        .filter((item) => item && Number(item.backpackType) === 4)
        .reduce((sum, item) => sum + Math.max(0, Number(item.quantity) || 0), 0);
    },
    getGenderBadgeBg() {
      // 根据性别返回对应的徽章背景图（参考 ListIndex.vue）
      // 根据 API 数据：gender === 1 表示女性（Female），gender === 2 表示男性（Male）
      if (!this.userInfo || this.userInfo.gender === undefined || this.userInfo.gender === null) {
        return null;
      }
      const gender = this.userInfo.gender;
      const isGirl = gender === 1;
      return isGirl
        ? require('@/assets/image/sdk/ic-userdetail-girl.png')
        : require('@/assets/image/sdk/ic-userdetail-boy.png');
    },
    getLevelBadgeBg() {
      // 返回等级徽章背景图
      return require('@/assets/image/sdk/ic-userdetail-level.png');
    },
    levelBadgeStyle() {
      return {
        backgroundImage: `url(${this.getLevelBadgeBg})`
      };
    }
  },
  watch: {
    // 'userInfo.gender'() {
    //   // 当 gender 变化时，强制更新视图
    //   this.$nextTick(() => {
    //     this.$forceUpdate();
    //   });
    // },
    // picList(newVal, oldVal) {
    //   console.log('=== picList watch 触发 ===', {
    //     newLength: newVal ? newVal.length : 0,
    //     oldLength: oldVal ? oldVal.length : 0,
    //     isNavigating: this.isNavigating,
    //     currentSlideIndex: this.currentSlideIndex
    //   });
    //
    //   // 如果正在导航，跳过同步
    //   if (this.isNavigating) {
    //     console.log('⚠️ picList watch: 正在导航中，跳过 syncSwiper');
    //     return;
    //   }
    //
    //   this.syncSwiper();
    // }
  },
  methods: {
    getCacheKey(userId) {
      return `user_detail_cache_${userId}`;
    },
    getPayloadKey(userId) {
      return `user_detail_payload_${userId}`;
    },
    cacheUserDetail() {
      if (!this.userId) return;
      cache.session.setJSON(this.getCacheKey(this.userId), {
        userInfo: this.userInfo,
        picList: this.picList,
        isFollowed: this.isFollowed
      });
    },
    applyCachedData(cached) {
      if (!cached) return;
      this.userInfo = cached.userInfo || this.userInfo;
      this.picList = cached.picList || this.picList;
      if (typeof cached.isFollowed === 'boolean') {
        this.isFollowed = cached.isFollowed;
      }
    },
    applyCachedLikeState(cached) {
      const cachedUserInfo = cached?.userInfo;
      if (!cachedUserInfo) return;
      if (cachedUserInfo.likeCount !== undefined && cachedUserInfo.likeCount !== null) {
        this.userInfo.likeCount = cachedUserInfo.likeCount;
      }
      if (cachedUserInfo.followStatus !== undefined && cachedUserInfo.followStatus !== null) {
        this.userInfo.followStatus = cachedUserInfo.followStatus;
        this.isFollowed = cachedUserInfo.followStatus === 2;
      } else if (typeof cached.isFollowed === 'boolean') {
        this.isFollowed = cached.isFollowed;
        this.userInfo.followStatus = cached.isFollowed ? 2 : 0;
      }
    },
    applyUserData(userData) {
      if (!userData) return;
      // 将卡片数据映射到 userInfo，直接替换整个对象以确保响应式
      this.userInfo = {
        name: userData.name,
        nickname: userData.nickname || userData.name,
        userId: userData.userId || null,
        age: userData.age ? parseInt(userData.age) : null,
        gender: userData.gender,
        likeCount: userData.likeCount || 0,
        status: userData.status === 'available' ? 1 : 0,
        onlineStatus: userData.onlineStatus,
        country: userData.country || null,
        signature: userData.signature,
        level: userData.level,
        isPremium: userData.isPremium || false,
        headImage: userData.avatar || userData.image || ''
      };
      this.isFollowed = userData.followStatus === 2;
      this.userInfo.followStatus = userData.followStatus;
      console.log('已设置 userInfo (来自 userData):', this.userInfo);
      console.log('userInfo.gender:', this.userInfo.gender);

      // 设置图片列表（优先使用 userPictures/videos，其次使用单卡片图片或视频）
      this.picList = [];
      if (userData.userPictures && Array.isArray(userData.userPictures) && userData.userPictures.length > 0) {
        const pictures = userData.userPictures.map(pic => ({
          url: pic.url || '',
          type: 'image',
          videoUrl: null,
          coverUrl: null,
          duration: null,
          buyId: pic.id || null,
          videoPrice: pic.coin || 0,
          locked: pic.isPay === true && pic.coin > 0
        }));
        this.picList = [...this.picList, ...pictures];
      }
      if (userData.videos && Array.isArray(userData.videos) && userData.videos.length > 0) {
        const videos = userData.videos.map(video => ({
          url: video.cover || video.videoUrl || '',
          type: 'video',
          videoUrl: video.videoUrl || '',
          coverUrl: video.cover || '',
          duration: video.duration || 0,
          buyId: video.videoId || null,
          videoPrice: video.coin || 0,
          locked: video.isPay === true && video.coin > 0
        }));
        this.picList = [...this.picList, ...videos];
      }
      if (this.picList.length === 0 && (userData.image || userData.videoUrl)) {
        this.picList = [{
          url: userData.image || userData.coverUrl || userData.videoCover || '',
          type: userData.videoUrl ? 'video' : (userData.type || 'image'),
          videoUrl: userData.videoUrl,
          coverUrl: userData.coverUrl || userData.videoCover || userData.image,
          duration: userData.duration,
          buyId: userData.buyId,
          videoPrice: userData.videoPrice,
          locked: userData.buyId === 0 && userData.videoPrice > 0
        }];
      }
      this.$nextTick(() => {
        this.syncSwiper();
      });
      console.log('已设置用户数据（不调用 API）:', this.userInfo);
    },
    getItemKey(item, index) {
      return item.videoUrl || item.url || item.coverUrl || `idx-${index}`;
    },
    shouldShowOverlay(index, item) {
      // 已用免费次数解锁的项不再显示遮罩
      const key = this.getItemKey(item, index);
      if (this.unlockedAlbumMediaKeys.includes(key)) return false;
      // 遮罩显示条件：非会员，picList > 1，从第二张开始（index > 0）
      const condition1 = index > 0;
      const condition2 = !this.isVip;
      const condition3 = this.picList.length > 1;
      return condition1 && condition2 && condition3;
    },
    getOverlayIcon(item) {
      // 根据内容类型返回对应的遮罩图标
      // 视频：ic-userdetail-play-lock
      // 图片：ic-userdetail-lock
      const isVideo = item.type === 'video' || item.videoUrl;
      return isVideo
        ? require('@/assets/image/sdk/ic-userdetail-play-lock.png')
        : require('@/assets/image/sdk/ic-userdetail-lock.png');
    },
    syncSwiper() {
      console.log('=== syncSwiper: 调用同步 swiper ===', {
        isNavigating: this.isNavigating,
        swiperInitialized: this.swiperInitialized,
        picListLength: this.picList.length,
        currentSlideIndex: this.currentSlideIndex,
        stackTrace: new Error().stack // 添加调用栈追踪
      });

      // 如果正在导航跳转，不执行 swiper 更新，避免重置位置
      if (this.isNavigating) {
        console.log('⚠️ syncSwiper: 正在导航中，跳过 swiper 更新');
        console.trace('syncSwiper 被阻止的调用栈');
        return;
      }

      this.$nextTick(() => {
        const swiper = this.$refs.photoSwiper && this.$refs.photoSwiper.swiper;
        if (!swiper) {
          return;
        }

        // 保存当前索引
        let savedIndex = this.currentSlideIndex;
        if (swiper.realIndex !== undefined) {
          savedIndex = swiper.realIndex;
        } else if (swiper.activeIndex !== undefined) {
          savedIndex = swiper.activeIndex;
        }

        console.log('syncSwiper: 准备执行 swiper.update()，保存的索引:', savedIndex);

        // 再次检查 isNavigating，防止在 $nextTick 期间被设置
        if (this.isNavigating) {
          console.log('⚠️ syncSwiper: update() 前再次检查，发现 isNavigating = true，跳过更新');
          return;
        }

        console.log('syncSwiper: 执行 swiper.update()');
        swiper.update();

        // 恢复索引位置（避免 update 后重置到第一张）
        if (savedIndex > 0 && this.swiperInitialized) {
          const maxIndex = Math.max(0, this.picList.length - 1);
          const targetIndex = Math.min(savedIndex, maxIndex);
          console.log('syncSwiper: 准备恢复索引位置:', {
            savedIndex,
            targetIndex,
            maxIndex,
            swiperInitialized: this.swiperInitialized
          });
          // 延迟恢复，确保 update 完成
          this.$nextTick(() => {
            if (swiper && swiper.params) {
              console.log('syncSwiper: 执行恢复索引到位置:', targetIndex);
              if (swiper.params.loop && typeof swiper.slideToLoop === 'function') {
                swiper.slideToLoop(targetIndex, 0);
              } else if (typeof swiper.slideTo === 'function') {
                swiper.slideTo(targetIndex, 0);
              }
              this.currentSlideIndex = targetIndex;
              console.log('syncSwiper: 索引已恢复到:', targetIndex);
            }
          });
        } else {
          console.log('syncSwiper: 跳过恢复索引', {
            savedIndex,
            swiperInitialized: this.swiperInitialized
          });
        }

        if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
          swiper.autoplay.start();
        }

        // 监听 slide 切换事件，更新当前索引
        if (!this.swiperInitialized) {
          swiper.off('slideChange'); // 先移除旧的监听，避免重复绑定
          swiper.on('slideChange', () => {
            if (swiper.realIndex !== undefined) {
              this.currentSlideIndex = swiper.realIndex;
            } else {
              this.currentSlideIndex = swiper.activeIndex || 0;
            }
            // 强制更新视图，确保 computed 属性重新计算
            this.$forceUpdate();
          });

          // 初始化当前索引
          if (swiper.realIndex !== undefined) {
            this.currentSlideIndex = swiper.realIndex;
          } else {
            this.currentSlideIndex = swiper.activeIndex || 0;
          }
          this.swiperInitialized = true; // 标记已初始化

        }

        if (!this.swiperReachEndBound) {
          swiper.on('slideChangeTransitionEnd', () => {
            const total = this.picList.length;
            // 确保有足够的图片且 loop 模式已启用
            if (total > 1 && swiper.params && swiper.params.loop && swiper.realIndex === total - 1) {
              if (this.swiperAutoplayResetTimer) {
                clearTimeout(this.swiperAutoplayResetTimer);
              }
              const delay = (swiper.params && swiper.params.autoplay && swiper.params.autoplay.delay) || 0;
              this.swiperAutoplayResetTimer = setTimeout(() => {
                // 检查 swiper 和 loop 模式是否可用
                if (swiper && swiper.params && swiper.params.loop && typeof swiper.slideToLoop === 'function') {
                  swiper.slideToLoop(0, 0);
                  if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
                    swiper.autoplay.start();
                  }
                }
              }, delay);
            }
          });
          this.swiperReachEndBound = true;
        }
      });
    },
    setDefaultData() {
      // 设置默认数据，使用 Object.assign 确保响应式
      this.userInfo = {
        name: '',
        nickname: '',
        userId: 0,
        age: 0,
        gender: 2, // 1 表示男性，2 表示女性
        likeCount: 1323,
        status: 1,
        signature: 'I like boys, come to chat with me I will show you something fun! 💕💕💕',
        level: 0,
        isPremium: true
      };
      this.picList = [{url: 'https://picsum.photos/400/600'},{url:'http://www.w3school.com.cn/i/movie.mp4'},{url:'https://picsum.photos/seed/user7/300/400'}];
      console.log('已设置默认数据:', this.userInfo);
      console.log('userInfo.gender:', this.userInfo.gender);
    },
    loadData(updateSocialOnly = false) {
      const uid = this.userId != null ? Number(this.userId) : NaN;
      if (Number.isNaN(uid) || uid <= 0) {
        console.warn('loadData: userId 无效，跳过 getAnchorInfo', { userId: this.userId });
        return;
      }

      getAnchorInfo(uid).then((rsp) => {
        // 根据 Request.js 的逻辑，成功的响应 code 应该是 200
        // 但有些 API 可能返回 code 0 表示成功，所以同时检查两种情况

        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success) && rsp.data) {
          const userData = rsp.data;
          console.log('用户数据 (rsp.data):', userData);

          if (updateSocialOnly) {
            if (userData.likeCount !== undefined && userData.likeCount !== null) {
              this.userInfo.likeCount = userData.likeCount;
            } else if (userData.follower !== undefined && userData.follower !== null) {
              this.userInfo.likeCount = userData.follower;
            }
            if (userData.followStatus !== undefined && userData.followStatus !== null) {
              this.userInfo.followStatus = userData.followStatus;
              this.isFollowed = userData.followStatus === 2;
            }
            this.cacheUserDetail();
            return;
          }

          // 直接替换整个对象以确保响应式
          this.userInfo = {
            userId: userData.userId || this.userId,
            name: userData.name || userData.nickname || '',
            nickname: userData.nickname || userData.name || '',
            age: userData.age || null,
            gender: userData.gender,
            likeCount: userData.likeCount || userData.follower || 0,
            status: userData.onlineStatus === 0 ? 1 : 0,
            onlineStatus: userData.onlineStatus,
            signature: userData.signature,
            level: userData.level,
            isPremium: userData.isPremium || false,
            country: userData.country || null,
            headImage: userData.headImage || userData.avatar || '',
            picList: userData.picList || [],
            followStatus: userData.followStatus || 0,
            callPrice:userData.callPrice,
          };

          // 初始化关注状态
          this.isFollowed = userData.followStatus === 2;

          console.log('已设置 userInfo:', this.userInfo);
          console.log('userInfo.gender:', this.userInfo.gender);

          // 构建图片列表：将 userPictures 和 videos 数组合并
          this.picList = [];

          // 处理图片数组 userPictures
          // 数据结构：{ coin, cover, id, isPay, type, url }
          if (userData.userPictures && Array.isArray(userData.userPictures) && userData.userPictures.length > 0) {
            const pictures = userData.userPictures.map(pic => ({
              url: pic.url || '',
              type: 'image',
              videoUrl: null,
              coverUrl: null,
              duration: null,
              buyId: pic.id || null,
              videoPrice: pic.coin || 0,
              locked: pic.isPay === true && pic.coin > 0
            }));
            this.picList = [...this.picList, ...pictures];
          }

          // 处理视频数组 videos
          // 数据结构：{ coin, cover, createTime, duration, introduction, isLike, isPay, likeNum, videoId, videoUrl }
          if (userData.videos && Array.isArray(userData.videos) && userData.videos.length > 0) {
            const videos = userData.videos.map(video => ({
              url: video.cover || video.videoUrl || '',
              type: 'video',
              videoUrl: video.videoUrl || '',
              coverUrl: video.cover || '',
              duration: video.duration || 0,
              buyId: video.videoId || null,
              videoPrice: video.coin || 0,
              locked: video.isPay === true && video.coin > 0
            }));
            this.picList = [...this.picList, ...videos];
          }

          // 如果没有图片和视频，使用 headImage 或默认图片
          if (this.picList.length === 0) {
            if (this.userInfo.headImage) {
              this.picList = [{url: this.userInfo.headImage, type: 'image'}];
            } else {
              this.picList = [];
            }
          }

          this.cacheUserDetail();
          console.log('最终图片列表 (picList):', this.picList);
          console.log('数据加载完成，界面将更新');

          // 数据加载完成后，同步 swiper
          this.$nextTick(() => {
            this.syncSwiper();
          });
        } else {
          console.warn('API 返回的数据格式不符合预期:', rsp);
        }
      }).catch((error) => {
        console.error('错误信息:', error);
      });
    },
    // eslint-disable-next-line no-unused-vars
    getCountryFlag(country) {
      // 使用 Unicode emoji 显示国旗，更安全且不依赖第三方服务
      // country 参数就是国家代码（可能是数字或字符串）
      return getCountryFlagEmojiByCode(country);
    },
    showMoreMenu() {
      // 显示更多菜单
      if (!this.userId) {
        showCallToast('User ID not found');
        return;
      }

      showUserDetailMoreDialog({
        onBlock: async () => {
          // 屏蔽用户
          try {
            const rsp = await statusBlack(this.userId);
            if (rsp && (rsp.success || rsp.code === 200 || rsp.code === 0)) {
              showCallToast('User blocked successfully');
              // 可以选择返回上一页
              setTimeout(() => {
                this.$router.back();
              }, 1000);
            } else {
              showCallToast('Failed to block user');
            }
          } catch (error) {
            console.error('Block user error:', error);
            showCallToast('Failed to block user');
          }
        },
        onReport: () => {
          // 显示举报对话框
          const userInfo = this.userInfo && Object.keys(this.userInfo).length > 0 ? {
            userId: this.userInfo.userId || this.userId,
            nickname: this.userInfo.nickname || this.userInfo.name || '',
            name: this.userInfo.name || this.userInfo.nickname || '',
            headImage: this.userInfo.headImage || this.userInfo.avatar || '',
            avatar: this.userInfo.avatar || this.userInfo.headImage || ''
          } : {};
          showReportDialog({
            userId: this.userId,
            userInfo: userInfo
          });
        },
        onBlockAndReport: () => {
          // 显示举报对话框，在 submit 时再调用拉黑和举报接口
          const userInfo = this.userInfo && Object.keys(this.userInfo).length > 0 ? {
            userId: this.userInfo.userId || this.userId,
            nickname: this.userInfo.nickname || this.userInfo.name || '',
            name: this.userInfo.name || this.userInfo.nickname || '',
            headImage: this.userInfo.headImage || this.userInfo.avatar || '',
            avatar: this.userInfo.avatar || this.userInfo.headImage || ''
          } : {};
          showReportDialog({
            userId: this.userId,
            userInfo: userInfo,
            needBlock: true // 标记需要先拉黑
          });
        },
        onFeedback: () => {
          // 显示反馈对话框
          showFeedbackDialog();
        },
        onCancel: () => {
          // 取消操作，不需要做任何事
        }
      });
    },
    handleChat(event) {
      console.log('=== handleChat: 点击聊天按钮 ===');
      if (!this.userId) {
        return;
      }

      // 立即停止 swiper 的所有操作，防止自动切换
      const swiper = this.$refs.photoSwiper && this.$refs.photoSwiper.swiper;
      if (swiper) {
        // 停止自动播放
        if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
          swiper.autoplay.stop();
        }
        // 禁用所有交互
        swiper.allowTouchMove = false;
        swiper.allowSlideNext = false;
        swiper.allowSlidePrev = false;
      }

      // 立即标记正在导航，防止 swiper 更新重置位置
      this.isNavigating = true;
      console.log('设置 isNavigating = true');

      // 立即隐藏 swiper，避免闪烁
      this.hideSwiperOnNavigate = true;
      console.log('立即隐藏 swiper，避免闪烁');

      // 使用 $nextTick 确保 DOM 更新完成后再执行跳转
      this.$nextTick(() => {
        // 执行跳转操作，如果跳转失败则显示回 swiper
        if (this.$route.query.from === 'chat') {
          console.log('从聊天页面进入，执行 router.back()');
          this.$router.back().catch((error) => {
            console.error('跳转失败:', error);
            // 跳转失败，恢复导航状态和显示 swiper
            this.isNavigating = false;
            this.hideSwiperOnNavigate = false;
            // 恢复 swiper 交互
            if (swiper) {
              swiper.allowTouchMove = true;
              swiper.allowSlideNext = true;
              swiper.allowSlidePrev = true;
              if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
                swiper.autoplay.start();
              }
            }
          });
        } else {
          console.log('执行 openChat，跳转到聊天页面');
          try {
            openChat(this.userId);
          } catch (error) {
            console.error('跳转失败:', error);
            // 跳转失败，恢复导航状态和显示 swiper
            this.isNavigating = false;
            this.hideSwiperOnNavigate = false;
            // 恢复 swiper 交互
            if (swiper) {
              swiper.allowTouchMove = true;
              swiper.allowSlideNext = true;
              swiper.allowSlidePrev = true;
              if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
                swiper.autoplay.start();
              }
            }
          }
        }
      });
    },
    async handleLike() {
      if (!this.userId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        const follow = !this.isFollowed; // 如果当前未关注，则关注；如果已关注，则取消关注
        const { success, data } = await followStatus(this.userId, follow, false);

        if (success) {
          this.isFollowed = follow;
          showCallToast(follow ? 'Liked' : 'Unliked');
          // 更新用户信息中的关注状态和点赞数量
          // followStatus: 0 = 未关注, 2 = 已关注
          if (this.userInfo) {
            this.userInfo.followStatus = follow ? 2 : 0;
            // 立即更新点赞数量：关注则加1，取消关注则减1
            if (follow) {
              this.userInfo.likeCount = (this.userInfo.likeCount || 0) + 1;
            } else {
              this.userInfo.likeCount = Math.max(0, (this.userInfo.likeCount || 0) - 1);
            }
          }
          this.cacheUserDetail();
        } else {
          showCallToast('Operation failed');
        }
      } catch (error) {
        console.error('Follow/Unfollow error:', error);
        showCallToast('Operation failed');
      }
    },
    handleVideoChat(event) {
      console.log('=== handleVideoChat: 点击视频聊天按钮 ===');
      if (this.isInCall) {
        showCallToast('User is busy');
        return;
      }
      if (!this.userId) {
        return;
      }

      // 立即停止 swiper 的所有操作，防止自动切换
      const swiper = this.$refs.photoSwiper && this.$refs.photoSwiper.swiper;
      if (swiper) {
        // 停止自动播放
        if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
          swiper.autoplay.stop();
        }
        // 禁用所有交互
        swiper.allowTouchMove = false;
        swiper.allowSlideNext = false;
        swiper.allowSlidePrev = false;
      }

      // 立即标记正在导航，防止 swiper 更新重置位置
      this.isNavigating = true;
      console.log('设置 isNavigating = true');

      // 立即隐藏 swiper，避免闪烁
      this.hideSwiperOnNavigate = true;
      console.log('立即隐藏 swiper，避免闪烁');

      // 使用 $nextTick 确保 DOM 更新完成后再执行跳转
      this.$nextTick(() => {
        // 执行视频通话请求
        console.log('执行 requestCall，发起视频通话');
        try {
          console.error("数据：",this.userInfo)
          store.dispatch('call/setAnchorInfo', this.userInfo);
          requestCall(this.userId);
        } catch (error) {
          console.error('视频通话请求失败:', error);
          // 请求失败，恢复导航状态和显示 swiper
          this.isNavigating = false;
          this.hideSwiperOnNavigate = false;
          // 恢复 swiper 交互
          if (swiper) {
            swiper.allowTouchMove = true;
            swiper.allowSlideNext = true;
            swiper.allowSlidePrev = true;
            if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
              swiper.autoplay.start();
            }
          }
        }
      });
    },
    onChatButtonClick(event) {
      if (this.isInCall) {
        this.handleVideoChat(event);
        return;
      }
      this.handleChat(event);
    },
    onVideoButtonClick(event) {
      if (this.isInCall) {
        this.handleChat(event);
        return;
      }
      this.handleVideoChat(event);
    },
    formatDuration(seconds) {
      // 格式化视频时长，将秒数转换为 MM:SS 格式
      if (!seconds && seconds !== 0) return '00:00';
      const totalSeconds = Math.floor(seconds);
      const minutes = Math.floor(totalSeconds / 60);
      const secs = totalSeconds % 60;
      return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    },
    handleVideoClick(event, item, index) {
      // 输出当前点击播放的数据源
      console.log('=== 点击播放视频 ===');
      console.log('视频数据源 (item):', item);
      console.log('视频索引 (index):', index);
      console.log('完整数据:', {
        index: index,
        type: item.type,
        url: item.url,
        videoUrl: item.videoUrl,
        coverUrl: item.coverUrl,
        duration: item.duration,
        buyId: item.buyId,
        videoPrice: item.videoPrice,
        locked: item.locked,
        fullItem: item
      });

      // 点击视频时直接播放，不管是否有遮罩或是否需要解锁
      if (!item.videoUrl) {
        console.warn('视频地址不存在，无法播放');
        return; // 如果没有视频地址，不处理
      }

      // 从点击的容器元素中查找 video 元素
      const videoElement = event.currentTarget.querySelector('video');
      if (videoElement) {
        console.log('找到 video 元素，准备播放:', {
          videoSrc: videoElement.src,
          videoPoster: videoElement.poster,
          videoElement: videoElement
        });
        this.toggleVideoPlay(videoElement);
      } else {
        console.warn('未找到 video 元素');
      }
    },
    toggleVideoPlay(video) {
      if (!video) return;

      if (video.paused) {
        // 如果视频暂停，则播放
        video.play().catch(err => {
          console.error('播放视频失败:', err);
          showCallToast('Failed to play video');
        });
      } else {
        // 如果视频正在播放，则暂停
        video.pause();
      }
    },
    handlePremiumOverlayClick(event, item, index) {
      if (event) {
        event.preventDefault();
        event.stopPropagation();
      }

      const isVideo = item && (item.type === 'video' || item.videoUrl);
      const canFreeUnlock = this.albumFilterFreeCount > 0 && isVideo;

      if (canFreeUnlock) {
        userBackpack()
          .then((res) => {
            if (res && res.code === 200) {
              const key = this.getItemKey(item, index);
              if (!this.unlockedAlbumMediaKeys.includes(key)) {
                this.unlockedAlbumMediaKeys.push(key);
              }
              return store.dispatch('GetUserBackpack');
            }
            showCallToast(res?.msg || 'Failed to use');
          })
          .catch((err) => {
            console.error('userBackpack consume fail:', err);
            showCallToast(err?.msg || 'Failed to use');
          });
        return;
      }

      console.log('=== handlePremiumOverlayClick: 点击遮罩跳转会员充值 ===');
      const swiper = this.$refs.photoSwiper && this.$refs.photoSwiper.swiper;
      if (swiper) {
        if (swiper.params && swiper.params.autoplay && swiper.autoplay) {
          swiper.autoplay.stop();
        }
        swiper.allowTouchMove = false;
        swiper.allowSlideNext = false;
        swiper.allowSlidePrev = false;
      }
      this.isNavigating = true;
      this.hideSwiperOnNavigate = true;
      setTimeout(() => {
        openPremium();
      }, 0);
    }
  }
}
</script>

<style scoped lang="less">
.user-detail {
  background-color: #000;
  min-height: 100vh;
  color: white;
}

.head-section {
  position: relative;
  width: 100%;
  height: 60vh;
  max-height: 500px;
  overflow: hidden;

  // 会员遮罩层（在每个 slide 内部）
  /deep/ .swiper-slide {
    position: relative;

    .premium-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      z-index: 20;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      backdrop-filter: blur(20px);

      // 确保当 v-show="false" 时完全隐藏
      &[style*="display: none"] {
        display: none !important;
      }

      .premium-lock-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 5px;

        .premium-lock-icon {
          width: 67px;
          height: 76px;
          object-fit: contain;
        }

        .album-free-badge {
          background: linear-gradient(90deg, #4CA703 0%, #01B7F3 100%);
          color: white;
          font-size: 16px;
          font-weight: 500;
          padding: 3px 10px;
          border-radius: 14px;
          white-space: nowrap;
        }
      }

    }
  }

  .photo-swiper {
    width: 100%;
    height: 100%;

    &.swiper-hidden {
      display: none !important;
    }

    .photo {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    // 视频幻灯片样式
    .video-slide {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;

      .video-preview {
        width: 100%;
        height: 100%;
        object-fit: cover;
        position: relative;
        z-index: 1; // 确保视频在播放按钮下方
        // 移除 blur 和 scale，避免影响遮罩显示
      }

      .video-blur {
        width: 100%;
        height: 100%;
        object-fit: cover;
        // 移除 blur 和 scale，避免影响遮罩显示
      }

      // 视频播放按钮：即使没有遮罩也显示
      .video-play-button {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 15; // 提高 z-index，确保在视频上方，不会被视频覆盖
        pointer-events: none; // 不阻止点击事件传递到 video-slide

        .play-icon {
          width: 30px;
          height: 30px;
          object-fit: contain;
        }

        .play-big-icon {
          width: 67px;
          height: 67px;
          object-fit: contain;
        }
      }
    }
  }

  // 分页指示器样式
  /deep/ .swiper-pagination {
    bottom: 15px !important;
    left: 0;
    width: 100%;
    padding: 0 20px;
    box-sizing: border-box;
    display: flex !important;
    justify-content: center;
    align-items: center;
    gap: 5px;
    z-index: 10;
  }

  /deep/ .swiper-pagination-bullet {
    flex: 1;
    height: 3px;
    border-radius: 2px;
    background: rgba(255, 255, 255, 0.5);
    opacity: 1;
    margin: 0 !important;
    cursor: pointer;
    transition: background-color 0.3s;
  }

  /deep/ .swiper-pagination-bullet-active {
    background: rgba(255, 255, 255, 1);
  }

  .top-nav {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 20px;
    padding-top: calc(15px + constant(safe-area-inset-top)); /* iOS < 11.2，状态栏高度 */
    padding-top: calc(15px + env(safe-area-inset-top)); /* 状态栏高度 */
    z-index: 100;

    .nav-back, .nav-more {
      width: 40px;
      height: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      -webkit-tap-highlight-color: transparent;
      -webkit-touch-callout: none;
      -webkit-user-select: none;
      -moz-user-select: none;
      user-select: none;
      outline: none;
    }
    
    .nav-more {
      position: relative;
    }
    
    .back-icon {
      width: 30px;
      height: 30px;
      object-fit: contain;
      -webkit-tap-highlight-color: transparent;
      -webkit-touch-callout: none;
      pointer-events: none;
    }

    .more-icon {
      width: 30px;
      height: 30px;
      object-fit: contain;
      -webkit-tap-highlight-color: transparent;
      -webkit-touch-callout: none;
      pointer-events: none;
    }
  }

  .online-badge {
    position: absolute;
    bottom: 34px;
    left: 20px;
    width: 84px;
    height: 25px;
    z-index: 10;
    object-fit: contain;
  }
}

.info-section {
  background-color: #1a1a1a;
  padding: 25px 20px;
  min-height: 40vh;

  .user-header {
    margin-bottom: 10px;
    text-align: left;

    .user-name {
      font-size: 24px;
      font-weight: bold;
      margin: 0 0 10px 0;
      color: white;
      text-align: left;
    }

    .user-meta {
      font-size: 14px;
      color: #FFFFFF;
      display: flex;
      align-items: center;
      gap: 8px;

      .divider {
        color: #666;
      }

      .call-price {
        display: flex;
        align-items: center;
        gap: 4px;
      }

      .coin-icon {
        width: 14px;
        height: 14px;
        object-fit: contain;
      }
    }
  }

  .badges {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-bottom: 15px;
    align-items: center;

    .badge-item {
      display: flex;
      align-items: center;
      border-radius: 5px;
      font-size: 13px;
      font-weight: 500;

      i {
        margin-right: 5px;
        font-size: 14px;
      }

      .badge-text {
        color: white;
        font-size: 13px;
        font-weight: 500;
      }

      .gender-icon {
        width: 12px;
        height: 12px;
        margin-right: 5px;
        object-fit: contain;
        flex-shrink: 0;
      }

      .level-icon {
        width: 12px;
        height: 12px;
        margin-right: 5px;
        object-fit: contain;
        flex-shrink: 0;
      }

      .premium-icon {
        width: 98px;
        height: 25px;
        object-fit: contain;
      }

      &.flag-badge {
        width: 25px;
        padding: 0;
        overflow: hidden;
        background: transparent;
        display: flex;
        align-items: center;
        justify-content: center;

        .flag-icon {
          display: inline-block;
          font-size: 34px;
          line-height: 1;
          vertical-align: middle;
          object-fit: cover;
          image-rendering: -webkit-optimize-contrast;
          image-rendering: auto;
          -ms-interpolation-mode: bicubic;
        }
      }

      &.age-badge {
        padding: 0;
        background-size: 100% 100%;
        background-repeat: no-repeat;
        background-position: center center;
        height: 25px;
        width: fit-content;
        display: inline-flex;
        align-items: center;
        position: relative;
        overflow: hidden;

        .badge-text {
          color: white;
          font-size: 13px;
          font-weight: 500;
          white-space: nowrap;
          text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
          position: relative;
          z-index: 1;
          padding-left: 28px;
          padding-right: 8px;
          padding-top: 2px;
          box-sizing: border-box;
        }
      }

      &.level-badge {
        padding: 0;
        background-size: 100% 100%;
        background-repeat: no-repeat;
        background-position: center center;
        height: 25px;
        width: fit-content;
        display: inline-flex;
        align-items: center;
        position: relative;
        overflow: hidden;

        .badge-text {
          color: white;
          font-size: 13px;
          font-weight: 500;
          white-space: nowrap;
          text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
          position: relative;
          z-index: 1;
          padding-left: 29px;
          padding-right: 8px;
          box-sizing: border-box;
        }
      }

      &.premium-badge {
        padding: 0;
        background: transparent;
        height: 20px;

        .premium-icon {
          display: block;
        }
      }

      .flag-icon {
        display: inline-block;
        font-size: 25px;
        line-height: 1;
        vertical-align: middle;
        object-fit: cover;
        border-radius: 50%;
        image-rendering: -webkit-optimize-contrast;
        image-rendering: auto;
        -ms-interpolation-mode: bicubic;
      }
    }
  }

  .bio-section {
    text-align: left;

    .bio-title {
      font-size: 18px;
      font-weight: bold;
      margin: 0 0 5px 0;
      color: white;
      text-align: left;
    }

    .bio-text {
      font-size: 15px;
      line-height: 1.6;
      color: #ddd;
      margin: 0;
    }
  }
}

.action-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  align-items: center;
  padding: 20px 0;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.9) 0%, transparent 100%);
  z-index: 100;

  .action-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: transform 0.2s;
      -webkit-tap-highlight-color: transparent;
      user-select: none;
      -webkit-user-select: none;

    &:active {
      transform: scale(0.95);
    }

    img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }

    &.chat-btn {
      width: 53px;
      height: 53px;
      margin-left: 20px;
      margin-right: 10px;
    }

    &.like-btn {
      width: 53px;
      height: 53px;
      margin-right: 16px;
    }

    &.video-btn {
      flex: 1;
      height: 50px;
      margin-right: 20px;
      border-radius: 25px;
      background:linear-gradient( 90deg, #FF57DB 0%, #D400FF 100%);
      color: white;
      font-weight: bold;
      font-size: 16px;
      gap: 8px;
      border: none;
      padding-left: 37px;
      padding-right: 36px;
      display: flex;
      align-items: center;
      justify-content: flex-start;

      img {
        width: 29px;
        height: 29px;
      }

      span {
        color: white;
        font-size: 18px;
        font-weight: bold;
        white-space: nowrap;
      }
    }

    &.video-btn.is-chat {
      background: linear-gradient(90deg, #FFB043 0%, #FF8A00 100%);
    }
  }
}
</style>
