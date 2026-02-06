<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar title="Black List"/>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <!-- 列表容器 - 固定定位，动态设置 top -->
        <div class="list-container" ref="listContainer">
          <div class="list-wrap">
            <m-list-drop-down-refresh :on-refresh="onRefresh" ref="downRefresh">
              <m-list-pull-up-reload
                :open-load-more="true"
                :on-infinite-load="onInfiniteLoad"
                :parent-pull-up-state="pullUpState">
                <div class="user-grid">
                  <div
                    v-for="(it,index) in userList"
                    :key="index"
                    class="user-card">
                    <div class="user-photo">
                      <img :src="it.avatar" @click="openUserInfo(it.userId)"/>
                      <div class="remove-btn" @click="statusBlackClick(it)">
                        <img src="@/assets/image/sdk/ic-blacklist-remove.png" alt="Remove"/>
                      </div>
                      <div class="user-info-overlay">
                        <div class="user-name">{{ it.nickname }}</div>
                        <div class="user-age">{{ it.age}}</div>
                      </div>
                    </div>
                  </div>
                </div>
                <m-empty-state v-if="!userList.length && !loading" message="Nothing Here Yet." />
              </m-list-pull-up-reload>
            </m-list-drop-down-refresh>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>

import MListDropDownRefresh from "@/components/MListDropDownRefresh.vue";
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import request from "@/utils/Request";
import {statusBlack} from "@/api/sdk/user";
import {openAnchorUserDetail} from "@/utils/PageUtils";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'BlackList',
  components: {MListDropDownRefresh, MListPullUpReload, MEmptyState},
  data() {
    return {
      loading: false,
      userList: [],
      page: 1, // 从 1 开始
      size: 20,
      hasMore: true,
      pullUpState: 0 // 0: 隐藏, 1: 加载更多, 2: 加载中, 3: 没有数据
    }
  },
  methods: {
    openUserInfo(userId) {
      // 跳转到用户详情页
      openAnchorUserDetail(userId);
    },
    updateListTop() {
      // 直接获取 action-bar 的高度，设置列表容器的 top 位置
      this.$nextTick(() => {
        const actionBar = this.$el.querySelector('.m-action-bar');
        const listContainer = this.$refs.listContainer;
        if (actionBar && listContainer) {
          const actionBarHeight = actionBar.offsetHeight;
          listContainer.style.top = `${actionBarHeight}px`;
        }
      });
    },
    // 加载黑名单数据
    async loadBlackList(page = 1) {
      if (this.loading) return;

      this.loading = true;
      try {
        const params = {
          page: page,
          size: this.size
        };

        const rsp = await request({
          url: 'userStatus/getBlackList',
          method: 'post',
          data: params
        });

        let newData = [];
        // 支持 code === 200 或 code === 0 或 success === true
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success) && rsp.data) {
          // 如果返回的是数组，直接使用
          if (Array.isArray(rsp.data)) {
            newData = rsp.data;
          } else if (rsp.data.list && Array.isArray(rsp.data.list)) {
            // 如果返回的是对象，包含 list 字段
            newData = rsp.data.list;
          } else {
            console.warn('API 返回的数据格式不符合预期:', rsp.data);
            newData = [];
          }
        } else {
          console.warn('API 返回的 code 不是 200/0 或 success 不是 true:', rsp);
          newData = [];
        }

        if (page === 1) {
          // 刷新：替换数据
          this.userList = newData;
        } else {
          // 加载更多：追加数据
          this.userList = [...this.userList, ...newData];
        }

        // 更新上拉加载状态
        this.hasMore = newData.length >= this.size;
        this.page = page;

        if (page === 1) {
          this.pullUpState = this.hasMore ? 1 : (newData.length > 0 ? 3 : 0);
        }
      } catch (error) {
        console.error('加载黑名单失败:', error);
        throw error;
      } finally {
        this.loading = false;
      }
    },
    // 下拉刷新回调
    async onRefresh(refreshDone) {
      try {
        // 重置页码到第一页
        this.page = 1;
        this.hasMore = true;
        await this.loadBlackList(1);
        if (this.$refs.downRefresh) {
          this.$refs.downRefresh.refreshDone(true);
        }
        if (refreshDone) {
          refreshDone(true);
        }
      } catch (error) {
        console.error('刷新失败:', error);
        if (this.$refs.downRefresh) {
          this.$refs.downRefresh.refreshDone(false);
        }
        if (refreshDone) {
          refreshDone(false);
        }
      }
    },
    // 上拉加载更多回调
    async onInfiniteLoad() {
      if (this.hasMore && !this.loading) {
        await this.loadBlackList(this.page);
      }
    },
    async statusBlackClick(it) {
      // 取消拉黑，传递 black: false
      try {
        const rsp = await statusBlack(it.userId, false);
        if (rsp && (rsp.success || rsp.code === 200 || rsp.code === 0)) {
          showCallToast('User removed from blacklist');
          // 刷新列表
          await this.onRefresh();
        } else {
          showCallToast('Failed to remove user from blacklist');
        }
      } catch (error) {
        console.error('Remove from blacklist error:', error);
        showCallToast('Failed to remove user from blacklist');
      }
    }
  },
  mounted() {
    // 先设置初始位置，避免内容显示在顶部
    this.updateListTop();

    // 首次加载
    this.loadBlackList(1);

    // 确保位置正确（延迟执行，确保 action-bar 已渲染）
    setTimeout(() => {
      this.updateListTop();
    }, 100);
  },
  activated() {
    // keep-alive 激活时更新位置
    this.updateListTop();
  },
  beforeRouteLeave(to, from, next) {
    // 离开页面时，重置滚动位置，避免影响其他页面
    // 重置列表容器的滚动位置
    const listWrap = this.$refs.listContainer && this.$refs.listContainer.querySelector('.list-wrap');
    if (listWrap) {
      listWrap.scrollTop = 0;
    }
    // 重置页面滚动容器的滚动位置
    const scrollContainer = document.querySelector('.m-page-content');
    if (scrollContainer) {
      scrollContainer.scrollTop = 0;
    }
    // 也重置 window 滚动位置
    if (window) {
      window.scrollTo(0, 0);
    }
    // 重置 document.body 和 document.documentElement 的滚动位置
    if (document.body) {
      document.body.scrollTop = 0;
    }
    if (document.documentElement) {
      document.documentElement.scrollTop = 0;
    }
    next();
  }
}
</script>

<style scoped lang="less">
/* 顶部安全区域适配 */
/deep/ .m-action-bar {
  padding-top: constant(safe-area-inset-top); /* iOS < 11.2，状态栏高度 */
  padding-top: env(safe-area-inset-top); /* 状态栏高度 */
}

.main {
  background-color: #141414;
  min-height: 100vh;
  padding: 0 0 20px;
  box-sizing: border-box;
  position: relative;
  height: 100vh;
  overflow: hidden;
}

/* 列表容器 - 固定定位，动态设置 top */
.list-container {
  position: fixed;
  left: 0;
  right: 0;
  top: 70px; /* 初始值，会被 updateListTop() 动态更新 */
  bottom: 0;
  padding-bottom: 20px;
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
    margin-top: -130px;
  }

  /deep/ .load-mobile {
    background: transparent;
  }
}

.user-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
  padding: 20px;
  padding-bottom: 20px;
  box-sizing: border-box;
}

.user-card {
  background-color: #282828;
  border-radius: 12px;
  overflow: hidden;
  position: relative;
}

.user-photo {
  width: 100%;
  padding-top: 133.33%; /* 3:4 比例 */
  position: relative;
  overflow: hidden;

  > img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    cursor: pointer;
  }

  .remove-btn {
    position: absolute;
    top: 15px;
    right: 15px;
    width: 22px;
    height: 22px;
    background-color: white;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: opacity 0.2s;
    z-index: 2;

    img {
      width: 16px;
      height: 16px;
      object-fit: contain;
    }

    &:active {
      opacity: 0.7;
    }
  }

  .user-info-overlay {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 12px;
    background: linear-gradient(to top, rgba(0, 0, 0, 0.6), transparent);
    z-index: 1;

    .user-name {
      font-size: 14px;
      font-weight: 500;
      color: white;
      margin-bottom: 2px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .user-age {
      font-size: 12px;
      color: white;
    }
  }
}
</style>
