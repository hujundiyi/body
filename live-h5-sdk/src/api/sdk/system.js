import request from '@/utils/Request'
import {isiOS} from "@/utils/Constant";
import cache from '@/utils/cache'

// 缓存键名
const CACHE_KEY_IP_COUNTRY = 'key_cache_ip_country'

export function init(data) {
  return request({
    url: '/init/init',
    method: 'post',
    data: data
  })
}

export function getConfig(data) {
    return request({
        url: 'init/getConfig',
        method: 'post',
        data: data
    })
}

/**
 * 获取国家列表
 * 如果本地有缓存则直接返回，否则请求接口并缓存
 * @param {Object} data - 请求参数（可选）
 * @returns {Promise}
 */
export function getIpCountry(data) {
  // 先检查本地缓存
  const cachedData = cache.local.getJSON(CACHE_KEY_IP_COUNTRY)
  if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
    console.log('使用缓存的国家列表')
    return Promise.resolve({
      success: true,
      data: cachedData,
      code: 200
    })
  }

  // 如果没有缓存，请求接口
  return request({
    url: 'init/getIpCountry',
    method: 'post',
    data: data || {},
    loading: false
  }).then(res => {
    if (res.success && res.data && Array.isArray(res.data)) {
      // 缓存到本地
      cache.local.setJSON(CACHE_KEY_IP_COUNTRY, res.data)
      console.log('国家列表已缓存到本地')
    }
    return res
  }).catch(error => {
    console.error('获取国家列表失败:', error)
    throw error
  })
}

export function productList() {
  return request({
    url: '/charge/productList',
    method: 'post',
    data: {type: isiOS ? 1 : 2}
  })
}
