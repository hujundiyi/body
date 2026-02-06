<template>
  <div id="app">
    <m-router-view/>
  </div>
</template>

<script>
import MRouterView from "@/components/MRouterView.vue";
import store from "@/store";
import {decodeBase64, formatTimestamp, getCurrentUsrPackageName, parseUrlParams} from "@/utils/Utils";
import {envIsDev, envIsTest, envIsProd, isiOS, key_cache} from "@/utils/Constant";
import cache from "@/utils/cache";
import {toast} from "@/components/toast";
import {getUserInfo, getWebUserDetail} from "@/api";
import {TencentImUtils} from "@/utils/TencentImUtils";
import AgoraRTMManager from "@/utils/AgoraRTMManager";
import clientNative from "@/utils/ClientNative";
import thinkingata from "thinkingdata-browser";
import {EVENT_NAME, setTDSuperProperties, tdTrack} from "@/utils/TdTrack";
import Vue from "vue";

export default {
  name: 'App',
  components: {MRouterView},
  beforeRouteLeave(to, from, next) {
    console.log( to, from, next)
  },
  mounted() {
    console.log( '应用创建')
    // 通知原生页面已就绪
    this.notifyPageReady()
  },
  created() {
    this.initQueryParams();
  },
  methods: {
    initQueryParams: function () {
      try {
        const query = parseUrlParams() || {};
        // 解析启动参数
        let base64LaunchData;
        if (query.d) {
          base64LaunchData = query.d
        } else if (envIsDev) {
          // base64LaunchData = 'eyJ1c2VySWQiOjEyNDc0LCJ0ZW5jZW50VXNlclNpZyI6ImVKeXJWZ3J4Q2RaTHJTaklMRXBWc2pJeXRUUXlNRERRQVF1V3BSWXBXU2taNlJrb1FmakZLZG1KQlFXWktVQmxCZ2JHUmliR2xoRHh6SlRVdkpMTXRFeXdja01qRTNNVG1JYk1kS0JJUms1WmxhdFpZVmh4YUpXanI1RnZlRmw2aVl0QllxUnJjTEtuV2E1amZwbWJSWEdxc1dOVWJvU2xveTFVWTBsbUx0QXhodWJtQmdaR1JpWVdCclVBaWI0di1BX18iLCJoZWFkZXJzIjp7IkF1dGhvcml6YXRpb24iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKbGVIQWlPakUzTnpJMk1UUTBPREFzSW5WelpYSkpaQ0k2TVRJME56UXNJbWxoZENJNk1UYzNNREF5TWpRNE1IMC4xdDdTa3JlMVpvcHVSX251QkNWNmF2R2R1cGFOMFVXWndyNnRtc014Y2lnIiwiWC1SZWdpb24iOiJDTiIsIlgtRGV2aWNlLUlEIjoiMjUzNDM1RjEtMzMzMi00ODcyLTk5QTMtNjBBODgzMTlBMDNCIiwiWC1EZWJ1Zy1Nb2RlIjpudWxsLCJYLUFwcC1JbmZvIjoiUVRBd01EVTdNUzR3TGpBPSIsIkFjY2VwdC1MYW5ndWFnZSI6ImVuLVVTLGVuO3E9MC45In19';
          base64LaunchData = 'eyJ1c2VySWQiOjEyNTI4LCJ0ZW5jZW50VXNlclNpZyI6ImVKeXJWZ3J4Q2RaTHJTaklMRXBWc2pJeXRUUXlNRERRQVF1V3BSWXBXU2taNlJrb1FmakZLZG1KQlFXWktVQmxCZ2JHUmliR2xoRHh6SlRVdkpMTXRFeXdja01qVXlNTG1JYk1kS0NJUjNsb2lINVZhWDZTdjN0d3VWRkFqbmQ2bWxtSWMxU1ZZM1poZVY1ZVNIWnBaRlJtcVdsT3VLRjNzaTFVWTBsbUx0QXhodWJtQm9hVzVvWkdSclVBb3BrdzBRX18iLCJoZWFkZXJzIjp7IkF1dGhvcml6YXRpb24iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKbGVIQWlPakUzTnpJM09Ea3hNaklzSW5WelpYSkpaQ0k2TVRJMU1qZ3NJbWxoZENJNk1UYzNNREU1TnpFeU1uMC5pRFRmcndEbFlwX3k2bmp3YXpDeWE2OVVLWVhZZVhhSEZPMk1vQmw4VmUwIiwiWC1SZWdpb24iOiJDTiIsIlgtRGV2aWNlLUlEIjoiMjUzNDM1RjEtMzMzMi00ODcyLTk5QTMtNjBBODgzMTlBMDNCIiwiWC1EZWJ1Zy1Nb2RlIjpudWxsLCJYLUFwcC1JbmZvIjoiUVRBd01EVTdNUzR3TGpBPSIsIkFjY2VwdC1MYW5ndWFnZSI6ImVuLVVTLGVuO3E9MC45In19';
          // zqy   eyJ1c2VySWQiOjEwNTY4LCJ0ZW5jZW50VXNlclNpZyI6ImVKeXJWZ3J4Q2RaTHJTaklMRXBWc2pJeXRUUXlNRERRQVF1V3BSWXBXU2taNlJrb1FmakZLZG1KQlFXWktVQmxCZ2JHUmliR2xoRHh6SlRVdkpMTXRFeXdja01EVXpNTG1JYk1kS0NJdVdkU1VvaGZwcGR6UUtoMmdZV2xaMEZtYVVCQXNXZWdiNkpuaFVXVXMxbVdXM0ZacFdWYWFYbXlyeTFVWTBsbUx0QXhodVptbHVZbUprYW14clVBY2VJd0RBX18iLCJoZWFkZXJzIjp7IkF1dGhvcml6YXRpb24iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKbGVIQWlPakUzTnpJek16WXlOVE1zSW5WelpYSkpaQ0k2TVRBMU5qZ3NJbWxoZENJNk1UYzJPVGMwTkRJMU0zMC5rQUNNTW1JYkhmc3NyQktzSGloMU1RR2F0bkZGUzlQZkttUTRITXF1Um84IiwiWC1SZWdpb24iOiJDTiIsIlgtRGV2aWNlLUlEIjoiMEMxNjQwREUtOEI1MS00QjFGLUE2N0UtOTk4QzQwOEU0RDdEIiwiWC1EZWJ1Zy1Nb2RlIjpudWxsLCJYLUFwcC1JbmZvIjoiUVRBd01URTdNUzR3TGpFPSIsIkFjY2VwdC1MYW5ndWFnZSI6ImVuLVVTLGVuO3E9MC45In19
        }
        const base64Str = decodeBase64(base64LaunchData)
        const params = JSON.parse(base64Str);
        cache.local.setJSON(key_cache.launch_h5_data, params);
        console.error('APP启动参数', params)
        this.startInit(params);
      } catch (e) {
        console.error('APP初始化异常', e)
        const params = cache.local.getJSON(key_cache.launch_h5_data, {});
        this.startInit(params);
      }
    },
    startInit(params) {
      console.error("启动参数：",params);
      store.dispatch('GetInfo');
      store.dispatch('GetUserBackpack');
      // 初始化配置后再登录 RTM
      store.dispatch('PageCache/initConfig').then(() => {
        const configData = store.state.PageCache.configData;
        const tencentAppId = configData.DEF_TENCENT_CHAT_APP_ID;
        TencentImUtils.init(tencentAppId)
        this.initRTMLogin(params);
        this.initThinkingata(params);
      })
    },
    // 初始化 RTM 登录
    async initRTMLogin(params) {
      try {
        const configData = store.state.PageCache.configData;
        const appId = configData.DEF_AGORA_APP_ID;
        const userId = params.userId;
        
        if (!appId || !userId) {
          console.warn('[📨RTM] 缺少 appId 或 userId，跳过 RTM 登录');
          return;
        }
        
        console.log('[📨RTM] 开始登录 RTM...', { appId, userId });
        await AgoraRTMManager.login(appId, userId);
        store.dispatch('PageCache/setRtmInitSuccess');
        console.log('[📨RTM] ✅ RTM 登录成功');
      } catch (error) {
        console.error('[📨RTM] RTM 登录失败:', error);
      }
    },
    notifyPageReady() {
      // 检查是否在 iOS WebView 环境中
      if (isiOS) {
        clientNative.pageLoadComplate();
      }
    },
    initThinkingata(params) {
      // 根据环境设置对应的 appId
      const appId = envIsProd 
        ? 'e83ee027c7ae4197bfe7a6ac84048e2e' // 生产环境
        : '0bb77e5ddab14825906f1d9597e62226'; // 测试/开发环境
      
      thinkingata.init({
        appId: appId,
        serverUrl: 'https://collect.point66.xyz', //  https://collect.point66.xyz
        // 其他配置项（如是否开启调试模式、日志设置等）可根据需要添加
        showLog:true,
        // mode:"debug",
      })
      thinkingata.login(params.userId)
      // 设置用户属性
      const {VUE_APP_VERSION} = process.env
      thinkingata.userSet({ app_version: VUE_APP_VERSION })

      // 3. 挂到全局 window
      window.tdInstance = thinkingata

      // 设置公共事件
      setTDSuperProperties()

      // 4. 挂 Vue 原型（可选，方便组件里 this.$tdTrack 调用）
      Vue.prototype.$tdTrack = tdTrack


      /// 埋点启动
      const appStartTime = Math.floor(Date.now() / 1000);
      const formatted = formatTimestamp(appStartTime);
      tdTrack(EVENT_NAME.app_start,{"time":formatted})
    },
  },
}
</script>

<style>
#app {
  height: 100%;
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
