import TencentCloudChat from '@tencentcloud/chat';
import TIMUploadPlugin from 'tim-upload-plugin';
import TIMProfanityFilterPlugin from 'tim-profanity-filter-plugin';

import store from "@/store";
import {showGiftDialog, showPurchaseSuccessDialog, showRechargeDialog, closeRechargePromoDialogIfOpen, closePremiumDialogIfOpen, showVipSuccessDialog} from "@/components/dialog";
import {msToTime} from "@/utils/Utils";
import cache from "@/utils/cache";
import {CALL_STATUS, key_cache, LOCAL_CALL_STATUS} from "@/utils/Constant";
import {getAnchorInfo} from "@/api/sdk/anchor";
import {openChat} from "@/utils/PageUtils";
import {closeNotice, showNotice} from "@/components/MNotice/NoticeManager";
import {router} from "@/router";
import clientNative from "@/utils/ClientNative";
import { showCallToast } from '@/components/toast/callToast';
import {toast} from "@/components/toast";
import {EVENT_NAME, tdTrack} from "@/utils/TdTrack";

let chatObj;
let isInitialized = false; // 标记是否已初始化，防止重复初始化导致重新登录
const chatPrefix = 'chat', conversationPrefix = 'C2C';


/**
 * 1000-1999段 通话业务
 * 2000-3000段 自定义消息业务
 */
export const
    // ========== 1000-1999段 通话业务 ==========
    // 用户状态变更
    ONLINE_STATUS_CHANGE = 1001,
    // 通话邀请消息
    CALL_INVITE = 1002,
    // 通话状态变更
    CALL_STATUS_CHANGE = 1003,
    // 通话不足一分钟提示（充值提醒）
    LESS_THAN_ONE_MINUTE = 1004,

    // ========== 2000-3000段 自定义消息业务 ==========
    // 礼物消息
    custom_type_gift = 2000,
    // 金币变更
    COIN_CHANGE = 2001,
    // VIP变更
    VIP_CHANGE = 2002,
    // 主播喜欢用户
    ANCHOR_LIKE_USER = 2003,
    // 首充礼包充值成功
    RECHARGE_PROMO = 2004,

    // ========== 通话状态子类型 ==========
    // 正常挂断（已接通，主叫方和被叫方挂断均为正常挂断）
    CALL_20003_1 = 'CALL_20003_1',
    // 主叫方取消 （未接通）
    CALL_20003_2 = 'CALL_20003_2',
    // 被叫方拒绝 （未接通）
    CALL_20003_3 = 'CALL_20003_3',
    // 超时未接通
    CALL_20003_5 = 'CALL_20003_5';

/**
 * 参考文档：
 * https://cloud.tencent.com/document/product/269/75285
 */
function init(tencentAppId) {
    const params = cache.local.getJSON(key_cache.launch_h5_data, {});
    let options = {
        SDKAppID: tencentAppId
    };
    chatObj = TencentCloudChat.create(options);
    TencentImUtils.chatObj = chatObj;
    // chatObj.setLogLevel(envIsProd ? 1 : 0);
    chatObj.setLogLevel(4);
    // 注册腾讯云即时通信 IM 上传插件
    chatObj.registerPlugin({'tim-upload-plugin': TIMUploadPlugin});
    // 注册腾讯云即时通信 IM 本地审核插件
    chatObj.registerPlugin({'tim-profanity-filter-plugin': TIMProfanityFilterPlugin})
    // 登录
    const uid = String(params.userId);
    const sig = params.tencentUserSig;
    let promise = chatObj.login({userID: uid, userSig: sig});
    promise.then(function () {
        console.error("腾讯登录成功")
    }).catch(function (imError) {
        console.warn('login error:', imError); // 登录失败的相关信息
    });

    chatObj.on(TencentCloudChat.EVENT.SDK_READY, function (event) {
        // 收到离线消息和会话列表同步完毕通知，接入侧可以调用 sendMessage 等需要鉴权的接口
        if (event.name === TencentCloudChat.EVENT.SDK_READY) {
            store.dispatch('PageCache/setChatInitSuccess').then()
        }
    });

    chatObj.on(TencentCloudChat.EVENT.TOTAL_UNREAD_MESSAGE_COUNT_UPDATED, (event) => {
        store.dispatch('PageCache/setUnreadMsgCount', event.data).then()
        clientNative.setUnreadNum(event.data);
    });

    chatObj.on(TencentCloudChat.EVENT.MESSAGE_RECEIVED, (event) => {
        const messageList = event.data;
        const loginUserInfo = store.state.user.loginUserInfo || {};
        const myUserId = loginUserInfo.userId;
        messageList.forEach((message) => {
            console.log("------",message);
            // 获取消息发送者 ID
            const fromUserId = TencentImUtils.getUserIdByImId(message.from);
            // 判断是否是自己发送的消息
            const isSelfMessage = myUserId && Number(fromUserId) === Number(myUserId);

            if (message.type === TencentCloudChat.TYPES.MSG_TEXT) {
                if (!isSelfMessage) {
                    showNoticeMessage(message.from,message)
                }
            }
            let result = initCustomMessage(message)
            if (result && message.customData.customType === ANCHOR_LIKE_USER) {
                if (!isSelfMessage) {
                    const likeUserId = message.customData.anchor.id;
                    if (likeUserId != null && likeUserId !== '' && Number(likeUserId) > 0) {
                        showNoticeMessage(likeUserId, message);
                        // 喜欢消息未读数 +1 并持久化到本地，会话列表展示
                        const current = parseInt(cache.local.get(key_cache.unread_like_count) || '0', 10);
                        const next = current + 1;
                        cache.local.set(key_cache.unread_like_count, String(next));
                        document.dispatchEvent(new CustomEvent('unreadLikeCountUpdated', { detail: next }));
                    }
                }
            }

            if (result && message.customData.customType === custom_type_gift) {
                // 只显示对方发来的礼物动画，自己发送的礼物在发送成功回调中已经显示过了
                if (!isSelfMessage) {
                    showGiftDialog(message.customData.svg)
                }
            }
            if (result && message.customData.customType === COIN_CHANGE) {
                store.dispatch('GetInfo')
                if (message.customData.coinChangeType === 0) {
                    toast("Recharge successfully")
                    tdTrack(EVENT_NAME.client_coinspopup_buy_suc,{"coins_status":true})
                }
            }
            if (result && message.customData.customType === VIP_CHANGE) {
                if (message.customData.vipCategory !== 0) {
                    toast("Recharge successfully")
                }
                store.dispatch('GetInfo');
                const currentRoute = router.currentRoute;
                const pageCache = store.state.PageCache;
                if (currentRoute && (currentRoute.name === 'PagePremium' || currentRoute.path === '/sdk/page/pagePremium')) {
                    router.back();
                } else if (pageCache && pageCache.rechargePromoDialogVisible) {
                    closeRechargePromoDialogIfOpen();
                } else if (pageCache && pageCache.premiumDialogVisible) {
                    closePremiumDialogIfOpen();
                } else {
                    router.back();
                }
                tdTrack(EVENT_NAME.client_vip_buy_suc,{"vip_status":true,"vip_type":"normal"});
                const customData = message.customData || {};
                const checkinTotalDay = Number(customData.checkinTotalDay);
                const checkinTotalCoin = Number(customData.checkinTotalCoin);
                showVipSuccessDialog({
                    benefitsCount: 15,
                    consecutiveDays: Number.isNaN(checkinTotalDay) ? 0 : checkinTotalDay,
                    freeCoins: Number.isNaN(checkinTotalCoin) ? 0 : checkinTotalCoin
                });
            }
            if (result && message.customData.customType === RECHARGE_PROMO) {
                closeRechargePromoDialogIfOpen();
                store.dispatch('GetInfo');
                store.dispatch('GetUserBackpack');
                store.dispatch('FetchFirstRechargeList').then(() => {
                    document.dispatchEvent(new CustomEvent('firstRechargeListRefreshed'));
                });
                const d = message.customData.productDetail;
                const rewards = Array.isArray(d.rewards) ? d.rewards : [];
                const rewardCoins = rewards.reduce((sum, r) => {
                    if (r && Number(r.backpackType) === 5) {
                        const q = Number(r.quantity);
                        return sum + (Number.isNaN(q) ? 0 : Math.max(0, q));
                    }
                    return sum;
                }, 0);
                const baseCoin = d.originalCoin != null ? Number(d.originalCoin) : 0;
                const coins = baseCoin + rewardCoins;
                const qty = { 2: 0, 3: 0, 4: 0 };
                rewards.forEach((r) => {
                    const t = r.backpackType;
                    if (t === 2 || t === 3 || t === 4) qty[t] += Math.max(0, Number(r.quantity) || 0);
                });
                const quantities = [qty[2], qty[3], qty[4]];
                showPurchaseSuccessDialog({ coins, quantities });
            }

            callMessageNew(message);
        });

        // 收到新消息后，更新会话列表，确保最后一条消息显示正确
        store.dispatch('PageCache/loadChatConversationList').then();
    });
}

function logoutIM() {
    chatObj.logout()
}

function getChatUserId(userId) {
    // return chatPrefix + userId;
    return String(userId);
}

// async function callMessage(message)  {
//     if (message.type === TencentCloudChat.TYPES.MSG_CUSTOM) {
//         console.error("=========通话消息",message);
//         const {customType} = message.customData;
//         if (customType === CALL_INVITE) { // 跳转到通话中
//             const {actionType, callStatus} = message.customData;
//             const isMatchingCall = store.state.call.isMatchingCall;
//
//             if (actionType === 3) {
//                 // 对方拒绝/取消通话
//                 if (isMatchingCall) {
//                     if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING) {
//                         // 匹配通话被拒绝：通知 matching.vue 重新匹配
//                         await store.dispatch('call/setMatchCallRejected', Date.now())
//                     }
//                 } else {
//                     // 普通来电被拒绝：退出 incoming.vue 界面
//                     if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING) {
//                         // 普通来电被拒绝：退出 incoming.vue 界面
//                         showCallToast("The caller rejected the call.")
//                         await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE)
//                         router.back()
//                     }
//                 }
//             }else if (actionType === 1) {  //新电话邀请
//                 const {callInvite} =  message.customData;
//                 if (callInvite === null) {
//                     return;
//                 }
//                 const {callType, anchorInfo, callNo,createUserId,rtcType, createUserSign, toUserSign} = callInvite;
//
//                 const loginUserInfo = store.state.user.loginUserInfo || {};
//                 const myUserId = loginUserInfo.userId;
//                 //只显示对方来电通知，自己拨打也会出现该数据，但是已经在createCall那里拉起了页面，所以这里就不做跳转了，
//                 if (createUserId !== myUserId
//                     && callType === CALL_STATUS.CALLING.value
//                     && (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_NONE || store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END) ) {
//                      await store.dispatch('call/setCallData', callInvite);
//                      await store.dispatch('call/setAnchorInfo', anchorInfo);
//                      await store.dispatch('call/setIncomingCall', true);
//                      const routeConfig = {name: 'PageCallIncoming'}
//                     await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_WAITING);
//                     router.push(routeConfig).catch(err => {
//                         console.error('跳转到通话页面失败:', err);
//                     });
//                 }
//             } else  if (actionType === 2){
//                 // TODO: 后端接口支持类型后，根据类型判断跳转 PageCalling 或 PageTXCalling
//                 // 非匹配通话：替换当前拨打页面；匹配通话：push 进去
//                 if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING  || isMatchingCall) {  // 如果是在响应界面，进入通话界面
//                     if (callStatus === CALL_STATUS.ANSWER.code) {
//                         console.log("=-=-=-=-=-=-=-=-=-=-=",store.state.call.callData);
//                         const {rtcType} = store.state.call.callData;
//                         let routeConfig = {name: 'PageTXCalling'};
//                         if (rtcType === 'ARTC') {
//                             routeConfig = {name: 'PageCalling'};
//                         }
//                         await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_CALLING);
//                         router.replace(routeConfig).catch(err => {
//                             console.error('跳转到通话页面失败:', err);
//                         });
//                     }
//
//                 }
//
//             }
//         } else if (customType === CALL_STATUS_CHANGE) {
//             console.log('');
//             const isMatchingCall = store.state.call.isMatchingCall;
//             if (isMatchingCall) {
//                 if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING) {
//                     const {callNo,callStatus,callTime} = message.customData;
//                     if (callStatus === CALL_STATUS.REFUSE.code) {
//                         // 匹配通话被拒绝：通知 matching.vue 重新匹配
//                         store.dispatch('call/setMatchCallRejected', Date.now())
//                     }
//                 }
//             }else {
//                 const {callNo,callStatus,callTime} = message.customData;
//                 if (store.state.call.localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING) {
//                     if (callStatus === CALL_STATUS.REFUSE.code) {
//                         showCallToast("The caller rejected the call.")
//                         store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
//                         router.back();
//                     }
//                 }
//             }
//
//         }else if (customType === COIN_CHANGE) {
//             // showRechargeDialog()
//         }
//     }
// }

/// 新版，之前的有问题
/// 新版，与 Flutter 端逻辑对齐
async function callMessageNew(message) {
    if (message.type !== TencentCloudChat.TYPES.MSG_CUSTOM) return;
    console.log("=========ssss通话消息", message);
    const { customType } = message.customData;
    console.log("=========customType", customType);
    // if (customType !== CALL_INVITE || customType !== CALL_STATUS_CHANGE) {
    //     if (customType === COIN_CHANGE) {
    //         // showRechargeDialog()
    //     }
    //     console.log("ssssssssssssssss")
    //     return;
    // }
    // console.log("ddddddddddddddd")
    const { actionType, callStatus, callInvite, callTime } = message.customData;
    const localCallStatus = store.state.call.localCallStatus;
    const isMatchingCall = store.state.call.isMatchingCall;

    // 1. 来电：无通话/已结束 + 新邀请 + callInvite 非空
    if ((localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_NONE || localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END)
        && actionType === 1
        && callInvite != null) {
        console.error('跳转到来电页面失败:');
        const { callType, anchorInfo, createUserId } = callInvite;
        const loginUserInfo = store.state.user.loginUserInfo || {};
        const myUserId = loginUserInfo.userId;
        if (createUserId !== myUserId && callType === CALL_STATUS.CALLING.value) {
            // 检查当前是否在假的来电页面
            const currentRoute = router.currentRoute;
            if (currentRoute && currentRoute.name === 'PageCallIncoming' && currentRoute.query.isJia === 'true') {
                // 如果在假的来电页面，先返回
                await router.back();
            } else if (currentRoute && currentRoute.name === 'PageCallIncoming' && !currentRoute.query.isJia) {
                // 如果已经在真实的来电页面，不做处理，避免覆盖当前真实来电
                return;
            }
            await store.dispatch('call/setCallData', callInvite);
            await store.dispatch('call/setAnchorInfo', anchorInfo);
            await store.dispatch('call/setIncomingCall', true);
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_WAITING);
            router.push({ name: 'PageCallIncoming' }).catch(err => {
                console.error('跳转到来电页面失败:', err);
            });
        }
        return;
    }

    // 2. 通话中收到状态变更：对方挂断 / 异常结束 / 系统终止 / 余额不足
    if (localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING || localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_END) {
        if (callStatus === CALL_STATUS.CALL_DONE.code
            || callStatus === CALL_STATUS.CALLING_ERROR_DONE.code
            || callStatus === CALL_STATUS.SYSTEM_STOP.code
            || callStatus === CALL_STATUS.CALL_TIMEOUT_DONE.code
            || callStatus === CALL_STATUS.NOT_BALANCE_DONE.code) {
            if (localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING) {
                await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_END);
                const isMyCallEnd = store.state.call.isMyCallEnd;
                if (!isMyCallEnd) {
                    showCallToast('The other person has left the room.');
                }
                const currentRoute = router.currentRoute?.name;
                if (currentRoute !== 'PageCallEnd') {
                    // router.replace({ name: 'PageCallEnd' }).catch(err => {
                    //     console.error('跳转到通话结束页失败:', err);
                    // });
                }
            }
            if (callTime != null && callTime > 0) {
                await store.dispatch('call/setEndCallData', message.customData);
            }
        }
        return;
    }

    // 3. 等待中收到状态变更
    if (localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING) {
        if (callStatus === CALL_STATUS.ANSWER.code) {
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_CALLING);
            const callData = store.state.call.callData || {};
            const rtcType = callData.rtcType;
            const routeConfig = rtcType === 'ARTC' ? { name: 'PageCalling' } : { name: 'PageTXCalling' };
            console.log(routeConfig);
            const currentRoute = router.currentRoute?.name;
            if (currentRoute !== 'PageCalling' && currentRoute !== 'PageTXCalling') {
                router.replace(routeConfig).catch(err => {
                    console.error('跳转到通话页面失败:', err);
                });
            }
        } else if (callStatus === CALL_STATUS.CANCEL_CALL.code) {
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
            showCallToast('The caller rejected the call.');
            router.back();
        } else if (callStatus === CALL_STATUS.CALL_TIMEOUT_DONE.code) {
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
            showCallToast('Call timeout, please try again later.');
            router.back();
        } else if (callStatus === CALL_STATUS.CALL_ERROR_DONE.code) {
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
            showCallToast('The caller rejected the call.');
            router.back();
        } else if (isMatchingCall && callStatus === CALL_STATUS.REFUSE.code) {
            store.dispatch('call/setMatchCallRejected', Date.now());
        } else if (!isMatchingCall && callStatus === CALL_STATUS.REFUSE.code) {
            await store.dispatch('call/setLocalCallStatus', LOCAL_CALL_STATUS.LOCAL_CALL_NONE);
            showCallToast('The caller rejected the call.');
            router.back();
        }
    }
}


/**
 * 初始化自定义消息
 * @param message
 * @returns {boolean}
 */
function initCustomMessage(message) {
    if (message.type === TencentCloudChat.TYPES.MSG_CUSTOM) {
        message.customData = JSON.parse(message.payload.data);
        const {customType} = message.customData;
        const formUser = TencentImUtils.getUserIdByImId(message.fromAccount);
        let typeText = '';
        if (customType === custom_type_gift) {
            typeText = 'Gift';
        }else if (customType === CALL_STATUS_CHANGE) {
            switch (message.customData.callStatus) {
                case CALL_STATUS.CALL_DONE.code:
                case CALL_STATUS.CALLING_ERROR_DONE.code:
                    typeText = msToTime(parseInt(message.customData.callTime) * 1000, '{h}:{i}:{s}');
                    break;
                case CALL_STATUS.CANCEL_CALL.code:
                    typeText = "Canceled";
                    break;
                case CALL_STATUS.REFUSE.code:
                    typeText = "Declined";
                    break;
                case CALL_STATUS.CALL_TIMEOUT_DONE.code:
                    typeText = "Missed"
                    break;
                case CALL_STATUS.NOT_BALANCE_DONE.code:
                    // typeText = "Missed"
                    typeText = msToTime(parseInt(message.customData.callTime) * 1000, '{h}:{i}:{s}');
                    break;
                default:
                    typeText = message.customData.desc;
            }
        }
        message.customData.typeText = typeText;
        return true;
    }
    return false;
}

function createCustomMessage(userId, data, type) {
    return TencentImUtils.chatObj.createCustomMessage({
        to: getChatUserId(userId),
        conversationType: TencentCloudChat.TYPES.CONV_C2C,
        payload: {
            data: JSON.stringify({type, content: data})
        }
    });
}

export const TencentImUtils = {
    init, logoutIM,chatObj, chatPrefix, conversationPrefix,
    getChatUserId,
    getConversationIdByUserId(userId) {
        // return conversationPrefix + chatPrefix + userId;
        return conversationPrefix + userId;
    },
    createTextMessage(text, userId) {
        return TencentImUtils.chatObj.createTextMessage({
            to: getChatUserId(userId),
            conversationType: TencentCloudChat.TYPES.CONV_C2C,
            payload: {
                text: text
            }
        });
    },
    createImageMessage(userId, file) {
        return TencentImUtils.chatObj.createImageMessage({
            to: getChatUserId(userId),
            conversationType: TencentCloudChat.TYPES.CONV_C2C,
            payload: {
                file: file
            }
        });
    },
    createGiftMessage(userId, gift) {
        return createCustomMessage(userId, gift, custom_type_gift);
    },
    createCallMessage(userId, typeCode, duration) {
        return createCustomMessage(userId, {callMsgType: typeCode, duration: duration || 0}, CALL_STATUS_CHANGE);
    },
    // 发送消息
    sendMessage(message) {
        return TencentImUtils.chatObj.sendMessage(message);
    },
    /**
     * 设置消息已读
     * @param userId
     */
    setMessageRead(userId) {
        TencentImUtils.chatObj.setMessageRead({conversationID: TencentImUtils.getConversationIdByUserId(userId)})
    },
    initCustomMessage,
    /**
     * 当收到新消息监听
     * @param callBack
     */
    onMessageReceived(callBack) {
        TencentImUtils.chatObj.on(TencentCloudChat.EVENT.MESSAGE_RECEIVED, callBack);
    },
    /**
     * 当消息变更监听
     * @param callBack
     */
    onMessageModified(callBack) {
        TencentImUtils.chatObj.on(TencentCloudChat.EVENT.MESSAGE_MODIFIED, callBack);
    },
    getUserIdByImId(imUserIdOrConversationId) {
        if (!imUserIdOrConversationId) {
            return imUserIdOrConversationId;
        }
        imUserIdOrConversationId = imUserIdOrConversationId.toString();
        if (imUserIdOrConversationId.indexOf(chatPrefix) !== -1) {
            imUserIdOrConversationId = imUserIdOrConversationId.replace(chatPrefix, '');
        }

        if (imUserIdOrConversationId.indexOf(conversationPrefix) !== -1) {
            imUserIdOrConversationId = imUserIdOrConversationId.replace(conversationPrefix, '');
        }
        return parseInt(imUserIdOrConversationId);
    }
}

/**
 * 新消息提示
 * @param fromAccountId 发送方id
 * @param messageObj 消息体
 */
export function showNoticeMessage(fromAccountId, messageObj) {
    // 如果当前在聊天页面、VIP 页面或 VIP 弹窗打开，不显示通知
    const currentRoute = router.currentRoute;
    if (currentRoute && (currentRoute.name === 'PageChat' || currentRoute.path === '/sdk/page/chat')) {
        return;
    }
    if (currentRoute && (currentRoute.name === 'PagePremium' || currentRoute.path === '/sdk/page/pagePremium')) {
        return;
    }
    if (store.state.PageCache && store.state.PageCache.premiumDialogVisible) {
        return;
    }
    if (store.state.PageCache && store.state.PageCache.rechargePromoDialogVisible) {
        return;
    }
    // 拨打电话/通话中不显示通知
    const localCallStatus = store.state.call?.localCallStatus;
    if (localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_WAITING || localCallStatus === LOCAL_CALL_STATUS.LOCAL_CALL_CALLING) {
        return;
    }

    // 推送消息里发送方 ID 无效时，不请求 anchor/getInfo，避免报错
    const uid = fromAccountId != null && fromAccountId !== '' ? Number(fromAccountId) : NaN;
    if (Number.isNaN(uid) || uid <= 0) {
        return;
    }

    clientNative.vibrationEvent(1, 1)
    const isOnlineNotice = false;
    // 判断是否是 ANCHOR_LIKE_USER 消息类型
    const isAnchorLikeUser = messageObj.customData?.customType === ANCHOR_LIKE_USER;
    getAnchorInfo(uid).then(({data: accountInfo}) => {
        let message = messageObj.payload.text;
        if (isAnchorLikeUser) {
            message = "Say hi now >>>"
        }
        let sliceNum = 13;
        const noticeId = showNotice({
            title: (accountInfo.nickname.length > sliceNum
                ? accountInfo.nickname.slice(0, sliceNum) + '...'
                : accountInfo.nickname),
            message: message,
            isBlur: false,
            backgroundColor: '#ffffff',
            avatar: accountInfo.avatar,
            country: accountInfo.country,
            age: accountInfo.age,
            rightImage: isAnchorLikeUser ? require('@/assets/image/message/ic-message-notice-like.png') : null,
            duration: 3000,
            isOnlineNotice: isOnlineNotice,
            isLikeNotice: isAnchorLikeUser,
            onClick: () => {
                closeNotice(noticeId)
                openChat(accountInfo.userId)
            }
        });
    });
}
