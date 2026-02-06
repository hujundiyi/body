<template>
  <m-bottom-dialog ref="baseDialog" :dialog-class="'top-dialog'">
    <div class="content">
      <canvas class="gift-canvas" ref="giftCanvas"></canvas>
    </div>
  </m-bottom-dialog>
</template>
<script>

import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import {Parser, Player} from 'svga';

export default {
  components: {MBottomDialog},
  props: {
    svgaUrl: {type: String}
  },
  data() {
    return {
      player: null,
      parser: null,
      svgaData: null,
      // 循环次数
      lookoutEquipment: 1,
      startFrame: 0,
      fillMode: 'forwards',
      playMode: 'forwards',
      loopStartFrame: 0,
      // 关闭帧缓存以节省内存 - WKWebView 内存有限
      isCacheFrames: false,
      isUseIntersectionObserver: false,
      isOpenNoExecutionDelay: false
    }
  },
  mounted() {
    this.startSvga()
  },
  methods: {
    async startSvga() {
      try {
        const parser = new Parser();
        this.parser = parser;
        const svga = await parser.load(this.svgaUrl);
        this.svgaData = svga;
        const doc = this.$refs.giftCanvas;
        if (!doc) {
          console.error('Canvas element not found');
          return;
        }
        const _this = this;
        const player = new Player({
          // 播放动画的 Canvas 元素
          container: doc,
          // 循环次数，默认值 0（无限循环）
          loop: _this.lookoutEquipment,
          // 最后停留的目标模式，默认值 forwards
          fillMode: _this.fillMode,
          // 播放模式，默认值 forwards
          playMode: _this.playMode,
          // 开始播放的帧数，默认值 0
          startFrame: _this.startFrame,
          // 循环播放开始的帧数
          loopStartFrame: _this.loopStartFrame,
          // 关闭帧缓存 - 减少内存占用
          isCacheFrames: _this.isCacheFrames,
          // 关闭视窗检测 - 减少开销
          isUseIntersectionObserver: _this.isUseIntersectionObserver,
          // 关闭 WebWorker - 减少资源占用
          isOpenNoExecutionDelay: _this.isOpenNoExecutionDelay,
        });
        await player.mount(svga);
        player.onStart = () => console.log('SVGA 播放开始');
        player.onEnd = () => {
          console.log('SVGA 播放结束');
          this.cleanup();
          this.$refs.baseDialog?.closeDialog();
        };
        // 开始播放动画
        player.start();
        this.player = player;
      } catch (error) {
        console.error('SVGA 加载或播放失败:', error);
        this.cleanup();
      }
    },
    // 清理所有资源
    cleanup() {
      // 停止并销毁 Player
      if (this.player) {
        try {
          this.player.stop();
          this.player.clear();
          this.player.destroy();
        } catch (e) {
          console.warn('Player cleanup error:', e);
        }
        this.player = null;
      }
      // 销毁 Parser
      if (this.parser) {
        try {
          this.parser.destroy();
        } catch (e) {
          console.warn('Parser cleanup error:', e);
        }
        this.parser = null;
      }
      // 清除 SVGA 数据引用
      this.svgaData = null;
      // 清空 Canvas 内容释放 GPU 内存
      const canvas = this.$refs.giftCanvas;
      if (canvas) {
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
        // 重置 canvas 尺寸可以强制释放内存
        canvas.width = 1;
        canvas.height = 1;
      }
    }
  },
  beforeDestroy() {
    this.cleanup();
  }
}
</script>
<style>
.top-dialog {
  top: 0 !important;
}


</style>
<style scoped lang="less">

.content {
  width: 100%;
  height: 100%;

  .gift-canvas {
    width: 100%;
    height: 100%;
  }
}
</style>

