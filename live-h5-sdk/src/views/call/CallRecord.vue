<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="'Call Records'" style="font-weight: 700;font-size: 18px">
      </m-action-bar>
    </template>
    <template #page-content-wrap>
      <div class="page">
        <m-list-drop-down-refresh :on-refresh="onRefresh">
          <m-list-pull-up-reload 
            :open-load-more="true"
            :on-infinite-load="onLoadMore"
            :parent-pull-up-state="pullUpState">
            <div class="list">
              <div v-for="item in records" :key="item.key" class="row" @click="openChat(item.userId)">
                <img class="avatar" :src="item.avatar || defaultAvatar" alt="" @click="openAnchorUserDetail(item.userId)"/>
                <div class="meta">
                  <div class="top">
                    <div class="name-wrapper">
                      <p class="name">{{ item.nickname }}</p>
                      <div class="user-meta">
                        <span class="flag-icon" v-if="item.country">{{ getCountryFlag(item.country) }}</span>
                        <div class="age-badge" :style="{ backgroundImage: `url(${getGenderBadgeBg()})` }">
                          <span class="badge-text">{{ item.age }}</span>
                        </div>
                      </div>
                    </div>
                    <p class="time">{{ formatClock(item.time * 1000) }}</p>
                  </div>
                  <div class="bottom">
                    <img class="type-icon" :src="item.icon"/>
                    <p class="desc">{{ getCallStatusText(item) }}</p>
                  </div>
                </div>
              </div>
              <m-empty-state v-if="!records.length && !loading" message="Nothing Here Yet." />
            </div>
          </m-list-pull-up-reload>
        </m-list-drop-down-refresh>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MActionBar from "@/components/MActionBar.vue";
import MPageWrap from "@/components/MPageWrap.vue";
import MListDropDownRefresh from "@/components/MListDropDownRefresh.vue";
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import {openAnchorUserDetail, openChat} from "@/utils/PageUtils";
import {getCallHistory} from "@/api/sdk/call";
import {getCountryFlagEmojiByCode} from "@/utils/Utils";
import {CALL_STATUS} from "@/utils/Constant";


export default {
  name: 'PageCallRecord',
  components: {MPageWrap, MActionBar, MListDropDownRefresh, MListPullUpReload, MEmptyState},
  data() {
    return {
      loading: false,
      records: [],
      defaultAvatar: require('@/assets/image/sdk/ic-logo.png'),
      currentPage: 0,
      pageSize: 20,
      hasMore: true,
      pullUpState: 0
    }
  },
  mounted() {
    this.loadCallHistory(1);
  },
  methods: {
    openAnchorUserDetail,
    openChat,
    async onRefresh(refreshDone) {
      try {
        this.currentPage = 0;
        this.hasMore = true;
        this.pullUpState = 0;
        this.records = [];
        
        await this.loadCallHistory(1);
        
        this.pullUpState = this.hasMore ? 1 : 3;
        
        refreshDone && refreshDone(true);
      } catch (error) {
        console.error('刷新失败:', error);
        refreshDone && refreshDone(false);
      }
    },
    /**
     * 上拉加载更多回调
     */
    async onLoadMore() {
      if (!this.hasMore || this.loading) {
        return;
      }
      
      try {
        this.pullUpState = 2; // 加载中
        const nextPage = this.currentPage + 1;
        await this.loadCallHistory(nextPage);
        
        // 更新上拉加载状态
        this.pullUpState = this.hasMore ? 1 : 3;
      } catch (error) {
        console.error('加载更多失败:', error);
        this.pullUpState = 1; // 恢复为可加载状态
      }
    },
    /**
     * 从 API 加载通话历史
     */
    async loadCallHistory(page = 1) {
      if (this.loading) return;
      
      this.loading = true;
      try {
        const res = await getCallHistory(page, this.pageSize);
        if (res && res.data) {
          // 处理不同的响应格式
          let list = [];
          if (Array.isArray(res.data)) {
            list = res.data;
          } else if (res.data.list && Array.isArray(res.data.list)) {
            list = res.data.list;
          } else if (res.data.records && Array.isArray(res.data.records)) {
            list = res.data.records;
          } else if (res.data.data && Array.isArray(res.data.data)) {
            list = res.data.data;
          }
          
          // 转换 API 数据格式为组件需要的格式
          const convertedRecords = list.map(item => this.convertApiRecordToRecord(item));
          
          if (page === 1) {
            this.records = convertedRecords;
          } else {
            this.records = [...this.records, ...convertedRecords];
          }
          
          this.hasMore = list.length >= this.pageSize;
          this.currentPage = page;
          
          if (page === 1) {
            this.pullUpState = this.hasMore ? 1 : (list.length > 0 ? 3 : 0);
          }
        }
      } catch (error) {
        console.error('加载通话历史失败:', error);
      } finally {
        this.loading = false;
      }
    },
    /**
     * 将 API 返回的记录转换为组件需要的格式
     */
    convertApiRecordToRecord(apiItem) {
      // 获取 matchCall 字段（接口返回）
      const matchCall = apiItem.matchCall || false;
      
      // 计算时间戳（如果 createTime 是字符串，需要转换）
      let time = 0;
      if (apiItem.createTime) {
        time = typeof apiItem.createTime === 'string' 
          ? new Date(apiItem.createTime).getTime() / 1000 
          : apiItem.createTime;
      }
      
      return {
        key: `api-${apiItem.id || apiItem.callId || Date.now()}`,
        userId: apiItem.userId,
        nickname: apiItem.nickname || 'Unknown',
        avatar: apiItem.avatar || null,
        time: time,
        duration: apiItem.callTime || 0, // callTime 可能是通话时长（秒）
        callStatus: apiItem.callStatus, // 保存通话状态
        matchCall: matchCall,
        icon: this.getIcon(matchCall),
        country: apiItem.country || null,
        age: apiItem.age || null,
        // 保留原始数据，以便后续使用
        rawData: apiItem
      };
    },
    /**
     * 根据 matchCall 字段获取对应的图标
     * @param {boolean} matchCall - 是否为匹配通话
     */
    getIcon(matchCall) {
      return matchCall
        ? require('@/assets/image/call/call-record/ic-call-records-match.png')
        : require('@/assets/image/call/call-record/ic-call-records-call.png');
    },
    formatClock(ms) {
      const d = new Date(ms);
      return d.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit'});
    },
    formatDuration(seconds) {
      const s = Math.max(0, parseInt(seconds || 0, 10));
      const hh = Math.floor(s / 3600);
      const mm = Math.floor((s % 3600) / 60);
      const ss = s % 60;
      const pad = (n) => (n < 10 ? '0' + n : '' + n);
      if (hh > 0) {
        return `${pad(hh)}:${pad(mm)}:${pad(ss)}`;
      }
      return `${pad(mm)}:${pad(ss)}`;
    },
    /**
     * 获取通话状态文字
     * 根据callStatus字段显示对应的状态文字或通话时长
     * @param {object} item - 通话记录项
     */
    getCallStatusText(item) {
      const callStatus = item.callStatus;
      const duration = item.duration || 0;
      
      // 如果callStatus为空，显示通话时长
      if (callStatus === null || callStatus === undefined) {
        return this.formatDuration(duration);
      }
      
      // 根据callStatus返回对应的文字（支持code和value两种格式）
      switch (callStatus) {
        case CALL_STATUS.CALL_DONE.code:
        case CALL_STATUS.CALL_DONE.value:
          // 通话结束，显示通话时长
          return this.formatDuration(duration);
        case CALL_STATUS.CANCEL_CALL.code:
        case CALL_STATUS.CANCEL_CALL.value:
        case CALL_STATUS.CALLING.code:
        case CALL_STATUS.CALLING.value:
          return "Canceled";
        case CALL_STATUS.REFUSE.code:
        case CALL_STATUS.REFUSE.value:
          return "Declined";
        case CALL_STATUS.CALL_TIMEOUT_DONE.code:
        case CALL_STATUS.CALL_TIMEOUT_DONE.value:
          return "Missed";
        case CALL_STATUS.CREATE.code:
        case CALL_STATUS.CREATE.value:
          // 通话创建（未接通），显示状态文字
          return "Missed";
        case CALL_STATUS.ANSWER.code:
        case CALL_STATUS.ANSWER.value:
          // 接听，显示通话时长
          return this.formatDuration(duration);
        case CALL_STATUS.CALL_ERROR_DONE.code:
        case CALL_STATUS.CALL_ERROR_DONE.value:
          // 异常挂断（未接通）
          return "Missed";
        case CALL_STATUS.CALLING_ERROR_DONE.code:
        case CALL_STATUS.CALLING_ERROR_DONE.value:
          // 异常挂断（已接通），显示通话时长
          return this.formatDuration(duration);
        case CALL_STATUS.NOT_BALANCE_DONE.code:
        case CALL_STATUS.NOT_BALANCE_DONE.value:
          // 余额不足结束，显示通话时长
          return this.formatDuration(duration);
        case CALL_STATUS.SYSTEM_STOP.code:
        case CALL_STATUS.SYSTEM_STOP.value:
          // 系统终止，显示通话时长
          return this.formatDuration(duration);
        default:
          // 其他未知状态，如果时长为0则显示状态文字，否则显示通话时长
          if (duration > 0) {
            return this.formatDuration(duration);
          }
          return "Missed";
      }
    },
    /**
     * 获取国家旗帜
     */
    getCountryFlag(country) {
      if (!country) return '🌐';
      return getCountryFlagEmojiByCode(country);
    },
    /**
     * 获取性别徽章背景（固定显示女性）
     */
    getGenderBadgeBg() {
      // 固定显示女性徽章
      return require('@/assets/image/sdk/ic-userdetail-girl.png');
    }
  }
}
</script>

<style scoped lang="less">
.page {
  height: 100%;
}


:deep(.refresh-mobile) {
  min-height: 100%;
  background: transparent;
}

:deep(.load-mobile) {
  background: transparent;
}

.list {
  padding: 0 18px 18px;
  box-sizing: border-box;
  min-height: 100%;
}

.row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 0;
}

.avatar {
  width: 56px;
  height: 56px;
  border-radius: 28px;
  object-fit: cover;
}

.meta {
  flex: 1;
  min-width: 0;
}

.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.name-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.name {
  font-size: 18px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.95);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.user-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;

  .flag-icon {
    display: inline-block;
    font-size: 20px;
    line-height: 1;
    vertical-align: middle;
    object-fit: cover;
    border-radius: 50%;
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
      margin-left: 15px;
      font-size: 14px;
      font-weight: 700;
      color: #ffffff;
      line-height: 1;
    }
  }
}


.time {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  flex-shrink: 0;
}

.bottom {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.type-icon {
  width: 18px;
  height: 18px;
  object-fit: contain;
  flex-shrink: 0;
}

.desc {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.55);
}

.desc.missed {
  color: rgba(255, 255, 255, 0.55);
}

.empty {
  padding: 40px 0;
  text-align: center;
  color: rgba(255, 255, 255, 0.45);
}
</style>
