import Vue from 'vue';
import store from '@/store';
import { router } from '@/router';
import cache from '@/utils/cache';
import { key_cache } from '@/utils/Constant';
import MRechargeDialog from "@/components/dialog/MRechargeDialog.vue";
import MGiftChangeDialog from "@/components/dialog/MGiftChangeDialog.vue";
import MShowGiftDialog from "@/components/dialog/MShowGiftDialog.vue";
import MGiftDialog from "@/components/dialog/MGiftDialog.vue";
import MHintDialog from "@/components/dialog/MHintDialog.vue";
import MReportDialog from "@/components/dialog/MReportDialog.vue";
import MGenderFilterDialog from "@/components/dialog/MGenderFilterDialog.vue";
import MCountryFilterDialog from "@/components/dialog/MCountryFilterDialog.vue";
import MSuperMatchHelpDialog from "@/components/dialog/MSuperMatchHelpDialog.vue";
import MCreateAccountDialog from "@/components/dialog/MCreateAccountDialog.vue";
import MAgePickerDialog from "@/components/dialog/MAgePickerDialog.vue";
import MPhotoPickerDialog from "@/components/dialog/MPhotoPickerDialog.vue";
import MTipsDialog from "@/components/dialog/MTipsDialog.vue";
import MExitDialog from "@/components/dialog/MExitDialog.vue";
import MCleanCacheDialog from "@/components/dialog/MCleanCacheDialog.vue";
import MConfirmDialog from "@/components/dialog/MConfirmDialog.vue";
import MDeletePhotoDialog from "@/components/dialog/MDeletePhotoDialog.vue";
import MResetFilterDialog from "@/components/dialog/MResetFilterDialog.vue";
import MUserListFilterDialog from "@/components/dialog/MUserListFilterDialog.vue";
import MUserDetailMoreDialog from "@/components/dialog/MUserDetailMoreDialog.vue";
import MNewUserDialog from "@/components/dialog/MNewUserDialog.vue";
import MPremiumDialog from "@/components/dialog/MPremiumDialog.vue";

import MCheckinDialog from "@/components/dialog/MCheckinDialog.vue";
import MUserPremiumDialog from "@/components/dialog/MUserPremiumDialog.vue";

import MRechargePromoDialog from "@/components/dialog/MRechargePromoDialog.vue";
import MPurchaseSuccessDialog from "@/components/dialog/MPurchaseSuccessDialog.vue";
import MVipSuccessDialog from "@/components/dialog/MVipSuccessDialog.vue";
import FeedBack from "@/views/home/me/page/FeedBack.vue";
import Report from "@/views/home/me/page/Report.vue";
import MPrivateFilter from "@/components/dialog/MPrivateFilter.vue";
import { DialogTaskArray } from "@/components/dialog/DialogTaskArray";

const RECHARGE_PROMO_DIALOG_NAME = 'MRechargePromoDialog';

function createDialog(component, propsData = {}) {
  const Dialog = Vue.extend(component);
  const dialog = new Dialog({
    propsData,
    store,
    router
  });
  dialog.$mount();
  document.body.appendChild(dialog.$el);
  return dialog;
}

function getBaseDialog(children) {
  if (!children || children.length === 0) return null;
  for (let i = 0; i < children.length; i++) {
    const child = children[i];
    if (child.dialogVisible !== undefined) {
      return child;
    }
    const res = getBaseDialog(child.$children);
    if (res) return res;
  }
  return null;
}

export function showRechargeDialog(options = false) {
  // 兼容旧的调用方式：showRechargeDialog(true) 或 showRechargeDialog(false)
  let showMessage = false;
  let onSuccess = null;
  let from = '';

  if (typeof options === 'boolean') {
    showMessage = options;
  } else if (options && typeof options === 'object') {
    // 如果是事件对象，忽略
    if (options.target) {
      showMessage = false;
    } else {
      // 新的调用方式：showRechargeDialog({ showMessage: true, onSuccess: () => {}, from: 'xxx' })
      showMessage = Boolean(options.showMessage);
      onSuccess = options.onSuccess || null;
      from = options.from || '';
    }
  }

  const dialog = createDialog(MRechargeDialog, { showMessage, onSuccess, from });
  const base = getBaseDialog(dialog.$children);
  if (base) {
    base.dialogVisible = true;
    store.commit('PageCache/SET_RECHARGE_DIALOG_VISIBLE', true);
    const unwatch = dialog.$watch(
      () => base.dialogVisible,
      (visible) => {
        if (visible === false) {
          store.commit('PageCache/SET_RECHARGE_DIALOG_VISIBLE', false);
          unwatch();
        }
      }
    );
  }
  return dialog;
}

export function showGiftCheckDialog(onChange) {
  const dialog = createDialog(MGiftChangeDialog, { onChange });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

// SVGA 播放队列 - 避免同时播放多个动画导致内存溢出
const svgaQueue = [];
let isPlayingSvga = false;
let currentSvgaDialog = null;

function processNextSvga() {
  if (svgaQueue.length === 0) {
    isPlayingSvga = false;
    currentSvgaDialog = null;
    return;
  }
  
  isPlayingSvga = true;
  const svgaUrl = svgaQueue.shift();
  
  const dialog = createDialog(MShowGiftDialog, { svgaUrl });
  currentSvgaDialog = dialog;
  const base = getBaseDialog(dialog.$children);
  
  if (base) {
    base.dialogVisible = true;
    
    // 标记是否已处理关闭，防止重复触发
    let hasHandledClose = false;
    
    // 监听 dialog 关闭，然后销毁组件并播放下一个
    const unwatch = dialog.$watch(
      () => base.dialogVisible,
      (visible, oldVisible) => {
        // 只处理从 true 变为 false 的情况，且只处理一次
        if (oldVisible === true && visible === false && !hasHandledClose) {
          hasHandledClose = true;
          unwatch();
          // 延迟销毁，确保动画完成
          setTimeout(() => {
            destroySvgaDialog(dialog);
            processNextSvga();
          }, 100);
        }
      }
    );
  }
}

function destroySvgaDialog(dialog) {
  if (!dialog) return;
  try {
    // 调用组件的 cleanup 方法
    if (typeof dialog.cleanup === 'function') {
      dialog.cleanup();
    }
    // 从 DOM 中移除
    if (dialog.$el && dialog.$el.parentNode) {
      dialog.$el.parentNode.removeChild(dialog.$el);
    }
    // 销毁 Vue 实例
    dialog.$destroy();
  } catch (e) {
    console.warn('destroySvgaDialog error:', e);
  }
  if (currentSvgaDialog === dialog) {
    currentSvgaDialog = null;
  }
}

export function showGiftDialog(svgaUrl) {
  // 加入队列
  svgaQueue.push(svgaUrl);
  
  // 如果当前没有在播放，开始处理队列
  if (!isPlayingSvga) {
    processNextSvga();
  }
}

export function showGiftGoodsDialog({ userId, onSend } = {}) {
  const dialog = createDialog(MGiftDialog, { userId, onSend });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

export function showHintDialog(message, onButtonClick) {
  const dialog = createDialog(MHintDialog, { message, onButtonClick });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showUserReportPopup(reportedUserId) {
  const dialog = createDialog(MReportDialog, { reportedUserId });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showGenderFilterDialog(onConfirm) {
  const dialog = createDialog(MGenderFilterDialog, { onConfirm });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showCountryFilterDialog(onConfirm) {
  const dialog = createDialog(MCountryFilterDialog, { onConfirm });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showSuperMatchHelpDialog() {
  const dialog = createDialog(MSuperMatchHelpDialog);
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showCreateAccountDialog(onConfirm) {
  const dialog = createDialog(MCreateAccountDialog, { onConfirm });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showAgePickerDialog(initialAge, onConfirm) {
  const dialog = createDialog(MAgePickerDialog, { initialAge, onConfirm });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showPhotoPickerDialog({ onTakePhoto, onPhotoLibrary, onCancel } = {}) {
  const dialog = createDialog(MPhotoPickerDialog, { onTakePhoto, onPhotoLibrary, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showTipsDialog({ onConfirm, onCancel } = {}) {
  const dialog = createDialog(MTipsDialog, { onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showExitDialog({ onConfirm, onCancel } = {}) {
  const dialog = createDialog(MExitDialog, { onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showDeletePhotoDialog({ onConfirm, onCancel } = {}) {
  const dialog = createDialog(MDeletePhotoDialog, { onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showResetFilterDialog({ onReset, onCancel } = {}) {
  const dialog = createDialog(MResetFilterDialog, { onReset, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

export function showCleanCacheDialog({ onConfirm, onCancel } = {}) {
  const dialog = createDialog(MCleanCacheDialog, { onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showConfirmDialog({ title, message, confirmText, cancelText, onConfirm, onCancel } = {}) {
  const dialog = createDialog(MConfirmDialog, { title, message, confirmText, cancelText, onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showUserListFilterDialog({ onConfirm, onCancel } = {}) {
  const dialog = createDialog(MUserListFilterDialog, { onConfirm, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showUserDetailMoreDialog({ onBlock, onReport, onBlockAndReport, onFeedback, onCancel } = {}) {
  const dialog = createDialog(MUserDetailMoreDialog, { onBlock, onReport, onBlockAndReport, onFeedback, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
}

export function showNewUserDialog({ onMatch } = {}) {
  // 检查是否已经显示过
  const hasShown = cache.local.get(key_cache.dialog_show_new_user);
  if (hasShown) {
    return null; // 已经显示过，不再显示
  }
  
  const dialog = createDialog(MNewUserDialog, { onMatch });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

export function showFeedbackDialog({ onSuccess, onCancel } = {}) {
  const dialog = createDialog(FeedBack, { onSuccess, onCancel });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

export function showReportDialog({ userId, userInfo, onSuccess, onCancel, needBlock } = {}) {
  const dialog = createDialog(Report, { userId, userInfo, onSuccess, onCancel, needBlock });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

const PREMIUM_DIALOG_NAME = 'MPremiumDialog';

export function showPremiumDialog() {
  const dialog = createDialog(MPremiumDialog);
  const base = getBaseDialog(dialog.$children);
  if (base) {
    base.dialogVisible = true;
    DialogTaskArray.push(dialog);
    store.commit('PageCache/SET_PREMIUM_DIALOG_VISIBLE', true);
    const unwatch = dialog.$watch(
      () => base.dialogVisible,
      (visible) => {
        if (visible === false) {
          store.commit('PageCache/SET_PREMIUM_DIALOG_VISIBLE', false);
          unwatch();
        }
      }
    );
  }
  return dialog;
}

export function showCheckinDialog(options = {}) {
  // options 可以包含 testVipCategory: 1=周会员, 2=月会员, 3=年度会员
  const dialog = createDialog(MCheckinDialog, { testVipCategory: options.testVipCategory });
  const base = getBaseDialog(dialog.$children);
  if (base) {
    base.dialogVisible = true;
    store.commit('PageCache/SET_CHECKIN_DIALOG_VISIBLE', true);
    const unwatch = dialog.$watch(
      () => base.dialogVisible,
      (visible) => {
        if (visible === false) {
          store.commit('PageCache/SET_CHECKIN_DIALOG_VISIBLE', false);
          unwatch();
        }
      }
    );
  }
  return dialog;
}

export function showPurchaseSuccessDialog(receivedData) {
  const dialog = createDialog(MPurchaseSuccessDialog, {
    receivedData: receivedData
  });
  const base = getBaseDialog(dialog.$children);
  if (base) {
    base.dialogVisible = true;
  }
  return dialog;
}

export function showPrivateFilterDialog(onConfirm) {
    const dialog = createDialog(MPrivateFilter, {onConfirm});
    const base = getBaseDialog(dialog.$children);
    if (base) base.dialogVisible = true;
    return dialog;
}
export function showRechargePromoDialog() {
    console.log('showRechargePromoDialog 被调用');
    const dialog = createDialog(MRechargePromoDialog);
    console.log('弹窗组件已创建:', dialog);
    const base = getBaseDialog(dialog.$children);
    console.log('找到 base dialog:', base);
    if (base) {
      base.dialogVisible = true;
      DialogTaskArray.push(dialog);
      store.commit('PageCache/SET_RECHARGE_PROMO_DIALOG_VISIBLE', true);
      const unwatch = dialog.$watch(
        () => base.dialogVisible,
        (visible) => {
          if (visible === false) {
            store.commit('PageCache/SET_RECHARGE_PROMO_DIALOG_VISIBLE', false);
            unwatch();
          }
        }
      );
      console.log('dialogVisible 已设置为 true');
    } else {
      console.warn('未找到 base dialog 组件');
    }
    return dialog;
}

export function closeAllDialogs() {
  while (!DialogTaskArray.isEmpty()) {
    DialogTaskArray.closeDialog();
  }
}

/** 若 MRechargePromoDialog 已打开则关闭它 */
export function closeRechargePromoDialogIfOpen() {
  return DialogTaskArray.closeDialogByName(RECHARGE_PROMO_DIALOG_NAME);
}

/** 若 MPremiumDialog（VIP 弹窗）已打开则关闭它 */
export function closePremiumDialogIfOpen() {
  const closed = DialogTaskArray.closeDialogByName(PREMIUM_DIALOG_NAME);
  if (closed) store.commit('PageCache/SET_PREMIUM_DIALOG_VISIBLE', false);
  return closed;
}

export function showUserPremiumDialog() {
  const dialog = createDialog(MUserPremiumDialog);
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}

/**
 * VIP 充值成功弹窗（皇冠+金币、CONGRATS、签到领金币）
 * @param {Object} options - { benefitsCount, consecutiveDays, freeCoins }
 */
export function showVipSuccessDialog(options = {}) {
  const dialog = createDialog(MVipSuccessDialog, {
    benefitsCount: options.benefitsCount ?? 15,
    consecutiveDays: options.consecutiveDays ?? 0,
    freeCoins: options.freeCoins ?? 0
  });
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = true;
  return dialog;
}
