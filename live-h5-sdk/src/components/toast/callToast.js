import Vue from "vue";
import MCallToast from "@/components/toast/MCallToast.vue";
import MLoadingToast from "@/components/toast/MLoadingToast.vue";

let currentToast = null;
let currentLoadingToast = null;

function createCallToast(props) {
  const Instance = new Vue({
    render: h => h(MCallToast, { props })
  });
  Instance.$mount();
  return Instance.$children[0];
}

/**
 * 显示通话中的自定义Toast
 * @param {string} msg - 提示文案
 * @param {number} duration - 显示时长，默认3000ms
 */
export function showCallToast(msg = 'The person is not online at the moment.', duration = 3000) {
  // 如果已有toast，先关闭
  if (currentToast) {
    currentToast.close();
    currentToast = null;
  }

  const toast = createCallToast({
    message: msg,
    duration
  });

  currentToast = toast;

  toast.$on('close', () => {
    currentToast = null;
  });

  return toast;
}

/**
 * 关闭当前的通话Toast
 */
export function closeCallToast() {
  if (currentToast) {
    currentToast.close();
    currentToast = null;
  }
}

/**
 * 创建Loading Toast实例
 */
function createLoadingToast(props) {
  const Instance = new Vue({
    render: h => h(MLoadingToast, { props })
  });
  Instance.$mount();
  return Instance.$children[0];
}

/**
 * 显示Loading Toast（带菊花动画）
 * @param {string} msg - 提示文案（可选）
 * @returns {object} toast实例，可调用close()关闭
 */
export function showLoadingToast(msg = '') {
  // 如果已有loading toast，先关闭
  if (currentLoadingToast) {
    currentLoadingToast.close();
    currentLoadingToast = null;
  }

  const toast = createLoadingToast({
    message: msg
  });

  currentLoadingToast = toast;

  toast.$on('close', () => {
    currentLoadingToast = null;
  });

  return toast;
}

/**
 * 关闭当前的Loading Toast
 */
export function closeLoadingToast() {
  if (currentLoadingToast) {
    currentLoadingToast.close();
    currentLoadingToast = null;
  }
}
