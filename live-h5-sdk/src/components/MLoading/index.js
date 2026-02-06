// loading.js
import Vue from "vue";
import MLoading from "@/components/MLoading/loading.vue"

// 单例实例
let loadingInstance = null
let autoHideTimer = null

function startAutoHideTimer() {
  if (autoHideTimer) {
    clearTimeout(autoHideTimer)
    autoHideTimer = null
  }
  autoHideTimer = setTimeout(() => {
    if (loadingInstance) {
      loadingInstance.hide()
      loadingInstance = null
    }
  }, 30000)
}

function createLoading(props) {
  // 如果已经存在实例，先关闭
  if (loadingInstance) {
    loadingInstance.hide()
    loadingInstance = null
  }

  const Instance = new Vue({
    render: h => h(MLoading, {props})
  })

  const component = Instance.$mount()
  document.body.appendChild(component.$el)

  loadingInstance = component.$children[0]

  // 监听关闭事件，清理实例
  loadingInstance.$on('close', () => {
    if (loadingInstance && loadingInstance.$el && loadingInstance.$el.parentNode) {
      loadingInstance.$el.parentNode.removeChild(loadingInstance.$el)
    }
    loadingInstance = null
    if (autoHideTimer) {
      clearTimeout(autoHideTimer)
      autoHideTimer = null
    }
  })

  startAutoHideTimer()
  return loadingInstance
}

/**
 * 显示 loading
 * @param text 加载文案
 * @param closable 是否允许取消
 * @returns {*}
 */
export function showLoading(text = 'loading...', closable = false) {
  if (!loadingInstance) {
    loadingInstance = createLoading({text, closable})
  } else {
    startAutoHideTimer()
  }
  return loadingInstance
}

// 隐藏 loading
export function hideLoading() {
  if (loadingInstance) {
    loadingInstance.hide()
    loadingInstance = null
    if (autoHideTimer) {
      clearTimeout(autoHideTimer)
      autoHideTimer = null
    }
  }
}

// 默认导出
export default {
  install(Vue) {
    Vue.prototype.$loading = showLoading
    Vue.prototype.$hideLoading = hideLoading

    // 也可以添加全局方法
    Vue.loading = showLoading
    Vue.hideLoading = hideLoading
  }
}
