import '@/assets/css/global.less';
import Vue from 'vue'
import App from './App.vue'
import {router} from './router';
import i18n from './assets/i18n';
import store from './store'
import clientEach from "@/utils/ClientEach";
import MPageWrap from "@/components/MPageWrap.vue";
import MButton from "@/components/MButton.vue";
import MActionBar from "@/components/MActionBar.vue";
import {showHintDialog} from "@/components/dialog";

// vconsole 调试工具（仅非生产环境）
if (process.env.NODE_ENV !== 'production') {
  const VConsole = require('vconsole');
  new VConsole();
}
Vue.prototype.$showHintDialog = showHintDialog
// 全局组件挂载
Vue.component('MPageWrap', MPageWrap)
Vue.component('MActionBar', MActionBar)
Vue.component('MButton', MButton)

// 注册 swipe-close 指令，用于向下滑动关闭对话框
Vue.directive('swipe-close', {
  bind(el, binding) {
    // 如果 binding.value 为 null、undefined 或 false，不绑定事件监听器
    // 这样可以避免影响内部元素的滚动（如年龄选择器）
    if (!binding.value || typeof binding.value !== 'function') {
      return;
    }

    let startY = 0;
    let currentY = 0;
    let isSwipeDown = false;
    let originalTransform = '';
    const threshold = 50; // 滑动阈值，超过这个距离才触发关闭

    const touchStart = (e) => {
      if (e.touches.length === 1) {
        startY = e.touches[0].clientY;
        isSwipeDown = false;
        // 保存原始的 transform 值
        originalTransform = el.style.transform || '';
      }
    };

    const touchMove = (e) => {
      if (e.touches.length === 1) {
        currentY = e.touches[0].clientY;
        const deltaY = currentY - startY;
        
        // 只处理向下滑动
        if (deltaY > 0) {
          isSwipeDown = true;
          e.preventDefault(); // 防止页面滚动
          // 添加视觉反馈
          const opacity = Math.min(1 - deltaY / 300, 1);
          el.style.opacity = opacity;
          // 保留原有的 transform，在此基础上添加 translateY
          const baseTransform = originalTransform || '';
          const translateY = `translateY(${Math.min(deltaY, 200)}px)`;
          if (baseTransform && !baseTransform.includes('translateY')) {
            el.style.transform = `${baseTransform} ${translateY}`;
          } else {
            el.style.transform = translateY;
          }
        }
      }
    };

    const touchEnd = (e) => {
      if (e.changedTouches.length === 1 && isSwipeDown) {
        const endY = e.changedTouches[0].clientY;
        const deltaY = endY - startY;
        
        // 如果向下滑动超过阈值，触发关闭回调
        // 只有当 binding.value 是函数时才执行关闭操作
        if (deltaY > threshold && typeof binding.value === 'function') {
          binding.value();
        } else {
          // 否则恢复原状
          el.style.opacity = '';
          el.style.transform = originalTransform;
        }
      }
      // 重置状态
      startY = 0;
      currentY = 0;
      isSwipeDown = false;
      originalTransform = '';
    };

    el._swipeCloseHandlers = {
      touchStart,
      touchMove,
      touchEnd
    };

    el.addEventListener('touchstart', touchStart, { passive: false });
    el.addEventListener('touchmove', touchMove, { passive: false });
    el.addEventListener('touchend', touchEnd, { passive: true });
  },
  unbind(el) {
    if (el._swipeCloseHandlers) {
      el.removeEventListener('touchstart', el._swipeCloseHandlers.touchStart);
      el.removeEventListener('touchmove', el._swipeCloseHandlers.touchMove);
      el.removeEventListener('touchend', el._swipeCloseHandlers.touchEnd);
      delete el._swipeCloseHandlers;
    }
  }
})

clientEach.initClientRefreshActionRegister();
Vue.config.productionTip = false
Vue.config.devtools = false

new Vue({
  router,
  store,
  i18n,
  render: h => h(App)
}).$mount('#app')
