import axios from 'axios'
import cache from '@/utils/cache'
import {aesDecrypt, aesEncrypt, getUUID, md5Sign, tansParams} from "@/utils/Utils";
import {httpCodeMsg, key_cache} from "@/utils/Constant";
import {toastWarning} from "@/components/toast";
import {showRechargeDialog} from "@/components/dialog";
import CryptoJS from "crypto-js";
import {showCallToast} from "@/components/toast/callToast";
import clientNative from "@/utils/ClientNative";


// 获取包名和版本（Base64编码的 "包名;版本"）
function getAppInfo() {
  const packageName = process.env.VUE_APP_TITLE || 'Live  chat';
  const version = process.env.VUE_APP_VERSION || '1.0.0';
  const appInfo = `${packageName};${version}`;
  // 使用 CryptoJS 进行 Base64 编码
  return CryptoJS.enc.Utf8.parse(appInfo).toString(CryptoJS.enc.Base64);
}

// 创建axios实例
axios.defaults.headers['Content-Type'] = 'application/json;charset=utf-8'
const service = axios.create({
  // axios中请求配置有baseURL选项，表示请求URL公共部分
  baseURL: process.env.VUE_APP_BASE_API + "/",
  // 超时 5分钟
  timeout: 1000 * 60 * 5
})

// request 拦截器
service.interceptors.request.use(config => {
  // 是否需要防止数据重复提交
  const isRepeatSubmit = (config.headers || {}).repeatSubmit === false,
    rawData = typeof config.data === 'object' ? JSON.stringify(config.data) : config.data || '{}',
    formData = aesEncrypt(rawData);
  // get请求映射params参数
  if (config.method === 'get' && config.params) {
    let url = config.url + '?' + tansParams(config.params);
    url = url.slice(0, -1);
    config.params = {};
    config.url = url;
  }

  const params = cache.local.getJSON(key_cache.launch_h5_data, {});

  // 安全地合并 headers，避免修改只读属性
  if (params && params.headers && typeof params.headers === 'object') {
    // 确保 config.headers 存在
    if (!config.headers) {
      config.headers = {};
    }
    // 使用 Object.assign 安全地合并 headers
    Object.assign(config.headers, params.headers);
  }


  // web-sign: MD5(data + requestId) 的大写
  // const dataStr = params && params.headers ? params.headers["Web-DeviceId"] : '';
  const dataStr = rawData || '';
  const requestId = getUUID().replace(/-/g, '');
  // 确保 config.headers 存在
  if (!config.headers) {
    config.headers = {};
  }
  // 即使 dataStr 为空，也需要生成 Web-Sign（使用空字符串 + requestId）
  const signString = dataStr + requestId;
  config.headers['X-Signature'] = md5Sign(signString).toUpperCase();
  config.headers['X-Request-ID'] = requestId;
  config.headers['X-Request-Timestamp'] = Math.floor(Date.now());
  config.headers['X-From-Web'] = process.env.PACKAGE_VERSION;

  // 格式化请求日志
  const requestTime = new Date().toLocaleTimeString();
  console.log(
    `%c[REQUEST]%c ${config.method.toUpperCase()} ${config.url}`,
    'color: #fff; background: #2196F3; padding: 2px 6px; border-radius: 3px 0 0 3px; font-weight: bold;',
    'color: #2196F3; font-weight: bold;'
  );
  console.groupCollapsed('  └─ Details');
  console.log(`%c⏰ 时间:`, 'color: #666; font-weight: bold;', requestTime);
  console.log(`%c🔗 URL:`, 'color: #666; font-weight: bold;', config.baseURL + config.url);
  console.log(`%c📋 Headers:`, 'color: #666; font-weight: bold;');
  console.table(config.headers);
  console.log(`%c📦 Request Data (原始):`, 'color: #666; font-weight: bold;', rawData);
  console.log(`%c🔐 Request Data (加密):`, 'color: #666; font-weight: bold;', formData);
  console.log(`%c🆔 Request ID:`, 'color: #666; font-weight: bold;', requestId);
  console.groupEnd();

  // 将加密后的数据赋值给config.data
  config.data = formData;

  if (!isRepeatSubmit && (config.method === 'post' || config.method === 'put')) {
    const requestObj = {
      url: config.url,
      data: formData
    };

    const sessionObj = cache.session.getJSON('sessionObj');
    if (sessionObj === undefined || sessionObj === null || sessionObj === '') {
      cache.session.setJSON('sessionObj', requestObj)
    } else {
      // 请求地址
      const s_url = sessionObj.url;
      // 请求数据
      const s_data = sessionObj.data;
      // 请求时间
      const s_time = sessionObj.time;
      // 间隔时间(ms)，小于此时间视为重复提交
      const interval = 1000;
      if (s_url === requestObj.url && s_data === requestObj.data && requestObj.time - s_time < interval) {
        const message = ' please waiting !';
        console.warn(`[${s_url}]: ` + message);
        return Promise.reject(new Error(message));
      } else {
        cache.session.setJSON('sessionObj', requestObj);
      }
    }
  }
  return config
}, error => {
  return Promise.reject(error)
});

// 响应拦截器
service.interceptors.response.use(res => {
  // 是否显示错误提示（默认显示）
  const showToast = res.config.showToast !== false;
  // 未设置状态码则默认成功状态
  let decryptedData;
  // 防止 res.data 为空字符串，如果为空字符串则直接使用原始数据
  if (res.data === '' || res.data === null || res.data === undefined) {
    decryptedData = res.data || {};
  } else {
    decryptedData = aesDecrypt(res.data);
    // 如果解密后的数据是字符串，尝试解析为 JSON
    if (typeof decryptedData === 'string') {
      try {
        decryptedData = JSON.parse(decryptedData);
      } catch (e) {
        console.error('Failed to parse decrypted data as JSON:', e);
      }
    }
  }
  res.data = decryptedData;
  const code = parseInt(res.data.code) || 0;
  res.data.code = code;
  res.data.success = code === 200;

  // 格式化响应日志
  const responseTime = new Date().toLocaleTimeString();
  const statusColor = code === 200 ? '#4CAF50' : '#F44336';
  const statusIcon = code === 200 ? '✅' : '❌';
  const bgColor = code === 200 ? '#4CAF50' : '#F44336';
  console.log(
    `%c[RESPONSE]%c ${statusIcon} ${res.config.method.toUpperCase()} ${res.config.url}`,
    `color: #fff; background: ${bgColor}; padding: 2px 6px; border-radius: 3px 0 0 3px; font-weight: bold;`,
    `color: ${statusColor}; font-weight: bold;`
  );
  console.groupCollapsed('  └─ Details');
  console.log(`%c⏰ 时间:`, 'color: #666; font-weight: bold;', responseTime);
  console.log(`%c📊 状态码: %c${code}`, 'color: #666; font-weight: bold;', `color: ${statusColor}; font-weight: bold;`);
  console.log(`%c📋 响应数据:`, 'color: #666; font-weight: bold;');
  console.log(res.data);
  if (res.data.msg) {
    console.log(`%c💬 消息:`, 'color: #666; font-weight: bold;', res.data.msg);
  }
  console.groupEnd();
  // 获取错误信息
  const msg = httpCodeMsg[code] || res.data.msg || httpCodeMsg['default']
  // 二进制数据则直接返回
  if (res.request.responseType === 'blob' || res.request.responseType === 'arraybuffer') {
    return res.data
  }
  if (code === 10003 || code === 1005) {
    if (showToast) showCallToast(msg)
    showRechargeDialog({
        onSuccess:(data) => {

        }
    });
  } else if (code === 401 || code === 403) {
      if (showToast) showCallToast(msg)
      clientNative.toLogin()
  }

  if (code !== 200) {
    if (showToast) showCallToast(msg)
    return Promise.reject(res.data);
  } else {
    return res.data;
  }
}, (error) => {
  let {message} = error;
  if (message === "Network Error") {
    message = "Network Error";
  } else if (message.includes("timeout")) {
    message = "Error api timeout";
  }

  // 格式化错误日志
  const errorTime = new Date().toLocaleTimeString();
  const url = error.config ? error.config.url : 'Unknown';
  const method = error.config ? error.config.method.toUpperCase() : 'UNKNOWN';
  console.group(`%c❌ ${method} ${url}`, 'color: #F44336; font-weight: bold; font-size: 12px;');
  console.log(`%c⏰ 时间:`, 'color: #666; font-weight: bold;', errorTime);
  console.log(`%c❌ 错误信息:`, 'color: #F44336; font-weight: bold;', message);
  if (error.response) {
    console.log(`%c📊 状态码:`, 'color: #666; font-weight: bold;', error.response.status);
    console.log(`%c📋 响应数据:`, 'color: #666; font-weight: bold;', error.response.data);
  } else if (error.request) {
    console.log(`%c⚠️ 请求已发出但无响应:`, 'color: #FF9800; font-weight: bold;', error.request);
  } else {
    console.log(`%c⚠️ 错误详情:`, 'color: #FF9800; font-weight: bold;', error);
  }
  console.groupEnd();

  toastWarning(message)
  return Promise.reject(error)
})
export default service
