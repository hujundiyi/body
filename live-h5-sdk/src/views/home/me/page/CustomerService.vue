<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar/>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <img class="ic-customer-logo" src="@/assets/image/sdk/ic-customer-service.png"/>
        <div class="email">
          <p>{{ email }}</p>
          <img src="@/assets/image/sdk/ic-copy.png" @click="copy(email)"/>
        </div>
        <p class="hint">
          If you have any questions, you can contact customer
          service mailbox above, we will get in touch with you ASAP.
        </p>
        <m-button @click="copy(email)">Contact</m-button>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>

import {copy} from "@/utils/Utils";

export default {
  name: 'CustomerService',
  data() {
    return {}
  },
  computed: {
    email() {
      return this.$store.state.PageCache.configData['CUSTOM_EMAIL']
    }
  },
  methods: {copy}
}
</script>

<style scoped lang="less">
.main {
  padding-left: 20px;
  box-sizing: border-box;
  text-align: center;
  padding-right: 20px;

  .ic-customer-logo {
    width: 120px;
    margin-top: 35px;
    margin-bottom: 50px;
  }

  .email {

    p {
      display: inline-block;
      color: white;
      font-size: @max-text-size;
      vertical-align: middle;
    }

    img {
      margin-left: 10px;
      vertical-align: middle;
      width: 20px;
    }
  }

  .hint {
    margin-top: 50px;
    opacity: 0.5;
    margin-bottom: 50px;
  }

}


</style>
