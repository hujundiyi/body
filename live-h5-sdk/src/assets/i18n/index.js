/**
 * 多语言初始化
 */

import Vue from "vue";
import VueI18n from 'vue-i18n';
import enLocale from "./lang/zh-EN";
import frLocal from "./lang/zh-FR";

Vue.use(VueI18n)

// 引入本地
const messages = {
  en: {
    message: 'hello',
    ...enLocale,
  },
  fr: {
    message: 'hello',
    ...frLocal
  },
}
const i18n = new VueI18n({
  messages,
})
export default i18n
