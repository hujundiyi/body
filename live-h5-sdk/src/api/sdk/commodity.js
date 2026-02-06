import request from "@/utils/Request";

/// rechargeTypes 充值类型 ；ifSubscribe: 0 金币，1 会员
export function getRechargeList(rechargeTypes = [0], ifSubscribe = 0) {
    return request({
        url: 'rechargeConsume/getRechargeList',
        method: 'post',
        data: {rechargeTypes, ifSubscribe}
    })
}

/// 首冲礼包
export function getFirstRechargeList(rechargeTypes = [0], ifSubscribe = 0) {
    return request({
        url: 'rechargeConsume/getFirstRechargeList',
        method: 'post',
        data: {rechargeTypes, ifSubscribe}
    })
}

/// 消耗背包道具
export function userBackpack(backpackType = 4, quantity = 1) {
    return request({
        url: 'userBackpack/consume',
        method: 'post',
        data: {
            backpackType: backpackType,
            quantity: quantity
        }
    })
}


/**
 * 获取硬币交易记录列表
 * @param {number} page - 页码（从1开始）
 * @param {number} size - 每页数量
 * @returns {Promise}
 */
export function getCoinTransactionList(page = 1, size = 20) {
    return request({
        url: 'rechargeConsume/getCoinConsumeList',
        method: 'post',
        data: {page, size},
        loading: false
    })
}

export function getGiftHistortList(page = 1, size = 20,coinChangeType = 3) {
    return request({
        url: 'rechargeConsume/getCoinConsumeList',
        method: 'post',
        data: {page, size, coinChangeType},
        loading: false
    })
}

/**
 * 收银台支付（PayPal）
 * @param {string|number} rechargeId - 充值档位ID
 * @returns {Promise}
 */
export function payWithCashier(rechargeId) {
    return request({
        url: 'payIn/payWithCashier',
        method: 'post',
        data: {rechargeId}
    })
}


/**
 * 创建订单
 * @param rechargeId 充值id
 * @returns {*}
 */
export function createOrderApi(rechargeId) {
    return request({
        url: 'order/create',
        method: 'post',
        data: {rechargeId}
    })
}


/**
 *
 * @param uuid uuid
 * @param transactionId 交易id
 * @returns {*}
 */
export function iosOrderVerifyApi(uuid, transactionId) {
    return request({
        url: 'order/iosVerify',
        method: 'post',
        data: {uuid, transactionId}
    })
}