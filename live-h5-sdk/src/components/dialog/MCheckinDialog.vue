<template>
  <m-base-dialog 
    ref="baseDialog" 
    :dialog-class="'checkin-dialog-wrapper'"
    :click-mask-close-dialog="false"
    width="90%"
  >
    <template #content>
      <div class="checkin-wrapper">
        <!-- 特殊日动画 -->
        <div v-if="specialDayAnimVisible" class="checkin-special-day-mask">
          <div class="special-day-animation">
            <img 
              v-if="membershipType === 'month'" 
              src="@/assets/image/checkin/ic-checkin-month-item-special.gif" 
              class="special-day-gif"
              alt="Special Day"
            />
            <img 
              v-else-if="membershipType === 'year' || membershipType === 'half-year'" 
              src="@/assets/image/checkin/ic-checkin-year-item-special.gif" 
              class="special-day-gif"
              alt="Special Day"
            />
          </div>
        </div>
        
        <!-- 奖励弹窗 -->
        <div v-if="rewardVisible" class="checkin-reward-mask">
          <div class="checkin-reward-card" :class="{ 'animate-scale': rewardAnimActive }">
            <img class="reward-title" :src="rewardTitleImg" alt="Rewards Claimed" />
            <img class="reward-coins" :src="rewardCoinsImg" alt="Coins" />
            <div class="reward-amount">x{{ formatNumber(rewardCoins) }}</div>
            <button class="reward-ok" type="button" @click="closeRewardDialog" aria-label="OK"></button>
          </div>
        </div>
        <div v-show="!rewardVisible" class="checkin-container" :class="{ 'is-week': membershipType === 'week', 'is-month': membershipType === 'month' || membershipType === 'year' || membershipType === 'half-year' }" :style="backgroundStyle">
          <!-- 标题区域 -->
          <div class="checkin-header" :class="{ 'is-week': membershipType === 'week', 'is-month': membershipType === 'month', 'is-year': membershipType === 'year' || membershipType === 'half-year' }">
            <div class="checkin-description">
              Complete Check-In To Get<br>
All <span class="highlight">{{ totalCoins }}</span> Premium Coins For Free.
            </div>
          </div>

          <!-- 周会员筛选标签 -->
<!--          <div class="checkin-filter" v-if="membershipType === 'week'">All</div>-->

          <div class="checkin-panel" :class="{ 'is-week': membershipType === 'week', 'is-month': membershipType === 'month', 'is-year': membershipType === 'year', 'is-half-year': membershipType === 'half-year' }">
            <!-- 签到网格 -->
            <div class="checkin-grid" :class="`grid-${membershipType}`">
              <div
                v-for="(day, index) in checkinDays"
                :key="index"
                class="checkin-day-card"
                :class="{
                  'checked': day.checked,
                  'is-week': membershipType === 'week',
                  'is-week-last': membershipType === 'week' && day.dayNumber === 7,
                  'is-month': membershipType === 'month',
                  'is-year': membershipType === 'year' || membershipType === 'half-year'
                }"
                :style="getItemStyle(day)"
              >
                <div class="day-label" :style="getDayLabelStyle(day)">
                  Day {{ day.dayNumber }}
                </div>
                <div
                  class="day-icon"
                  :class="{ 'is-special': day.isSpecialDay, 'is-hidden': day.isSpecialDay && !day.checked }"
                >
                  <!-- 周、月、年签到统一图标逻辑 -->
                  <img 
                    v-if="!day.isSpecialDay" 
                    src="@/assets/image/checkin/ic-checkin-coin.png" 
                    class="coin-icon-normal"
                    alt="Coin"
                  />
                  <!-- 已签到图标 -->
                  <div v-if="day.checked" class="checked-icon-wrapper">
                    <img 
                      v-if="membershipType === 'week'" 
                      src="@/assets/image/checkin/ic-checkin-week-check.png" 
                      class="checked-icon"
                      alt="Checked"
                    />
                    <img 
                      v-else-if="membershipType === 'month'" 
                      src="@/assets/image/checkin/ic-checkin-month-check.png" 
                      class="checked-icon"
                      alt="Checked"
                    />
                    <img 
                      v-else-if="membershipType === 'year' || membershipType === 'half-year'" 
                      src="@/assets/image/checkin/ic-checkin-year-check.png" 
                      class="checked-icon"
                      alt="Checked"
                    />
                  </div>
                </div>
                <div v-if="!day.isSpecialDay" class="day-amount">{{ formatNumber(day.coins) }}</div>
                <div v-else class="day-amount placeholder"></div>
              </div>
            </div>

            <!-- 当前金币余额 -->
            <div class="coin-balance-wrap" :class="{ 'is-week': membershipType === 'week', 'is-month': membershipType === 'month', 'is-year': membershipType === 'year' || membershipType === 'half-year' }">
              <div class="coin-balance" :class="{ 'is-animating': coinAnimActive }">
                <img src="@/assets/image/match/ic-match-coin@2x.png" class="balance-coin-icon" />
                <span>Coins: {{ formatNumber(displayedCoinBalance) }}</span>
              </div>
            </div>

            <!-- 签到按钮 -->
            <div 
              class="checkin-button" 
              :class="{ 'checked-in': hasCheckedInToday || allCheckedIn, 'is-week': membershipType === 'week', 'is-month': membershipType === 'month', 'is-year': membershipType === 'year' || membershipType === 'half-year' }"
              :style="getButtonStyle()"
              @click="!(hasCheckedInToday || allCheckedIn) && handleCheckIn()"
            >
              {{ hasCheckedInToday || allCheckedIn ? 'Checked In' : 'Check In' }}
            </div>
          </div>
        </div>

        <!-- 关闭按钮 - 底部居中 -->
        <div v-show="!rewardVisible" class="close-button-bottom" @click.stop="closeDialog">
          <img src="@/assets/image/checkin/ic-checkin-close.png" class="close-icon-bottom" alt="Close" />
        </div>
      </div>
    </template>
  </m-base-dialog>
</template>

<script>
import MBaseDialog from "@/components/dialog/MBaseDialog.vue";
import { toast } from "@/components/toast";
import { getCheckinInfo, doCheckin } from "@/api/sdk/user";
import { hideLoading, showLoading } from "@/components/MLoading";
import { DialogTaskArray } from "@/components/dialog/DialogTaskArray";

export default {
  name: 'MCheckinDialog',
  components: { MBaseDialog },
  props: {
    // 用于调试：可以传入测试用的 vipCategory (1=周, 2=月, 3=年)
    testVipCategory: {
      type: Number,
      default: null
    }
  },
  data() {
    return {
      checkinDays: [],
      hasCheckedInToday: false,
      currentDay: 1,
      totalCoins: 0,
      dailyCoins: 0,
      rewardVisible: false,
    rewardCoins: 0,
    rewardTitleImg: require('@/assets/image/checkin/ic-checkin-rc-title.png'),
    rewardCoinsImg: require('@/assets/image/checkin/ic-checkin-rc-coins.png'),
    rewardAnimActive: false,
    specialDayAnimVisible: false,
    displayedCoinBalance: 0,
    coinAnimFrameId: null,
    coinAnimTimeout: null,
      coinAnimActive: false,
      pendingCoinBalance: null,
      suppressCoinBalanceSync: false
    };
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    dictData() {
      return this.$store.state.PageCache.dict || {};
    },
    vipCategoryDict() {
      const vipCategoryItem = Object.values(this.dictData).find(item => item.dictType === 'vip_category');
      return vipCategoryItem ? vipCategoryItem.dictItems : [];
    },
    membershipType() {
      // 根据 vipCategory 判断会员类型
      // 直接使用用户的实际 vipCategory 值
      const value = this.userInfo.vipCategory || 0;
      console.log('Using actual vipCategory:', value);
      
      // 根据 value (code) 映射到会员类型
      if (value === 1 || value === 20 || value === 21 || value === 22) return 'week';
      if (value === 31 || value === 32) return 'month';
      if (value === 33) return 'half-year';
      if (value === 41 || value === 42 || value === 43) return 'year';
      
      // 默认返回周会员（如果没有会员，可能不显示，但这里做容错处理）
      return 'week';
    },
    titleText() {
      const titles = {
        week: 'Weekly Premium Check-In Rewards',
        month: 'Monthly Premium Check-In Rewards',
        year: 'Annual Premium Check-In Rewards',
        'half-year': 'Half-Year Premium Check-In Rewards'
      };
      return titles[this.membershipType] || titles.week;
    },
    backgroundStyle() {
      const backgrounds = {
        week: require('@/assets/image/checkin/ic-checkin-week-bg.png'),
        month: require('@/assets/image/checkin/ic-checkin-month-bg.png'),
        year: require('@/assets/image/checkin/ic-checkin-year-bg.png'),
        'half-year': require('@/assets/image/checkin/ic-checkin-half-year-bg.png')
      };
      const isWeek = this.membershipType === 'week';
      const isMonth = this.membershipType === 'month';
      return {
        backgroundImage: `url(${backgrounds[this.membershipType] || backgrounds.week})`,
        backgroundSize: '100% 100%',
        backgroundPosition: 'center',
        backgroundRepeat: 'no-repeat'
      };
    },
    totalDays() {
      const days = {
        week: 7,
        month: 30,
        year: 30,
        'half-year': 30
      };
      return days[this.membershipType] || 7;
    },
    allCheckedIn() {
      return this.checkinDays.length > 0 && this.checkinDays.every(day => day.checked || day.isCheckin);
    }
  },
  mounted() {
    this.loadCheckinData();
    this.displayedCoinBalance = this.userInfo.coinBalance || 0;
  },
  watch: {
    'userInfo.coinBalance'(value) {
      if (!this.rewardVisible && !this.coinAnimFrameId && !this.suppressCoinBalanceSync) {
        this.displayedCoinBalance = value || 0;
      }
    }
  },
  methods: {
    loadCheckinData() {
      // 尝试从API获取签到数据，如果API不存在则使用模拟数据
      getCheckinInfo().then((res) => {
        if (res && (res.code === 200 || res.code === 0 || res.success) && res.data) {
          // 使用API返回的数据
          const data = res.data;
          this.currentDay = data.currentDay || 1;
          this.hasCheckedInToday = data.hasCheckedInToday || false;
          this.totalCoins = data.totalCoin;
          this.dailyCoins = data.dailyCoins;
          
          if (data.rewards && Array.isArray(data.rewards)) {
            // 将rewards数组转换为checkinDays格式（兼容多种后端字段名）
            this.checkinDays = data.rewards.map((reward, index) => ({
              dayNumber: reward.day,
              coins: reward.baseReward,
              checked: reward.isCheckin,
              isSpecialDay: !!(reward.isSpecialDay ?? reward.specialDay ?? reward.is_special_day)
            }));
          } else if (data.checkinDays && Array.isArray(data.checkinDays)) {
            this.checkinDays = data.checkinDays;
          } else {
            this.initCheckinDays();
          }
          
          // 进入界面后，滑动到最新待签到的那行
          this.scrollToCurrentDay();
        } else {
          // 如果API调用失败，使用模拟数据
          this.initCheckinDays();
          // 进入界面后，滑动到最新待签到的那行
          this.scrollToCurrentDay();
        }
      }).catch((error) => {
        console.error('获取签到数据失败:', error);
        // 如果API不存在，使用模拟数据
        this.initCheckinDays();
        // 进入界面后，滑动到最新待签到的那行
        this.scrollToCurrentDay();
      });
    },
    refreshCheckinStatus() {
      // 刷新签到状态，重新获取签到数据
      this.loadCheckinData();
    },
    scrollToCurrentDay() {
      // 进入界面时，滑动到最新待签到的那行
      this.$nextTick(() => {
        const checkinGrid = document.querySelector('.checkin-grid');
        if (checkinGrid) {
          // 计算当前待签到的位置
          const currentIndex = Math.max(0, this.currentDay - 1);
          // 计算需要滚动的位置，假设每个签到卡片的高度为100px
          const scrollPosition = Math.floor(currentIndex / 4) * 120; // 4列，每列高度100px，间距10px
          checkinGrid.scrollTop = scrollPosition;
        }
      });
    },
    initCheckinDays() {
      // 初始化签到数据（模拟数据）
      const days = [];
      for (let i = 1; i <= this.totalDays; i++) {
        days.push({
          dayNumber: i,
          coins: this.dailyCoins,
          checked: i < this.currentDay
        });
      }
      this.checkinDays = days;
      this.hasCheckedInToday = this.currentDay <= this.totalDays && 
                                this.checkinDays[this.currentDay - 1]?.checked || false;
    },
    formatNumber(num) {
      if (!num) return '0';
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    },
    getItemStyle(day) {
      if (this.membershipType === 'week') {
        const isLast = day.dayNumber === 7;
        const bg = isLast
          ? (day.checked
            ? require('@/assets/image/checkin/ic-checkin-week-item-7-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-week-item-7-usign-bg.png'))
          : (day.checked
            ? require('@/assets/image/checkin/ic-checkin-week-item-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-week-item-nsign-bg.png'));
        const style = {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
        // 已签到的白色叠加层处理
        if (day.checked) {
          style.backgroundColor = 'rgba(255, 255, 255, 0.7)';
          style.backgroundBlendMode = 'overlay';
        }
        return style;
      }
      if (this.membershipType === 'month') {
        const isChecked = day.checked;
        let bg;
        
        // 检查是否是特殊日
        if (day.isSpecialDay) {
          // 特殊日背景图
          bg = isChecked
            ? require('@/assets/image/checkin/ic-checkin-month-item-special-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-month-item-special-nsign-bg.png');
        } else {
          // 常规日背景图
          bg = isChecked
            ? require('@/assets/image/checkin/ic-checkin-month-item-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-month-item-nsign-bg.png');
        }
        
        const style = {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
        // 已签到的白色叠加层处理
        if (isChecked) {
          style.backgroundColor = 'rgba(255, 255, 255, 0.7)';
          style.backgroundBlendMode = 'overlay';
        }
        return style;
      }
      if (this.membershipType === 'year' || this.membershipType === 'half-year') {
        const isChecked = day.checked;
        let bg;
        
        // 检查是否是特殊日
        if (day.isSpecialDay) {
          // 特殊日背景图
          bg = isChecked
            ? require('@/assets/image/checkin/ic-checkin-year-item-special-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-year-item-special-usign-bg.png');
        } else {
          // 常规日背景图
          bg = isChecked
            ? require('@/assets/image/checkin/ic-checkin-year-item-sign-bg.png')
            : require('@/assets/image/checkin/ic-checkin-year-item-nsign-bg.png');
        }
        
        const style = {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
        // 已签到的白色叠加层处理
        if (isChecked) {
          style.backgroundColor = 'rgba(255, 255, 255, 0.7)';
          style.backgroundBlendMode = 'overlay';
        }
        return style;
      }
      return {};
    },
    getDayLabelStyle(day) {
      // 根据日期数字动态调整right值
      // Day 10或以后的使用right: 3px，其他的使用right: 6px
      if (this.membershipType === 'month' || this.membershipType === 'year' || this.membershipType === 'half-year') {
        if (day.dayNumber >= 10) {
          return { right: '3px' };
        } else {
          return { right: '6px' };
        }
      }
      // 周签到保持原有样式
      return {};
    },
    getButtonStyle() {
      const isChecked = this.hasCheckedInToday || this.allCheckedIn;
      if (this.membershipType === 'week') {
        const bg = isChecked
          ? require('@/assets/image/checkin/ic-checkin-week-btn-bg.png')
          : require('@/assets/image/checkin/ic-checkin-week-btn-u-bg.png');
        return {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
      }
      if (this.membershipType === 'month') {
        const bg = isChecked
          ? require('@/assets/image/checkin/ic-checkin-month-btn-bg.png')
          : require('@/assets/image/checkin/ic-checkin-month-btn-u-bg.png');
        return {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
      }
      if (this.membershipType === 'year' || this.membershipType === 'half-year') {
        const bg = isChecked
          ? require('@/assets/image/checkin/ic-checkin-year-btn-bg.png')
          : require('@/assets/image/checkin/ic-checkin-year-btn-u-bg.png');
        return {
          backgroundImage: `url(${bg})`,
          backgroundSize: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center'
        };
      }
      return {};
    },
    handleCheckIn() {
      if (this.hasCheckedInToday) {
        toast('You have already checked in today');
        return;
      }

      showLoading();
      doCheckin().then((res) => {
        hideLoading();
        if (res && (res.code === 200 || res.code === 0 || res.success)) {
          const data = res.data || {};
          this.suppressCoinBalanceSync = true;
          // 更新签到状态（用 $set 保证 Vue 响应式，UI 会立即刷新）
          let todayIndex = this.currentDay - 1;
          if (
            todayIndex < 0 ||
            todayIndex >= this.checkinDays.length ||
            this.checkinDays[todayIndex]?.checked
          ) {
            // 若 currentDay 指向已签到或越界，回退到首个未签到日
            const firstUncheckedIndex = this.checkinDays.findIndex((day) => !day.checked);
            if (firstUncheckedIndex !== -1) {
              todayIndex = firstUncheckedIndex;
            }
          }
          if (todayIndex >= 0 && todayIndex < this.checkinDays.length) {
            this.$set(this.checkinDays[todayIndex], 'checked', true);
            this.hasCheckedInToday = true;

            // 更新到下一天
            if (todayIndex + 1 < this.checkinDays.length) {
              this.currentDay = todayIndex + 2;
            }
          }
          
          // 延迟更新用户金币余额，等奖励弹窗关闭后再刷新
          if (data.coinBalance !== undefined) {
            this.pendingCoinBalance = data.coinBalance;
          }
          
          // 检查当前签到的是否是特殊日
          // 优先使用签到接口返回的 isSpecialDay / specialDay / is_special_day，其次用列表里当天的 isSpecialDay
          const currentDay = this.checkinDays[todayIndex];
          const isSpecialDayFromApi = !!(data.isSpecialDay ?? data.specialDay ?? data.is_special_day);
          const isSpecialDay = isSpecialDayFromApi || (currentDay && currentDay.isSpecialDay);
          // 从接口返回的数据中获取baseReward和extraReward，计算总和作为奖励金币数
          this.rewardCoins = (data.baseReward || 0) + (data.extraReward || 0);
          
          if (isSpecialDay && (this.membershipType === 'month' || this.membershipType === 'year' || this.membershipType === 'half-year')) {
            // 特殊日签到，先显示特殊日动画
            this.openSpecialDayAnimation();
          } else {
            // 普通签到，直接显示奖励弹窗
            this.openRewardDialog(this.rewardCoins);
          }
          // toast('Check-in successful!');
        } else {
          toast(res.msg || 'Check-in failed');
          this.suppressCoinBalanceSync = false;
        }
      }).catch((error) => {
        hideLoading();
        console.error('签到失败:', error);
        toast('Check-in failed. Please try again later.');
        this.suppressCoinBalanceSync = false;
      });
    },
    openRewardDialog(coins) {
      this.rewardCoins = coins || 0;
      this.rewardVisible = true;
      // 触发从小到大的缩放动画
      this.$nextTick(() => {
        this.rewardAnimActive = true;
      });
    },
    closeRewardDialog() {
      this.rewardVisible = false;
      this.rewardAnimActive = false;
      if (this.pendingCoinBalance !== null && this.pendingCoinBalance !== undefined) {
        const userInfo = { ...this.userInfo, coinBalance: this.pendingCoinBalance };
        this.$store.commit('user/SET_USERINFO', userInfo);
        const cache = require('@/utils/cache').default;
        const { key_cache } = require('@/utils/Constant');
        cache.local.setJSON(key_cache.user_info, userInfo);
        this.pendingCoinBalance = null;
      }
      this.suppressCoinBalanceSync = false;
      this.animateCoinBalance(this.rewardCoins);
    },
    openSpecialDayAnimation() {
      this.specialDayAnimVisible = true;
      // 只有月、年和半年会员需要特殊日动画，根据用户提供的具体时长设置
      let animationDuration = 2500; // 默认2.5秒
      
      if (this.membershipType === 'month') {
        // 月会员特殊日动画播放时间：2.5秒
        animationDuration = 2500;
      } else if (this.membershipType === 'year' || this.membershipType === 'half-year') {
        // 年和半年会员特殊日动画播放时间：2.6秒
        animationDuration = 2600;
      }
      
      // 手动控制动画的显示和隐藏，根据不同会员类型设置不同的播放时间
      setTimeout(() => {
        this.specialDayAnimVisible = false;
        // 动画播放完成后显示奖励弹窗
        this.openRewardDialog(this.rewardCoins);
      }, animationDuration);
    },
    onSpecialDayAnimEnd() {
      // 移除动画结束事件的处理，因为我们现在手动控制动画的显示和隐藏
    },
    animateCoinBalance(addedCoins) {
      if (!addedCoins) return;
      const current = this.displayedCoinBalance || 0;
      let target = this.userInfo.coinBalance || 0;
      if (target <= current) {
        this.displayedCoinBalance = target;
        return;
      }
      if (target < current + addedCoins) {
        target = current + addedCoins;
        const userInfo = { ...this.userInfo, coinBalance: target };
        this.$store.commit('user/SET_USERINFO', userInfo);
        const cache = require('@/utils/cache').default;
        const { key_cache } = require('@/utils/Constant');
        cache.local.setJSON(key_cache.user_info, userInfo);
      }
      const start = Math.max(target - addedCoins, 0);
      const duration = 900;
      const startTime = performance.now();

      this.displayedCoinBalance = start;
      if (this.coinAnimFrameId) {
        cancelAnimationFrame(this.coinAnimFrameId);
      }
      if (this.coinAnimTimeout) {
        clearTimeout(this.coinAnimTimeout);
      }
      this.coinAnimActive = true;
      this.coinAnimTimeout = setTimeout(() => {
        this.coinAnimActive = false;
      }, 900);

      const step = (now) => {
        const progress = Math.min((now - startTime) / duration, 1);
        const nextValue = Math.round(start + (target - start) * progress);
        this.displayedCoinBalance = nextValue;
        if (progress < 1) {
          this.coinAnimFrameId = requestAnimationFrame(step);
        } else {
          this.coinAnimFrameId = null;
          this.displayedCoinBalance = target;
        }
      };

      this.coinAnimFrameId = requestAnimationFrame(step);
    },
    closeDialog() {
      if (this.$refs.baseDialog) {
        this.$refs.baseDialog.dialogVisible = false;
        DialogTaskArray.pop();
      }
    }
  }
};
</script>

<style scoped lang="less">
.checkin-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
}

.checkin-special-day-mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.special-day-animation {
  display: flex;
  align-items: center;
  justify-content: center;
}

.special-day-gif {
  width: 80%;
  max-width: 300px;
  height: auto;
  animation: specialDayFadeIn 0.5s ease-in-out;
}

.checkin-reward-mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.checkin-reward-card {
  width: 88%;
  max-width: 320px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.checkin-reward-card.animate-scale {
  animation: scaleIn 0.5s ease-out;
}

@keyframes specialDayFadeIn {
  from {
    opacity: 0;
    transform: scale(0.8);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes scaleIn {
  from {
    opacity: 0;
    transform: scale(0.3);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.checkin-reward-card .reward-title {
  width: 100%;
  height: auto;
  display: block;
}

.checkin-reward-card .reward-coins {
  width: 86%;
  height: auto;
  display: block;
}

.checkin-reward-card .reward-amount {

  font-weight: 900;
  font-size: 28px;
  color: #FFFFFF;
  text-align: center;
  font-style: italic;
  text-transform: none;
  margin-top: -6px;
}

.checkin-reward-card .reward-ok {
  width: 90%;
  height: 52px;
  border: none;
  background: transparent;
  background-image: url("@/assets/image/checkin/ic-checkin-rc-ok.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;
  cursor: pointer;
  margin-top: 20px;
}

.checkin-container {
  position: relative;
  min-height: 500px;
  max-height: 90vh;
  border-radius: 20px;
  padding: 20px;
  box-sizing: border-box;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  background-color: transparent;
  width: 100%;
}

.checkin-container.is-week {
  padding-top: 190px;
  padding-bottom: 24px;
}

.checkin-container.is-month {
  padding-top: 190px;
  padding-bottom: 24px;
}

.checkin-container.is-year,
.checkin-container.is-half-year {
  padding-top: 190px;
  padding-bottom: 24px;
}

.close-button-bottom {
  position: relative;
  width: 32px;
  height: 32px;
  margin: 12px auto 0;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 10;
  
  .close-icon-bottom {
    width: 32px;
    height: 32px;
    object-fit: contain;
  }
  
  &:active {
    transform: scale(0.95);
    background: rgba(0, 0, 0, 0.8);
  }
}

.checkin-header {
  text-align: center;
  margin-bottom: 0px;
  margin-top: 0;
  
  .checkin-title {
    font-size: 22px;
    font-weight: bold;
    color: white;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8), 0 0 10px rgba(255, 0, 0, 0.3);
    margin-bottom: 10px;
    padding: 8px 20px;
    background: rgba(255, 0, 0, 0.2);
    border-radius: 8px;
    display: inline-block;
  }
  
  .checkin-description {
    font-size: 14px;
    color: white;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.5);
    
    .highlight {
      color: #FFA500;
      font-weight: bold;
      font-size: 16px;
      display: inline-block;
      padding: 0 6px;
    }
  }
}

.checkin-header.is-week {
  margin-top: 15px;
  //margin-bottom: 18px;
}

.checkin-header.is-month {
  margin-top: 30px;
}

.checkin-header.is-year,
.checkin-header.is-half-year {
  margin-top: 30px;
}

.checkin-header.is-week .checkin-description {
  color: #ffffff;
  text-shadow: none;
}

.checkin-header.is-month .checkin-description {
  color: #ffffff;
  text-shadow: none;
}

.checkin-header.is-year .checkin-description,
.checkin-header.is-half-year .checkin-description {
  color: #ffffff;
  text-shadow: none;
}

.checkin-header.is-week .checkin-description .highlight {
  color: #ffffff;
  font-weight: 700;
  font-size: 14px;
  background-image: url("@/assets/image/checkin/ic-checkin-week-coin-bg.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center;
  padding: 2px 8px;
  line-height: 18px;
}

.checkin-header.is-month .checkin-description .highlight {
  color: #ffffff;
  font-weight: 700;
  font-size: 14px;
  background-image: url("@/assets/image/checkin/ic-checkin-month-coin-bg.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center;
  padding: 2px 8px;
  line-height: 18px;
}

.checkin-header.is-year .checkin-description .highlight,
.checkin-header.is-half-year .checkin-description .highlight {
  color: #9E4801;
  font-weight: 700;
  font-size: 14px;
  background-image: url("@/assets/image/checkin/ic-checkin-year-coin-bg.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center;
  padding: 2px 8px;
  line-height: 18px;
}

.checkin-filter {
  align-self: flex-start;
  font-size: 12px;
  color: #999;
  margin: 0 0 6px 12px;
}

.checkin-panel {
  width: 100%;
  padding: 10px 0px 12px;
  border-radius: 16px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.checkin-panel.is-month,
.checkin-panel.is-year,
.checkin-panel.is-half-year {
  width: 100%;
  padding: 10px 0px 12px;
  border-radius: 16px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
  
  .checkin-grid {
    flex: 1;
    overflow-y: auto;
    scrollbar-width: none;
    -ms-overflow-style: none;
    
    &::-webkit-scrollbar {
      display: none;
    }
  }
  
  .coin-balance-wrap {
    margin-top: 10px;
  }
  
  .checkin-button {
    margin-top: 10px;
  }
}

.checkin-panel.is-week {
  width: 100%;
  padding: 10px 0px 12px;
  border-radius: 16px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.checkin-grid {
  display: grid;
  gap: 10px;
  width: 100%;
  margin-bottom: 20px;
  box-sizing: border-box;
  
  &.grid-week {
    grid-template-columns: repeat(4, 1fr);
    max-height: none;
  }
  
  &.grid-month {
    grid-template-columns: repeat(4, 1fr);
    max-height: 220px;
    overflow-y: auto;
    scrollbar-width: none;
    -ms-overflow-style: none;
    
    &::-webkit-scrollbar {
      display: none;
    }
  }
  
  &.grid-year,
  &.grid-half-year {
    grid-template-columns: repeat(4, 1fr);
    max-height: 220px;
    overflow-y: auto;
    scrollbar-width: none;
    -ms-overflow-style: none;
    
    &::-webkit-scrollbar {
      display: none;
    }
  }

}

.checkin-day-card {
  background: #fff;
  border-radius: 12px;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 80px;
  height: 80px;
  box-sizing: border-box;
  position: relative;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  
  .day-label {
    font-size: 12px;
    color: #666;
    margin-bottom: 8px;
    font-weight: 600;
    padding: 3px 8px;
    border-radius: 10px;
    background: #f3f3f3;
  }

  .day-label.is-today {
    color: #fff;
    background: #ff5a5f;
    font-weight: bold;
  }
  
  .day-icon {
    width: 32px;
    height: 32px;
    margin-bottom: 6px;
    
    img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
  }
  
  .day-icon.is-special {
    position: relative;
  }
  
  .day-icon.is-hidden {
    visibility: hidden;
  }
  
  .day-amount {
    font-size: 14px;
    font-weight: bold;
    color: #333;
  }
  
  .day-amount.placeholder {
    height: 16px; /* Same height as regular day-amount */
    visibility: hidden;
  }
  
  &.checked {
    background: #f8f8f8;
    
    .day-label {
      color: #999;
    }
    
    .day-amount {
      color: #999;
    }
  }
  
  &.today {
    background: linear-gradient(135deg, #ff7aa2 0%, #ffb347 100%);
    border: 1px solid #fff;
    box-shadow: 0 4px 12px rgba(255, 107, 157, 0.4);
    
    .day-label {
      color: white;
      font-weight: bold;
    }
    
    .day-amount {
      color: white;
    }
  }
  
  &.future {
    background: white;
  }
}

.checkin-day-card.is-week {
  background: transparent;
  box-shadow: none;
  border-radius: 10px;
  padding: 6px;
}

.checkin-day-card.is-month,
.checkin-day-card.is-year {
  background: transparent;
  box-shadow: none;
  border-radius: 10px;
  padding: 6px;
}

.checkin-day-card.is-week .day-label {
  position: absolute;
  top: 0px;
  right: 8px;
  margin: 0;
  padding: 0;
  border-radius: 0;
  background: transparent;
  color: #FFFFFF;
  font-size: 12px;
  font-weight: 600;
  line-height: 18px;
}

.checkin-day-card.is-month .day-label {
  position: absolute;
  top: 0px;
  margin: 0;
  padding: 0;
  border-radius: 0;
  background: transparent;
  color: #FFFFFF;
  font-size: 12px;
  font-weight: 600;
  line-height: 18px;
}

.checkin-day-card.is-year .day-label,
.checkin-day-card.is-half-year .day-label {
  position: absolute;
  top: 0px;
  margin: 0;
  padding: 0;
  border-radius: 0;
  background: transparent;
  color: #FFFFFF;
  font-size: 12px;
  font-weight: 600;
  line-height: 18px;
}

.checkin-day-card.is-year.checked .day-label,
.checkin-day-card.is-half-year.checked .day-label {
  color: #B0B0B0;
}

.checkin-day-card.is-month .day-label.is-today,
.checkin-day-card.is-year .day-label.is-today,
.checkin-day-card.is-half-year .day-label.is-today {
  color: #FFFFFF;
  background: transparent;
}

.checkin-day-card.is-week .day-label.is-today,
.checkin-day-card.is-month .day-label.is-today {
  color: #FFFFFF;
  background: transparent;
}

.checkin-day-card.is-year .day-label.is-today {
  color: #FFFFFF;
  background: transparent;
}

.checkin-day-card.is-week .day-icon {
  width: 28px;
  height: 28px;
  margin-top: 20px;
  margin-bottom: 4px;
  position: relative;
  
  .checked-icon-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    
    .checked-icon {
      width: 100%;
      height: 100%;
      object-fit: contain;
      opacity: 1; /* 确保已签到图标不透明 */
    }
  }
}

.checkin-day-card.is-week .day-icon.is-special {
  width: 28px;
  height: 28px;
  margin-top: 20px;
  margin-bottom: 4px;
  position: relative;
  
  .checked-icon-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    
    .checked-icon {
      width: 100%;
      height: 100%;
      object-fit: contain;
      opacity: 1; /* 确保已签到图标不透明 */
    }
  }
}

.checkin-day-card.is-month .day-icon,
.checkin-day-card.is-year .day-icon {
  width: 28px;
  height: 28px;
  margin-top: 20px;
  margin-bottom: 4px;
  position: relative;
  
  .checked-icon-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    
    .checked-icon {
      width: 100%;
      height: 100%;
      object-fit: contain;
      opacity: 1; /* 确保已签到图标不透明 */
    }
  }
}

.checkin-day-card.is-month .day-icon.is-special,
.checkin-day-card.is-year .day-icon.is-special {
  width: 28px;
  height: 28px;
  margin-top: 20px;
  margin-bottom: 4px;
  position: relative;
  
  .checked-icon-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    
    .checked-icon {
      width: 100%;
      height: 100%;
      object-fit: contain;
      opacity: 1; /* 确保已签到图标不透明 */
    }
  }
}

.checkin-day-card.is-week .day-amount {
  font-size: 14px;
  color: #333333;
  font-weight: 600;
}

.checkin-day-card.is-month .day-amount,
.checkin-day-card.is-year .day-amount {
  font-size: 14px;
  color: #333333;
  font-weight: 600;
}

.checkin-day-card.is-week.checked,
.checkin-day-card.is-week.today,
.checkin-day-card.is-week.future {
  background: transparent;
  box-shadow: none;
  border: none;
}

.checkin-day-card.is-month.checked,
.checkin-day-card.is-month.today,
.checkin-day-card.is-month.future {
  background: transparent;
  box-shadow: none;
  border: none;
}

.checkin-day-card.is-year.checked,
.checkin-day-card.is-year.today,
.checkin-day-card.is-year.future {
  background: transparent;
  box-shadow: none;
  border: none;
}

.checkin-day-card.is-half-year.checked,
.checkin-day-card.is-half-year.today,
.checkin-day-card.is-half-year.future {
  background: transparent;
  box-shadow: none;
  border: none;
}

/* 已签到的文本透明度处理 */
.checkin-day-card.checked .day-label,
.checkin-day-card.checked .day-amount {
  opacity: 0.7;
}

.checkin-grid.grid-week {
  .checkin-day-card.is-week-last {
    grid-column: 3 / 5;
  }
}

.coin-balance-wrap {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 14px;
  padding: 0 8px;
  height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  margin-bottom: 12px;
  white-space: nowrap;
}

.coin-balance-wrap.is-week {
  background: #FFFFFF;
  border-radius: 14px;
  padding: 0 8px;
  height: auto;
  margin-bottom: 12px;
  min-height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  white-space: nowrap;
}

.coin-balance-wrap.is-month {
  border-radius: 14px;
  padding: 0 8px;
  height: auto;
  margin-bottom: 12px;
  min-height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  white-space: nowrap;
}

.coin-balance-wrap.is-year {
  background: #000000;
  border-radius: 14px;
  padding: 0 8px;
  height: auto;
  margin-bottom: 12px;
  min-height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  white-space: nowrap;
}

.coin-balance {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #E94A6D;
  height: 24px;
  line-height: 24px;
  transition: transform 0.2s ease, color 0.2s ease;
  
  .balance-coin-icon {
    width: 16px;
    height: 16px;
    display: block;
  }
}

.coin-balance.is-animating {
  animation: coin-balance-pop 0.9s ease;
}

@keyframes coin-balance-pop {
  0% {
    transform: scale(1);
  }
  35% {
    transform: scale(1.12);
  }
  60% {
    transform: scale(0.98);
  }
  100% {
    transform: scale(1);
  }
}

.coin-balance-wrap .coin-balance {
  height: 24px;
}

.coin-balance-wrap.is-week .coin-balance {
  color: #E94A6D;
  text-shadow: none;
  font-weight: 600;
}

.coin-balance-wrap.is-month .coin-balance {
  color: #9943FF;
  text-shadow: none;
  font-weight: 600;
}

.coin-balance-wrap.is-year .coin-balance {
  color: #FFAE00;
  text-shadow: none;
  font-weight: 600;
}

.checkin-button {
  width: calc(100% - 46px);
  margin-left: 23px;
  margin-right: 23px;
  height: 54px;
  line-height: 54px;
  background: linear-gradient(135deg, #ff7aa2 0%, #ff9a57 100%);
  border-radius: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(255, 107, 157, 0.3);
  transition: all 0.3s;
  margin-bottom: 0px;
  
  &:active {
    transform: scale(0.98);
  }
  
  &.checked-in {
    background: #999;
    box-shadow: none;
    cursor: not-allowed;
  }
}

.checkin-button.is-week {
  background-color: transparent;
  box-shadow: none;
  padding-bottom: 6px;
}

.checkin-button.is-month {
  height: 50px;
  line-height: 50px;
  background: transparent;
  border: none;
  box-shadow: none;
}

.checkin-button.is-month.checked-in {
  height: 50px;
  line-height: 50px;
  background: transparent;
  border: none;
  box-shadow: none;
  cursor: not-allowed;
}

.checkin-button.is-year {
  background: transparent;
  box-shadow: none;
  padding-bottom: 6px;
}
</style>

<style lang="less">
.checkin-dialog-wrapper {
  .m-dialog {
    background: transparent;
    box-shadow: none;
    overflow: visible;
  }
  
  .m-dialog-body {
    padding: 0;
    background: transparent;
    overflow: visible;
  }
}
</style>
