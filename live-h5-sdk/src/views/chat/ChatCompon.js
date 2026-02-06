import {custom_type_gift, TencentImUtils as chat, TencentImUtils} from "@/utils/TencentImUtils";
import store from "@/store";
import TencentCloudChat from "@tencentcloud/chat";
import {getUUID} from "@/utils/Utils";
import {sendMessage} from "@/api/sdk/message";
import {toast} from "@/components/toast";

export function isSelf(chatUserId) {
    return TencentImUtils.getChatUserId(store.state.user.loginUserInfo.userId) === chatUserId;
}

const tencentChat = {
    m_getMessageType(message) {
        if (message.type === TencentCloudChat.TYPES.MSG_CUSTOM) {
            let cusDic = {};
            try {
                cusDic = JSON.parse(message.cloudCustomData);
            } catch (e) {
                console.error('JSON 解析失败', e)
            }

            // 判断是否存在 customType
            let typeValue = undefined
            if (cusDic.customType !== undefined) {
                typeValue = cusDic.customType;
            }

            if (typeValue === custom_type_gift) {
                return "CustomElemGift";
            }
        }

        return message.type;
    },

    /// 创建文本消息
    m_createTextMessage(toUserId, textContent) {
        const clientLocalId = getUUID().substring(0, 8);
        var parm = {};
        parm["clientLocalId"] = clientLocalId;
        const message = chat.chatObj.createTextMessage({
            to: String(toUserId),
            conversationType: TencentCloudChat.TYPES.CONV_C2C,
            payload: {
                text: textContent,
                data: `{"text": "${textContent}", "clientLocalId": "${clientLocalId}"}`
            },
            needReadReceipt: true,
            cloudCustomData: JSON.stringify(parm)
        });
        console.log('创建的 message:', message);
        return message;
    },

    // 创建礼物消息
    m_createGiftMessage: (toUserId, gift) => {
        const clientLocalId = getUUID().substring(0, 8);
        gift["customType"] = custom_type_gift;
        gift["clientLocalId"] = clientLocalId;
        gift["giftId"] = gift.id;
        const message = chat.chatObj.createCustomMessage({
            to: String(toUserId),
            conversationType: TencentCloudChat.TYPES.CONV_C2C,
            payload: {
                data: JSON.stringify(gift),
                description: 'gift',
            },
            needReadReceipt: true,
            cloudCustomData: JSON.stringify(gift)
        });
        console.log('创建的 message:', message);
        return message;
    },

    m_sendTextMessage(toUserId, text, sucCallback, failCallback) {
        const targetId = (toUserId !== undefined && toUserId !== null)
            ? String(toUserId)
            : '';
        if (!targetId) {
            return
        }

        const newString = (text !== undefined && text !== null) ? String(text) : '';
        let message = this.m_createTextMessage(targetId, newString);
        if (message) {
            this.m_sendMessage(targetId, message, null, sucCallback, failCallback);
        }
    },

    m_sendGiftMessage(toUserId, gift, sucCallback, failCallback) {
        const message = this.m_createGiftMessage(toUserId, gift)
        if (message) {
            this.m_sendMessage(toUserId, message, null, sucCallback, failCallback)
        }
    },

    // 发送消息总方法
    m_sendMessage(toUserId, msg, extraMap, sucCallback, failCallback) {
        const parm = {};
        const subData = {};
        subData["toUserId"] = toUserId;
        console.log("创建的 message:", msg.cloudCustomData);
        if (msg.cloudCustomData) {
            let cloudDic;
            if (typeof msg.cloudCustomData === 'string') {
                cloudDic = JSON.parse(msg.cloudCustomData);
            } else {
                cloudDic = msg.cloudCustomData;
            }
            subData["cloudCustomData"] = cloudDic;
            Object.assign(subData, cloudDic);
        }

        if (extraMap) {
            Object.assign(subData, extraMap);
        }

        if (msg.payload && msg.payload.data && JSON.parse(msg.payload.data)) {
            console.log("msg.payload.data:", msg.payload.data);
            Object.assign(subData, JSON.parse(msg.payload.data))
        }
        if (msg.payload && msg.payload.text) {
            subData["text"] = msg.payload.text;
        }
        parm["msgType"] = this.m_getMessageType(msg);
        parm["data"] = subData;
        sendMessage(parm).then(function ({code, data, msg: toastMsg}) {
            console.log('消息发送成功', data);
            if (code === 200) {
                if (data && typeof sucCallback === 'function') {
                    sucCallback(data);
                }
                // if (msg.payload.description === "gift") {
                //
                // }

            } else {
                // if (code === 20008) {
                //
                // } else {
                toastMsg && toast(toastMsg);
                // }
                if (typeof failCallback === 'function') {
                    failCallback(code);
                }
            }
        }).catch((error) => {
            // 消息发送失败的统一处理
            if (error.message) {
                toast(error.message);
            }
            if (typeof failCallback === 'function') {
                failCallback(error.code);
            }
        })
    }
}

export default tencentChat