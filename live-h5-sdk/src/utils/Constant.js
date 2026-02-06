export const envIsProd = process.env.VUE_APP_ENV === 'prod';
export const envIsTest = process.env.VUE_APP_ENV === 'test';
export const envIsDev = process.env.VUE_APP_ENV === 'dev';
export const u = navigator.userAgent;
export const isAndroid = u.indexOf('Android') > -1 || u.indexOf('Adr') > -1;
export const isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/);
export const httpCodeMsg = {
    '401': 'Authentication failed, unable to access system resources',
    '403': 'Current operation has no permission',
    '404': '404 Not Found',
    'default': 'Unknown system error, please feed back to the administrator'
}
export const key_cache = {
    launch_h5_data: 'key_cache_launch_h5_data',
    user_info: 'key_cache_user_info',
    user_backpack: 'key_cache_user_backpack',
    dict_data: 'key_cache_dict_data',
    config_data: 'key_cache_config_data',
    has_called: 'key_cache_has_called',
    dialog_show_new_user: 'key_cache_dialog_show_new_user',
    /// 好评弹窗
    dialog_show_good_pop: 'key_cache_dialog_show_good_pop',
    /// 私聊按主播累计发送消息条数 { [userId]: number }
    chat_sent_count_by_anchor: 'key_cache_chat_sent_count_by_anchor',
    /// 充值促销弹窗
    dialog_show_recharge_promo: 'key_cache_dialog_show_recharge_promo',
    /// 充值促销弹窗每日状态：{ date, visitCount, hasShownToday }
    first_recharge_promo_daily: 'key_cache_first_recharge_promo_daily',
    /// 喜欢消息未读数（本地持久化，进入 LikeList 时清零）
    unread_like_count: 'key_cache_unread_like_count',
}

// 1未关注 2:已关注对方 3:对方关注自己 4:互相关注
export const followIcon = {
    1: require('@/assets/image/sdk/ic_follow_add.png'),
    2: require('@/assets/image/sdk/ic_follow.png'),
    3: require('@/assets/image/sdk/ic_follow_to_me.png'),
    4: require('@/assets/image/sdk/ic_follow_mutual.png'),
}

export const dict_keys = [
    // 反馈
    'AAG',
    // 删除
    'AAW',
    // 好评
    'AAF',
    // 差评
    'AAI',
]


// 通话状态枚举（包含 code 数字码和 value 字符串值）
export const CALL_STATUS = {
    // 通话流程态
    CREATE:             { code: 0,  value: 'create' },             // 通话创建
    ANSWER:             { code: 1,  value: 'answer' },             // 接听
    CALLING:            { code: 2,  value: 'calling' },            // 通话中
    REFUSE:             { code: 30, value: 'refuse' },             // 拒接

    // 结束态
    CALL_DONE:          { code: 31, value: 'callDone' },           // 通话结束
    CALL_TIMEOUT_DONE:  { code: 32, value: 'callTimeoutDone' },    // 超时未接听
    CALL_ERROR_DONE:    { code: 33, value: 'callErrorDone' },      // 异常挂断（未接通）
    CALLING_ERROR_DONE: { code: 34, value: 'callingErrorDone' },   // 异常挂断（已接通）
    NOT_BALANCE_DONE:   { code: 35, value: 'notBalanceDone' },     // 余额不足结束
    SYSTEM_STOP:        { code: 36, value: 'systemStop' },         // 系统终止
    CANCEL_CALL:        { code: 37, value: 'cancelCall' },         // 取消拨号
}

// 通话状态枚举（包含 code 数字码和 value 字符串值）
export const LOCAL_CALL_STATUS = {
    LOCAL_CALL_NONE: { code: 0,  value: 'localCallNone' },             // 无通话状态
    LOCAL_CALL_WAITING: { code: 1,  value: 'localCallWaiting' },             // 拨打进来通话
    LOCAL_CALL_CALLING: { code: 2,  value: 'localCallCalling' },             // 通话中
    LOCAL_CALL_END: { code: 3,  value: 'localCallEnd' },             // 通话结束
}

// 根据 code 查找状态
export const getCallStatusByCode = (code) => {
    return Object.values(CALL_STATUS).find(s => s.code === code);
}

// 根据 value 查找状态
export const getCallStatusByValue = (value) => {
    return Object.values(CALL_STATUS).find(s => s.value === value);
}

/**
 * 原生交互事件key
 */
export const NATIVE_EVENT_KEY = {
    // 关闭WebView
    closeWebView: 0,
    // 原生打开一个新webview
    openWebView: 1,
    // 拉起原生支付
    payment: 2,
    // 去登录
    toLogin: 3,
    // 刷新桌面未读数角标
    setUnreadNum: 4,
    // 调用震动
    vibration: 5,
    // 获取定位
    getLocation: 6,
    // 更新原生本地启动参数
    updateLaunchData: 7,
    // 申请权限
    requestPermission: 8,
    // 到设置 权限开关页面
    toSettingPermission: 9,
    // 好评弹窗
    openEvaluate: 10,
    // 好评弹窗
    pageLoadComplate: 11,
}