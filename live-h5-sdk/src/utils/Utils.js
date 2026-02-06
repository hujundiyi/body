/**
 * 基础工具
 */
import CryptoJS from "crypto-js";
import {toast} from "@/components/toast";
import store from "@/store";
import cache from "@/utils/cache";
import {key_cache} from "@/utils/Constant";

// 日期格式化
export function parseTime(time, pattern) {
  if (arguments.length === 0 || !time) {
    return null
  }
  const format = pattern || '{y}-{m}-{d} {h}:{i}:{s}'
  let date
  if (typeof time === 'object') {
    date = time
  } else {
    if ((typeof time === 'string') && (/^[0-9]+$/.test(time))) {
      time = parseInt(time)
    } else if (typeof time === 'string') {
      time = time.replace(new RegExp(/-/gm), '/').replace('T', ' ').replace(new RegExp(/\.[\d]{3}/gm), '');
    }
    if ((typeof time === 'number') && (time.toString().length === 10)) {
      time = time * 1000
    }
    date = new Date(time)
  }
  const formatObj = {
    y: date.getFullYear(),
    m: date.getMonth() + 1,
    d: date.getDate(),
    h: date.getHours(),
    i: date.getMinutes(),
    s: date.getSeconds(),
    a: date.getDay()
  }
  const time_str = format.replace(/{(y|m|d|h|i|s|a)+}/g, (result, key) => {
    let value = formatObj[key]
    // Note: getDay() returns 0 on Sunday
    if (key === 'a') {
      return ['日', '一', '二', '三', '四', '五', '六'][value]
    }
    if (result.length > 0 && value < 10) {
      value = '0' + value
    }
    return value || 0
  })
  return time_str
}

export function msToTime(duration) {
  let seconds = parseInt((duration / 1000) % 60)
    , minutes = parseInt((duration / (1000 * 60)) % 60)
    , hours = parseInt((duration / (1000 * 60 * 60)));
  hours = (hours < 10) ? "0" + hours : hours;
  minutes = (minutes < 10) ? "0" + minutes : minutes;
  seconds = (seconds < 10) ? "0" + seconds : seconds;
  return hours + ":" + minutes + ":" + seconds;
}

export function getInviteContent(type, link) {
  let result = {
    // 用户对用户
    1: 'Sexy , Private, Tons of Super Hot Girls. Many girls are waiting at the app.   「${url}」  Beauty one on one video chat app, listen to your command in your phone！',
    // 主播对用户：
    2: 'Honey, I want you to cum on me, can you cum on me? Download this app and turn me on:   「${url}」  You can hear and see me cum with your iPhone！',
    // 主播对主播：
    3: "Ladies, Earn money in minutes - Join the best mobile platform for cam girls!    「${url}」  It's never been so easy to make MONEY from home,just with one phone!Have fun and earn money being sexy."
  }[type];
  return result.replace('${url}', link);
}

// 表单重置
export function resetForm(refName) {
  if (this.$refs[refName]) {
    this.$refs[refName].resetFields();
  }
}

// 添加日期范围
export function addDateRange(params, dateRange, propName) {
  let search = params;
  search.params = typeof (search.params) === 'object' && search.params !== null && !Array.isArray(search.params) ? search.params : {};
  dateRange = Array.isArray(dateRange) ? dateRange : [];
  if (typeof (propName) === 'undefined') {
    search.params['beginTime'] = dateRange[0];
    search.params['endTime'] = dateRange[1];
  } else {
    search.params['begin' + propName] = dateRange[0];
    search.params['end' + propName] = dateRange[1];
  }
  return search;
}

// 回显数据字典
export function selectDictLabel(datas, value) {
  if (value === undefined) {
    return "";
  }
  const actions = [];
  Object.keys(datas).some((key) => {
    if (datas[key].value == ('' + value)) {
      actions.push(datas[key].label);
      return true;
    }
  })
  if (actions.length === 0) {
    actions.push(value);
  }
  return actions.join('');
}

// 回显数据字典（字符串数组）
export function selectDictLabels(datas, value, separator) {
  if (value === undefined) {
    return "";
  }
  const actions = [];
  const currentSeparator = undefined === separator ? "," : separator;
  const temp = value.split(currentSeparator);
  Object.keys(value.split(currentSeparator)).some((val) => {
    let match = false;
    Object.keys(datas).some((key) => {
      if (datas[key].value == ('' + temp[val])) {
        actions.push(datas[key].label + currentSeparator);
        match = true;
      }
    })
    if (!match) {
      actions.push(temp[val] + currentSeparator);
    }
  })
  return actions.join('').substring(0, actions.join('').length - 1);
}

// 字符串格式化(%s )
export function sprintf(str) {
  let args = arguments, flag = true, i = 1;
  str = str.replace(/%s/g, function () {
    const arg = args[i++];
    if (typeof arg === 'undefined') {
      flag = false;
      return '';
    }
    return arg;
  });
  return flag ? str : '';
}

// 转换字符串，undefined,null等转化为""
export function parseStrEmpty(str) {
  if (!str || str == "undefined" || str == "null") {
    return "";
  }
  return str;
}

// 数据合并
export function mergeRecursive(source, target) {
  for (const p in target) {
    try {
      if (target[p].constructor == Object) {
        source[p] = mergeRecursive(source[p], target[p]);
      } else {
        source[p] = target[p];
      }
    } catch (e) {
      source[p] = target[p];
    }
  }
  return source;
}

/**
 * 构造树型结构数据
 * @param {*} data 数据源
 * @param {*} id id字段 默认 'id'
 * @param {*} parentId 父节点字段 默认 'parentId'
 * @param {*} children 孩子节点字段 默认 'children'
 */
export function handleTree(data, id, parentId, children) {
  let config = {
    id: id || 'id',
    parentId: parentId || 'parentId',
    childrenList: children || 'children'
  };

  const childrenListMap = {};
  const nodeIds = {};
  const tree = [];

  for (let d of data) {
    let parentId = d[config.parentId];
    if (childrenListMap[parentId] == null) {
      childrenListMap[parentId] = [];
    }
    nodeIds[d[config.id]] = d;
    childrenListMap[parentId].push(d);
  }

  for (let d of data) {
    let parentId = d[config.parentId];
    if (nodeIds[parentId] == null) {
      tree.push(d);
    }
  }

  for (let t of tree) {
    adaptToChildrenList(t);
  }

  function adaptToChildrenList(o) {
    if (childrenListMap[o[config.id]] !== null) {
      o[config.childrenList] = childrenListMap[o[config.id]];
    }
    if (o[config.childrenList]) {
      for (let c of o[config.childrenList]) {
        adaptToChildrenList(c);
      }
    }
  }

  return tree;
}

/**
 * 参数处理
 * @param {*} params  参数
 */
export function tansParams(params) {
  let result = ''
  for (const propName of Object.keys(params)) {
    const value = params[propName];
    const part = encodeURIComponent(propName) + "=";
    if (value !== null && value !== "" && typeof (value) !== "undefined") {
      if (typeof value === 'object') {
        for (const key of Object.keys(value)) {
          if (value[key] !== null && value[key] !== "" && typeof (value[key]) !== 'undefined') {
            let params = propName + '[' + key + ']';
            const subPart = encodeURIComponent(params) + "=";
            result += subPart + encodeURIComponent(value[key]) + "&";
          }
        }
      } else {
        result += part + encodeURIComponent(value) + "&";
      }
    }
  }
  return result
}

// 验证是否为blob格式
export async function blobValidate(data) {
  try {
    const text = await data.text();
    JSON.parse(text);
    return false;
  } catch (error) {
    return true;
  }
}

/**
 * 获取当前用户包名
 * @returns {*}
 */
export function getCurrentUsrPackageName() {
    const params = cache.local.getJSON(key_cache.launch_h5_data, {});
    const {headers} = params;
    const xAppInfo = headers ? headers['X-App-Info'] : null;
    let packageName = '';
    if (xAppInfo) {
        const info = decodeBase64(xAppInfo);
        // 解密后的格式是 "包名;版本号"，用分号分割
        const parts = info.split(';');
        packageName = parts[0] || ''; // 第一个是包名
        const version = parts[1] || '';     // 第二个是版本号
        return packageName;
    }
    return packageName;
}

export function getUUID() {
  const s = [];
  const hexDigits = "0123456789abcdef";
  for (let i = 0; i < 36; i++) {
    s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
  }
  // bits 12-15 of the time_hi_and_version field to 0010
  s[14] = "4";
  // bits 6-7 of the clock_seq_hi_and_reserved to 01
  s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1);
  s[8] = s[13] = s[18] = s[23] = "-";
  return s.join("");
}

/**
 * aes 加密
 * @param word 是待加密或者解密的字符串；
 * @returns {*}
 */
export function aesEncrypt(word) {
  // 是aes加密需要用到的16位字符串的key
  const key = CryptoJS.enc.Latin1.parse('CZ8o1bAxqYVyV3ORrmjYYcVf1ux7S2ak');
  // 初始化向量 iv。
  const iv = CryptoJS.enc.Latin1.parse('VNFl53924LgUMrbj');
  return CryptoJS.AES.encrypt(word, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC
  }).toString();
}

/**
 * aes 解密
 * @param word 是待解密的字符串；
 * @returns {*}
 */
export function aesDecrypt(word) {
  // 是aes解密需要用到的16位字符串的key
  const key = CryptoJS.enc.Latin1.parse('CZ8o1bAxqYVyV3ORrmjYYcVf1ux7S2ak');
  // 初始化向量 iv。
  const iv = CryptoJS.enc.Latin1.parse('VNFl53924LgUMrbj');

  const decrypted = CryptoJS.AES.decrypt(word, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC
  });
  return decrypted.toString(CryptoJS.enc.Utf8);
}

/**
 * md5 签名
 * @param word 是待加密或者解密的字符串；
 * @returns {*}
 */
export function md5Sign(word) {
  return CryptoJS.MD5(word).toString().toUpperCase();
}

export function copy(value) {
  // 创建input对象
  const input = document.createElement("input");
  // 设置复制内容
  input.value = value;
  // 添加临时实例
  document.body.appendChild(input);
  // 选择实例内容
  input.select();
  document.execCommand("Copy");
  document.body.removeChild(input);
  toast('Copy success .');
}

export function formatTimeAgoEnglish(timestamp) {
  const now = new Date();
  const pastDate = new Date(timestamp);
  const diff = now - pastDate; // 毫秒差

  // 辅助函数：判断两个日期是否是同一天
  const isSameDay = (date1, date2) => {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
  };

  // 辅助函数：判断是否是昨天
  const isYesterday = (date) => {
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    return isSameDay(date, yesterday);
  };

  // 辅助函数：格式化12小时制时间（带AM/PM）
  const format12Hour = (date) => {
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    const displayMinutes = minutes < 10 ? '0' + minutes : minutes;
    return `${displayHours}:${displayMinutes} ${ampm}`;
  };

  // 辅助函数：获取星期几的缩写
  const getWeekdayShort = (date) => {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[date.getDay()];
  };

  // 1. ≤ 5分钟内：显示 "Just now"
  const fiveMinutes = 5 * 60 * 1000;
  if (diff <= fiveMinutes) {
    return 'Just now';
  }

  // 2. 5分钟 ~ 1小时内：显示 "X min ago"
  const oneHour = 60 * 60 * 1000;
  if (diff < oneHour) {
    const minutes = Math.floor(diff / (60 * 1000));
    return `${minutes} min ago`;
  }

  // 3. 1小时 ~ 今天结束：显示 "hh:mm AM/PM"
  if (isSameDay(pastDate, now)) {
    return format12Hour(pastDate);
  }

  // 4. 昨天：显示 "Yesterday hh:mm AM/PM"
  if (isYesterday(pastDate)) {
    return `Yesterday ${format12Hour(pastDate)}`;
  }

  // 5. 7天内（不包括今天和昨天）：显示 "EEE hh:mm AM/PM"
  const sevenDays = 7 * 24 * 60 * 60 * 1000;
  if (diff < sevenDays) {
    const weekday = getWeekdayShort(pastDate);
    return `${weekday} ${format12Hour(pastDate)}`;
  }

  // 6. 超过7天但在今年内：显示 "MMM D"
  const currentYear = now.getFullYear();
  if (pastDate.getFullYear() === currentYear) {
    return pastDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  // 7. 不是今年：显示 "MMM D, YYYY"
  return pastDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export function formatTimestamp(sec) {
    const date = new Date(sec * 1000);

    const pad = (n) => String(n).padStart(2, '0');

    return (
        date.getFullYear() + '-' +
        pad(date.getMonth() + 1) + '-' +
        pad(date.getDate()) + ' ' +
        pad(date.getHours()) + ':' +
        pad(date.getMinutes()) + ':' +
        pad(date.getSeconds())
    );
}


export function parseUrlParams() {
    const params = {};
    // 尝试从 search 部分获取参数
    const searchParams = parseSearchParams();
    Object.assign(params, searchParams);

    // 尝试从 hash 部分获取参数
    const hashParams = parseHashParams();
    Object.assign(params, hashParams);

    return params;
}

// 解析 search 部分的参数
function parseSearchParams() {
    const params = {};
    const queryString = window.location.search.slice(1);

    if (!queryString) return params;

    parseQueryString(queryString, params);
    return params;
}

// 解析 hash 部分的参数
function parseHashParams() {
    const params = {};
    const hash = window.location.hash;

    if (!hash) return params;

    // 处理不同格式的 hash
    let queryString = '';

    if (hash.includes('?')) {
        // 格式: #/path?key=value
        const hashParts = hash.split('?');
        queryString = hashParts[1] || '';
    } else if (hash.includes('=')) {
        // 格式: #key=value
        queryString = hash.slice(1); // 去掉开头的 #
    }

    if (queryString) {
        parseQueryString(queryString, params);
    }

    return params;
}

// 通用的查询字符串解析
function parseQueryString(queryString, params) {
    const pairs = queryString.split('&');

    pairs.forEach(pair => {
        const [key, value] = pair.split('=');
        if (key) {
            const decodedKey = decodeURIComponent(key);
            const decodedValue = value ? decodeURIComponent(value) : '';
            params[decodedKey] = isNaN(Number(decodedValue)) || decodedValue === ''
                ? decodedValue
                : Number(decodedValue);
        }
    });
}

/**
 * 对Base64字符串进行解码
 * @param {string} base64Str - 需要解码的Base64字符串
 * @returns {string} 解码后的字符串
 */
export function decodeBase64(base64Str) {
    if (!base64Str) {
        return '';
    }
    try {
        // 1. 清理字符串：去除空白字符和换行
        let cleanStr = base64Str.replace(/\s/g, '');

        // 2. 处理 URL-safe Base64：将 - 替换为 +，将 _ 替换为 /
        cleanStr = cleanStr.replace(/-/g, '+').replace(/_/g, '/');

        // 3. 修复 padding：Base64 字符串长度必须是 4 的倍数
        const pad = cleanStr.length % 4;
        if (pad) {
            cleanStr += '='.repeat(4 - pad);
        }

        // 浏览器环境下使用atob解码，同时处理Unicode字符
        const decoded = atob(cleanStr);
        // 对于纯 ASCII 字符串（如 JSON），直接返回
        // 对于包含 Unicode 的字符串，需要转换为 URI 编码再解码
        try {
            return decodeURIComponent(
                decoded
                    .split('')
                    .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
                    .join('')
            );
        } catch (e) {
            // 如果 decodeURIComponent 失败，说明可能是纯 ASCII，直接返回
            return decoded;
        }
    } catch (error) {
        console.error('Base64 解码失败:', error, '原始字符串:', base64Str);
        // 如果解码失败，返回原始字符串而不是抛出错误
        return base64Str;
    }
}

/**
 * base64编码
 * @param str
 * @returns {string}
 */
export function encodeBase64(str) {
    // 先将字符串转换为UTF-8字节序列
    const utf8Bytes = unescape(encodeURIComponent(str));
    // 使用btoa进行Base64编码
    return btoa(utf8Bytes);
}

/**
 * 国家数字到国家代码的映射表
 * 基于 ISO 3166-1 alpha-2 标准
 */
export const COUNTRY_CODE_MAP = {
  1: 'US',   // 美国 United States
  2: 'IN',   // 印度 India
  3: 'BR',   // 巴西 Brazil
  4: 'CA',   // 加拿大 Canada
  5: 'GB',   // 英国 United Kingdom
  6: 'CN',   // 中国 China
  7: 'MX',   // 墨西哥 Mexico
  8: 'FR',   // 法国 France
  9: 'DE',   // 德国 Germany
  10: 'JP',  // 日本 Japan
  11: 'KR',  // 韩国 South Korea
  12: 'AU',  // 澳大利亚 Australia
  13: 'ES',  // 西班牙 Spain
  14: 'IT',  // 意大利 Italy
  15: 'RU',  // 俄罗斯 Russia
  16: 'NL',  // 荷兰 Netherlands
  17: 'BE',  // 比利时 Belgium
  18: 'CH',  // 瑞士 Switzerland
  19: 'AT',  // 奥地利 Austria
  20: 'SE',  // 瑞典 Sweden
  21: 'NO',  // 挪威 Norway
  22: 'DK',  // 丹麦 Denmark
  23: 'FI',  // 芬兰 Finland
  24: 'PL',  // 波兰 Poland
  25: 'PT',  // 葡萄牙 Portugal
  26: 'GR',  // 希腊 Greece
  27: 'IE',  // 爱尔兰 Ireland
  28: 'NZ',  // 新西兰 New Zealand
  29: 'ZA',  // 南非 South Africa
  30: 'AR',  // 阿根廷 Argentina
  31: 'CL',  // 智利 Chile
  32: 'CO',  // 哥伦比亚 Colombia
  33: 'PE',  // 秘鲁 Peru
  34: 'VE',  // 委内瑞拉 Venezuela
  35: 'PH',  // 菲律宾 Philippines
  36: 'TH',  // 泰国 Thailand
  37: 'VN',  // 越南 Vietnam
  38: 'ID',  // 印度尼西亚 Indonesia
  39: 'MY',  // 马来西亚 Malaysia
  40: 'SG',  // 新加坡 Singapore
  41: 'AE',  // 阿联酋 United Arab Emirates
  42: 'SA',  // 沙特阿拉伯 Saudi Arabia
  43: 'IL',  // 以色列 Israel
  44: 'TR',  // 土耳其 Turkey
  45: 'EG',  // 埃及 Egypt
  46: 'NG',  // 尼日利亚 Nigeria
  47: 'KE',  // 肯尼亚 Kenya
  48: 'UA',  // 乌克兰 Ukraine
  49: 'RO',  // 罗马尼亚 Romania
  50: 'CZ',  // 捷克 Czech Republic
  51: 'HU',  // 匈牙利 Hungary
  52: 'BG',  // 保加利亚 Bulgaria
  53: 'HR',  // 克罗地亚 Croatia
  54: 'RS',  // 塞尔维亚 Serbia
  55: 'SK',  // 斯洛伐克 Slovakia
  56: 'SI',  // 斯洛文尼亚 Slovenia
  57: 'LT',  // 立陶宛 Lithuania
  58: 'LV',  // 拉脱维亚 Latvia
  59: 'EE',  // 爱沙尼亚 Estonia
  60: 'BY',  // 白俄罗斯 Belarus
  61: 'KZ',  // 哈萨克斯坦 Kazakhstan
  62: 'PK',  // 巴基斯坦 Pakistan
  63: 'BD',  // 孟加拉国 Bangladesh
  64: 'LK',  // 斯里兰卡 Sri Lanka
  65: 'MM',  // 缅甸 Myanmar
  66: 'KH',  // 柬埔寨 Cambodia
  67: 'LA',  // 老挝 Laos
  68: 'MN',  // 蒙古 Mongolia
  69: 'NP',  // 尼泊尔 Nepal
  70: 'AF',  // 阿富汗 Afghanistan
  71: 'IQ',  // 伊拉克 Iraq
  72: 'IR',  // 伊朗 Iran
  73: 'JO',  // 约旦 Jordan
  74: 'LB',  // 黎巴嫩 Lebanon
  75: 'SY',  // 叙利亚 Syria
  76: 'YE',  // 也门 Yemen
  77: 'OM',  // 阿曼 Oman
  78: 'KW',  // 科威特 Kuwait
  79: 'QA',  // 卡塔尔 Qatar
  80: 'BH',  // 巴林 Bahrain
  81: 'MA',  // 摩洛哥 Morocco
  82: 'DZ',  // 阿尔及利亚 Algeria
  83: 'TN',  // 突尼斯 Tunisia
  84: 'LY',  // 利比亚 Libya
  85: 'SD',  // 苏丹 Sudan
  86: 'ET',  // 埃塞俄比亚 Ethiopia
  87: 'GH',  // 加纳 Ghana
  88: 'TZ',  // 坦桑尼亚 Tanzania
  89: 'UG',  // 乌干达 Uganda
  90: 'ZM',  // 赞比亚 Zambia
  91: 'ZW',  // 津巴布韦 Zimbabwe
  92: 'AO',  // 安哥拉 Angola
  93: 'MZ',  // 莫桑比克 Mozambique
  94: 'MG',  // 马达加斯加 Madagascar
  95: 'CM',  // 喀麦隆 Cameroon
  96: 'CI',  // 科特迪瓦 Côte d'Ivoire
  97: 'SN',  // 塞内加尔 Senegal
  98: 'ML',  // 马里 Mali
  99: 'BF',  // 布基纳法索 Burkina Faso
  100: 'NE', // 尼日尔 Niger
  // 可以根据实际需要继续添加更多映射
};

/**
 * 根据国家数字或国家代码获取国家代码
 * @param {number|string} country - 国家数字或国家代码
 * @returns {string|null} 国家代码 (ISO 3166-1 alpha-2)，如果未找到则返回 null
 */
export function getCountryCode(country) {
  if (!country) {
    return null;
  }

  // 如果已经是国家代码字符串（2个字母），直接返回
  if (typeof country === 'string' && /^[A-Z]{2}$/i.test(country)) {
    return country.toUpperCase();
  }

  // 如果是数字，从映射表中查找
  if (typeof country === 'number') {
    return COUNTRY_CODE_MAP[country] || null;
  }

  return null;
}


/**
 * 国家名称到国家代码的完整映射表
 * 基于 ISO 3166-1 alpha-2 标准，支持多种名称变体，不区分大小写
 */
const COUNTRY_NAME_TO_CODE_MAP = {
  // A
  'afghanistan': 'AF',
  'albania': 'AL',
  'algeria': 'DZ',
  'american samoa': 'AS',
  'andorra': 'AD',
  'angola': 'AO',
  'anguilla': 'AI',
  'antarctica': 'AQ',
  'antigua and barbuda': 'AG',
  'argentina': 'AR',
  'armenia': 'AM',
  'aruba': 'AW',
  'australia': 'AU',
  'austria': 'AT',
  'azerbaijan': 'AZ',
  // B
  'bahamas': 'BS',
  'bahrain': 'BH',
  'bangladesh': 'BD',
  'barbados': 'BB',
  'belarus': 'BY',
  'belgium': 'BE',
  'belize': 'BZ',
  'benin': 'BJ',
  'bermuda': 'BM',
  'bhutan': 'BT',
  'bolivia': 'BO',
  'bolivia, plurinational state of': 'BO',
  'bosnia and herzegovina': 'BA',
  'botswana': 'BW',
  'bouvet island': 'BV',
  'brazil': 'BR',
  'british indian ocean territory': 'IO',
  'brunei': 'BN',
  'brunei darussalam': 'BN',
  'bulgaria': 'BG',
  'burkina faso': 'BF',
  'burundi': 'BI',
  'burma': 'MM', // 缅甸的旧称
  // C
  'cabo verde': 'CV',
  'cape verde': 'CV',
  'cambodia': 'KH',
  'cameroon': 'CM',
  'canada': 'CA',
  'cayman islands': 'KY',
  'central african republic': 'CF',
  'chad': 'TD',
  'chile': 'CL',
  'china': 'CN',
  'christmas island': 'CX',
  'cocos (keeling) islands': 'CC',
  'cocos keeling islands': 'CC',
  'colombia': 'CO',
  'comoros': 'KM',
  'congo': 'CG',
  'congo, democratic republic of the': 'CD',
  'congo, republic of the': 'CG',
  'cook islands': 'CK',
  'costa rica': 'CR',
  'côte d\'ivoire': 'CI',
  'ivory coast': 'CI',
  'croatia': 'HR',
  'cuba': 'CU',
  'curaçao': 'CW',
  'cyprus': 'CY',
  'czech republic': 'CZ',
  'czechia': 'CZ',
  // D
  'denmark': 'DK',
  'djibouti': 'DJ',
  'dominica': 'DM',
  'dominican republic': 'DO',
  // E
  'ecuador': 'EC',
  'egypt': 'EG',
  'el salvador': 'SV',
  'equatorial guinea': 'GQ',
  'eritrea': 'ER',
  'estonia': 'EE',
  'eswatini': 'SZ',
  'ethiopia': 'ET',
  // F
  'falkland islands': 'FK',
  'falkland islands (malvinas)': 'FK',
  'faroe islands': 'FO',
  'fiji': 'FJ',
  'finland': 'FI',
  'france': 'FR',
  'french guiana': 'GF',
  'french polynesia': 'PF',
  'french southern territories': 'TF',
  // G
  'gabon': 'GA',
  'gambia': 'GM',
  'georgia': 'GE',
  'germany': 'DE',
  'ghana': 'GH',
  'gibraltar': 'GI',
  'greece': 'GR',
  'greenland': 'GL',
  'grenada': 'GD',
  'guadeloupe': 'GP',
  'guam': 'GU',
  'guatemala': 'GT',
  'guernsey': 'GG',
  'guinea': 'GN',
  'guinea-bissau': 'GW',
  'guyana': 'GY',
  // H
  'haiti': 'HT',
  'heard island and mcdonald islands': 'HM',
  'holy see': 'VA',
  'vatican city': 'VA',
  'honduras': 'HN',
  'hong kong': 'HK',
  'hungary': 'HU',
  // I
  'iceland': 'IS',
  'india': 'IN',
  'indonesia': 'ID',
  'iran': 'IR',
  'iran, islamic republic of': 'IR',
  'iraq': 'IQ',
  'ireland': 'IE',
  'isle of man': 'IM',
  'israel': 'IL',
  'italy': 'IT',
  // J
  'jamaica': 'JM',
  'japan': 'JP',
  'jersey': 'JE',
  'jordan': 'JO',
  // K
  'kazakhstan': 'KZ',
  'kenya': 'KE',
  'kiribati': 'KI',
  'korea': 'KR',
  'korea, democratic people\'s republic of': 'KP',
  'korea, north': 'KP',
  'north korea': 'KP',
  'korea, republic of': 'KR',
  'korea, south': 'KR',
  'south korea': 'KR',
  'kuwait': 'KW',
  'kyrgyzstan': 'KG',
  // L
  'lao people\'s democratic republic': 'LA',
  'laos': 'LA',
  'latvia': 'LV',
  'lebanon': 'LB',
  'lesotho': 'LS',
  'liberia': 'LR',
  'libya': 'LY',
  'liechtenstein': 'LI',
  'lithuania': 'LT',
  'luxembourg': 'LU',
  // M
  'macao': 'MO',
  'macau': 'MO',
  'macedonia': 'MK',
  'north macedonia': 'MK',
  'madagascar': 'MG',
  'malawi': 'MW',
  'malaysia': 'MY',
  'maldives': 'MV',
  'mali': 'ML',
  'malta': 'MT',
  'marshall islands': 'MH',
  'martinique': 'MQ',
  'mauritania': 'MR',
  'mauritius': 'MU',
  'mayotte': 'YT',
  'mexico': 'MX',
  'micronesia': 'FM',
  'micronesia, federated states of': 'FM',
  'moldova': 'MD',
  'moldova, republic of': 'MD',
  'monaco': 'MC',
  'mongolia': 'MN',
  'montenegro': 'ME',
  'montserrat': 'MS',
  'morocco': 'MA',
  'mozambique': 'MZ',
  'myanmar': 'MM',
  // N
  'namibia': 'NA',
  'nauru': 'NR',
  'nepal': 'NP',
  'netherlands': 'NL',
  'new caledonia': 'NC',
  'new zealand': 'NZ',
  'nicaragua': 'NI',
  'niger': 'NE',
  'nigeria': 'NG',
  'niue': 'NU',
  'norfolk island': 'NF',
  'northern mariana islands': 'MP',
  'norway': 'NO',
  // O
  'oman': 'OM',
  // P
  'pakistan': 'PK',
  'palau': 'PW',
  'palestine': 'PS',
  'palestine, state of': 'PS',
  'panama': 'PA',
  'papua new guinea': 'PG',
  'paraguay': 'PY',
  'peru': 'PE',
  'philippines': 'PH',
  'pitcairn': 'PN',
  'poland': 'PL',
  'portugal': 'PT',
  'puerto rico': 'PR',
  // Q
  'qatar': 'QA',
  // R
  'réunion': 'RE',
  'reunion': 'RE',
  'romania': 'RO',
  'russian federation': 'RU',
  'russia': 'RU',
  'rwanda': 'RW',
  // S
  'saint barthélemy': 'BL',
  'saint helena': 'SH',
  'saint helena, ascension and tristan da cunha': 'SH',
  'saint kitts and nevis': 'KN',
  'saint lucia': 'LC',
  'saint martin': 'MF',
  'saint martin (french part)': 'MF',
  'saint pierre and miquelon': 'PM',
  'saint vincent and the grenadines': 'VC',
  'samoa': 'WS',
  'san marino': 'SM',
  'sao tome and principe': 'ST',
  'saudi arabia': 'SA',
  'senegal': 'SN',
  'serbia': 'RS',
  'seychelles': 'SC',
  'sierra leone': 'SL',
  'singapore': 'SG',
  'sint maarten': 'SX',
  'sint maarten (dutch part)': 'SX',
  'slovakia': 'SK',
  'slovenia': 'SI',
  'solomon islands': 'SB',
  'somalia': 'SO',
  'south africa': 'ZA',
  'south georgia and the south sandwich islands': 'GS',
  'south sudan': 'SS',
  'spain': 'ES',
  'sri lanka': 'LK',
  'sudan': 'SD',
  'suriname': 'SR',
  'svalbard and jan mayen': 'SJ',
  'sweden': 'SE',
  'switzerland': 'CH',
  'syria': 'SY',
  'syrian arab republic': 'SY',
  // T
  'taiwan': 'CN',
  'taiwan, province of china': 'CN',
  'tajikistan': 'TJ',
  'tanzania': 'TZ',
  'tanzania, united republic of': 'TZ',
  'thailand': 'TH',
  'timor-leste': 'TL',
  'east timor': 'TL',
  'togo': 'TG',
  'tokelau': 'TK',
  'tonga': 'TO',
  'trinidad and tobago': 'TT',
  'tunisia': 'TN',
  'turkey': 'TR',
  'türkiye': 'TR',
  'turkmenistan': 'TM',
  'turks and caicos islands': 'TC',
  'tuvalu': 'TV',
  // U
  'uganda': 'UG',
  'ukraine': 'UA',
  'united arab emirates': 'AE',
  'uae': 'AE',
  'united kingdom': 'GB',
  'united kingdom of great britain and northern ireland': 'GB',
  'uk': 'GB',
  'great britain': 'GB',
  'united states': 'US',
  'united states of america': 'US',
  'usa': 'US',
  'united states minor outlying islands': 'UM',
  'uruguay': 'UY',
  'uzbekistan': 'UZ',
  // V
  'vanuatu': 'VU',
  'venezuela': 'VE',
  'venezuela, bolivarian republic of': 'VE',
  'viet nam': 'VN',
  'vietnam': 'VN',
  'virgin islands, british': 'VG',
  'virgin islands, u.s.': 'VI',
  // W
  'wallis and futuna': 'WF',
  'western sahara': 'EH',
  // Y
  'yemen': 'YE',
  // Z
  'zambia': 'ZM',
  'zimbabwe': 'ZW',
  // 特殊地区
  'åland islands': 'AX',
  'aland islands': 'AX',
};

/**
 * 国家代码到国家名称的映射表（反向映射）
 * 用于根据国家代码获取国家名称
 */
const COUNTRY_CODE_TO_NAME_MAP = {};
// 从 COUNTRY_NAME_TO_CODE_MAP 生成反向映射
Object.entries(COUNTRY_NAME_TO_CODE_MAP).forEach(([name, code]) => {
  // 优先使用较短的名称作为标准名称（更简洁）
  if (!COUNTRY_CODE_TO_NAME_MAP[code] || name.length < COUNTRY_CODE_TO_NAME_MAP[code].length) {
    COUNTRY_CODE_TO_NAME_MAP[code] = name;
  }
});

/**
 * 根据国家代码获取国家名称
 * @param {string} countryCode - 国家代码 (ISO 3166-1 alpha-2)
 * @returns {string|null} 国家名称，如果未找到则返回 null
 */
export function getCountryNameByCode(countryCode) {
  if (!countryCode || typeof countryCode !== 'string') {
    return null;
  }

  const code = String(countryCode).trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(code)) {
    return null;
  }

  return COUNTRY_CODE_TO_NAME_MAP[code] || null;
}

/**
 * 根据国家名称获取国家代码
 * @param {string} countryName - 国家名称
 * @returns {string|null} 国家代码 (ISO 3166-1 alpha-2)，如果未找到则返回 null
 */
export function getCountryCodeByName(countryName) {
  if (!countryName || typeof countryName !== 'string') {
    return null;
  }

  // 标准化国家名称：转小写、去除前后空格、处理特殊字符
  let normalizedName = countryName.trim().toLowerCase()
    .replace(/\s+/g, ' ') // 多个空格替换为单个空格
    .replace(/[，,]/g, ',') // 统一逗号
    .replace(/\(/g, '(')
    .replace(/\)/g, ')')
    .replace(/[''"]/g, '\''); // 统一引号

  // 直接查找
  if (COUNTRY_NAME_TO_CODE_MAP[normalizedName]) {
    return COUNTRY_NAME_TO_CODE_MAP[normalizedName];
  }

  // 移除括号内容后再次查找（如 "Taiwan, Province of China" -> "Taiwan"）
  const nameWithoutParentheses = normalizedName.replace(/\s*\([^)]*\)\s*/g, '').trim();
  if (nameWithoutParentheses && nameWithoutParentheses !== normalizedName) {
    if (COUNTRY_NAME_TO_CODE_MAP[nameWithoutParentheses]) {
      return COUNTRY_NAME_TO_CODE_MAP[nameWithoutParentheses];
    }
  }

  // 移除逗号后的内容再次查找（如 "Taiwan, Province of China" -> "Taiwan"）
  const nameBeforeComma = normalizedName.split(',')[0].trim();
  if (nameBeforeComma && nameBeforeComma !== normalizedName) {
    if (COUNTRY_NAME_TO_CODE_MAP[nameBeforeComma]) {
      return COUNTRY_NAME_TO_CODE_MAP[nameBeforeComma];
    }
  }

  // 模糊匹配：处理变体名称（包含匹配）
  for (const [name, code] of Object.entries(COUNTRY_NAME_TO_CODE_MAP)) {
    // 完全匹配
    if (normalizedName === name) {
      return code;
    }
    // 包含匹配（至少3个字符才进行包含匹配，避免误匹配）
    if (name.length >= 3 && normalizedName.length >= 3) {
      if (normalizedName.includes(name) || name.includes(normalizedName)) {
        return code;
      }
    }
  }

  return null;
}

/**
 * 根据国家代码生成国旗 emoji
 * @param {string} countryCode - 国家代码 (ISO 3166-1 alpha-2)
 * @returns {string} 国旗 emoji，如果无效则返回 🌐
 */
export function getCountryFlagEmoji(countryCode) {
  if (!countryCode) {
    return '🌐';
  }

  const cc = String(countryCode || '').trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(cc)) {
    return '🌐';
  }

  const a = cc.charCodeAt(0) - 65 + 0x1F1E6;
  const b = cc.charCodeAt(1) - 65 + 0x1F1E6;
  try {
    return String.fromCodePoint(a, b);
  } catch (e) {
    return '🌐';
  }
}

/**
 * 根据国家名称获取国旗 emoji
 * @param {string} countryName - 国家名称
 * @returns {string} 国旗 emoji，如果无效则返回 🌐
 */
export function getCountryFlagEmojiByName(countryName) {
  const countryCode = getCountryCodeByName(countryName);
  if (!countryCode) {
    return '🌐';
  }
  return getCountryFlagEmoji(countryCode);
}

/**
 * 根据国家代码获取国旗 emoji（通过国家名称）
 * 先根据 code 获取国家名称，再根据国家名称获取国旗
 * 支持 ISO 3166-1 alpha-2 代码（如 'CN', 'US'）、国家数字 ID（如 356）和国家名称（英文或中文）
 * @param {string|number} countryCode - 国家代码 (ISO 3166-1 alpha-2)、国家数字 ID 或国家名称
 * @returns {string} 国旗 emoji，如果无效则返回 🌐
 */
export function getCountryFlagEmojiByCode(countryCode) {
  if (!countryCode) {
    return '🌐';
  }

  // ISO 3166-1 numeric code 映射（标准映射，优先级最高）
  // 扩展了更多常见国家的ISO numeric codes，以支持更多国家
  const ISO_NUMERIC_MAP = {
    // 主要国家
    840: 'US', // United States
    826: 'GB', // United Kingdom
    124: 'CA', // Canada
    156: 'CN', // China
    356: 'IN', // India
    276: 'DE', // Germany
    250: 'FR', // France
    392: 'JP', // Japan
    410: 'KR', // South Korea
    36: 'AU', // Australia (ISO 3166-1 numeric: 036)
    554: 'NZ', // New Zealand
    // 欧洲国家
    724: 'ES', // Spain
    380: 'IT', // Italy
    643: 'RU', // Russia
    528: 'NL', // Netherlands
    56: 'BE', // Belgium
    756: 'CH', // Switzerland
    40: 'AT', // Austria
    752: 'SE', // Sweden
    578: 'NO', // Norway
    208: 'DK', // Denmark
    246: 'FI', // Finland
    616: 'PL', // Poland
    620: 'PT', // Portugal
    300: 'GR', // Greece
    372: 'IE', // Ireland
    642: 'RO', // Romania
    203: 'CZ', // Czech Republic
    348: 'HU', // Hungary
    100: 'BG', // Bulgaria
    191: 'HR', // Croatia
    688: 'RS', // Serbia
    703: 'SK', // Slovakia
    705: 'SI', // Slovenia
    440: 'LT', // Lithuania
    428: 'LV', // Latvia
    233: 'EE', // Estonia
    112: 'BY', // Belarus
    398: 'KZ', // Kazakhstan
    804: 'UA', // Ukraine
    492: 'MC', // Monaco
    // 亚洲国家
    608: 'PH', // Philippines
    764: 'TH', // Thailand
    704: 'VN', // Vietnam
    360: 'ID', // Indonesia
    458: 'MY', // Malaysia
    702: 'SG', // Singapore
    784: 'AE', // United Arab Emirates
    682: 'SA', // Saudi Arabia
    376: 'IL', // Israel
    792: 'TR', // Turkey
    586: 'PK', // Pakistan
    50: 'BD', // Bangladesh
    144: 'LK', // Sri Lanka
    104: 'MM', // Myanmar
    116: 'KH', // Cambodia
    418: 'LA', // Laos
    496: 'MN', // Mongolia
    524: 'NP', // Nepal
    4: 'AF', // Afghanistan
    368: 'IQ', // Iraq
    364: 'IR', // Iran
    400: 'JO', // Jordan
    422: 'LB', // Lebanon
    760: 'SY', // Syria
    887: 'YE', // Yemen
    512: 'OM', // Oman
    414: 'KW', // Kuwait
    634: 'QA', // Qatar
    48: 'BH', // Bahrain
    // 美洲国家
    76: 'BR', // Brazil
    484: 'MX', // Mexico
    32: 'AR', // Argentina
    152: 'CL', // Chile
    170: 'CO', // Colombia
    604: 'PE', // Peru
    862: 'VE', // Venezuela
    // 非洲国家
    710: 'ZA', // South Africa
    566: 'NG', // Nigeria
    450: 'MG', // Madagascar
    120: 'CM', // Cameroon
    384: 'CI', // Côte d'Ivoire
    686: 'SN', // Senegal
    466: 'ML', // Mali
    854: 'BF', // Burkina Faso
    562: 'NE', // Niger
    404: 'KE', // Kenya
    834: 'TZ', // Tanzania
    800: 'UG', // Uganda
    894: 'ZM', // Zambia
    716: 'ZW', // Zimbabwe
    24: 'AO', // Angola
    508: 'MZ', // Mozambique
    504: 'MA', // Morocco
    12: 'DZ', // Algeria
    788: 'TN', // Tunisia
    434: 'LY', // Libya
    729: 'SD', // Sudan
    231: 'ET', // Ethiopia
    288: 'GH', // Ghana
    // 其他
    818: 'EG', // Egypt
  };

  // 中文国家名称映射
  const CHINESE_COUNTRY_MAP = {
    '摩纳哥': 'MC',
    '中国': 'CN',
    '美国': 'US',
    '英国': 'GB',
    '加拿大': 'CA',
    '印度': 'IN',
    '德国': 'DE',
    '法国': 'FR',
    '日本': 'JP',
    '韩国': 'KR',
    '澳大利亚': 'AU',
    '新西兰': 'NZ',
    '西班牙': 'ES',
    '意大利': 'IT',
    '俄罗斯': 'RU',
    '荷兰': 'NL',
    '比利时': 'BE',
    '瑞士': 'CH',
    '奥地利': 'AT',
    '瑞典': 'SE',
    '挪威': 'NO',
    '丹麦': 'DK',
    '芬兰': 'FI',
    '波兰': 'PL',
    '葡萄牙': 'PT',
    '希腊': 'GR',
    '爱尔兰': 'IE',
    '罗马尼亚': 'RO',
    '捷克': 'CZ',
    '匈牙利': 'HU',
    '保加利亚': 'BG',
    '克罗地亚': 'HR',
    '塞尔维亚': 'RS',
    '斯洛伐克': 'SK',
    '斯洛文尼亚': 'SI',
    '立陶宛': 'LT',
    '拉脱维亚': 'LV',
    '爱沙尼亚': 'EE',
    '白俄罗斯': 'BY',
    '哈萨克斯坦': 'KZ',
    '乌克兰': 'UA',
    '菲律宾': 'PH',
    '泰国': 'TH',
    '越南': 'VN',
    '印度尼西亚': 'ID',
    '马来西亚': 'MY',
    '新加坡': 'SG',
    '阿联酋': 'AE',
    '沙特阿拉伯': 'SA',
    '以色列': 'IL',
    '土耳其': 'TR',
    '巴基斯坦': 'PK',
    '孟加拉国': 'BD',
    '斯里兰卡': 'LK',
    '缅甸': 'MM',
    '柬埔寨': 'KH',
    '老挝': 'LA',
    '蒙古': 'MN',
    '尼泊尔': 'NP',
    '阿富汗': 'AF',
    '伊拉克': 'IQ',
    '伊朗': 'IR',
    '约旦': 'JO',
    '黎巴嫩': 'LB',
    '叙利亚': 'SY',
    '也门': 'YE',
    '阿曼': 'OM',
    '科威特': 'KW',
    '卡塔尔': 'QA',
    '巴林': 'BH',
    '巴西': 'BR',
    '墨西哥': 'MX',
    '阿根廷': 'AR',
    '智利': 'CL',
    '哥伦比亚': 'CO',
    '秘鲁': 'PE',
    '委内瑞拉': 'VE',
    '南非': 'ZA',
    '尼日利亚': 'NG',
    '马达加斯加': 'MG',
    '喀麦隆': 'CM',
    '科特迪瓦': 'CI',
    '塞内加尔': 'SN',
    '马里': 'ML',
    '布基纳法索': 'BF',
    '尼日尔': 'NE',
    '肯尼亚': 'KE',
    '坦桑尼亚': 'TZ',
    '乌干达': 'UG',
    '赞比亚': 'ZM',
    '津巴布韦': 'ZW',
    '安哥拉': 'AO',
    '莫桑比克': 'MZ',
    '摩洛哥': 'MA',
    '阿尔及利亚': 'DZ',
    '突尼斯': 'TN',
    '利比亚': 'LY',
    '苏丹': 'SD',
    '埃塞俄比亚': 'ET',
    '加纳': 'GH',
    '埃及': 'EG',
  };

  // 如果是数字，先转换为 ISO 代码
  let isoCode = null;
  if (typeof countryCode === 'number') {
    // 优先检查 ISO numeric code（标准映射，避免与自定义映射冲突）
    if (ISO_NUMERIC_MAP[countryCode]) {
      isoCode = ISO_NUMERIC_MAP[countryCode];
    } else {
      // 如果不在 ISO 标准中，使用自定义映射表（COUNTRY_CODE_MAP）
      isoCode = getCountryCode(countryCode);
    }
  } else {
    const code = String(countryCode).trim();
    if (/^[A-Z]{2}$/i.test(code)) {
      // 已经是 ISO alpha-2 代码（如 'US', 'CN'）
      isoCode = code.toUpperCase();
    } else if (/^\d+$/.test(code)) {
      // 尝试作为数字处理（如 "1", "356"）
      const numCode = parseInt(code, 10);
      if (!isNaN(numCode)) {
        // 优先检查 ISO numeric code（标准映射，避免与自定义映射冲突）
        if (ISO_NUMERIC_MAP[numCode]) {
          isoCode = ISO_NUMERIC_MAP[numCode];
        } else {
          // 如果不在 ISO 标准中，使用自定义映射表（COUNTRY_CODE_MAP）
          isoCode = getCountryCode(numCode);
        }
      }
    } else {
      // 尝试作为国家名称处理（英文或中文）
      // 先尝试中文名称映射
      if (CHINESE_COUNTRY_MAP[code]) {
        isoCode = CHINESE_COUNTRY_MAP[code];
      } else {
        // 尝试英文名称映射
        const countryCodeByName = getCountryCodeByName(code);
        if (countryCodeByName) {
          isoCode = countryCodeByName;
        }
      }
    }
  }

  if (!isoCode) {
    return '🌐';
  }

  // 先根据 ISO code 获取国家名称
  const countryName = getCountryNameByCode(isoCode);
  if (!countryName) {
    // 如果找不到国家名称，直接尝试使用 ISO code 获取国旗
    return getCountryFlagEmoji(isoCode);
  }

  // 根据国家名称获取国旗（这样可以处理特殊映射，如 Taiwan -> CN）
  return getCountryFlagEmojiByName(countryName);
}


/**
 * 生成随机昵称
 * 规则：数字+字母，可以随机位置，昵称长度 10-15 位
 * @returns {string} 随机生成的昵称
 */
export function generateRandomNickname() {
  // 数字字符集
  const numbers = '0123456789';
  // 字母字符集（大小写）
  const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  // 所有可用字符
  const allChars = numbers + letters;

  // 随机生成昵称长度（10-15位）
  const length = Math.floor(Math.random() * 6) + 10; // 10-15

  // 确保至少包含一个数字和一个字母
  let nickname = '';

  // 随机添加一个数字
  nickname += numbers[Math.floor(Math.random() * numbers.length)];

  // 随机添加一个字母
  nickname += letters[Math.floor(Math.random() * letters.length)];

  // 填充剩余位置，随机选择数字或字母
  for (let i = nickname.length; i < length; i++) {
    nickname += allChars[Math.floor(Math.random() * allChars.length)];
  }

  // 打乱字符顺序（Fisher-Yates 洗牌算法）
  const nicknameArray = nickname.split('');
  for (let i = nicknameArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [nicknameArray[i], nicknameArray[j]] = [nicknameArray[j], nicknameArray[i]];
  }

  return nicknameArray.join('');
}


/**
 * 获取 iOS / Web 当前默认语言
 * @returns {string} 例如：zh-CN / en-US / ja-JP
 */
export function getDeviceLanguage() {
    if (navigator.languages && navigator.languages.length > 0) {
        return navigator.languages[0];
    }
    return navigator.language || 'en-US';
}
