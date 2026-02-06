import request from '@/utils/Request'

// 视频点赞
export function videoPraise(videoId) {
  return request({
    url: 'video/praise',
    method: 'post',
    data: {videoId: videoId},
    loading: true
  })
}

// 购买视频
export function videoBuy(videoId) {
  return request({
    url: 'video/buy',
    method: 'post',
    data: {videoId: videoId},
    loading: true
  })
}
