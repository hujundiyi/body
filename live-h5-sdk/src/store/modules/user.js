import clientEach from "@/utils/ClientEach";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";
import {getUserInfo, getWebUserDetail, getUserBackpack} from "@/api";
import {getFirstRechargeList} from "@/api/sdk/commodity";
import {setTDSuperProperties} from "@/utils/TdTrack";

const user = {
    state: {
        loginUserInfo: cache.local.getJSON(key_cache.user_info) || {msgNum: 0},
        userBackpack: cache.local.getJSON(key_cache.user_backpack) || [],
        /** 是否视为已完成全部首充：超过注册 3 天或首充列表全部已购买；每次 FetchFirstRechargeList 成功后更新 */
        allPurchased: true,
        firstRechargeDiscount:'',
    },
    mutations: {
        SET_USERINFO: (state, loginUserInfo) => {
            state.loginUserInfo = loginUserInfo
        },
        SET_USER_BACKPACK: (state, userBackpack) => {
            state.userBackpack = userBackpack
        },
        SET_ALL_PURCHASED: (state, allPurchased) => {
            state.allPurchased = !!allPurchased
        },
        SET_FIRST_RECHARGE_DISCOUNT: (state, firstRechargeDiscount) => {
            state.firstRechargeDiscount = firstRechargeDiscount != null ? firstRechargeDiscount : ''
        },
    },

    actions: {
        // 获取用户信息
        GetInfo({commit}) {
            return new Promise((resolve, reject) => {
                getWebUserDetail().then(res => {
                    const user = res.data
                    cache.local.setJSON(key_cache.user_info, user)
                    commit('SET_USERINFO', user)
                    // 更新公共属性
                    setTDSuperProperties()
                    resolve(res)
                }).catch(error => {
                    reject(error)
                })
            })
        },
        // 获取用户背包，缓存到本地，并写入 store
        GetUserBackpack({commit}) {
            return getUserBackpack().then(res => {
                const list = (res && res.data) ? (Array.isArray(res.data) ? res.data : res.data?.list || []) : [];
                cache.local.setJSON(key_cache.user_backpack, list);
                commit('SET_USER_BACKPACK', list);
                return res;
            }).catch(error => {
                console.error('[GetUserBackpack] 获取用户背包失败:', error);
                throw error;
            });
        },
        /** 获取首充列表并更新全局 allPurchased；每次调用都会更新。
         * 视为已充值：超过用户创建时间 3 天，或首充列表全部 purchased 为 true。 */
        FetchFirstRechargeList({commit, state}, params = {}) {
            const {rechargeTypes = [0,2], ifSubscribe = 0} = params;
            return getFirstRechargeList(rechargeTypes, ifSubscribe).then((res) => {
                const list = (res && res.code === 200 && res.data)
                    ? (Array.isArray(res.data) ? res.data : [])
                    : [];
                const user = cache.local.getJSON(key_cache.user_info) || state.loginUserInfo || {};
                const createTime = user.createTime;
                const now = Math.floor(Date.now() / 1000);
                const threeDaysSec = 3 * 24 * 3600;
                const overThreeDays = createTime != null && createTime !== '' && (now - Number(createTime)) > threeDaysSec;
                const allPurchased = !!overThreeDays || (list.length > 0 && list.every((item) => !!item.purchased));
                commit('SET_ALL_PURCHASED', allPurchased);
                const lastUnpurchased = list.length > 0
                    ? (() => { for (let i = list.length - 1; i >= 0; i--) { if (!list[i].purchased) return list[i]; } return null; })()
                    : null;
                const intros = lastUnpurchased && lastUnpurchased.intros != null ? lastUnpurchased.intros : '';
                commit('SET_FIRST_RECHARGE_DISCOUNT', intros);
                return res;
            });
        },
    }
};

export default user
