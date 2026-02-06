import request from "@/utils/Request";
import {getDeviceLanguage} from "@/utils/Utils";


export function sendMessage(data) {
    return request({
        url: 'message/send',
        method: 'post',
        data: data,
    })
}

export function getBatchList(userIds) {
    return request({
        url: 'userStatus/getBatchList',
        method: 'post',
        data: userIds,
    })
}

export function translationMsg(message) {
    const fromUserId = message.from;
    const toUserId = message.to;
    const content = message.payload.text;
    const target = getDeviceLanguage();
    const seq = message.sequence || 0;
    const random = message.random || 0;
    const interval = message.time;
    const msgKey = `${seq}_${random}_${interval}`;
    const data = {fromUserId, toUserId, content, target, msgKey};
    
    return request({
        url: 'message/translationMsg',
        method: 'post',
        data: data,
    })
}