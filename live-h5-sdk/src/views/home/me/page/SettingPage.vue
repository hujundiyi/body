<template>
  <m-page-wrap :show-action-bar="true">
    <template #page-head-wrap>
      <m-action-bar/>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <ul class="menu-items">
          <li v-for="(it ,index) in menuItems" :key="index" @click="menuClick(it)">
            <p>{{ it.title }} </p>
            <span>{{ it.text }}</span>
            <i class="ic-right el-icon-arrow-right"/>
          </li>
        </ul>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MPageWrap from "@/components/MPageWrap.vue";
import {openWebView} from "@/utils/PageUtils";

export default {
  name: 'SettingPage',
  components: {MPageWrap},
  data() {
    return {
      menuItems: [
        {
          name: 'PageDeleteAccount',
          title: 'Delete Account'
        },
        {
          name: null,
          title: 'Privacy policy',
          onClick() {
            openWebView('Privacy policy', 'https://agree.stampyteam.shop/privacy.html')
          }
        },
        {
          name: null,
          title: 'About us'
        },
        {
          name: null,
          title: 'FAQs'
        },
        {
          name: "PageVersion",
          title: 'Version ',
          text: 'V' + process.env.VUE_APP_VERSION
        },
      ]
    }
  },
  methods: {
    menuClick({name, onClick}) {
      if (onClick) {
        onClick()
      } else if (name) {
        this.$router.push({name: name});
      }
    }
  }
}
</script>

<style scoped lang="less">
.main {
  box-sizing: border-box;
}


.menu-items {
  padding: 0 15px;

  li {
    height: 50px;
    display: flex;
    align-content: center;
    align-items: center;
    box-sizing: border-box;
    border-bottom: @theme-line-color solid 1px;

    .icon {
      width: 22px;
      height: 22px;
    }

    p {
      color: @theme-un-select-text-color;
      flex: 1;
      margin-left: 15px;
    }

    span {
      font-size: @min-text-size;
      color: @theme-un-select-text-color;
    }

    .ic-right {
      opacity: 0.5;
    }

  }
}

.ic-right {
  height: 18px;
  margin-left: 10px;
  width: 22px;
}
</style>
