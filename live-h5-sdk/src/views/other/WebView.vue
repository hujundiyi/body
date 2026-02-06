<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="title"/>
    </template>
    <template #page-content-wrap>
      <iframe ref="webviewIframe" :src="url" @load="handleIframeLoad"></iframe>
    </template>
  </m-page-wrap>
</template>

<script>
import {getWebUserDetail} from "@/api";
import {key_cache} from "@/utils/Constant";
import cache from "@/utils/cache";
import store from "@/store";

export default {
  name: 'WebView',
  data() {
    return {
      title: this.$route.query.title || 'Web View',
      url: this.formatUrl(this.$route.query.url),
      isPaymentPage: this.$route.query.isPayment === 'true' || this.$route.query.title === 'PayPal Payment',
      checkTimer: null,
      messageHandler: null,
      visibilityHandler: null,
      focusHandler: null,
      hasUpdatedUserInfo: false, // 防止重复更新
      returnRoute: null, // 保存返回的路由信息
      isNavigatingBack: false // 防止重复返回
    };
  },
  mounted() {
    // 如果是支付页面，保存返回路由信息
    if (this.isPaymentPage) {
      // 从路由参数中获取返回路由，如果没有则使用历史记录
      const returnRouteName = this.$route.query.returnRoute;
      const returnRoutePath = this.$route.query.returnPath;
      
      if (returnRouteName) {
        this.returnRoute = { name: returnRouteName };
      } else if (returnRoutePath) {
        this.returnRoute = { path: returnRoutePath };
      }
      
      // 保存当前路由到sessionStorage，用于支付完成后恢复
      try {
        const currentRouteInfo = {
          name: this.$route.name,
          path: this.$route.path,
          query: this.$route.query,
          params: this.$route.params
        };
        sessionStorage.setItem('paypal_return_route', JSON.stringify(currentRouteInfo));
      } catch (e) {
        console.error('保存路由信息失败:', e);
      }
      
      this.setupPaymentListeners();
    }
  },
  beforeDestroy() {
    if (this.checkTimer) {
      clearInterval(this.checkTimer);
      this.checkTimer = null;
    }
    if (this.messageHandler) {
      window.removeEventListener('message', this.messageHandler);
      this.messageHandler = null;
    }
    if (this.visibilityHandler) {
      document.removeEventListener('visibilitychange', this.visibilityHandler);
      this.visibilityHandler = null;
    }
    if (this.focusHandler) {
      window.removeEventListener('focus', this.focusHandler);
      this.focusHandler = null;
    }
  },
  methods: {
    formatUrl(url) {
      // 如果没有传入 URL，使用默认地址
      if (!url) {
        url = 'www.baidu.com';
      }
      
      // 如果 URL 没有协议前缀，添加 https://
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://' + url;
      }
      
      return url;
    },
    handleIframeLoad() {
      // iframe 加载完成后，尝试监听 postMessage
      if (this.isPaymentPage && this.$refs.webviewIframe) {
        // 尝试通过 postMessage 与 iframe 通信
        this.tryPostMessageCommunication();
      }
    },
    setupPaymentListeners() {
      // 监听来自 iframe 的 postMessage
      this.messageHandler = (event) => {
        // 验证消息来源（可选，根据实际需求）
        if (event.data && typeof event.data === 'object') {
          if (event.data.type === 'payment-success' || event.data.paymentStatus === 'success') {
            this.handlePaymentSuccess();
          }
        }
      };
      window.addEventListener('message', this.messageHandler);
      
      // 监听页面可见性变化，当用户返回时检查支付状态
      this.visibilityHandler = this.handleVisibilityChange.bind(this);
      document.addEventListener('visibilitychange', this.visibilityHandler);
      
      // 监听页面焦点变化（作为备用检测方式）
      this.focusHandler = this.handleWindowFocus.bind(this);
      window.addEventListener('focus', this.focusHandler);
      
      // 监听页面显示事件（pageshow），用于检测从缓存中恢复
      window.addEventListener('pageshow', this.handlePageShow.bind(this));
    },
    handleVisibilityChange() {
      // 当页面变为可见时（用户返回），如果是支付页面，更新用户信息
      if (!document.hidden && this.isPaymentPage && !this.hasUpdatedUserInfo) {
        // 延迟一点更新，确保页面已完全加载
        setTimeout(() => {
          this.updateUserInfo().then(() => {
            // 更新完成后，延迟返回，给用户一点时间看到更新
            setTimeout(() => {
              this.navigateBack();
            }, 500);
          });
        }, 1000);
      }
    },
    handleWindowFocus() {
      // 当窗口获得焦点时（用户返回），如果是支付页面，更新用户信息
      if (this.isPaymentPage && !this.hasUpdatedUserInfo) {
        setTimeout(() => {
          this.updateUserInfo().then(() => {
            // 更新完成后，延迟返回
            setTimeout(() => {
              this.navigateBack();
            }, 500);
          });
        }, 1000);
      }
    },
    tryPostMessageCommunication() {
      // 尝试向 iframe 发送消息，请求支付状态
      try {
        const iframe = this.$refs.webviewIframe;
        if (iframe && iframe.contentWindow) {
          // 可以尝试发送消息请求支付状态
          // iframe.contentWindow.postMessage({ type: 'getPaymentStatus' }, '*');
        }
      } catch (e) {
        // 跨域错误，忽略
      }
    },
    handlePageShow(event) {
      // 如果页面是从缓存中恢复的（back/forward），且是支付页面
      if (event.persisted && this.isPaymentPage && !this.hasUpdatedUserInfo) {
        // 延迟更新，确保页面已完全恢复
        setTimeout(() => {
          this.updateUserInfo();
        }, 500);
      }
    },
    handlePaymentSuccess() {
      // 停止检查
      if (this.checkTimer) {
        clearInterval(this.checkTimer);
        this.checkTimer = null;
      }
      
      // 更新用户信息
      this.updateUserInfo().then(() => {
        // 返回上一页
        this.navigateBack();
      });
    },
    navigateBack() {
      // 防止重复返回
      if (this.isNavigatingBack) {
        return;
      }
      
      this.isNavigatingBack = true;
      
      // 使用 nextTick 确保状态更新完成
      this.$nextTick(() => {
        let targetRoute = null;
        
        // 优先使用传递的返回路由
        if (this.returnRoute && this.returnRoute.name) {
          targetRoute = this.returnRoute;
        } else if (this.returnRoute && this.returnRoute.path) {
          targetRoute = { path: this.returnRoute.path };
        } else {
          // 尝试从sessionStorage恢复路由
          try {
            const savedRoute = sessionStorage.getItem('paypal_return_route');
            if (savedRoute) {
              const routeInfo = JSON.parse(savedRoute);
              // 只使用name或path，避免query和params导致的问题
              if (routeInfo.name) {
                targetRoute = { name: routeInfo.name };
              } else if (routeInfo.path) {
                targetRoute = { path: routeInfo.path };
              }
              // 清除保存的路由信息
              sessionStorage.removeItem('paypal_return_route');
            }
          } catch (e) {
            console.error('恢复路由信息失败:', e);
          }
        }
        
        if (targetRoute) {
          // 使用 replace 而不是 push，避免在历史记录中留下当前页面
          // 这样可以避免返回时重新加载页面
          this.$router.replace(targetRoute).catch((error) => {
            console.error('返回路由失败:', error);
            // 如果指定路由失败，尝试使用 back
            if (window.history.length > 1) {
              this.$router.back();
            } else {
              this.$router.replace({ name: 'PageSdkIndex' });
            }
          }).finally(() => {
            this.isNavigatingBack = false;
          });
        } else {
          // 如果没有指定返回路由，使用 router.back()
          // 但先检查历史记录
          if (window.history.length > 1) {
            // 使用 go(-1) 而不是 back()，更可靠
            this.$router.go(-1);
          } else {
            // 如果没有历史记录，跳转到首页
            this.$router.replace({ name: 'PageSdkIndex' });
          }
          this.isNavigatingBack = false;
        }
      });
    },
    updateUserInfo() {
      // 防止重复更新
      if (this.hasUpdatedUserInfo) {
        return Promise.resolve();
      }
      
      this.hasUpdatedUserInfo = true;
      return getWebUserDetail().then(res => {
        if (res && res.data) {
          const user = res.data;
          store.commit('user/SET_USERINFO', user);
          cache.local.setJSON(key_cache.user_info, user);
        }
      }).catch(() => {
        // 静默处理错误，重置标志以便重试
        this.hasUpdatedUserInfo = false;
      });
    }
  }
}
</script>

<style scoped lang="less">
:deep(.m-page-content) {
  height: 100vh;
  box-sizing: border-box;
  position: relative;
  overflow: hidden;
  padding-top: 0 !important; // 移除默认 padding，由 iframe 自己处理
}

iframe {
  position: absolute;
  top: calc(70px + constant(safe-area-inset-top)); // 兼容 iOS 11.0-11.2
  top: calc(70px + env(safe-area-inset-top));
  left: 0;
  width: 100%;
  height: calc(100vh - 70px - constant(safe-area-inset-top)); // 兼容 iOS 11.0-11.2
  height: calc(100vh - 70px - env(safe-area-inset-top));
  background: #fff;
  border: none;
  display: block;
  box-sizing: border-box;
}
</style>
