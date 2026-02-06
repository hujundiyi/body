import request from '@/utils/Request'

/**
 * 批量添加或更新图片
 * @param {Object} data - 图片数据
 * @param {number} data.userId - 用户ID
 * @param {Array} data.pics - 图片数组
 * @param {string} data.pics[].url - 图片URL
 * @param {boolean} data.pics[].cover - 是否为封面
 * @param {number} data.pics[].type - 类型（1: 图片, 2: 视频）
 * @param {number} data.pics[].id - 图片ID（更新时传入，新增时为0）
 * @param {number} data.pics[].coin - 价格
 * @param {boolean} data.pics[].isPay - 是否需要付费
 * @returns {Promise}
 */
export function batchAddUpdatePicture(data) {
  return request({
    url: 'picture/batchAddUpdate',
    method: 'post',
    data: data
  })
}

/**
 * 删除图片
 * @param {Object} data - 删除数据
 * @param {number} data.userId - 用户ID
 * @param {Array<number>} data.ids - 图片ID数组
 * @returns {Promise}
 */
export function removePicture(data) {
  return request({
    url: 'picture/remove',
    method: 'post',
    data: data
  })
}
