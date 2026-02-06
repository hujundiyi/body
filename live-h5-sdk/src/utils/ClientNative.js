import {isiOS, NATIVE_EVENT_KEY} from "@/utils/Constant";
import {getCurrentUsrPackageName} from "@/utils/Utils";
import {TencentImUtils} from "@/utils/TencentImUtils";

const callBackKey = {
    success: 'resolve_',
    error: 'reject_'
}
const asyncFunctionOBj = {};


const initHandlerEvent = () => {
    const packageName = getCurrentUsrPackageName();
    window[packageName] = (jsonStr) => {
        console.error('原生回调 原始json', jsonStr);
        const {type, data} = JSON.parse(jsonStr);
        console.error('原生回调 解析后的json', type, data);
        try {
            // type与拉起时的type一致
            asyncFunctionOBj[callBackKey.success + type](data);
        } catch (e) {
            // console.errorAndToServer('原生回调 Promise 异常', e)
        }
    };
}

/**
 *
 * @param type 事件类型
 * @param data 传参数据
 * @returns {Promise<unknown>}
 */
const handlerEvent = (type, data = {}) => {
    console.info('拉起原生', 'event:' + type, data);
    return new Promise((resolve, reject) => {
        try {
            const packageName = getCurrentUsrPackageName();
            // 挂载回调
            if (!window[packageName]) {
                initHandlerEvent();
            }
            if (isiOS && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[packageName]) {
                window.webkit.messageHandlers[packageName].postMessage(JSON.stringify({type, data}));
                asyncFunctionOBj[callBackKey.success + type] = resolve
                asyncFunctionOBj[callBackKey.error + type] = reject
            } else {
                throw new Error("Native error");
            }
        } catch (e) {
            // console.errorAndToServer('原生拉起失败', e);
            reject(e);
        }
    })
};


const clientNative = {
    /**
     * 是否在原生环境
     * @returns {boolean}
     */
    isNativeEnv() {
        const packageName = getCurrentUsrPackageName();
        if (isiOS) {
            return window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[packageName];
        }

        return false
    },
    /**
     * 触发震动 默认使用系统频次
     * @param level  0 系统默认震动 1轻微震动、2中度震动、3强烈震动
     * @param number 震动次数 >= 1
     */
    vibrationEvent(level = 0, number) {
        return handlerEvent(NATIVE_EVENT_KEY.vibration, {level, number})
    },
    /**
     * 触发位置获取
     */
    getLocation() {
        return handlerEvent(NATIVE_EVENT_KEY.getLocation)
    },
    /**
     * 打开新 web-view
     * @param url
     */
    closeWebView() {
        return handlerEvent(NATIVE_EVENT_KEY.closeWebView);
    },
    /**
     * 打开新 web-view
     * @param url
     */
    openWebView(url, isNeedNav = false) {
        return handlerEvent(NATIVE_EVENT_KEY.openWebView, {url, isNeedNav});
    },
    /**
     * 拉起原生支付
     * @param data 下单参数
     */
    openPayment({code, uuid}) {
        return handlerEvent(NATIVE_EVENT_KEY.payment, {code, uuid});
    },
    /**
     * 设置桌面未读数
     * @param unreadNum
     * @returns {Promise<unknown>}
     */
    setUnreadNum(unreadNum) {
        return handlerEvent(NATIVE_EVENT_KEY.setUnreadNum, unreadNum)
    },
    /**
     * 去登录页面
     */
    toLogin() {
        TencentImUtils.logoutIM();
        return handlerEvent(NATIVE_EVENT_KEY.toLogin, {})
    },
    /**
     * 更新原生启动参数
     */
    updateLaunchData(launchData) {
        return handlerEvent(NATIVE_EVENT_KEY.updateLaunchData, launchData)
    },
    /**
     * 申请权限
     * @param getType 0：通知权限 1：相机 2：相册 3：麦克风
     */
    requestPermission(getType) {
        return handlerEvent(NATIVE_EVENT_KEY.requestPermission, {getType})
    },
    /**
     * 打开原生设置页面
     */
    openNativePermissionSetting() {
        return handlerEvent(NATIVE_EVENT_KEY.toSettingPermission, {})
    },
    /**
     * 好评弹窗
     */
    openEvaluate() {
        return handlerEvent(NATIVE_EVENT_KEY.openEvaluate)
    },
    /**
     * h5加载完成
     */
    pageLoadComplate() {
        return handlerEvent(NATIVE_EVENT_KEY.pageLoadComplate)
    },
}
/**
 * 原生交互
 */
export default clientNative
