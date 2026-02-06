import {router} from "@/router";
import {toastWarning} from "@/components/toast";
import {getUserInfo} from "@/api";
import {TencentImUtils} from "@/utils/TencentImUtils";
import {callApply} from "@/api/sdk/call";
import {callCreate} from "@/utils/CallUtils";
import store from "@/store";
import {showUserPremiumDialog} from "@/components/dialog";

export function openWebView(title, url) {
  router.push({name: 'PageWebView', query: {title, url}}).then()
}

export function openPicturePreview(urls, index) {
  router.push({name: 'PicturePreview', query: {urls: JSON.stringify(urls), index}}).then()
}

export function openUserInfo(userId) {
  router.push({name: 'PageUserInformation', query: {userId: userId}}).then()
}

export function requestCall(userIdOrImUserIdOrConversationId) {
  const userId = TencentImUtils.getUserIdByImId(userIdOrImUserIdOrConversationId);
  // callApply(userId).then(({data}) => {
  //   openCall(data.unactiveInfo, data.activeInfo)
  // })
  //   router.push({
  //       name: 'PageCalling'
  //   }).then(() => {
  //       console.log('✅ 跳转成功，已导航到用户详情页 (PageUserDetail)');
  //   }).catch((err) => {
  //       console.error('❌ 跳转失败:', err);
  //       console.error('错误详情:', err.message || err);
  //   });
    console.log(userIdOrImUserIdOrConversationId);

    callCreate(userIdOrImUserIdOrConversationId).then(res => {
        // 通话数据已自动存储到 store.state.call
        console.log('通话申请成功', res);
        // TODO: 可以在这里跳转到通话页面或显示通话界面
    }).catch(error => {
        console.error('通话申请失败:', error);
        // TODO: 可以在这里显示错误提示
    });
}

/**
 * 打开通话
 *
 * @param callInfo           主叫信息
 * @param invitationCallInfo  被叫 通话邀请信息
 */
export function openCall(callInfo, invitationCallInfo) {
  router.push({
      name: 'PageCall', params: {callInfo, invitationCallInfo}
    }
  ).then()
}

export function openChat(userId, isReplace = false) {
  userId = TencentImUtils.getUserIdByImId(userId);
  if (isReplace) {
      router.replace({name: 'PageChat', query: {userId: userId, nickname: '', headImage: ''}})
  }else {
      router.push({name: 'PageChat', query: {userId: userId, nickname: '', headImage: ''}})
  }

}

export function openPremium() {
    // 判断当前登录用户是否是 VIP
    const loginUserInfo = store.state.user.loginUserInfo || {};
    const isVip = loginUserInfo.vipCategory !== undefined && 
                  loginUserInfo.vipCategory !== null && 
                  loginUserInfo.vipCategory !== 0;
    
    // 如果已经是 VIP，弹出会员信息弹窗
    if (isVip) {
        showUserPremiumDialog();
        return;
    }
    
    router.push({name: 'PagePremium'})
}

/**
 * 打开主播用户详情页
 * @param {number|string} userId - 用户ID
 * @param {string|object} from - 来源页面标识（如 'chat' 表示从聊天页面进入）
 * @param {object} userData - 透传用户卡片数据（可选）
 */
export function openAnchorUserDetail(userId, from, userData) {
  console.log('=== openAnchorUserDetail: 准备跳转到用户详情页 ===');

  if (!userId) {
    console.error('用户ID为空，无法跳转');
    return;
  }

  try {
    const query = { userId: userId };
    let fromValue = from;
    let userDataValue = userData;
    if (from && typeof from === 'object' && !Array.isArray(from)) {
      userDataValue = from;
      fromValue = undefined;
    }
    if (fromValue) {
      query.from = fromValue;
    }
    if (userDataValue) {
      try {
        query.userData = JSON.stringify(userDataValue);
      } catch (error) {
        console.error('用户数据序列化失败，已跳过传参:', error);
      }
    }
    
    router.push({
      name: 'PageUserDetail',
      query: query
    }).then(() => {
      console.log('✅ 跳转成功，已导航到用户详情页 (PageUserDetail)');
    }).catch((err) => {
      console.error('❌ 跳转失败:', err);
      console.error('错误详情:', err.message || err);
    });
  } catch (error) {
    console.error('❌ 跳转时发生异常:', error);
    console.error('异常详情:', error.message || error);
  }
}

