import request from '@/utils/Request'
import cache from '@/utils/cache'
import {key_cache} from '@/utils/Constant'

// 缓存键名
const CACHE_KEY_RECOMMEND_ANCHORS = 'key_cache_recommend_anchors'

/**
 * 获取推荐主播列表
 * 如果本地有缓存则直接返回，否则请求接口并缓存
 * @returns {Promise}
 */
export function getRecommendAnchors() {
  // 先检查本地缓存
  const cachedData = cache.local.getJSON(CACHE_KEY_RECOMMEND_ANCHORS)
  if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
    console.log('使用缓存的推荐主播列表')
    return Promise.resolve({
      success: true,
      data: cachedData,
      code: 200
    })
  }

  // 如果没有缓存，请求接口
  return request({
    url: 'anchor/recommendAnchor',
    method: 'post',
    loading: false,
    data: {
      "page": 0,
      "size": 30
    }
  }).then(res => {
      console.log("=========11111", res.data)
    if (res.success && res.data && Array.isArray(res.data)) {
      // 缓存到本地
      cache.local.setJSON(CACHE_KEY_RECOMMEND_ANCHORS, res.data)
      console.log('推荐主播列表已缓存到本地')
    }
    return res
  }).catch(error => {
    console.error('获取推荐主播列表失败:', error)
    throw error
  })
}


/**
 * 匹配主播接口
 * @param {Object} params - 匹配参数。country / consumeType / consumeQuantity 由调用方按规则传入。
 * @returns {Promise}
 */
export function matcherAnchor(params = {}) {
  return request({
    url: 'anchor/matcherAnchor',
    method: 'post',
    data: params,
    loading: false
  })
}
