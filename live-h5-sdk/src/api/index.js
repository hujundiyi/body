import request from '@/utils/Request'
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";

/**
 * 获取用户信息
 */
export function getUserInfo(uid) {
  return request({
    url: 'user/getInfo',
    method: 'post',
    data: {userId: uid}
  })
}

export function getWebUserDetail() {
    return request({
        url: 'authorize/getUserInfo',
        method: 'post'
    }).then(res => {
        // 自动缓存用户信息
        if (res && res.data) {
            const user = res.data
            cache.local.setJSON(key_cache.user_info, user)
        }
        return res
    })
}


export function getUserBackpack() {
    return request({
        url: 'userBackpack/listByUserId',
        method: 'post',
        loading: false,
    });
}



/**
 *
 * abe
 * 用户邀请用户 1
 * 主播邀请用户 2
 * 主播邀请主播 3
 */
export function getInviteUrl(abe) {
  return request({
    url: 'marketing/getInviteLink',
    method: 'get',
    params: {abe}
  })
}

/**
 * 发送验证码
 * @param data
 * @returns {AxiosPromise}
 */
export function sendCode(data) {
  return request({
    url: '/auth/sendVerifyCode',
    method: 'post',
    data: data
  })
}

export function emailSignup(obj) {
  return request({
    url: 'register/emailRegn',
    method: 'post',
    data: obj
  })
}

/**
 * 翻译文本
 * @param {string} text - 要翻译的文本
 * @param {string} from - 源语言代码（可选）
 * @param {string} to - 目标语言代码（可选，默认中文）
 * @returns {Promise}
 */
export function translateText(text, from = 'auto', to = 'zh') {
  return request({
    url: '/translate/text',
    method: 'post',
    data: {
      text,
      from,
      to
    }
  })
}
