import { getRecommendAnchors } from "@/api/sdk/match";
import { getDetailList, getAnchorDetailList, getAnchorInfo } from "@/api/sdk/anchor";

const anchor = {
  namespaced: true,
  state: {
    recommendAnchors: [],      // 推荐主播列表
    isLoading: false,          // 是否正在加载
    isLoaded: false,           // 是否已加载过
    cachedVideoUrl: null       // 缓存的视频URL
  },
  mutations: {
    SET_RECOMMEND_ANCHORS: (state, anchors) => {
      state.recommendAnchors = anchors || [];
      state.isLoaded = true;
    },
    SET_LOADING: (state, loading) => {
      state.isLoading = loading;
    },
    SET_CACHED_VIDEO_URL: (state, url) => {
      state.cachedVideoUrl = url;
    }
  },
  actions: {
    /**
     * 加载推荐主播列表
     * @param {boolean} force - 是否强制刷新
     */
    async loadRecommendAnchors({ state, commit }, force = false) {
      // 如果已加载且不强制刷新，直接返回
      if (state.isLoaded && !force && state.recommendAnchors.length > 0) {
        return state.recommendAnchors;
      }
      
      // 如果正在加载中，不重复请求
      if (state.isLoading) {
        return state.recommendAnchors;
      }
      
      commit('SET_LOADING', true);
      
      try {
        const res = await getRecommendAnchors();
        if (res.success && res.data && Array.isArray(res.data)) {
          commit('SET_RECOMMEND_ANCHORS', res.data);
          return res.data;
        } else {
          console.warn('推荐主播列表为空');
          return [];
        }
      } catch (error) {
        console.error('加载推荐主播失败:', error);
        return [];
      } finally {
        commit('SET_LOADING', false);
      }
    },
    
    /**
     * 获取随机视频URL
     * 优先从推荐主播列表中获取，如果没有视频则调用 getAnchorInfo 接口
     */
    async fetchRandomVideoUrl({ state, commit, dispatch }) {
      // 如果有缓存，直接返回
      if (state.cachedVideoUrl) {
        return state.cachedVideoUrl;
      }
      
      // 确保推荐主播列表已加载
      if (!state.isLoaded || state.recommendAnchors.length === 0) {
        await dispatch('loadRecommendAnchors');
      }
      
      if (state.recommendAnchors.length === 0) {
        return null;
      }
      
      // 先尝试从推荐主播列表中获取视频
      const anchorsWithVideo = state.recommendAnchors.filter(
        a => a.videoUrl || a.video || (a.videos && a.videos.length > 0)
      );
      
      if (anchorsWithVideo.length > 0) {
        const randomIndex = Math.floor(Math.random() * anchorsWithVideo.length);
        const anchor = anchorsWithVideo[randomIndex];
        let videoUrl = null;
        
        if (anchor.videoUrl) {
          videoUrl = anchor.videoUrl;
        } else if (anchor.video) {
          videoUrl = anchor.video;
        } else if (anchor.videos && anchor.videos.length > 0) {
          const videoIndex = Math.floor(Math.random() * anchor.videos.length);
          videoUrl = anchor.videos[videoIndex].videoUrl || anchor.videos[videoIndex].url;
        }
        
        if (videoUrl) {
          commit('SET_CACHED_VIDEO_URL', videoUrl);
          return videoUrl;
        }
      }
      
      // 如果推荐列表中没有视频，打乱主播顺序后依次调用 getAnchorInfo 获取视频
      const shuffledAnchors = [...state.recommendAnchors].sort(() => Math.random() - 0.5);
      
      for (const anchor of shuffledAnchors) {
        if (!anchor || !anchor.userId) continue;
        
        try {
          const rsp = await getAnchorInfo(anchor.userId);
          if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success) && rsp.data) {
            const anchorDetail = rsp.data;
            
            // 从 getAnchorInfo 返回的数据中获取视频
            if (anchorDetail.videos && anchorDetail.videos.length > 0) {
              const videoIndex = Math.floor(Math.random() * anchorDetail.videos.length);
              const video = anchorDetail.videos[videoIndex];
              const videoUrl = video.videoUrl || video.url;
              
              if (videoUrl) {
                commit('SET_CACHED_VIDEO_URL', videoUrl);
                return videoUrl;
              }
            }
            // 没有视频，继续下一个主播
          }
        } catch (error) {
          console.error('获取主播详情失败:', error);
          // 出错继续下一个主播
        }
      }
      
      return null;
    }
    ,
    /**
     * 获取推荐主播的视频列表（包含详情视频）
     */
    async fetchVideoPlaylist() {
      const avatarList = [];
      const avatarSet = new Set(); // 用于去重

      const addAvatarFromAnchor = (anchor) => {
        if (!anchor) return;
        const avatar = anchor.avatar || anchor.headPic || anchor.headImg || anchor.avatarUrl || '';
        // 只要有头像就添加，即使没有视频URL也用于轮播
        if (avatar && !avatarSet.has(avatar)) {
          avatarSet.add(avatar);
          // 保留完整的 anchor 对象，包括 nickname 等字段
          avatarList.push({
            avatar: avatar,
            nickname: anchor.nickname || anchor.name || null,
            name: anchor.name || anchor.nickname || null,
            userId: anchor.userId || null,
            ...anchor // 保留所有其他字段
          });
        }
      };

      try {
        const fetchDetailList = getDetailList || getAnchorDetailList;
        if (!fetchDetailList) {
          console.error('getDetailList 未定义');
          return avatarList;
        }
        const rsp = await fetchDetailList({ page: 1, size: 20, type: "ALL" });
        console.log('fetchVideoPlaylist - getDetailList 响应:', rsp);
        
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success) && rsp.data) {
          // 处理不同的数据结构：可能是数组，也可能是包含 list 的对象
          let detailList = Array.isArray(rsp.data) ? rsp.data : (rsp.data.list || []);
          console.log('fetchVideoPlaylist - 解析后的数据列表长度:', detailList.length);
          
          if (detailList && detailList.length > 0) {
            detailList.forEach((anchor) => addAvatarFromAnchor(anchor));
          }
        } else {
          console.warn('fetchVideoPlaylist - 响应数据格式不正确:', rsp);
        }
      } catch (error) {
        console.error('批量获取主播详情失败:', error);
      }

      console.log('fetchVideoPlaylist - 返回的头像列表长度:', avatarList.length);
      return avatarList;
    }
  },
  getters: {
    // 获取推荐主播列表
    recommendAnchors: (state) => state.recommendAnchors,
    
    // 随机获取指定数量的主播
    getRandomAnchors: (state) => (count = 3) => {
      if (!state.recommendAnchors || state.recommendAnchors.length === 0) {
        return [];
      }
      
      const availableAnchors = [...state.recommendAnchors];
      const selected = [];
      
      for (let i = 0; i < count; i++) {
        if (availableAnchors.length === 0) {
          // 如果已经用完，重新填充
          availableAnchors.push(...state.recommendAnchors);
        }
        const randomIndex = Math.floor(Math.random() * availableAnchors.length);
        selected.push(availableAnchors.splice(randomIndex, 1)[0]);
      }
      
      return selected;
    },
    
    // 随机获取一个主播
    getRandomAnchor: (state) => () => {
      if (!state.recommendAnchors || state.recommendAnchors.length === 0) {
        return null;
      }
      const randomIndex = Math.floor(Math.random() * state.recommendAnchors.length);
      return state.recommendAnchors[randomIndex];
    },
    
    // 随机获取一个主播的视频URL
    getRandomVideoUrl: (state) => () => {
      if (!state.recommendAnchors || state.recommendAnchors.length === 0) {
        return null;
      }
      // 筛选有视频的主播
      const anchorsWithVideo = state.recommendAnchors.filter(
        a => a.videoUrl || a.video || (a.videos && a.videos.length > 0)
      );
      
      if (anchorsWithVideo.length === 0) {
        return null;
      }
      
      const randomIndex = Math.floor(Math.random() * anchorsWithVideo.length);
      const anchor = anchorsWithVideo[randomIndex];
      
      // 返回视频URL（根据实际数据结构调整）
      if (anchor.videoUrl) return anchor.videoUrl;
      if (anchor.video) return anchor.video;
      if (anchor.videos && anchor.videos.length > 0) {
        const videoIndex = Math.floor(Math.random() * anchor.videos.length);
        return anchor.videos[videoIndex].videoUrl || anchor.videos[videoIndex].url;
      }
      
      
      return null;
    }
  }
};

export default anchor;
