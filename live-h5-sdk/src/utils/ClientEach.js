/**
 *客户端交互
 */

import {isiOS} from "@/utils/Constant";


const openRecharge = function () {
  if (isiOS) {
    return window.prompt("openRecharge");
  }
}
const reloadUserInfo = function () {
  if (isiOS) {
    return window.prompt("reloadUserInfo");
  }
}
const setNavigationBarTitle = function (title) {
  if (isiOS) {
    return window.prompt("setNavigationBarTitle", title);
  }
}
const openInOSBrowser = function (url) {
  if (isiOS) {
    return window.prompt("openInOSBrowser", url);
  }
}

const onRefreshCallBind = {}
/**
 *添加原生app刷新回调监听
 */
const addOnClientRefreshCallListener = function (key, call) {
  onRefreshCallBind[key] = call;
}

/**
 *移除原生app刷新回调监听
 */
const removeOnClientRefreshCallListener = function (key) {
  delete onRefreshCallBind[key];
}

const initClientRefreshActionRegister = function () {
  window.clientRefreshAction = function () {
    for (const it in onRefreshCallBind) {
      onRefreshCallBind[it]();
    }
  }
}

export default {
  // 拉起客户端充值
  openRecharge,
  // 刷新用户信息
  reloadUserInfo,
  // 设置导航栏标题
  setNavigationBarTitle,
  // 从系统浏览器打开网页
  openInOSBrowser,
  // 初始化刷新意图
  initClientRefreshActionRegister,
  // 注册刷新监听
  addOnClientRefreshCallListener,
  // 移除刷新监听
  removeOnClientRefreshCallListener
}
