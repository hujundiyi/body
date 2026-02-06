<template>
  <m-page-wrap :show-action-bar="true" :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar title="Coin Transactions" style="font-weight: 700;font-size: 18px">
      </m-action-bar>
    </template>
    <template #page-content-wrap>
      <div class="page">
        <m-list-pull-up-reload 
          :open-load-more="true"
          :on-infinite-load="onLoadMore"
          :parent-pull-up-state="pullUpState">
          <div class="list">
            <div v-for="(item, index) in transactions" :key="item.consumeId || index" class="transaction-item">
              <div class="left">
                <p class="time">{{ formatTime(item.createTime) }}</p>
                <p class="type">{{ item.coinChangeType_dict }}</p>
              </div>
              <div class="right">
                <span class="amount" :class="item.spendCoin >= 0 ? 'positive' : 'negative'">
                  {{ formatAmount(item.spendCoin) }}
                </span>
              </div>
            </div>
            <m-empty-state v-if="!transactions.length && !loading" message="Nothing Here Yet." />
          </div>
        </m-list-pull-up-reload>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MActionBar from "@/components/MActionBar.vue";
import MPageWrap from "@/components/MPageWrap.vue";
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MEmptyState from "@/components/MEmptyState.vue";
import {getCoinTransactionList} from "@/api/sdk/commodity";

export default {
  name: 'CoinDetails',
  components: {MPageWrap, MActionBar, MListPullUpReload, MEmptyState},
  data() {
    return {
      loading: false,
      transactions: [],
      currentPage: 1,
      pageSize: 20,
      hasMore: true,
      pullUpState: 0
    }
  },
  mounted() {
    this.loadTransactions(1);
  },
  methods: {
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
        await this.loadTransactions(nextPage);
        
        // 更新上拉加载状态
        this.pullUpState = this.hasMore ? 1 : 3;
      } catch (error) {
        console.error('加载更多失败:', error);
        this.pullUpState = 1; // 恢复为可加载状态
      }
    },
    /**
     * 从 API 加载交易记录
     */
    async loadTransactions(page = 1) {
      if (this.loading) return;
      
      this.loading = true;
      try {
        const res = await getCoinTransactionList(page, this.pageSize);
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
          
          if (page === 1) {
            this.transactions = list;
          } else {
            this.transactions = [...this.transactions, ...list];
          }
          
          this.hasMore = list.length >= this.pageSize;
          this.currentPage = page;
          
          if (page === 1) {
            this.pullUpState = this.hasMore ? 1 : (list.length > 0 ? 3 : 0);
          }
        }
      } catch (error) {
        console.error('加载交易记录失败:', error);
      } finally {
        this.loading = false;
      }
    },
    /**
     * 格式化时间显示
     * 支持 Unix 时间戳（秒级）和 ISO 字符串格式
     * 最近24小时内的显示为 "17:49 PM" 格式
     * 超过24小时的显示为 "2025.01.13 16:30" 格式
     */
    formatTime(timeValue) {
      if (!timeValue) return '';
      
      let date;
      // 判断是否为时间戳（数字类型）
      if (typeof timeValue === 'number') {
        // 判断是秒级还是毫秒级时间戳
        // 如果小于 13 位数字，认为是秒级，需要乘以 1000
        if (timeValue < 1000000000000) {
          date = new Date(timeValue * 1000);
        } else {
          date = new Date(timeValue);
        }
      } else if (typeof timeValue === 'string') {
        // 如果是字符串，尝试解析为数字时间戳
        const numValue = Number(timeValue);
        if (!isNaN(numValue)) {
          if (numValue < 1000000000000) {
            date = new Date(numValue * 1000);
          } else {
            date = new Date(numValue);
          }
        } else {
          // 否则当作 ISO 字符串处理
          date = new Date(timeValue);
        }
      } else {
        return '';
      }
      
      // 检查日期是否有效
      if (isNaN(date.getTime())) {
        return '';
      }
      
      const now = new Date();
      const diffMs = now - date;
      const diffHours = diffMs / (1000 * 60 * 60);
      
      // 如果是在24小时内，显示时间格式 "17:49 PM"
      if (diffHours < 24) {
        return date.toLocaleTimeString('en-US', {
          hour: '2-digit',
          minute: '2-digit',
          hour12: true
        });
      }
      
      // 超过24小时，显示日期时间格式 "2025.01.13 16:30"
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');
      
      return `${year}.${month}.${day} ${hours}:${minutes}`;
    },
    /**
     * 格式化金额显示，带 +/- 符号
     */
    formatAmount(amount) {
      if (amount === 0) return '0';
      return amount > 0 ? `+${amount}` : `${amount}`;
    },
    /**
     * 获取交易类型文本
     * 根据 coinChangeType 的值返回对应的描述文本
     */
    getCoinChangeTypeText(coinChangeType) {
      // 交易类型映射表，根据实际业务需求调整
      const typeMap = {
        0: 'Coin Change',
        1: 'Recharge',
        2: 'Call',
        3: 'Gift',
        4: 'Refund',
        5: 'Withdrawal',
        // 可以根据实际业务添加更多类型
      };
      
      return typeMap[coinChangeType] || 'Coin Change';
    }
  }
}
</script>

<style scoped lang="less">
.page {
  height: 100%;
}

:deep(.load-mobile) {
  background: transparent;
}

.list {
  padding: 10px 18px 18px;
  box-sizing: border-box;
  min-height: 100%;
}

.transaction-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 0;
  //border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.left {
  flex: 1;
  min-width: 0;
}

.time {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.95);
  margin-bottom: 8px;
}

.type {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.55);
}

.right {
  flex-shrink: 0;
  margin-left: 12px;
}

.amount {
  font-size: 16px;
  color: #FFFFFF;
  
  &.positive {
    color:#FFFFFF;
  }
  
  &.negative {
    color: #999999;
  }
}
</style>
