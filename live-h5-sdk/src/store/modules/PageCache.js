import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import {TencentImUtils} from "@/utils/TencentImUtils";
import TencentCloudChat from "@tencentcloud/chat";
import {getConfig} from "@/api/sdk/system";
import {getBatchList} from "@/api/sdk/message";

const state = {
  cachedViews: [],
  dict: cache.local.getJSON(key_cache.dict_data, {}),
  configData: cache.local.getJSON(key_cache.config_data, {}),
  routeStack: [],
  pageSwitchAnimationName: '',
  chatInitSuccess: false,
  chatConversationList: [],
  unreadMsgCount: 0,
  rtmInitSuccess: false,
  lastQueriedUserIds: [], // 记录上一次查询的 userIds
  premiumDialogVisible: false, // VIP 弹窗 MPremiumDialog 是否显示，用于通知是否展示
  rechargePromoDialogVisible: false, // 首充促销弹窗 MRechargePromoDialog 是否显示
  rechargeDialogVisible: false, // 金币充值弹窗 MRechargeDialog 是否显示
  checkinDialogVisible: false // 签到弹窗 MCheckinDialog 是否显示
}

const mutations = {
  ADD_CACHED_VIEW: (state, view) => {
    if (state.cachedViews.includes(view.name)) {
      return;
    }
    state.cachedViews.push(view.name)
  },
  ADD_DICT: (state, dictList) => {
    cache.local.setJSON(key_cache.dict_data, dictList)
    state.dict = dictList;
  },
  ADD_CONFIG: (state, configs) => {
    cache.local.setJSON(key_cache.config_data, configs)
    state.configData = configs;
  },
  PUSH_ROUTE_STACK(state, route) {
    state.routeStack.push(route.name)
  },
  POP_ROUTE_STACK(state) {
    state.routeStack.pop()
  },
  ADD_PAGE_SWITCH_ANIMATION_NAME: (state, name) => {
    state.pageSwitchAnimationName = name;
  },
  SET_CHAT_INIT_SUCCESS: (state, success) => {
    state.chatInitSuccess = success;
  },
  SET_RTM_INIT_SUCCESS: (state, success) => {
    state.rtmInitSuccess = success;
  },
  SET_PREMIUM_DIALOG_VISIBLE: (state, visible) => {
    state.premiumDialogVisible = !!visible;
  },
  SET_RECHARGE_PROMO_DIALOG_VISIBLE: (state, visible) => {
    state.rechargePromoDialogVisible = !!visible;
  },
  SET_RECHARGE_DIALOG_VISIBLE: (state, visible) => {
    state.rechargeDialogVisible = !!visible;
  },
  SET_CHECKIN_DIALOG_VISIBLE: (state, visible) => {
    state.checkinDialogVisible = !!visible;
  },
  SET_UNREAD_MSG_COUNT: (state, unreadMsgCount) => {
    state.unreadMsgCount = unreadMsgCount;
  },
  ADD_CHAT_CONVERSATION_LIST: (state, list) => {
    list.forEach((it) => {
      const last = it.lastMessage;
      if (last && last.type === TencentCloudChat.TYPES.MSG_TEXT) {
        if (last.payload.text.length >= 30) {
          last.digest = last.payload.text.substr(0, 30) + '...';
        } else {
          last.digest = last.payload.text;
        }
      } else if (last && last.type === TencentCloudChat.TYPES.MSG_IMAGE) {
        last.digest = '[Image]';
      } else if (last && last.type === TencentCloudChat.TYPES.MSG_VIDEO) {
          last.digest = '[Video]';
      } else if (last && last.type === TencentCloudChat.TYPES.MSG_CUSTOM) {
        if (TencentImUtils.initCustomMessage(last)) {
          last.digest = '[' + last.customData.typeText + ']';
        }
      }
    })
    state.chatConversationList = list;
  },
  UPDATE_USER_PROFILES: (state, userProfilesMap) => {
    // 更新会话列表中的用户信息
    state.chatConversationList.forEach((conversation) => {
      const userId = TencentImUtils.getUserIdByImId(conversation.conversationID);
      if (userId && userProfilesMap[userId]) {
        const userInfo = userProfilesMap[userId];
        // 更新 userProfile
        if (!conversation.userProfile) {
          conversation.userProfile = {};
        }
        // 映射接口返回的字段到模板使用的字段
        // 只有当 avatar 有值且不为空字符串时才更新，避免用空值覆盖已有的头像
        if (userInfo.avatar !== undefined && userInfo.avatar !== null && userInfo.avatar !== '') {
          conversation.userProfile.avatar = userInfo.avatar;
        }
        if (userInfo.nickname !== undefined && userInfo.nickname !== null) {
          conversation.userProfile.nick = userInfo.nickname;
        }
        // 可以更新其他字段
        if (userInfo.userId !== undefined) {
          conversation.userProfile.userId = userInfo.userId;
        }
        // 更新在线状态
        if (userInfo.onlineStatus !== undefined && userInfo.onlineStatus !== null) {
          conversation.userProfile.onlineStatus = userInfo.onlineStatus;
        }
        // 更新年龄
        if (userInfo.age !== undefined && userInfo.age !== null) {
          conversation.userProfile.age = userInfo.age;
        }
      }
    });
    // 触发响应式更新
    state.chatConversationList = [...state.chatConversationList];
  }
}
const actions = {
  addView({commit}, view) {
    commit('ADD_CACHED_VIEW', view)
  },
  initConfig({commit}) {
      return getConfig({"configs":['HOME_RANDOM_VIDEOS','PAY_LIMIT_TYPE'],"dictTypes":['report_type','country','vip_category']}).then(res => {
        const {configs, dict} = res.data;
        console.log("config: " + JSON.stringify(configs))
        cache.local.setJSON(key_cache.config_data, configs)
        cache.local.setJSON(key_cache.dict_data, dict)
        commit('ADD_CONFIG', configs)
        commit('ADD_DICT', dict)
      })
  },
  addPageSwitchAnimationName({commit}, payload) {
    const {to, from} = payload
    let len = state.routeStack.length
    let animName = null;
    if (len === 0) {
      commit('PUSH_ROUTE_STACK', to)
    } else if (len === 1) {
      animName = 'slide-left';
      commit('PUSH_ROUTE_STACK', to)
    } else {
      let lastBeforeRoute = state.routeStack[len - 2]
      if (lastBeforeRoute === to.name) {
        // 打开上一页路由，后退
        commit('POP_ROUTE_STACK')
        animName = 'slide-right'
      } else {
        // 前进
        commit('PUSH_ROUTE_STACK', to)
        animName = 'slide-left';
      }
    }
    if (animName) {
      // 未开启页面切换动画
      if (to.meta.openPageSwitchAnimation === false || from.meta.openPageSwitchAnimation === false) {
        animName = null;
      }
      commit('ADD_PAGE_SWITCH_ANIMATION_NAME', animName);
    }
  },
  setChatInitSuccess({commit}) {
    commit('SET_CHAT_INIT_SUCCESS', true);
  },
  setUnreadMsgCount({commit}, unreadNum) {
    commit('SET_UNREAD_MSG_COUNT', unreadNum <= 0 ? -1 : unreadNum);
  },
  setRtmInitSuccess({commit}) {
    commit('SET_RTM_INIT_SUCCESS', true);
  },
  async loadChatConversationList({commit}) {
    if (!TencentImUtils.chatObj) {
      return
    }
    try {
      const imResponse = await TencentImUtils.chatObj.getConversationList();
      const conversationList = imResponse.data.conversationList;
      console.log('获取会话列表', conversationList)
      commit('ADD_CHAT_CONVERSATION_LIST', conversationList);

      // 提取所有 userId
      const userIds = [];
      conversationList.forEach((conversation) => {
        const userId = TencentImUtils.getUserIdByImId(conversation.conversationID);
        if (userId) {
          userIds.push(userId);
        }
      });

      // 排序 userIds 以便比较
      const sortedUserIds = [...userIds].sort((a, b) => a - b);
      const sortedLastUserIds = [...state.lastQueriedUserIds].sort((a, b) => a - b);

      // 比较当前 userIds 和上一次的 userIds，如果相同则跳过批量查询
      const userIdsChanged = sortedUserIds.length !== sortedLastUserIds.length ||
        sortedUserIds.some((id, index) => id !== sortedLastUserIds[index]);

      // 检查是否有缺失用户信息的会话（新会话或用户信息不完整）
      const missingUserInfoIds = [];
      conversationList.forEach((conversation) => {
        const userId = TencentImUtils.getUserIdByImId(conversation.conversationID);
        if (userId) {
          // 检查用户信息是否缺失或不完整
          if (!conversation.userProfile || 
              !conversation.userProfile.nick || 
              !conversation.userProfile.avatar) {
            missingUserInfoIds.push(userId);
          }
        }
      });

      // 批量查询用户信息（用户列表变化时，或有缺失用户信息的会话时）
      const needQuery = userIdsChanged || missingUserInfoIds.length > 0;
      const queryUserIds = userIdsChanged ? userIds : missingUserInfoIds;
      
      if (needQuery && queryUserIds.length > 0) {
        try {
          const batchResponse = await getBatchList(queryUserIds);
          if (batchResponse && batchResponse.data && Array.isArray(batchResponse.data)) {
            // 创建 userId 到用户信息的映射
            const userProfilesMap = {};
            batchResponse.data.forEach((userInfo) => {
              if (userInfo.userId) {
                userProfilesMap[userInfo.userId] = userInfo;
              }
            });
            // 更新会话列表中的用户信息
            commit('UPDATE_USER_PROFILES', userProfilesMap);
            // 更新记录的上一次查询的 userIds（仅在用户列表变化时更新）
            if (userIdsChanged) {
              state.lastQueriedUserIds = [...userIds];
            }
          }
        } catch (error) {
          console.error('批量查询用户信息失败:', error);
        }
      }
    } catch (imError) {
      console.warn('getConversationList error:', imError);
    }
  }
}

export default {
  namespaced: true,
  state,
  mutations,
  actions
}
