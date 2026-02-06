import request from '@/utils/Request'
import {CALL_STATUS} from '@/utils/Constant'

// 申请通话
export function apiCallCreate(userId, {callNo = ''}) {
  return request({
    url: 'call/callCreate',
    method: 'post',
    data: {callNo: callNo, userId: userId},
    showToast: false,
  })
}

/**
 * 开始通话
 * @param callNo
 */
export function apiCallStart(callNo) {
  return request({
    url: '/call/callStart',
    method: 'post',
    data: {callNo},
    loading: false
  })
}

/**
 * 结束通话
 * @param {string} callNo - 通话编号
 * @param {string|number} status - 通话状态（字符串）或 callStatus code（数字，用于兼容旧代码）
 *   字符串值: create, answer, calling, refuse, callDone, callTimeoutDone, callErrorDone, callingErrorDone, notBalanceDone, systemStop, cancelCall
 * @param {string} [remark] - 备注（可选）
 * @param {number} [callDoneUserId] - 完成通话的用户ID（可选）
 * @returns {Promise}
 */
export function apiCallEnd(callNo, status, remark = '', callDoneUserId = 0) {
  // 如果 status 是数字（callStatus code），则映射到 API 状态字符串
  let apiStatus = status;
  const data = {
    callNo,
    status: apiStatus
  };

  // 可选参数
  if (remark) {
    data.remark = remark;
  }
  if (callDoneUserId) {
    data.callDoneUserId = callDoneUserId;
  }
  console.log("data: " + JSON.stringify(data))
  return request({
    url: 'call/callEnd',
    method: 'post',
    data,
    loading: false
  })
}

/**
 *通话评价
 * @param callNo
 * @param toUserId 被评价用户id
 * @param label  好评AAF 差评 AAI
 */
export function callComment({callNo, toUserId, label}) {
  return request({
    url: 'call/comment',
    method: 'post',
    data: {callNo, toUserId, label},
    loading: true
  })
}

/**
 * 获取通话历史
 * @param {number} page - 页码（从0开始）
 * @param {number} size - 每页数量
 * @returns {Promise}
 */
export function getCallHistory(page = 1, size = 20) {
  return request({
    url: '/call/getCallHistory',
    method: 'post',
    data: {page, size},
    loading: false
  })
}



// 获取礼物列表
export function getGiftList() {
  return request({
    url: 'rechargeConsume/getGiftList',
    method: 'post'
  })
}

/**
 * 赠送礼物
 * @param giftId 礼物id
 * @param acceptUserId 被赠送人
 * @returns {*}
 */
export function sendGift(giftId,userId) {
  return request({
    url: 'rechargeConsume/sendGift',
    method: 'post',
    data: {
      userId,
      giftId
    }
  })
}

/**
 * 获取 RTM Token
 * @param {string} channelName - 频道名称（通话编号）
 * @returns {Promise} 包含 rtmToken 的响应
 */
export function getRtmToken() {
  return request({
    url: '/user/rtmToken',
    method: 'post',
    data: {  },
    loading: false,
    showToast: false
  })
}
