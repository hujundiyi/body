# PayPal H5 支付对接说明

## 概述

本项目已实现 PayPal 支付功能，采用后端收银台模式。用户在前端选择 PayPal 支付后，会跳转到后端返回的 PayPal 支付页面完成支付。

## 支付流程

```
用户选择充值档位 
  ↓
选择 PayPal 支付方式
  ↓
点击 Continue 按钮
  ↓
调用 requestPay(productCode, 'paypal', rechargeId)
  ↓
后端 API: payWithCashier(rechargeId) 返回 pay_url
  ↓
跳转到 WebView 页面打开 PayPal 支付链接
  ↓
用户在 PayPal 页面完成支付
  ↓
用户返回应用，WebView 检测到页面可见性变化
  ↓
自动更新用户信息（余额等）
```

## 关键代码位置

### 1. 充值对话框组件
**文件**: `src/components/dialog/MRechargeDialog.vue`

- 支付方式选择：`selectedPayment: 'paypal'`
- 支付处理：`handleContinue()` 方法（第 420-462 行）

### 2. 支付工具函数
**文件**: `src/utils/PaymentUtils.js`

- `requestPay()` 函数处理 PayPal 支付逻辑
- 调用 `payWithCashier(rechargeId)` API 获取支付链接

### 3. 支付 API
**文件**: `src/api/sdk/commodity.js`

```javascript
export function payWithCashier(rechargeId) {
    return request({
        url: 'payIn/payWithCashier',
        method: 'post',
        data: { rechargeId }
    })
}
```

### 4. WebView 组件
**文件**: `src/views/other/WebView.vue`

- 使用 iframe 加载 PayPal 支付页面
- 监听页面可见性变化，检测用户返回
- 自动更新用户信息

## 后端接口要求

### 接口：`payIn/payWithCashier`

**请求参数**:
```json
{
  "rechargeId": "充值档位ID"
}
```

**响应格式**:
```json
{
  "code": 0,
  "data": {
    "pay_url": "https://paypal.com/checkout/xxx"
  }
}
```

## 支付状态检测

当前实现通过以下方式检测支付完成：

1. **页面可见性 API**: 当用户从 PayPal 页面返回时，`document.visibilitychange` 事件触发
2. **自动更新用户信息**: 返回后自动调用 `getWebUserDetail()` 更新用户余额等信息

### 改进建议

如果需要更可靠的支付状态检测，可以考虑：

1. **轮询查询**: 在 WebView 页面定期查询订单状态
2. **Webhook 回调**: 后端接收 PayPal 的 webhook 通知
3. **URL 参数检测**: PayPal 支付完成后可能重定向到特定 URL，可以检测 URL 变化

## 注意事项

### 1. 跨域问题
- PayPal 支付页面在 iframe 中加载，需要确保 PayPal 允许 iframe 嵌入
- 如果 PayPal 不允许 iframe，需要改为 `window.open()` 或直接跳转

### 2. 支付完成回调
- 当前实现依赖页面可见性变化，可能不够准确
- 建议后端实现支付状态查询接口，前端定期轮询

### 3. 错误处理
- 需要处理支付取消、支付失败等情况
- 建议添加支付超时检测

### 4. 安全性
- 确保支付链接通过 HTTPS 传输
- 验证后端返回的 `pay_url` 是否为 PayPal 域名

## 测试建议

1. **沙箱环境测试**: 使用 PayPal 沙箱账号测试支付流程
2. **支付取消测试**: 测试用户取消支付后的处理
3. **网络异常测试**: 测试网络中断时的处理
4. **多设备测试**: 在不同设备和浏览器上测试

## 相关文件清单

- `src/components/dialog/MRechargeDialog.vue` - 充值对话框
- `src/utils/PaymentUtils.js` - 支付工具函数
- `src/api/sdk/commodity.js` - 支付 API
- `src/views/other/WebView.vue` - WebView 组件
- `src/router/index.js` - 路由配置（PageWebView）

## 常见问题

### Q: PayPal 支付页面无法在 iframe 中加载？
A: PayPal 可能禁止 iframe 嵌入。解决方案：
- 使用 `window.open()` 打开新窗口
- 或直接使用 `window.location.href` 跳转
- 或使用原生 WebView（如果可用）：`clientNative.openWebView(payUrl, true)`

### Q: 如何知道支付是否成功？
A: 当前通过页面可见性变化检测。更可靠的方式：
- 后端提供订单状态查询接口
- 前端轮询查询订单状态
- 或后端通过 Webhook 通知前端

### Q: 支付完成后如何更新余额？
A: 当前在 WebView 组件的 `handleVisibilityChange()` 中自动调用 `updateUserInfo()` 更新用户信息。

### Q: 支付成功后返回页面时，项目重新启动了怎么办？
A: 已优化解决方案：
1. **使用 `router.replace` 而不是 `router.push`**：避免在历史记录中留下 WebView 页面
2. **保存返回路由信息**：使用 sessionStorage 保存支付前的路由，确保能正确返回
3. **禁用页面缓存**：将 WebView 页面的 `keepAlive` 设置为 `false`
4. **改进返回逻辑**：使用 `router.replace` 返回到指定路由，而不是 `router.back()`

如果问题仍然存在，可以考虑：
- 使用原生 WebView：`clientNative.openWebView(payUrl, true)`（如 premium/index.vue 中的实现）
- 使用 `window.open()` 打开新窗口，通过 `window.postMessage` 通信
