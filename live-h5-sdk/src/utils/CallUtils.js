import {apiCallCreate, apiCallStart, apiCallEnd} from "@/api/sdk/call";
import store from "@/store";
import {router} from "@/router";
import {CALL_STATUS, LOCAL_CALL_STATUS} from "@/utils/Constant";
import {showConfirmDialog, showCreateAccountDialog, showRechargeDialog} from "@/components/dialog";
import {getAnchorInfo} from "@/api/sdk/anchor";
import clientNative from "@/utils/ClientNative";
import {showCallToast, showLoadingToast} from "@/components/toast/callToast";
import AgoraRTCManager from "@/utils/AgoraRTCManager";


/**
 * 检查用户信息是否需要完善，如果需要则弹出完善信息弹窗
 * @param {Function} onConfirm - 用户完善信息后的回调函数
 * @returns {boolean} 是否需要完善用户信息（true: 需要完善，已弹窗；false: 信息已完善）
 */
export function checkAndCompleteUserInfo(onConfirm) {
  const userInfo = store.state.user.loginUserInfo;
  if (!userInfo.nickname || !userInfo.age || !userInfo.gender) {
    showCreateAccountDialog(onConfirm);
  }else {
      onConfirm(true);
  }

}

/**
 * 申请通话
 * @param {number|string} userId - 主播用户ID
 * @param {string} callNo - 通话编号（可选）
 * @returns {Promise}
 */
export async function callCreate(userId, callNo = '',isMatch = false) {
    if (!isMatch) {
        const cameraPromise = await clientNative.requestPermission(1);
        const microphonePromise = await clientNative.requestPermission(3);

        // 等待两个权限都获取成功后再执行后续操作
        try {
            await Promise.all([cameraPromise, microphonePromise]);
            const  {getType: cameraType, isOpen: cameraIsOpen} = cameraPromise;
            const  {getType: microphoneType, isOpen: microphoneIsOpen} = microphonePromise;
            if (!microphoneIsOpen && !cameraIsOpen) {
              showConfirmDialog({
                title: 'Enable Microphone and Camera Access',
                message: 'To enable the microphone and camera for video chat, please enable microphone and camera access in your system settings.',
                confirmText: 'Cancel',
                cancelText: 'Go to Settings',
                onConfirm: () => {
                  return false;
                },
                onCancel: () => {
                  clientNative.openNativePermissionSetting();
                  return true;
                }
              });
              return;
            }else if (!microphoneIsOpen) {
              showConfirmDialog({
                title: 'Enable Microphone Access',
                message: 'To enable the microphone for video chat, please enable microphone access in your system settings.',
                confirmText: 'Cancel',
                cancelText: 'Go to Settings',
                onConfirm: () => {
                  return false;
                },
                onCancel: () => {
                  clientNative.openNativePermissionSetting();
                  return true;
                }
              });
              return;
            }else if (!cameraIsOpen) {
              showConfirmDialog({
                title: 'Enable Camera Access',
                message: 'To enable the camera for video chat, please enable camera access in your system settings.',
                confirmText: 'Cancel',
                cancelText: 'Go to Settings',
                onConfirm: () => {
                  return false;
                },
                onCancel: () => {
                  clientNative.openNativePermissionSetting();
                  return true;
                }
              });
              return;
            }
            return await ssssscallCreate(userId, callNo,isMatch);
        } catch (e) {
            console.error('permissions failed:', e);
            throw e; // 权限获取失败，抛出错误终止流程
        }
    }else {
      return ssssscallCreate(userId,callNo,isMatch);
    }
}

async function ssssscallCreate(userId, callNo = '',isMatch = false) {
    // 显示 loading toast（带菊花动画）
    // const loading = showLoadingToast('Connecting...');
    await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_WAITING);
    if (!isMatch) {
        // 先设为 false，避免从上次来电残留的 true 导致接听按钮闪一下再消失
        await store.dispatch('call/setIncomingCall', false);
        router.push({name: 'PageCallIncoming'}).catch(err => {
            console.error('跳转到等待:', err);
        });
    }
    return apiCallCreate(userId, {callNo}).then(async res => {
        // 存储主播数据和通话信息到 store
        if (res.data) {
            const callData = res.data;
            const {createUserId } = callData;
            const loginUserInfo = store.state.user.loginUserInfo || {};
            const myUserId = loginUserInfo.userId;
            console.log('loginUserInfo', loginUserInfo);
            console.log('createUserId', createUserId);
            await store.dispatch('call/setIsMatchingCall', isMatch);
            await store.dispatch('call/setIncomingCall', createUserId !== myUserId);
            // console.log('IncomingCall', store.state.call.incomingCall);
            // 直接使用 API 返回的完整数据结构
            await store.dispatch('call/setCallData', callData);
            // if (callData.anchorInfo.createUserId === callNo) {
            //     await  store.dispatch('call/setAnchorInfo', callData.anchorInfo);
            // }


            // 跳转到通话页面，使用返回的 callNo
            const actualCallNo = callData.callNo || callNo;
            if (actualCallNo) {
                // await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_WAITING);
                // if (!isMatch) {
                //     router.push({name: 'PageCallIncoming', params: {callNo: actualCallNo}}).catch(err => {
                //         console.error('跳转到等待:', err);
                //     });
                // } else {
                //     //   router.push({name: 'PageCalling', params: {callNo: actualCallNo}}).catch(err => {
                //     //     console.error('跳转到等待:', err);
                //     // });
                // }
                // await  store.dispatch('call/setAnchorInfo', callData.anchorInfo);
                getAnchorInfo(userId).then(res => {
                    if (res.data) {
                        store.dispatch('call/setAnchorInfo', res.data);
                    }
                });
                const {rtcType} = callData;
                if (rtcType === 'ARTC') {
                    // 提前初始化音视频（不阻塞流程）
                    setTimeout(() => {
                        AgoraRTCManager.preInit().catch(err => {

                        });
                    }, 500);
                }
            }
        }

        return res;
    }).catch(error => {
        router.back();
        if (error.msg === 'Insufficient Balance') {
            // showRechargeDialog({
            //     onSuccess:(data) => {
            //
            //     }
            // });
        }
        console.log(error);
        if (error.code === 1003) {
            if (error.msg && error.msg.includes('busy')) {
                showCallToast("The person is busy with another call.");
            }else {
                showCallToast("The person is not online at the moment.");
            }

        }else if (error.code === 500) {
            showCallToast(error.msg);
        }
        throw error;
    }).finally(() => {
        // loading && loading.close && loading.close();
    });
}

/**
 * 开始通话
 * @param {string} callNo - 通话编号
 * @param {number|string} activeUserId - 主叫用户ID
 * @param {number|string} unactiveUserId - 被叫用户ID
 * @returns {Promise}
 */
export function callStart(callNo) {
  return apiCallStart(callNo).then(res => {
    // 更新通话状态为开始
    return res;
  }).catch(error => {
    console.error('开始通话失败:', error);
    throw error;
  });
}

/**
 * 结束通话
 * @param {string} callNo - 通话编号
 * @param {object|string} status - 通话状态对象 { code, value } 或字符串
 * @param {string} [remark] - 备注（可选）
 * @param {number} [callDoneUserId] - 完成通话的用户ID（可选）
 * @returns {Promise}
 */
export function callEnd(callNo, status, remark = '', callDoneUserId = 0) {
  if (!callNo) {
    return;
  }
  // 支持对象格式 { code, value } 和字符串格式
  const apiStatus = typeof status === 'object' ? status.value : status;

  return apiCallEnd(callNo, apiStatus, remark, callDoneUserId).then(res => {
    // 更新通话状态为结束
    if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING) {
        store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END).then();
        store.dispatch('call/setCallStatus', CALL_STATUS.CALL_DONE.value).then();
        // store.dispatch('call/setEndCallData', res.data).then();
    }
    return res;
  }).catch(error => {
    console.error('结束通话失败:', error);
    throw error;
  });
}
