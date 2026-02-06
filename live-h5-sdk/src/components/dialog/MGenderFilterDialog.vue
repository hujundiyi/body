<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="dialogClass">
    <div class="filter-content">
      <div class="filter-header">Gender Filter</div>
      
      <div class="section-title">Match With</div>
      <div class="gender-options">
        <div 
          class="gender-option" 
          :class="{ active: selectedGender === 0 }"
          @click="selectedGender = 0"
        >
          <img :src="getGenderIcon(0)" class="option-icon" />
          <div class="option-name">All</div>
          <div class="option-cost">Free</div>
        </div>
        
        <div 
          class="gender-option" 
          :class="{ active: selectedGender === 2 }"
          @click="selectedGender = 2"
        >
          <img :src="getGenderIcon(2)" class="option-icon" />
          <div class="option-name">Female</div>
          <div class="option-cost">
             <img src="@/assets/image/match/ic-match-coin@2x.png" class="coin-img"/> 10/Match
          </div>
        </div>
        
        <div 
          class="gender-option" 
          :class="{ active: selectedGender === 1 }"
          @click="selectedGender = 1"
        >
          <img :src="getGenderIcon(1)" class="option-icon" />
          <div class="option-name">Male</div>
          <div class="option-cost">
             <img src="@/assets/image/match/ic-match-coin@2x.png" class="coin-img"/> 10/Match
          </div>
        </div>
      </div>

      <div class="action-btn" @click="confirm">
        Go to Match
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import { showSuperMatchHelpDialog } from "@/components/dialog";
import genderIconNo from "@/assets/image/match/ic-match-gender-no@2x.png";
import genderIcon from "@/assets/image/match/ic-match-gender@2x.png";
import nvIconNo from "@/assets/image/match/ic-match-nv-no@2x.png";
import nvIcon from "@/assets/image/match/ic-match-nv@2x.png";
import nanIconNo from "@/assets/image/match/ic-match-nan-no@2x.png";
import nanIcon from "@/assets/image/match/ic-match-nan@2x.png";

export default {
  name: "MGenderFilterDialog",
  components: { MBottomDialog },
  props: {
    onConfirm: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    return {
      selectedGender: 0, // 0: All, 1: Male, 2: Female
      isClosing: false
    };
  },
  computed: {
    dialogClass() {
      return `match-filter-dialog${this.isClosing ? ' is-closing' : ''}`;
    },
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    }
  },
  methods: {
    confirm() {
      if (this.onConfirm) {
        this.onConfirm({ gender: this.selectedGender });
      }
      this.$refs.bottomDialog.closeDialog();
    },
    openHelp() {
      showSuperMatchHelpDialog();
    },
    getGenderIcon(gender) {
      const isActive = this.selectedGender === gender;
      if (gender === 0) {
        // All
        return isActive ? genderIcon : genderIconNo;
      } else if (gender === 2) {
        // Female
        return isActive ? nvIcon : nvIconNo;
      } else if (gender === 1) {
        // Male
        return isActive ? nanIcon : nanIconNo;
      }
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
  padding-bottom: 40px;
}

.filter-header {
  font-size: 22px;
  font-weight: heavy;
  margin-bottom: 20px;
}

.section-title {
  color: #999;
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 12px;
}

.gender-options {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 24px;
}

.gender-option {
  flex: 1;
  background: #373737;
  border-radius: 12px;
  padding: 16px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border: 2px solid transparent;
  cursor: pointer;
  
  &.active {
    border-color: white;
    background: #282828;
    
    .option-name {
      font-weight: 800;
    }
  }
  
  .option-icon {
    width: 40px;
    height: 40px;
    margin-bottom: 8px;
    object-fit: contain;
  }
  
  .option-name {
    font-size: 16px;
    font-weight: 500;
    margin-bottom: 4px;
  }
  
  .option-cost {
    font-size: 12px;
    color: #999;
    display: flex;
    align-items: center;
    
    .coin-img {
      width: 12px;
      height: 12px;
      margin-right: 2px;
    }
  }
}


.action-btn {
  background: white;
  color: black;
  height: 48px;
  border-radius: 24px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
}


:deep(.hint-dialog.d-bottom.match-filter-dialog) {
  transition: transform 0.25s ease, opacity 0.25s ease;
    }

:deep(.hint-dialog.d-bottom.match-filter-dialog.is-closing) {
  transform: translateY(100%);
  opacity: 0;
}
</style>
