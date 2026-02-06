<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="''">
      </m-action-bar>
    </template>
    <template #page-content-wrap>
      <video
          ref="videoRef"
          :src="info.videoUrl"
          width="100%"
          autoplay
          loop
          controls
      ></video>
      <div class="footer">
        <div class="content">
          <div><h2>{{ info.nickname }}</h2>
            <p>{{ info.signature }}</p></div>
          <img src="@/assets/image/sdk/ic-call.png" v-if="false"/>
        </div>
      </div>

    </template>
  </m-page-wrap>
</template>

<script>

export default {
  name: 'VideoPlay',
  components: {},
  data() {
    return {
      info: JSON.parse(this.$route.query.params || '{}')
    };
  },
  methods: {}
}
</script>

<style>


.footer {
  position: absolute;
  bottom: 60px;
  width: 100%;
  text-align: left;

  .content {
    padding: 10px;
    position: relative;
    display: flex;
    align-items: center;
    justify-items: center;

    div {
      flex: 1;

      h2 {
        text-align: left;
      }

      p {
        margin-top: 5px;
        color: #a5a5a5;
      }
    }

    img {
      width: 50px;
      height: 50px;
      right: 10px;
    }
  }


}
</style>
