import clientNative from "@/utils/ClientNative";
import {hideLoading, showLoading} from "@/components/MLoading";
import {toast, toastWarning} from "@/components/toast";
import {createOrder, createOrderApi, iosOrderVerifyApi, payWithCashier} from "@/api/sdk/commodity";
import {tdTrack} from "@/utils/TdTrack";
import {getCurrentUsrPackageName} from "@/utils/Utils";

let isPaying = false

/**
 *
 * @param productCode 商品码
 * @param type apple paypal
 * @param rechargeId 充值id
 */
export function requestPay(productCode, type = "apple", rechargeId = null) {
    // 参数校验（在设置 isPaying 之前）
    if (isPaying) {
        return Promise.reject(new Error("Payment ... ！"));
    }

    if (type !== 'apple' && type !== 'paypal') {
        return Promise.reject(new Error(`Parameter error : ${type} ！`));
    }

    // 设置支付状态并显示加载
    isPaying = true;
    showLoading();

    // 创建统一的清理函数
    const cleanup = () => {
        isPaying = false;
    };

    // PayPal 支付逻辑
    if (type === 'paypal') {
        if (!rechargeId) {
            cleanup();
            return Promise.reject(new Error("RechargeId is required for PayPal payment"));
        }

        return payWithCashier(rechargeId)
            .then((response) => {
                const res = response.data;
                // 统一在内部处理 PayPal 支付，直接调用 openWebView
                if (res && res.pay_url) {
                    clientNative.openWebView(res.pay_url, true);
                } else {
                    toast("Payment URL not found");
                }
                return res;
            }).finally(cleanup);
    }

    // Apple 支付逻辑
    if (type === 'apple') {
        const packageName = getCurrentUsrPackageName();
        let paymentPromise;
        if (packageName === 'A0011' || packageName === 'A0019') {
            // 老包充值
            paymentPromise = clientNative.openPayment({code: productCode})
                .then((data) => {
                    const code = data.code;
                    if (code === 0) {
                        console.error("验单成功", data);
                    } else {
                        console.error("验单错误", data);
                    }
                    return data;
                })
                .catch((err) => {
                    console.error(err)
                    toast('Sorry,there was a problem');
                    throw err;
                });
        } else {
            // 1、新包充值走下单
            paymentPromise = createOrderApi(rechargeId)
                .then((orderData) => {
                    const {uuid} = orderData.data;
                    return clientNative.openPayment({code: productCode, uuid: uuid});
                })
                .then((payData) => {
                    const {uuid, transactionId, code} = payData;
                    if (code === 0) {
                        // 2、请求后台验单
                        return iosOrderVerifyApi(uuid, transactionId);
                    } else {
                        throw new Error("Payment error :" + code)
                    }
                })
                .then((verifyData) => {
                    // 3、统一返回格式：iosOrderVerifyApi 返回 code === 200 表示成功，转换为 code === 0
                    if (verifyData && verifyData.success) {
                        return {code: 0, data: verifyData.data || verifyData};
                    } else {
                        throw new Error("Order verify failed :" + (verifyData?.code || 'unknown'));
                    }
                })
                .catch((err) => {
                    console.error(err)
                    toast('Sorry,there was a problem');
                    throw err;
                });
        }

        return paymentPromise.finally(cleanup);
    }
}
