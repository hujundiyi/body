import clientEach from "@/utils/ClientEach";
import cache from "@/utils/cache";
import {key_cache, CALL_STATUS,LOCAL_CALL_STATUS} from "@/utils/Constant";

// 本地存储的 key
const CALL_SETTINGS_KEY = 'call_settings'

// 从本地存储读取设置
const getStoredSettings = () => {
  const stored = cache.local.getJSON(CALL_SETTINGS_KEY, {})
  return {
    isOpenCamera: stored.isOpenCamera !== undefined ? stored.isOpenCamera : true,
    isOpenMicrophone: stored.isOpenMicrophone !== undefined ? stored.isOpenMicrophone : true,
    isFrontCamera: stored.isFrontCamera !== undefined ? stored.isFrontCamera : true,
  }
}

// 保存设置到本地存储
const saveSettings = (settings) => {
  cache.local.setJSON(CALL_SETTINGS_KEY, settings)
}

const call = {
  namespaced: true,
  state: {
    ...getStoredSettings(),
    incomingCall: false, // 是否是 拨打进来 通话
      isMatchingCall: false,  // 是否是匹配通话
    callData: {}, // 完整的通话数据
    anchorInfo: {}, // 主播信息
    endCallData: {}, // 结束通话数据
    localCallStatus: LOCAL_CALL_STATUS.LOCAL_CALL_NONE, // 本地通话状态
    matchCallRejected: 0, // 匹配通话被拒绝的时间戳，用于通知 matching 页面重新匹配
    isMyCallEnd: false, // 是否是本方挂断
  },
  mutations: {
    SET_LOCAL_CALL_STATUS: (state, localCallStatus) => {
      state.localCallStatus = localCallStatus
    },
    SET_IS_MATCHING_CALL: (state, isMatchingCall) => {
      state.isMatchingCall = isMatchingCall
    },  
    SET_IS_OPEN_CAMERA: (state, isOpenCamera) => {
      state.isOpenCamera = isOpenCamera
      saveSettings({
        isOpenCamera: state.isOpenCamera,
        isOpenMicrophone: state.isOpenMicrophone,
        isFrontCamera: state.isFrontCamera
      })
    },
    SET_IS_OPEN_MICROPHONE: (state, isOpenMicrophone) => {
      state.isOpenMicrophone = isOpenMicrophone
      saveSettings({
        isOpenCamera: state.isOpenCamera,
        isOpenMicrophone: state.isOpenMicrophone,
        isFrontCamera: state.isFrontCamera
      })
    },
    SET_IS_FRONT_CAMERA: (state, isFrontCamera) => {
      state.isFrontCamera = isFrontCamera
      saveSettings({
        isOpenCamera: state.isOpenCamera,
        isOpenMicrophone: state.isOpenMicrophone,
        isFrontCamera: state.isFrontCamera
      })
    },
    SET_CALL_DATA: (state, callData) => {
      // 保存完整数据
      state.callData = {...state.callData, ...callData}
    },
    SET_CALL_STATUS: (state, status) => {
      state.callData = {...state.callData, callStatus: status}
    },
    SET_INCOMING_CALL: (state, isIncomingCall) => {
      state.incomingCall = isIncomingCall
    },
    CLEAR_CALL_DATA: (state) => {
      state.incomingCall = false
      state.callData = {}
      state.anchorInfo = {}
      state.endCallData = {}
    },
    SET_ANCHOR_INFO: (state, anchorInfo) => {
      state.anchorInfo = anchorInfo
    },
    SET_END_CALL_DATA: (state, endCallData) => {
      state.endCallData = endCallData
    },
    SET_MATCH_CALL_REJECTED: (state, timestamp) => {
      state.matchCallRejected = timestamp
    },
    SET_IS_MY_CALL_END: (state, isMyCallEnd) => {
      state.isMyCallEnd = isMyCallEnd
    }
  },
  actions: {
    setIsOpenCamera({commit}, isOpenCamera) {
      commit('SET_IS_OPEN_CAMERA', isOpenCamera)
    },
    setIsOpenMicrophone({commit}, isOpenMicrophone) {
      commit('SET_IS_OPEN_MICROPHONE', isOpenMicrophone)
    },
    setIsFrontCamera({commit}, isFrontCamera) {
      commit('SET_IS_FRONT_CAMERA', isFrontCamera)
    },
    setCallData({commit}, callData) {
      commit('SET_CALL_DATA', callData)
    },
    setCallStatus({commit}, status) {
      commit('SET_CALL_STATUS', status)
    },
    setIncomingCall({commit}, isIncomingCall) {
      commit('SET_INCOMING_CALL', isIncomingCall)
    },
    clearCallData({commit}) {
      commit('CLEAR_CALL_DATA')
    },
    setAnchorInfo({commit}, anchorInfo) {
      commit('SET_ANCHOR_INFO', anchorInfo)
    },
    setEndCallData({commit}, endCallData) {
      commit('SET_END_CALL_DATA', endCallData)
    },
    setIsMatchingCall({commit}, isMatchingCall) {
      commit('SET_IS_MATCHING_CALL', isMatchingCall)
    },
    setLocalCallStatus({commit}, localCallStatus) {
      commit('SET_LOCAL_CALL_STATUS', localCallStatus)
    },
    setMatchCallRejected({commit}, timestamp) {
      commit('SET_MATCH_CALL_REJECTED', timestamp)
    },
    setIsMyCallEnd({commit}, isMyCallEnd) {
      commit('SET_IS_MY_CALL_END', isMyCallEnd)
    }
  },
  getters: {

  }
}

export default call
export { CALL_STATUS }
