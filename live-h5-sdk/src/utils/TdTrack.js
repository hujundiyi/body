import user from "@/store/modules/user";
import store from "@/store";
import {getCurrentUsrPackageName, getCurrentUsrVersion, getUUID} from "@/utils/Utils";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";

/**
 * 封装 TD track
 * @param {string} eventName 事件名
 * @param {object} props 附加属性
 * @returns {boolean} 是否成功
 */
export function tdTrack(eventName, props = {}) {
    const td = window.tdInstance

    if (!td) {
        if (process.env.NODE_ENV !== 'production') {
            console.error('[TD] SDK 未初始化，track 被忽略', eventName, props)
        }
        return false
    }

    if (!eventName || typeof eventName !== 'string') {
        console.error('[TD] eventName 非法', eventName)
        return false
    }

    try {
        td.track(eventName, props)
        return true
    } catch (e) {
        console.error('[TD] track 出错', eventName, e)
        return false
    }
}

// 公共事件
export function setTDSuperProperties() {
    const td = window.tdInstance
    if (!td) return

    const params = cache.local.getJSON(key_cache.launch_h5_data, {});
    const {VUE_APP_VERSION} = process.env

    const superProperties = {
        was_vip: store.state.user.loginUserInfo.vipCategory !== 0,
        package_name: getCurrentUsrPackageName() || '',
        user_id: store.state.user.loginUserInfo.userId || '',
        app_device_id: params.headers?.['X-Device-ID'] || '',
        h5_version: VUE_APP_VERSION || '',
    }

    td.setSuperProperties(superProperties)
}

// 预制属性
export function setTDPresetProperties() {
    const td = window.tdInstance
    if (!td) return

    //获取属性对象
    let presetProperties = td.getPresetProperties();
    //生成事件预置属性
    let properties = presetProperties.toEventPresetProperties();
    const {VUE_APP_VERSION} = process.env
    properties['#app_version'] = VUE_APP_VERSION
}

export const EVENT_NAME = {
    app_start: 'app_start', /// 启动应用
    coinspopup_show: 'coinspopup_show', /// 金币购买弹窗展示
    coinspopup_buy: 'coinspopup_buy', /// 金币购买弹窗点击购买金币
    client_coinspopup_buy_suc: 'client_coinspopup_buy_suc', /// 金币购买弹窗购买金币下单完成（客户端）
    vip_show: 'vip_show', /// 会员页展示
    vip_buy: 'vip_buy', /// 用户点击购买会员
    client_vip_buy_suc: 'client_vip_buy_suc', /// 购买会员下单完成（客户端）
    pay_process_fail: 'pay_process_fail',/// 支付失败
    pay_verify_fail: 'pay_verify_fail',/// pay_verify_fail
}