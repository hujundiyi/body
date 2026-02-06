import request from '@/utils/Request'
import cache from '@/utils/cache'
import {key_cache} from '@/utils/Constant'

/**
 * 获取剩余消息数量
 */
export function getFreeMsgNum() {
  return request({
    url: 'user/getFreeMsgNum',
    method: 'post'
  })
}

/**
 * 获取用户信息
 */
export function updateUserInfo(data) {
  return request({
    url: 'user/complete',
    method: 'post',
    data: data
  })
}

/**
 * 拉黑/取消拉黑用户
 * @param {number} blackUserId - 要拉黑的用户ID
 * @param {boolean} black - true表示拉黑，false表示取消拉黑
 * @returns {Promise}
 */
export function statusBlack(blackUserId, black = true) {
  return request({
    url: 'userStatus/blackStatus',
    method: 'post',
    data: {
      blackUserId: blackUserId,
      black: black
    }
  })
}

// 反馈
export function userFeedback(params) {
  return request({
    url: 'user/feedback',
    method: 'post',
    data: params
  })
}

// 举报
export function userReport(params) {
  return request({
    url: 'user/reportUser',
    method: 'post',
    data: params,
    loading: true
  })
}

// 获取首充
export function getFirstRechargeConfig() {
  return request({
    url: 'user/getFirstRechargeConfig',
    method: 'post'
  })
}

export function intoDel(params) {
  return request({
    url: 'into/del',
    method: 'post',
    data: params,
    loading: true
  })
}

export function createRtcToken() {
    return request({
        url: 'user/rtcToken',
        method: 'post',
    })
}

export function createRtmToken() {
    return request({
        url: 'user/rtmToken',
        method: 'post',
    })
}

export function requestToHome() {
    return request({
        url: 'authorize/toHome',
        method: 'post',
    })
}


// 获取关注列表
export function getFollowList(params) {
  return request({
    url: 'anchor/getList',
    method: 'post',
    data: params
  })
}

/**
 * 关注/取消关注
 * @param {number} followUserId - 要关注/取消关注的用户ID
 * @param {boolean} follow - true表示关注，false表示取消关注
 * @returns {Promise}
 */
export function followStatus(followUserId, follow, loading = true) {
  return request({
    url: 'userStatus/followStatus',
    method: 'post',
    data: {
      followUserId: followUserId,
      follow: follow
    },
    loading
  })
}
/**
 * 设置用户信息
 * @param {Object} data - 用户信息数据
 * @param {string} data.nickname - 昵称（可选）
 * @param {number} data.gender - 性别（可选）
 * @param {string} data.signature - 个人简介（可选）
 * @returns {Promise}
 */
export function setUserInfo(data) {
  return request({
    url: 'user/setInfo',
    method: 'post',
    data: data
  })
}

/**
 * 删除用户账号
 * @param {Object} params - 删除账号参数
 * @param {number} params.reason - 删除原因
 * @param {string} params.desc - 删除描述
 * @returns {Promise}
 */
export function delUser(params) {
  return request({
    url: 'user/delUser',
    method: 'post',
    data: params,
    loading: true
  })
}

/**
 * 获取签到信息
 * @returns {Promise}
 */
export function getCheckinInfo() {
  return request({
    url: 'checkin/listReward',
    method: 'post'
  })
}

/**
 * 执行签到
 * @returns {Promise}
 */
export function doCheckin() {
  return request({
    url: 'checkin/getReward',
    method: 'post',
    loading: true
  })
}
