<template>
  <m-page-wrap :show-safe-area="true">
    <template #page-head-wrap>
      <m-action-bar :title="'Image'"/>
    </template>
    <template #page-content-wrap>
      <!--      <div  v-for="(item,index) in urls" :key="index" class="image-container" @wheel.prevent="handleWheel"
                 @touchstart="handleTouchStart" @touchmove="handleTouchMove" @touchend="handleTouchEnd">
              <img :src="item" :style="{ transform: `scale(${scale})` }" :data-preview="item" @dblclick="zoomTagger"
                   ref="image"/>
            </div>-->
      <swiper ref="swiper" class="img-wrap" :options="swiperOption" @slideChange="onSlotChange">
        <swiper-slide v-for="(item,index) in urls" :key="index">
          <img :src="item" :style="{ transform: `scale(${scale})` }" :data-preview="item" @dblclick="zoomTagger"
               ref="image"/>
        </swiper-slide>
      </swiper>
      <div class="swiper-pagination" slot="pagination">
        <span> {{ index + 1 }} / {{ urls.length }}</span>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import 'swiper/dist/css/swiper.css'
import {swiper, swiperSlide} from 'vue-awesome-swiper'

export default {
  components: {swiper, swiperSlide},
  name: 'PicturePreview',
  data() {
    const url = JSON.parse(this.$route.query.urls || '[]');
    return {
      swiperOption: {
        // 自动播放
        autoplay: false,
        loop: false,
        spaceBetween: 0,
        centeredSlides: true,
        slideToClickedSlide: true
      },
      index: parseInt(this.$route.query.index || 0),
      urls: url,
      // 手势部分
      scale: 1,
      initialScale: 1,
      touchStart: {x: 0, y: 0},
      touchEnd: {x: 0, y: 0},
    };
  },
  mounted() {
    this.$refs.swiper.swiper.slideTo(this.index, 0);
  },
  methods: {
    onSlotChange() {
      this.index = this.$refs.swiper.swiper.activeIndex
    },
    zoomTagger() {
      if (this.scale >= 1) {
        this.scale = ++this.scale;
      }
      if (this.scale > 3) {
        this.scale = this.initialScale;
      }
    }
  }
}
</script>

<style scoped lang="less">
img {
  width: 100%;
}

.swiper-pagination {
  text-align: center;
  position: fixed;
  bottom: 20px;
  z-index: 999;
  width: 100%;

  span {
    display: inline-block;
    color: #ffffff;
    padding: 5px 15px;
    border-radius: 20px;
    background: @theme-line-color;
  }
}


</style>
