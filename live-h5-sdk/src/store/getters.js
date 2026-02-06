const getters = {
  token: state => state.user.token,
  loginUserInfo: state => state.user.loginUserInfo,
  isOpenCamera: state => state.call.isOpenCamera,
  isOpenMicrophone: state => state.call.isOpenMicrophone,
  isFrontCamera: state => state.call.isFrontCamera,
  callData: state => state.call.callData,
  incomingCall: state => state.call.incomingCall,
}
export default getters
