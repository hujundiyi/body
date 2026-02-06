<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'feedback-dialog'" :enable-swipe-close="false">
    <div class="dialog-content">
      <div class="dialog-header">
        <h1 class="dialog-title">Feedback</h1>
        <p class="dialog-subtitle">Please share the details of your issue, and we'll get back to you soon</p>
      </div>

      <div class="input-wrapper">
        <textarea
          v-model="form.content"
          placeholder="Input..."
          maxlength="300"
          class="feedback-textarea"
          ref="textareaInput"
          @input="handleInput"
        ></textarea>
        <div class="word-count">{{ form.content.length }}/300</div>
      </div>

      <div class="dialog-actions">
        <div class="submit-btn" @click="handleSubmit" :class="{ disabled: !canSubmit }">
          Submit
        </div>
      </div>

      <!-- 底部透明占位，用于间距和安全区域 -->
      <div class="bottom-spacer"></div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import {userFeedback} from "@/api/sdk/user";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'FeedBack',
  components: { MBottomDialog },
  props: {
    onSuccess: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    return {
      form: {
        content: ''
      }
    }
  },
  computed: {
    canSubmit() {
      return this.form.content && this.form.content.trim().length > 0;
    }
  },
  methods: {
    handleInput() {
      // 输入时确保内容不超过最大长度
      if (this.form.content.length > 300) {
        this.form.content = this.form.content.substring(0, 300);
      }
    },
    handleSubmit() {
      if (!this.canSubmit) {
        return;
      }

      // 调用反馈API
      const feedbackData = {
        type: 0,
        reason: this.form.content.trim(),
        imgUrl: '',
        contactEmail:'',
      };

      userFeedback(feedbackData).then(({success}) => {
        if (success) {
          showCallToast('Feedback submitted successfully');
          if (this.onSuccess) {
            this.onSuccess();
          }
          setTimeout(() => {
            this.form.content = '';
            this.closeDialog();
          }, 1500);
        }
      }).catch(() => {
        showCallToast('Failed to submit feedback');
      });
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
  padding: 20px;
  color: white;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  pointer-events: auto !important;
  position: relative;
  z-index: 1;
}

.dialog-header {
  margin-bottom: 20px;
}

.dialog-title {
  font-size: 22px;
  font-weight: bold;
  color: white;
  margin: 0 0 8px 0;
  text-align: left;
}

.dialog-subtitle {
  font-size: 15px;
  color: #999;
  line-height: 1.5;
  margin: 0;
  text-align: left;
}

.input-wrapper {
  margin-bottom: 20px;
  border: 3px solid #282828;
  border-radius: 8px;
  overflow: hidden;
  flex: 1;
  min-height: 200px;
  display: flex;
  flex-direction: column;
  pointer-events: auto !important;
  position: relative;
  z-index: 1;
}

.feedback-textarea {
  width: 100%;
  flex: 1;
  min-height: 200px;
  background-color: transparent;
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 16px !important; /* 防止 iOS 自动缩放 */
  line-height: 1.5;
  padding: 15px;
  padding-bottom: 40px;
  box-sizing: border-box;
  /* 防止键盘弹起时页面异常 */
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

.word-count {
  position: absolute;
  bottom: 10px;
  right: 15px;
  color: #666;
  font-size: 12px;
  pointer-events: none;
}

.dialog-actions {
  margin-top: 20px;
}

.bottom-spacer {
  width: 100%;
  height: calc(20px + constant(safe-area-inset-bottom)); /* iOS < 11.2，底部间距 20px + 安全区域 */
  height: calc(20px + env(safe-area-inset-bottom)); /* 底部间距 20px + 安全区域 */
  flex-shrink: 0;
  background: transparent;
}

.submit-btn {
  width: 100%;
  height: 54px;
  background-color: white;
  border-radius: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 500;
  color: #000;
  cursor: pointer;
  transition: background-color 0.2s;
  box-sizing: border-box;

  &:active {
    background-color: #f0f0f0;
  }

  &.disabled {
    background-color: #666;
    color: #999;
    cursor: not-allowed;

    &:active {
      background-color: #666;
    }
  }
}
</style>

<style lang="less">
/* 覆盖 MBottomDialog 的样式，确保反馈对话框正确显示 */
.feedback-dialog.d-bottom {
  border-radius: 0 !important;
}


.feedback-dialog.d-bottom .m-dialog {
  pointer-events: auto !important;
}

.feedback-dialog.d-bottom .m-dialog-body {
  pointer-events: auto !important;
  overflow: visible !important;
}

.feedback-dialog.d-bottom .move-wrap {
  border-radius: 0 !important;
  display: flex !important;
  flex-direction: column !important;
  max-height: 90vh !important;
  pointer-events: auto !important;
  transform: none !important;
}
</style>
