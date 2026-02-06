<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="dialogClass" :enable-swipe-close="false">
    <div class="filter-content">
      <!-- 顶部固定标题 -->
      <div class="filter-header sticky-header">Country Filter</div>

      <!-- 滚动内容区域 -->
      <div class="scrollable-section">
        <div class="fixed-section">
          <div class="section-title">Country Preference</div>

          <div class="radio-item" @click="setCountryMode('balanced')">
            <img :src="getRadioIcon('balanced')" class="radio-circle" />
            <div class="radio-label">Balanced</div>
          </div>

          <div class="radio-item" @click="setCountryMode('global')">
            <img :src="getRadioIcon('global')" class="radio-circle" />
            <div class="radio-label">Global</div>
          </div>

          <div class="radio-item" @click="selectVipCountryMode('us')">
            <img :src="getRadioIcon('us')" class="radio-circle" />
            <div class="radio-content">
               <div class="radio-label-row">
                 <span>United States & More</span>
                 <img :src="vipIcon" class="crown-img"/>
                 <span v-if="!isVip" class="coins-save">
                   <img src="@/assets/image/match/ic-match-coins-icon@2x.png" class="coins-icon"/> {{ COINS_SAVE_AMOUNT }}/Save
                 </span>
               </div>
               <div class="radio-desc">
                 <div class="desc-text">
                   <span class="rec-tag">Recommended</span>
                   You're more likely to meet people from your country.
                 </div>
               </div>
            </div>
          </div>
        </div>

        <div class="super-match-section">
          <div class="super-match-info">
            <div class="super-match-title">
              Super Match <img src="@/assets/image/match/ic-match-question@2x.png" class="question-icon" @click.stop="openHelp"/> <img src="@/assets/image/match/ic-match-beta@2x.png" class="beta-img"/> <img :src="vipIcon" class="crown-img"/>
              <span v-if="!isVip" class="coins-save">
                <img src="@/assets/image/match/ic-match-coins-icon@2x.png" class="coins-icon"/> {{ COINS_SAVE_AMOUNT }}/Save
              </span>
            </div>
            <div class="super-match-desc">
              <img src="@/assets/image/match/ic-match-heart@2x.png" class="heart-icon" />
              The Super Match filter helps you find more compatible matches
            </div>
          </div>
          <div class="m-switch" :class="{ active: superMatch }" @click="toggleSuperMatch">
            <div class="m-switch-handle"></div>
          </div>
        </div>

        <div class="section-title sticky-title section-title-wrap">
          <div class="section-title-row">
            Select A Country To Match With <img src="@/assets/image/match/ic-match-beta@2x.png" class="beta-img"/>
          </div>
          <div class="section-title-row">
            <img :src="vipIcon" class="crown-img"/>
            <span v-if="!isVip" class="coins-save">
              <img src="@/assets/image/match/ic-match-coins-icon@2x.png" class="coins-icon"/> {{ COINS_SAVE_AMOUNT }}/Save
            </span>
          </div>
        </div>

        <div class="scrollable-content" style="margin-top: 0;">
          <!-- All 选项 -->
          <div
            class="radio-item"
            @click="selectCountry('all')"
          >
            <img :src="getRadioIcon('all')" class="radio-circle" />
            <div class="radio-label">🌍 All</div>
          </div>

          <!-- 动态国家选项 -->
          <div v-if="countryList.length === 0" class="empty-text">No countries available</div>
          <div
            v-else
            v-for="(country, index) in countryList"
            :key="country.id || index"
            class="radio-item"
            @click="selectCountry(country)"
          >
            <img :src="getRadioIcon(country)" class="radio-circle" />
            <div class="radio-label">{{ country.emoji || '🌍' }} {{ country.name || country.countryName || 'Unknown' }}</div>
          </div>
        </div>
      </div>

      <!-- 底部固定按钮 -->
      <div class="bottom-fixed-section">
        <div class="action-btn" @click="confirm">
          Go to Match
          <span v-if="matchFilterFreeCount > 0" class="free-badge">Free x{{ matchFilterFreeCount }}</span>
        </div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import selIcon from "@/assets/image/match/ic-match-sel@2x.png";
import selIconNo from "@/assets/image/match/ic-match-sel-no@2x.png";
import { getCountryFlagEmoji, getCountryFlagEmojiByName, getCountryNameByCode } from "@/utils/Utils";
import { openPremium } from "@/utils/PageUtils";
import {showPremiumDialog, showSuperMatchHelpDialog} from "@/components/dialog";
import cache from "@/utils/cache";
import { key_cache } from "@/utils/Constant";

/** 非 VIP 时展示的「Save」文案中的金币数量，方便统一修改 */
const COINS_SAVE_AMOUNT = 200;

export default {
  name: "MCountryFilterDialog",
  components: { MBottomDialog },
  props: {
    onConfirm: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    return {
      COINS_SAVE_AMOUNT,
      selectedCountryCacheKey: 'country_filter_selected',
      countryModeCacheKey: 'country_filter_mode',
      superMatchCacheKey: 'country_filter_super_match',
      countryMode: 'balanced',
      selIcon: selIcon,
      selIconNo: selIconNo,
      selectedCountry: null,
      superMatch: false
    };
  },
  computed: {
    dialogClass() {
      return 'match-filter-dialog';
    },
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    isVip() {
      return this.userInfo.vipCategory !== 0;
    },
    vipIcon() {
      // 根据当前用户是否是 VIP 返回对应的图标
      return this.isVip 
        ? require('@/assets/image/match/ic-match-vip@2x.png')
        : require('@/assets/image/match/ic-match-un-vip@2x.png');
    },
    matchFilterFreeCount() {
      const list = cache.local.getJSON(key_cache.user_backpack) || [];
      if (!Array.isArray(list)) return 0;
      return list
        .filter((item) => item && Number(item.backpackType) === 3)
        .reduce((sum, item) => sum + Math.max(0, Number(item.quantity) || 0), 0);
    },
    countryList() {
      const dictList = this.$store.state.PageCache.dict || [];
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
            // 如果 value 不存在或为 'N/A'，则根据国家名称获取国旗
            emoji = getCountryFlagEmojiByName(item.label);
          }

          return {
            id: item.value,
            name: item.label,
            value: item.value,  // value 就是 code
            code: item.value,   // code 就是 value
            emoji: emoji
          };
        });
        const cachedCountry = cache.local.getJSON(this.selectedCountryCacheKey);
        if (cachedCountry && cachedCountry !== 'all') {
          const cachedId = cachedCountry.id || cachedCountry.countryId || cachedCountry.code || cachedCountry.name;
          const matchIndex = options.findIndex((opt) => {
            const optId = opt.id || opt.countryId || opt.code || opt.name;
            return cachedId && optId && cachedId === optId;
          });
          if (matchIndex > -1) {
            const [matched] = options.splice(matchIndex, 1);
            options.unshift(matched);
          }
        }
        return options;
      }
      return [];
    }
  },
  methods: {
    setCountryMode(mode) {
      this.countryMode = mode;
      cache.local.set(this.countryModeCacheKey, mode);
    },
    handleVipGate() {
      showPremiumDialog();
      return true;
    },
    selectVipCountryMode(mode) {
      // 无论是否是 VIP，都先选中该项
      this.countryMode = mode;
      cache.local.set(this.countryModeCacheKey, mode);
      
      // 如果不是 VIP，弹出 VIP 对话框
      if (!this.isVip) {
        this.handleVipGate();
      }
    },
    toggleSuperMatch() {
      const newValue = !this.superMatch;
      
      // 如果是关闭操作（从 true 变为 false），直接切换，不需要 VIP 判断
      if (this.superMatch && !newValue) {
        this.superMatch = newValue;
        cache.local.set(this.superMatchCacheKey, this.superMatch);
        return;
      }
      
      // 如果是打开操作（从 false 变为 true），需要 VIP 判断
      // 无论是否是 VIP，都先切换状态
      this.superMatch = newValue;
      // 保存到缓存
      cache.local.set(this.superMatchCacheKey, this.superMatch);
      
      // 如果不是 VIP，弹出 VIP 对话框
      if (!this.isVip) {
        this.handleVipGate();
        return;
      }
    },
    openHelp() {
      showSuperMatchHelpDialog();
    },
    selectCountry(country) {
      // 如果选择的是 'all'，不需要会员判断
      if (country === 'all') {
        if (this.selectedCountry === 'all') {
          // 如果已经选中 'all'，取消选择
          this.selectedCountry = null;
          cache.local.remove(this.selectedCountryCacheKey);
        } else {
          // 选择 'all'
          this.selectedCountry = 'all';
          cache.local.setJSON(this.selectedCountryCacheKey, 'all');
        }
        return;
      }

      // 选择具体国家需要会员判断
      // 无论是否是 VIP，都先选中该项
      const selectedId = this.selectedCountry === 'all' ? 'all' : (this.selectedCountry?.id || this.selectedCountry?.countryId || this.selectedCountry?.code || this.selectedCountry?.name);
      const nextId = country?.id || country?.countryId || country?.code || country?.name;
      if (selectedId && nextId && selectedId === nextId) {
        this.selectedCountry = null;
        cache.local.remove(this.selectedCountryCacheKey);
        return;
      }
      this.selectedCountry = country;
      cache.local.setJSON(this.selectedCountryCacheKey, {
        id: country?.id,
        countryId: country?.countryId,
        code: country?.code,
        name: country?.name
      });
      
      // 如果不是 VIP，弹出 VIP 对话框
      if (!this.isVip) {
        this.handleVipGate();
      }
    },
    confirm() {
      if (this.onConfirm) {
        // 如果选择的是 'all'，传递 'all'；否则传递国家 code
        const countryValue = this.selectedCountry === 'all' ? 'all' : (this.selectedCountry?.code || this.selectedCountry?.value || this.selectedCountry?.id);
        this.onConfirm({
          countryMode: this.countryMode,
          selectedCountry: this.selectedCountry,
          country: countryValue // 兼容 MUserListFilterDialog 的格式
        });
      }
      this.$refs.bottomDialog.closeDialog();
      // 跳转到匹配页面
      this.$router.push('/sdk/page/matching');
    },
    getRadioIcon(modeOrCountry) {
      // 如果传入的是 'all'，检查是否选中
      if (modeOrCountry === 'all') {
        return this.selectedCountry === 'all' ? this.selIcon : this.selIconNo;
      }
      // 如果传入的是国家对象，检查是否选中
      if (typeof modeOrCountry === 'object' && modeOrCountry !== null) {
        return this.selectedCountry === modeOrCountry ? this.selIcon : this.selIconNo;
      }
      // 如果传入的是模式字符串
      return this.countryMode === modeOrCountry ? this.selIcon : this.selIconNo;
    }
  },
  mounted() {
    // 恢复缓存的 countryMode
    const cachedMode = cache.local.get(this.countryModeCacheKey);
    if (cachedMode) {
      this.countryMode = cachedMode;
    }

    // 恢复缓存的 superMatch 状态
    const cachedSuperMatch = cache.local.get(this.superMatchCacheKey);
    if (cachedSuperMatch !== null && cachedSuperMatch !== undefined) {
      this.superMatch = cachedSuperMatch === true || cachedSuperMatch === 'true';
    }

    // 恢复缓存的选中状态（避免在 computed 属性中产生副作用）
    const cachedCountry = cache.local.getJSON(this.selectedCountryCacheKey);
    if (cachedCountry) {
      if (cachedCountry === 'all') {
        this.selectedCountry = 'all';
        // 不修改 countryMode，保持 data 中的默认值 'balanced'
      } else {
        // 查找匹配的国家对象
        const cachedId = cachedCountry.id || cachedCountry.countryId || cachedCountry.code || cachedCountry.name;
        const matchedCountry = this.countryList.find((opt) => {
          const optId = opt.id || opt.countryId || opt.code || opt.name;
          return cachedId && optId && cachedId === optId;
        });
        if (matchedCountry) {
          this.selectedCountry = matchedCountry;
          // 不修改 countryMode，保持 data 中的默认值 'balanced' 或缓存值
        }
      }
    } else {
      // 没有缓存时，默认选中 All（仅针对国家选择，Country Preference 保持默认的 balanced）
      this.selectedCountry = 'all';
      // 不修改 countryMode，保持 data 中的默认值 'balanced'
    }
  }
}
</script>

<style scoped lang="less">
:deep(.el-dialog__body) {
  overflow-y: visible !important;
}
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
  margin-bottom: 20px;

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
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 6px;

  &.mt-20 {
    margin-top: 20px;
  }

  .beta-img {
    width: 33px;
    height: 22px;
    object-fit: contain;
    flex-shrink: 0;
  }

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

  &.section-title-wrap {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .section-title-row {
    display: flex;
    align-items: center;
    gap: 6px;
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
  }
}

.super-match-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  flex-shrink: 0;
}

.super-match-info {
  flex: 1;
  margin-right: 16px;
}

.super-match-title {
  display: flex;
  align-items: center;
  font-weight: bold;
  font-size: 14px;
  margin-bottom: 4px;
  gap: 6px;
  color: #999999;

.beta-img {
  width: 33px;
  height: 22px;
  object-fit: contain;
}

  .crown-img {
    width: 22px;
    height: 22px;
  }

  .question-icon {
    width: 22px;
    height: 22px;
    cursor: pointer;
    margin: 0 4px;
    vertical-align: middle;
  }

  .beta-img {
    width: 33px;
    height: 22px;
    object-fit: contain;
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
  }
}

.super-match-desc {
  font-size: 12px;
  color: #666;
  line-height: 1.4;
  display: flex;
  align-items: center;
  gap: 8px;

  .heart-icon {
    width: 26px;
    height: 26px;
    flex-shrink: 0;
    object-fit: contain;
  }
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
    background: linear-gradient(90deg, #F4D890 0%, #D5A351 100%);

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

.scrollable-content {
  flex: 1;
  min-height: 0;
  padding-bottom: 10px;
}

.beta-tag {
  background: #999999;
  height: 22px;
  padding: 0 6px;
  border-radius: 11px;
  font-size: 10px;
  color: #282828;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.crown-img {
  width: 22px;
  height: 22px;
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

.radio-content {
  flex: 1;
}

.radio-label-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
  font-size: 16px;
  font-weight: 300;

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
  }
}

.radio-desc {
  display: flex;
  align-items: flex-start;
}

.desc-text {
  font-size: 12px;
  color: #666;
  line-height: 1.3;
}

.rec-tag {
  display: block;
  color: #888;
  margin-bottom: 2px;
}

.action-btn {
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
  position: relative;
  flex-shrink: 0;
  width: calc(100% - 80px);
  margin: 0 40px 20px;
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

:deep(.hint-dialog.d-bottom.match-filter-dialog) {
  transition: transform 0.25s ease, opacity 0.25s ease;
}

:deep(.hint-dialog.d-bottom.match-filter-dialog.is-closing) {
  transform: translateY(100%);
  opacity: 0;
}

.loading-text,
.empty-text {
  text-align: center;
  color: #888;
  font-size: 14px;
  padding: 20px;
}
</style>
