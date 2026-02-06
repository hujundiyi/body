<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'report-dialog'" :enableSwipeClose = "false">
    <div class="dialog-content">
      <!-- 标题栏 - 固定在顶部 -->
      <div class="dialog-header">
        <h2 class="dialog-title">Report</h2>
        <div class="close-btn" @click="closeDialog">
          <span class="close-icon">×</span>
        </div>
      </div>

      <!-- 可滚动内容区域 -->
      <div class="scrollable-content">
        <!-- 被举报用户信息 -->
        <div class="user-info-section">
          <div class="user-details">
              <p class="user-name">{{ mergedUserInfo.nickname || mergedUserInfo.name || 'User' }}</p>
              <p class="user-id">ID:{{ mergedUserInfo.userId || userId }}</p>
          </div>
            <img
              class="user-avatar"
              :src="mergedUserInfo.headImage || mergedUserInfo.avatar || require('@/assets/image/sdk/ic-logo.png')"
              alt="User avatar"
            />
        </div>

        <!-- 报告原因 -->
        <div class="reason-section">
          <h2 class="section-title">Reason</h2>
          <div class="reason-buttons">
            <button
              v-for="(reason, index) in reasonOptions"
              :key="index"
              class="reason-btn"
              :class="{ active: selectedReason === reason.value }"
              @click="toggleReason(reason)"
            >
              {{ reason.label }}
            </button>
          </div>
        </div>

        <!-- 详细信息 -->
        <div class="details-section">
          <h2 class="section-title">Details</h2>
          <p class="details-description">
            Providing detailed information helps us address the issue promptly and thoroughly.
          </p>
          <div class="input-wrapper">
            <textarea
              v-model="form.details"
              placeholder="Add..."
              maxlength="300"
              class="details-textarea"
              ref="textareaInput"
              @input="handleInput"
            ></textarea>
            <span class="char-count">{{ form.details.length }}/300</span>
          </div>
          <div class="feedback-messages">
            <div class="feedback-item">
              <img src="@/assets/image/sdk/ic-report-warn.png" alt="Warning" class="warn-icon"/>
              <span>Your feedback matters.</span>
            </div>
            <div class="feedback-item">
              <img src="@/assets/image/sdk/ic-report-warn.png" alt="Warning" class="warn-icon"/>
              <span>Clearly describing the issue helps us take action and maintain a safe, welcoming community.</span>
            </div>
          </div>
        </div>

        <!-- 内容区域底部占位，为固定按钮留出空间 -->
        <div class="content-bottom-spacer"></div>
      </div>

      <!-- 提交按钮 - 固定在底部 -->
      <div class="dialog-actions">
        <button
          class="submit-btn"
          @click="handleSubmit"
          :class="{ disabled: !canSubmit }"
          :disabled="!canSubmit"
        >
          Submit
        </button>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import {userReport, statusBlack} from "@/api/sdk/user";
import { getUserInfo } from "@/api";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'PageReport',
  components: { MBottomDialog },
  props: {
    userId: {
      type: [Number, String],
      default: null
    },
    userInfo: {
      type: Object,
      default: () => ({})
    },
    onSuccess: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    },
    needBlock: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      selectedReason: null, // 单选，存储选中的 reason value
      form: {
        details: ''
      },
      internalUserInfo: {}
    }
  },
  computed: {
    canSubmit() {
      return this.selectedReason !== null && this.form.details.trim().length > 0;
    },
    // 从 store 中获取举报原因选项
    reasonOptions() {
      const dictList = this.$store.state.PageCache.dict || [];
      // 查找 dictType 为 'report_type' 的字典项
      const reportTypeDict = dictList.find(item => item.dictType === 'report_type');
      if (reportTypeDict && reportTypeDict.dictItems) {
        // 返回 dictItems，每个项包含 value 和 label
        return reportTypeDict.dictItems.map(item => ({
          label: item.label,
          value: item.value
        }));
      }
      // 如果没有找到字典数据，返回默认值
      return [];
    },
    // 合并传入的 userInfo 和内部获取的 userInfo
    mergedUserInfo() {
      return Object.keys(this.internalUserInfo).length > 0 ? this.internalUserInfo : this.userInfo;
    }
  },
  mounted() {
    console.log('=== Report Component Mounted ===');
    console.log('needBlock prop:', this.needBlock);
    console.log('userId prop:', this.userId);
    this.initUserInfo();
  },
  methods: {
    handleInput() {
      // 输入时确保内容不超过最大长度
      if (this.form.details.length > 300) {
        this.form.details = this.form.details.substring(0, 300);
      }
    },
    initUserInfo() {
      // 如果通过 props 传入 userId，优先使用
      const targetUserId = this.userId || null;

      // 如果通过 props 传入 userInfo，直接使用
      if (this.userInfo && Object.keys(this.userInfo).length > 0) {
        this.internalUserInfo = { ...this.userInfo };
        return;
      }

      // 如果没有传入用户信息但有 userId，调用 API 获取
      if (targetUserId) {
        getUserInfo(targetUserId).then((rsp) => {
          if (rsp && rsp.data) {
            this.internalUserInfo = {
              userId: rsp.data.userId || targetUserId,
              nickname: rsp.data.nickname || rsp.data.name || '',
              name: rsp.data.name || rsp.data.nickname || '',
              headImage: rsp.data.headImage || rsp.data.avatar || '',
              avatar: rsp.data.avatar || rsp.data.headImage || ''
            };
          }
        }).catch((err) => {
          console.error('获取用户信息失败:', err);
        });
      }
    },
    toggleReason(reason) {
      // 单选：如果点击的是已选中的项，则取消选择；否则选择该项
      if (this.selectedReason === reason.value) {
        this.selectedReason = null;
      } else {
        this.selectedReason = reason.value;
      }
    },
    async handleSubmit() {
      if (!this.canSubmit) {
        return;
      }

      const targetUserId = this.userId || this.mergedUserInfo.userId;
      if (!targetUserId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        // 如果需要拉黑，先调用拉黑接口
        console.log('=== Report Submit ===');
        console.log('needBlock:', this.needBlock);
        console.log('targetUserId:', targetUserId);

        if (this.needBlock) {
          console.log('开始调用拉黑接口...');
          const blockRsp = await statusBlack(targetUserId, true);
          console.log('拉黑接口响应:', blockRsp);
          if (!blockRsp || !(blockRsp.success || blockRsp.code === 200 || blockRsp.code === 0)) {
            showCallToast('Failed to block user');
            return;
          }
          console.log('拉黑成功');
        }

        // 构建举报数据
        // 根据接口文档：reportType (integer) - 举报原因, reportedType (string) - 被举报类型, reportedId - 被举报ID
        const reportData = {
          reportType: this.selectedReason, // 举报原因ID (使用 value)
          reportedType: 'USER_INFO', // 被举报类型
          reportedId: targetUserId, // 被举报用户ID
        };

        const rsp = await userReport(reportData);
        if (rsp && (rsp.success || rsp.code === 200 || rsp.code === 0)) {
          showCallToast(this.needBlock ? 'User blocked and reported successfully' : 'Report submitted successfully');
          if (this.onSuccess) {
            this.onSuccess();
          }
          // 清空表单
          this.selectedReason = null;
          this.form.details = '';
          // 延迟关闭对话框
          setTimeout(() => {
            this.closeDialog();
          }, 1500);
        } else {
          showCallToast('Failed to submit report');
        }
      } catch (err) {
        console.error('提交失败:', err);
        showCallToast('Failed to submit');
      }
    },
    closeDialog() {
      this.$refs.bottomDialog.closeDialog();
    }
  }
}
</script>

<style scoped lang="less">
.dialog-content {
  background: #1A1A1A;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 0;
  color: white;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  -webkit-overflow-scrolling: touch;
  pointer-events: auto !important;
  position: relative;
  z-index: 1;
}

.dialog-header {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px 20px 16px;
  position: relative;
  flex-shrink: 0;
  position: sticky;
  top: 0;
  background: #1A1A1A;
  z-index: 10;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
}

.scrollable-content {
  flex: 1;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  padding-bottom: 0;
}

.content-bottom-spacer {
  height: 90px; /* 为底部固定按钮留出空间 */
  flex-shrink: 0;
}

.dialog-title {
  font-size: 18px;
  font-weight: bold;
  color: #ffffff;
  margin: 0;
  text-align: center;
}

.close-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 10;

  .close-icon {
    font-size: 24px;
    color: #ffffff;
    line-height: 1;
    font-weight: 300;
  }

  &:active {
    opacity: 0.7;
  }
}

/* 用户信息区域 */
.user-info-section {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
  padding: 0 20px;
}

.user-details {
  flex: 1;
}

.user-name {
  font-size: 24px;
  color: #999999;
  margin: 0 0 8px 0;
}

.user-id {
  font-size: 14px;
  color: #999;
  margin: 0;
}

.user-avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #282828;
}

/* 原因区域 */
.reason-section {
  margin-bottom: 40px;
  padding: 0 20px;
}

.section-title {
  font-size: 18px;
  color: #ffffff;
  margin: 0 0 16px 0;
  text-align: left;
}

.reason-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.reason-btn {
  padding: 10px 20px;
  background-color: #282828;
  border: 1px solid #383838;
  border-radius: 20px;
  color: #999;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  outline: none;

  &:active {
    transform: scale(0.98);
  }

  &.active {
    background-color: transparent;
    border-color: #ffffff;
    color: #ffffff;
  }
}

/* 详细信息区域 */
.details-section {
  margin-bottom: 40px;
  padding: 0 20px;
}

.details-description {
  font-size: 14px;
  color: #999;
  line-height: 1.5;
  margin: 0 0 16px 0;
}

.input-wrapper {
  position: relative;
  border: 1px solid #282828;
  border-radius: 12px;
  overflow: hidden;
  margin-bottom: 20px;
  background-color: #1a1a1a;
  pointer-events: auto !important;
}

.details-textarea {
  width: 100%;
  min-height: 150px;
  background-color: transparent;
  border: none;
  border-radius: 12px;
  color: #ffffff;
  font-size: 16px !important; /* 防止 iOS 自动缩放 */
  line-height: 1.5;
  padding: 15px;
  padding-bottom: 40px;
  box-sizing: border-box;
  -webkit-appearance: none;
  appearance: none;
  resize: none;
  pointer-events: auto !important;
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
  font-family: inherit;
  outline: none;

  &::placeholder {
    color: #666;
  }

  &:focus {
    outline: none;
  }
}

.char-count {
  position: absolute;
  bottom: 10px;
  right: 15px;
  font-size: 12px;
  color: #666;
  pointer-events: none;
}

.feedback-messages {
  margin-top: 20px;
}

.feedback-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 12px;

  .warn-icon {
    width: 16px;
    height: 16px;
    margin-right: 8px;
    margin-top: 0px;
    flex-shrink: 0;
    object-fit: contain;
  }

  span {
    font-size: 12px;
    color: #666666;
    line-height: 1.5;
    flex: 1;
  }
}

.dialog-actions {
  position: sticky;
  bottom: 0;
  padding: 20px;
  padding-bottom: calc(20px + constant(safe-area-inset-bottom)); /* iOS < 11.2 */
  padding-bottom: calc(20px + env(safe-area-inset-bottom));
  background: #1A1A1A;
  flex-shrink: 0;
  z-index: 10;
  box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.3);
}

.submit-btn {
  width: 100%;
  height: 54px;
  background-color: #666666;
  border: none;
  border-radius: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 500;
  color: #000000;
  cursor: pointer;
  transition: background-color 0.2s;
  box-sizing: border-box;
  outline: none;

  &:not(.disabled) {
    background-color: #FFFFFF;
    color: #000000;
  }

  &.disabled {
    background-color: #666666;
    color: #999999;
    cursor: not-allowed;
  }
}
</style>

<style lang="less">
/* 覆盖 MBottomDialog 的样式，确保举报对话框正确显示 */
.report-dialog.d-bottom {
  border-radius: 0 !important;
}

.report-dialog.d-bottom .m-dialog {
  pointer-events: auto !important;
}

.report-dialog.d-bottom .m-dialog-body {
  pointer-events: auto !important;
  overflow: visible !important;
}

.report-dialog.d-bottom .move-wrap {
  border-radius: 0 !important;
  display: flex !important;
  flex-direction: column !important;
  max-height: 90vh !important;
  pointer-events: auto !important;
  transform: none !important;
}
</style>
