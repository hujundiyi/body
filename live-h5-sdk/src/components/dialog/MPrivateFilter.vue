<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'private-filter-dialog'" :enable-swipe-close="false">
    <div class="filter-content">
      <!-- 顶部背景图区域 -->
      <div
        class="filter-header"
        :style="{ backgroundImage: `url(${headerBgImage})` }"
        @click="closeDialog"
      />

      <!-- 滚动内容区域 -->
      <div class="scrollable-section">
        <!-- Role Section -->
        <div class="filter-category">
          <div class="category-title">Role</div>
          <div class="category-scroll" ref="roleScroll">
            <div class="option-card" 
                 v-for="(option, index) in roleOptions" 
                 :key="index"
                 :class="{ active: selectedRole === option.value }"
                 @click="selectRole(option.value)">
              <img :src="option.icon" class="option-icon" :alt="option.label"/>
              <div class="option-label">{{ isVip ? option.label : maskLockedLabel(option.label) }}</div>
            </div>
          </div>
        </div>

        <!-- Interest Section -->
        <div class="filter-category">
          <div class="category-title">Interest</div>
          <div class="category-scroll" ref="interestScroll">
            <div class="option-card" 
                 v-for="(option, index) in interestOptions" 
                 :key="index"
                 :class="{ active: selectedInterest === option.value }"
                 @click="selectInterest(option.value)">
              <img :src="isVip ? option.icon : lockIcon" class="option-icon" :alt="option.label"/>
              <div class="option-label">{{ isVip ? option.label : maskLockedLabel(option.label) }}</div>
            </div>
          </div>
        </div>

        <!-- Experience Level Section -->
        <div class="filter-category filter-category--circle">
          <div class="category-title">Experience Level</div>
          <div class="category-scroll" ref="experienceScroll">
            <div class="option-card" 
                 v-for="(option, index) in experienceOptions" 
                 :key="index"
                 :class="{ active: selectedExperience === option.value }"
                 @click="selectExperience(option.value)">
              <img :src="option.icon" class="option-icon" :alt="option.label"/>
              <div class="option-label">{{ isVip ? option.label : maskLockedLabel(option.label) }}</div>
            </div>
          </div>
        </div>

        <!-- Relationship Section -->
        <div class="filter-category">
          <div class="category-title">Relationship</div>
          <div class="category-scroll" ref="relationshipScroll">
            <div class="option-card" 
                 v-for="(option, index) in relationshipOptions" 
                 :key="index"
                 :class="{ active: selectedRelationship === option.value }"
                 @click="selectRelationship(option.value)">
              <img :src="isVip ? option.icon : lockIcon" class="option-icon" :alt="option.label"/>
              <div class="option-label">{{ isVip ? option.label : maskLockedLabel(option.label) }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部固定按钮 -->
      <div class="bottom-fixed-section">
        <div class="save-btn" @click="confirm">
          Go to Match
        </div>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import { showPremiumDialog } from "@/components/dialog";
import cache from "@/utils/cache";
import bgPre from "@/assets/image/private/ic-private-bg-pre@2x.png";
import bgUnPre from "@/assets/image/private/ic-private-bg-un-pre@2x.png";
// Role 图标
import role0 from "@/assets/image/private/ic-private-role-0@2x.png";
import role1 from "@/assets/image/private/ic-private-role-1@2x.png";
import role2 from "@/assets/image/private/ic-private-role-2@2x.png";
import role3 from "@/assets/image/private/ic-private-role-3@2x.png";
import role4 from "@/assets/image/private/ic-private-role-4@2x.png";
// Interest 图标
import interest0 from "@/assets/image/private/ic-private-interest-0@2x.png";
import interest1 from "@/assets/image/private/ic-private-interest-1@2x.png";
import interest2 from "@/assets/image/private/ic-private-interest-2@2x.png";
import interest3 from "@/assets/image/private/ic-private-interest-3@2x.png";
import interest4 from "@/assets/image/private/ic-private-interest-4@2x.png";
import interest5 from "@/assets/image/private/ic-private-interest-5@2x.png";
import interest6 from "@/assets/image/private/ic-private-interest-6@2x.png";
// Experience Level 图标
import level0 from "@/assets/image/private/ic-private-level-0@2x.png";
import level1 from "@/assets/image/private/ic-private-level-1@2x.png";
import level2 from "@/assets/image/private/ic-private-level-2@2x.png";
import level3 from "@/assets/image/private/ic-private-level-3@2x.png";
// Relationship 图标
import relationship0 from "@/assets/image/private/ic-private-relationship-0@2x.png";
import relationship1 from "@/assets/image/private/ic-private-relationship-1@2x.png";
import relationship2 from "@/assets/image/private/ic-private-relationship-2@2x.png";
import lockIcon from "@/assets/image/private/ic-private-lock@2x.png";

export default {
  name: "MPrivateFilter",
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
    const cacheKey = 'private_filter_settings';
    const cachedSettings = cache.local.getJSON(cacheKey, null);
    
    return {
      cacheKey: cacheKey,
      selectedRole: cachedSettings?.role || null,
      selectedInterest: cachedSettings?.interest || null,
      selectedExperience: cachedSettings?.experience || null,
      selectedRelationship: cachedSettings?.relationship || null,
      roleOptions: [
        { value: 'dominant', label: 'Dominant/Dom', icon: role0 },
        { value: 'submission', label: 'Submission/Sub', icon: role1 },
        { value: 'switch', label: 'Switch', icon: role2 },
        { value: 'top', label: 'Top', icon: role3 },
        { value: 'bottom', label: 'Bottom', icon: role4 }
      ],
      // Interest 选项
      interestOptions: [
        { value: 'bandage', label: 'Bandage & Restraints', icon: interest0 },
        { value: 'impact', label: 'Impact Play', icon: interest1 },
        { value: 'sensation', label: 'Sensation Play', icon: interest2 },
        { value: 'roleplay', label: 'Roleplay & D/s', icon: interest3 },
        { value: 'fetish', label: 'Fetish / Object Play', icon: interest4 },
        { value: 'pain', label: 'Pain Play', icon: interest5 },
        { value: 'service', label: 'Service & Control', icon: interest6 }
      ],
      // Experience Level 选项
      experienceOptions: [
        { value: 'beginner', label: 'Beginner', icon: level0 },
        { value: 'intermediate', label: 'Intermediate', icon: level1 },
        { value: 'advanced', label: 'Advanced', icon: level2 },
        { value: 'expert', label: 'Expert', icon: level3 }
      ],
      // Relationship 选项
      relationshipOptions: [
        { value: 'play_partners', label: 'Play Partners', icon: relationship0 },
        { value: 'long_term', label: 'Long-Term Dynamic', icon: relationship1 },
        { value: 'online_only', label: 'Online Only', icon: relationship2 }
      ],
      lockIcon
    };
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    isVip() {
      const loginUserInfo = this.userInfo;
      return loginUserInfo.vipCategory !== undefined &&
             loginUserInfo.vipCategory !== null &&
             loginUserInfo.vipCategory !== 0;
    },
    headerBgImage() {
      return this.isVip ? bgPre : bgUnPre;
    }
  },
  created() {
    // 非 VIP 不记住选中：打开弹窗时清空选中并清缓存
    if (!this.isVip) {
      this.selectedRole = null;
      this.selectedInterest = null;
      this.selectedExperience = null;
      this.selectedRelationship = null;
      this.saveSettings();
    }
  },
  methods: {
    selectRole(value) {
      if (!this.isVip) {
        showPremiumDialog();
        return;
      }
      if (this.selectedRole === value) {
        this.selectedRole = null;
      } else {
        this.selectedRole = value;
      }
      this.saveSettings();
    },
    selectInterest(value) {
      if (!this.isVip) {
        showPremiumDialog();
        return;
      }
      if (this.selectedInterest === value) {
        this.selectedInterest = null;
      } else {
        this.selectedInterest = value;
      }
      this.saveSettings();
    },
    selectExperience(value) {
      if (!this.isVip) {
        showPremiumDialog();
        return;
      }
      if (this.selectedExperience === value) {
        this.selectedExperience = null;
      } else {
        this.selectedExperience = value;
      }
      this.saveSettings();
    },
    selectRelationship(value) {
      if (!this.isVip) {
        showPremiumDialog();
        return;
      }
      if (this.selectedRelationship === value) {
        this.selectedRelationship = null;
      } else {
        this.selectedRelationship = value;
      }
      this.saveSettings();
    },
    // 保存筛选条件到缓存
    saveSettings() {
      const settingsToSave = {
        role: this.selectedRole,
        interest: this.selectedInterest,
        experience: this.selectedExperience,
        relationship: this.selectedRelationship
      };
      cache.local.setJSON(this.cacheKey, settingsToSave);
    },
    confirm() {
      const filterData = {
        role: this.selectedRole,
        interest: this.selectedInterest,
        experience: this.selectedExperience,
        relationship: this.selectedRelationship
      };
      
      // 保存筛选条件到 localStorage（确保最新状态已保存）
      this.saveSettings();

      if (!this.isVip) {
        showPremiumDialog();
        return
      }
      
      if (this.onConfirm && typeof this.onConfirm === 'function') {
        this.onConfirm(filterData);
      }
      
      this.$refs.bottomDialog.closeDialog();
    },
    closeDialog() {
      this.$refs.bottomDialog.closeDialog();
    },
    // 锁住项文案：首字母正常，其余用五位 * 代替
    maskLockedLabel(label) {
      if (!label || label.length === 0) return '';
      return label[0] + '*'.repeat(5);
    }
  }
};
</script>

<style scoped lang="less">
.filter-content {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-height: 100vh;
  /* 顶部 350px 透明以露出背景图区域，其余为弹窗背景色 */
  background: linear-gradient(to bottom, transparent 350px, #282828 350px);
}

.filter-header {
  margin-top: 50px;
  flex-shrink: 0;
  width: 100%;
  height: 350px;
  background-color: transparent;
  background-size: 100% 100%;
  background-position: center;
  background-repeat: no-repeat;
}

.scrollable-section {
  flex: 1;
  overflow-y: auto;
  margin-top: -20px;
  padding: 0 20px 160px 20px;
  min-height: 0;
}

.filter-category {
  margin-bottom: 15px;
  
  &:last-child {
    margin-bottom: 0;
  }
  
  .category-title {
    font-size: 18px;
    font-weight: bold;
    color: #FFFFFF;
    margin-bottom: 10px;
  }
  
  .category-scroll {
    display: flex;
    overflow-x: auto;
    gap: 12px;
    padding-bottom: 4px;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none; // Firefox
    -ms-overflow-style: none; // IE/Edge
    
    &::-webkit-scrollbar {
      display: none; // Chrome/Safari
    }
  }
}

.option-card {
  flex-shrink: 0;
  width: 123px;
  height: 163px;
  background: #282828; /* 与弹窗背景一致 */
  border-radius: 20px;
  padding: 16px 8px 25px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  box-shadow: inset 0 0 0 1px #404040;
  cursor: pointer;
  transition: all 0.2s;
  
  &.active {
    background: #191919; /* 与弹窗背景一致 */
    box-shadow: inset 0 0 0 2px #FFFFFF;
    
    .option-label {
      font-weight: 600;
      color: rgba(255, 255, 255, 1);
    }
  }
  
  .option-icon {
    width: 119px;
    height: 119px;
    margin-bottom: 2px;
    object-fit: contain;
  }
  
  .option-label {
    margin-top: auto;
    padding-bottom: 0;
    font-size: 14px;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.6);
    text-align: center;
    line-height: 1.2;
  }
}

/* Experience Level 区块：圆形 123×123 */
.filter-category--circle .category-scroll {
  align-items: flex-start;
}

.filter-category--circle .option-card {
  box-sizing: border-box;
  width: 123px;
  height: 123px;
  min-height: 123px;
  border-radius: 50%;
  align-self: flex-start;
  flex-shrink: 0;
  padding: 0 12px 25px;

  .option-icon {
    width: 83px;
    height: 83px;
  }
}

.bottom-fixed-section {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 20px 42px;
  padding-bottom: calc(20px + env(safe-area-inset-bottom));
  padding-bottom: calc(20px + constant(safe-area-inset-bottom));
  background-color: transparent;
  background-image: url("@/assets/image/private/ic-private-bttom@2x.png");
  background-size: 100% 100%;
  background-position: center;
  background-repeat: no-repeat;
}

.save-btn {
  background: url("@/assets/image/private/ic-private-button-bg@2x.png") center / 100% 100% no-repeat;
  color: #fff;
  height: 54px;
  border-radius: 27px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
  flex-shrink: 0;
  width: 100%;
  border: none;
}
</style>

<style lang="less">
// 覆盖底部弹窗样式，设置为固定高度，距离顶部0px
.private-filter-dialog.d-bottom {
  align-items: flex-start !important;
  
  .m-dialog-wrapper {
    align-items: flex-start !important;
  }
  
  .m-dialog {
    top: 0 !important;
    bottom: auto !important;
    max-height: 100vh !important;
    height: 100vh !important;
    border-radius: 20px 20px 0 0 !important;
    position: relative !important;
  }
  
  .m-dialog-body {
    height: 100% !important;
    max-height: 100% !important;
  }
}
</style>
