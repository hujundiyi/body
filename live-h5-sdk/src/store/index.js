import Vue from 'vue'
import Vuex from 'vuex'
import user from './modules/user'
import call from './modules/call'
import anchor from './modules/anchor'
import getters from './getters'
import PageCache from "@/store/modules/PageCache";

Vue.use(Vuex)

const store = new Vuex.Store({
  modules: {PageCache, user, call, anchor},
  getters
})

export default store
