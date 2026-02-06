<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar ref="actionBar"></m-action-bar>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <img src="@/assets/image/sdk/ic-logo.png"/>
        <h2>Nana Chat <span> {{ version }}</span></h2>
        <p class="m-release-time">
          Release time: {{ releaseDate }}
        </p>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
console.log( process.env)
export default {
  name: 'VersionPage',
  data() {
    return {
      version: 'V ' + process.env.VUE_APP_VERSION,
      releaseDate: process.env.VUE_APP_RELEASE_DATE
    }
  },
}
</script>

<style scoped lang="less">
.main {
  padding-left: 20px;
  box-sizing: border-box;
  text-align: center;
  padding-right: 20px;

  img {
    width: 140px;
    margin-top: 50px;
  }

  h2 {
    margin-top: 40px;
    font-size: @max-big-text-size;

    span {
      font-size: @min-text-size;
    }
  }



  .m-release-time {
    margin-top: 20px;
    color: @theme-un-select-text-color;
  }
}

</style>
