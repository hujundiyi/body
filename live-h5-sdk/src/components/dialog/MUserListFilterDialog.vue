<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'user-list-filter-dialog'" :enable-swipe-close="false">
    <div class="filter-content">
      <!-- 顶部固定标题 -->
      <div class="filter-header sticky-header">Filter</div>
      
      <!-- 滚动内容区域 -->
      <div class="scrollable-section">
        <!-- Around My Age Section - 移到顶部 -->
        <div class="fixed-section">
          <div class="fixed-header">
            <div class="section-title">
              Around My Age
              <img :src="vipIcon" class="crown-icon"/>
              <span v-if="!isVip" class="coins-save">
                <img src="@/assets/image/match/ic-match-coins-icon@2x.png" class="coins-icon"/> {{ COINS_SAVE_AMOUNT }}/Save
              </span>
            </div>
            <div class="m-switch" :class="{ active: aroundMyAge }" @click="handleAgeToggle">
              <div class="m-switch-handle"></div>
            </div>
          </div>
          <div class="toggle-label">Show users around my age</div>
        </div>

        <!-- Preferred Country Section - 移到底部，参照 MCountryFilterDialog 样式 -->
        <div class="section-title sticky-title">
          Preferred Country
          <img src="@/assets/image/sdk/ic-match-beta.png" class="beta-img-icon"/>
          <img :src="vipIcon" class="crown-icon"/>
          <span v-if="!isVip" class="coins-save">
            <img src="@/assets/image/match/ic-match-coins-icon@2x.png" class="coins-icon"/> {{ COINS_SAVE_AMOUNT }}/Save
          </span>
        </div>
        <div class="scrollable-content">
          <!-- All 选项 -->
          <div 
            class="radio-item" 
            @click="handleCountryClick('all')"
          >
            <img :src="getRadioIcon('all')" class="radio-circle" />
            <div class="radio-label">🌍 All</div>
          </div>
          
          <!-- 动态国家选项 -->
          <div 
            v-for="country in countryOptions" 
            :key="country.value"
            class="radio-item" 
            @click="handleCountryClick(country.value)"
          >
            <img :src="getRadioIcon(country)" class="radio-circle" />
            <div class="radio-label">{{ country.emoji || '🌐' }} {{ country.label }}</div>
          </div>
        </div>
      </div>

      <!-- 底部固定按钮 -->
      <div class="bottom-fixed-section">
        <div class="save-btn" @click="confirm">
          Save
          <span v-if="feedFilterFreeCount > 0" class="free-badge">Free x{{ feedFilterFreeCount }}</span>
        </div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import selIcon from "@/assets/image/match/ic-match-sel@2x.png";
import selIconNo from "@/assets/image/match/ic-match-sel-no@2x.png";
import {getCountryFlagEmoji, getCountryFlagEmojiByName, getCountryNameByCode} from "@/utils/Utils";
import {showPremiumDialog} from "@/components/dialog";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";

/** 非 VIP 时展示的「Save」文案中的金币数量，方便统一修改 */
const COINS_SAVE_AMOUNT = 200;

export default {
  name: "MUserListFilterDialog",
  components: { MBottomDialog },
  props: {
    onConfirm: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    // 从缓存中恢复筛选条件
    const cacheKey = 'user_list_filter_settings';
    const cachedSettings = cache.local.getJSON(cacheKey, null);
    
    console.log('=== MUserListFilterDialog: 恢复筛选条件 ===', {
      cachedSettings: cachedSettings,
      selectedCountry: cachedSettings?.country ?? 'all',
      aroundMyAge: cachedSettings?.aroundMyAge ?? false
    });
    
    return {
      COINS_SAVE_AMOUNT,
      selectedCountry: cachedSettings?.country ?? 'all',
      aroundMyAge: cachedSettings?.aroundMyAge ?? false, // 默认关闭状态
      selIcon: selIcon,
      selIconNo: selIconNo,
      cacheKey: cacheKey
    };
  },
  computed:{
    isVip() {
      // 判断当前登录用户是否是会员
      let loginUserInfo = this.$store.state.user.loginUserInfo || {};
      
      // 检查用户信息是否已经加载完成
      // 如果只有默认值（msgNum: 0）且没有 userId，说明可能还在加载中
      const isDefaultInfo = loginUserInfo.msgNum === 0 && 
                            !loginUserInfo.userId &&
                            Object.keys(loginUserInfo).length <= 1; // 只有默认字段
      
      // 如果用户信息还在加载中，尝试从缓存中读取最新的用户信息
      if (isDefaultInfo) {
        const cachedUserInfo = cache.local.getJSON(key_cache.user_info);
        if (cachedUserInfo && cachedUserInfo.userId) {
          // 使用缓存中的用户信息
          loginUserInfo = cachedUserInfo;
        } else {
          // 如果缓存中也没有，返回 false（保守处理，避免误判）
          return false;
        }
      }
      
      // 判断 vipCategory：存在且不等于 0 时才是会员
      return loginUserInfo.vipCategory !== undefined && 
             loginUserInfo.vipCategory !== null && 
             loginUserInfo.vipCategory !== 0;
    },
    vipIcon() {
      // 根据当前用户是否是 VIP 返回对应的图标
      return this.isVip 
        ? require('@/assets/image/match/ic-match-vip@2x.png')
        : require('@/assets/image/match/ic-match-un-vip@2x.png');
    },
    feedFilterFreeCount() {
      const list = cache.local.getJSON(key_cache.user_backpack) || [];
      if (!Array.isArray(list)) return 0;
      return list
        .filter((item) => item && Number(item.backpackType) === 2)
        .reduce((sum, item) => sum + Math.max(0, Number(item.quantity) || 0), 0);
    },
    countryOptions() {
      const dictList = this.$store.state.PageCache.dict || [];
      // 查找 dictType 为 'country' 的字典项
      const countryTypeDict = dictList.find(item => item.dictType === 'country');
      if (countryTypeDict && countryTypeDict.dictItems) {
        // 为每个国家项添加 emoji，优先使用 item.value（国家代码）映射到国家名称再获取国旗
        const options = countryTypeDict.dictItems.map(item => {
          let emoji = '🌐';
          if (item.value && item.value !== 'N/A' && String(item.value).trim() !== '') {
            const countryCode = String(item.value);
            const countryName = getCountryNameByCode(countryCode);
            if (countryName) {
              emoji = getCountryFlagEmojiByName(countryName);
            } else {
              if (item.label) {
                emoji = getCountryFlagEmojiByName(item.label);
              } else {
                emoji = getCountryFlagEmoji(countryCode);
              }
            }
          } else if (item.label) {
            emoji = getCountryFlagEmojiByName(item.label);
          }
          return {
            label: item.label,
            value: item.value,
            code: item.value,
            emoji: emoji
          };
        });
        return options;
      }
      return [];
    },
  },
  mounted() {
    // 恢复筛选条件后，验证国家选项是否存在
    // 使用 watch 监听 countryOptions 的变化，确保数据加载完成后再验证
    this.$watch('countryOptions', (newOptions) => {
      if (newOptions && newOptions.length > 0 && this.selectedCountry !== 'all') {
        // 检查保存的国家 value 是否在当前国家列表中
        const countryExists = newOptions.some(opt => opt.value === this.selectedCountry);
        if (!countryExists) {
          // 如果保存的国家不存在，重置为 'all'
          this.selectedCountry = 'all';
          // 更新缓存
          const cachedSettings = cache.local.getJSON(this.cacheKey, {});
          cache.local.setJSON(this.cacheKey, {
            ...cachedSettings,
            country: 'all'
          });
        }
      }
    }, { immediate: true });
  },
  methods: {
    // 保存筛选条件到缓存
    saveSettings() {
      const settingsToSave = {
        country: this.selectedCountry, // 保存选中的国家 value，用于恢复
        aroundMyAge: this.aroundMyAge
      };
      cache.local.setJSON(this.cacheKey, settingsToSave);
    },
    confirm() {
      if (this.onConfirm) {
        // 获取选中的国家 code
        let countryCode = null;
        if (this.selectedCountry !== 'all') {
          const selectedCountryOption = this.countryOptions.find(opt => opt.value === this.selectedCountry);
          countryCode = selectedCountryOption?.code || null;
        }
        
        const filterData = { 
          country: this.selectedCountry === 'all' ? 'all' : countryCode, // 传递国家 code
          aroundMyAge: this.aroundMyAge
        };
        
        // 保存筛选条件到 localStorage（确保最新状态已保存）
        this.saveSettings();
        
        this.onConfirm(filterData);
      }
      this.$refs.bottomDialog.closeDialog();
    },
    handleCountryClick(countryValue) {
      // 无论是否是 VIP，都先选中该项
      this.selectedCountry = countryValue;
      this.saveSettings();
      
      // 如果选择的是 'all'，不需要 VIP 判断
      if (countryValue === 'all') {
        return;
      }
      
      // 选择其他国家时，如果不是 VIP，弹出 VIP 对话框
      if (!this.isVip) {
        showPremiumDialog();
      }
    },
    handleAgeToggle() {
      const newValue = !this.aroundMyAge;
      
      // 如果是关闭操作（从 true 变为 false），直接切换，不需要 VIP 判断
      if (this.aroundMyAge && !newValue) {
        this.aroundMyAge = newValue;
        this.saveSettings();
        return;
      }
      
      // 如果是打开操作（从 false 变为 true），需要 VIP 判断
      // 无论是否是 VIP，都先切换状态
      this.aroundMyAge = newValue;
      this.saveSettings();
      
      // 如果不是 VIP，弹出 VIP 对话框
      if (!this.isVip) {
        showPremiumDialog();
      }
    },
    getRadioIcon(countryOrAll) {
      // 如果传入的是 'all'，检查是否选中
      if (countryOrAll === 'all') {
        return this.selectedCountry === 'all' ? this.selIcon : this.selIconNo;
      }
      // 如果传入的是国家对象，检查是否选中
      if (typeof countryOrAll === 'object' && countryOrAll !== null) {
        return this.selectedCountry === countryOrAll.value ? this.selIcon : this.selIconNo;
      }
      // 默认返回未选中图标
      return this.selIconNo;
    }
  }
}
</script>

<style scoped lang="less">
.filter-content {
  background: #1A1A1A;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 20px;
  color: white;
  display: flex;
  flex-direction: column;
  max-height: 60vh;
  min-height: 0;
  overflow: hidden;
}

.filter-header {
  font-size: 22px;
  font-weight: bold;
  text-align: left;
  margin-bottom: 20px;
  color: white;
  
  &.sticky-header {
    position: sticky;
    top: 0;
    background: #1A1A1A;
    z-index: 20;
    padding-bottom: 20px;
    margin-bottom: 0;
  }
}

.scrollable-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
}

.fixed-section {
  flex-shrink: 0;
  padding-top: 4px;
}

.fixed-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 0px;
}

.bottom-fixed-section {
  flex-shrink: 0;
  padding-top: 20px;
  background: #1A1A1A;
}

.section-title {
  color: #888;
  font-size: 16px;
  font-weight: 800;
  margin-bottom: 0px;
  display: flex;
  align-items: center;
  gap: 6px;
  
  &.sticky-title {
    position: sticky;
    top: -2px;
    background: #1A1A1A;
    z-index: 10;
    padding-top: 15px;
    padding-bottom: 5px;
    margin-top: 0;
    margin-bottom: 12px;
  }

  .beta-img-icon {
    width: 33px;
    height: 22px;
    object-fit: contain;
  }
  .crown-icon {
    width: 22px;
    height: 22px;
  }

  .coins-save {
    display: inline-flex;
    align-items: center;
    color: #999999;
    font-size: 10px;
    font-weight: bold;
  }

  .coins-icon {
    width: 12px;
    height: 12px;
    object-fit: contain;
    flex-shrink: 0;
    margin-right: 4px;
  }
}

.scrollable-content {
  flex: 1;
  min-height: 0;
  padding-bottom: 10px;
}

.radio-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 16px;
  cursor: pointer;
  
  &.disabled {
    opacity: 0.3;
    pointer-events: none;
  }
}

.radio-circle {
  width: 20px;
  height: 20px;
  margin-right: 12px;
  flex-shrink: 0;
  margin-top: 2px;
  object-fit: contain;
}

.radio-label {
  font-size: 16px;
  font-weight: 300;
  padding-top: 2px;
}

.toggle-label {
  margin-top: -6px;
  font-size: 12px;
  color: #999;
}

.m-switch {
  width: 54px;
  height: 32px;
  background: #555;
  border-radius: 16px;
  position: relative;
  cursor: pointer;
  transition: background 0.3s;
  flex-shrink: 0;

  &.active {
    background: linear-gradient(90deg, #D5A351 100%, #F4D890 100%);
    
    .m-switch-handle {
      transform: translateX(22px);
    }
  }

  .m-switch-handle {
    width: 22px;
    height: 22px;
    background: white;
    border-radius: 50%;
    position: absolute;
    top: 5px;
    left: 5px;
    transition: transform 0.3s;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  }
}

.save-btn {
  background: white;
  color: black;
  height: 54px;
  border-radius: 27px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
  font-size: 18px;
  cursor: pointer;
  flex-shrink: 0;
  width: calc(100% - 80px);
  margin: 0 40px 20px;
  position: relative;
}

.free-badge {
  position: absolute;
  top: -8px;
  right: -20px;
  background: linear-gradient(90deg, #4CA703 0%, #01B7F3 100%);
  color: white;
  font-size: 16px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 14px;
  white-space: nowrap;
  z-index: 10;
}
</style>