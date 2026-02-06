<template>
  <m-base-dialog 
    ref="baseDialog" 
    :width="'100%'"
    :click-mask-close-dialog="true"
    dialog-class="user-premium-dialog"
  >
    <template #content>
      <div class="premium-dialog-content">
        <!-- 背景图片：整个弹窗背景 -->
        <img class="premium-bg" :src="premiumBgImg" alt="Premium Background" />
        
        <!-- 上半部分：包含用户头像 -->
        <div class="premium-top-section">
          <!-- 用户头像区域 -->
          <div class="avatar-section">
            <div class="avatar-wrapper">
            <!-- 用户头像 -->
            <img class="user-avatar" :src="userAvatar" @error="handleAvatarError" alt="User Avatar" />
            <!-- 头像背景光环 -->
            <img class="avatar-bg" :src="avatarBgImg" alt="Avatar Background" />
            </div>
          </div>
        </div>
        
        <!-- 会员信息 -->
        <div class="membership-info">
          <p class="greeting">Dear {{ userName }},</p>
          <p class="expire-label">Your Membership Expires On</p>
          <p class="expire-date">{{ formattedExpireDate }}</p>
        </div>
        
        <!-- 剩余天数分隔线 -->
        <div class="remaining-days-section">
          <div class="separator-line">
            <img class="remain-decoration" :src="remainDecorationImg" alt="Decoration" />
          </div>
        </div>
        
        <!-- 剩余天数数字 -->
        <div class="remaining-count-wrapper">
          <p class="remaining-count">{{ remainingDays }}</p>
        </div>
        
        <!-- 操作按钮 -->
        <div class="action-buttons">
          <button class="renew-btn" :style="{ backgroundImage: `url(${buttonBgImg})` }" @click="handleClose">OK</button>
        </div>
      </div>
    </template>
  </m-base-dialog>
</template>

<script>
import MBaseDialog from "@/components/dialog/MBaseDialog.vue";

export default {
  name: 'MUserPremiumDialog',
  components: { MBaseDialog },
  data() {
    return {
      premiumBgImg: require('@/assets/image/dialog/ic-dialog-user-pre-bg.png'),
      avatarBgImg: require('@/assets/image/dialog/ic-dialog-user-pre-avatar-bg.png'),
      remainDecorationImg: require('@/assets/image/dialog/ic-dialog-user-pre-remain.png'),
      buttonBgImg: require('@/assets/image/global/ic-pre-button-bg.png'),
      defaultAvatar: require('@/assets/image/ic-placeholder-avatar.png')
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {};
    },
    userName() {
      return this.userInfo.nickname || this.userInfo.name || 'User';
    },
    userAvatar() {
      return this.userInfo.avatar || this.userInfo.headImage || this.defaultAvatar;
    },
    expireDate() {
      // 从用户信息中获取到期日期，renewTime 是毫秒时间戳
      if (this.userInfo.renewTime) {
        // renewTime 是毫秒时间戳，直接创建 Date 对象
        return new Date(this.userInfo.renewTime);
      }
      return null;
    },
    formattedExpireDate() {
      const date = this.expireDate;
      if (!date) {
        return '';
      }
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                     'July', 'August', 'September', 'October', 'November', 'December'];
      const month = months[date.getMonth()];
      const day = date.getDate();
      const year = date.getFullYear();
      return `${month} ${day}, ${year}`;
    },
    remainingDays() {
      const expire = this.expireDate;
      if (!expire) {
        return 0;
      }
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const expireDate = new Date(expire);
      expireDate.setHours(0, 0, 0, 0);
      const diffTime = expireDate.getTime() - today.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      return diffDays > 0 ? diffDays : 0;
    }
  },
  methods: {
    handleClose() {
      this.$refs.baseDialog.handleClose();
    },
    handleRenew() {
      // 跳转到续费页面
      this.$router.push({ name: 'PagePremium' });
      this.handleClose();
    },
    handleAvatarError(event) {
      event.target.src = this.defaultAvatar;
    }
  }
}
</script>

<style lang="less">
.user-premium-dialog {
  .m-dialog {
    background: transparent !important;
    border-radius: 30px;
    overflow: visible;
    max-width: 95% !important;
  }
}
</style>

<style scoped lang="less">

.premium-dialog-content {
  position: relative;
  width: 100%;
  border-radius: 20px;
  padding: 40px 20px 30px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
  overflow: hidden;
}

.premium-top-section {
  position: relative;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.premium-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  z-index: 1;
  pointer-events: none;
}

.avatar-section {
  position: relative;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
  margin-bottom: 0;
  z-index: 2;
}

.avatar-wrapper {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
}

.user-avatar {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 50%;
  object-fit: cover;
  z-index: 2;
  border: 5px solid #FEEDBC;
}

.avatar-bg {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 180px;
  height: 180px;
  object-fit: contain;
  z-index: 3;
  pointer-events: none;
}

.membership-info {
  text-align: center;
  margin-top: 30px;
  z-index: 2;
  
  .greeting {
    font-size: 16px;
    font-weight: 500;
    margin: 0 0 8px 0;
    line-height: 1;
    color: #A26900;
  }
  
  .expire-label {
    font-size: 16px;
    font-weight: 500;
    margin: 0 0 8px 0;
    line-height: 1;
    color: #A26900;
  }
  
  .expire-date {
    font-size: 16px;
    font-weight: 500;
    margin: 0;
    line-height: 1;
    color: #A26900;
  }
}

.remaining-days-section {
  width: 100%;
  text-align: center;
  margin-bottom: 0;
  z-index: 2;
  
  .separator-line {
    position: relative;
    width: 100%;
    height: 40px;
    display: flex;
    justify-content: center;
    align-items: center;
    margin: 10px 0 0 0;
    
    .remain-decoration {
      position: relative;
      width: 264px;
      height: 18px;
      object-fit: contain;
      z-index: 1;
    }
  }
}

.remaining-count-wrapper {
  width: 100%;
  text-align: center;
  margin-bottom: 20px;
  z-index: 2;
  
  .remaining-count {
    font-size: 48px;
    font-weight: bold;
    color: #000000;
    line-height: 1;
  }
}

.action-buttons {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  z-index: 2;

  .renew-btn {
    width: 85%;
    max-width: 280px;
    height: 52px;
    border-radius: 26px;
    border: none;
    color: #000000;
    font-size: 18px;
    font-weight: 900;
    cursor: pointer;
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
  }
  
  .ok-btn {
    font-size: 18px;
    color: #999999;
    font-weight: 500;
    cursor: pointer;
    user-select: none;
    -webkit-tap-highlight-color: transparent;
    -webkit-touch-callout: none;
    outline: none;
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
  }
}
</style>
