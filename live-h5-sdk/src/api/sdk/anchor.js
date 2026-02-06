import request from '@/utils/Request'

/**
 * 获取主播列表
 */
export function getAnchorList(data) {
  return request({
    url: 'anchor/getList',
    method: 'post',
    data: data
  })
}

/**
 * 获取主播信息
 */
export function getAnchorInfo(uid) {
  return request({
    url: 'anchor/getInfo',
    method: 'post',
    data: {userId: uid}
  })
}

/**

 * 批量获取主播详情
 */

export function getDetailList(data) {
  return request({
    url: 'anchor/getDetailList',
    method: 'post',
    data: data
  })
}

// 兼容旧命名
export const getAnchorDetailList = getDetailList;