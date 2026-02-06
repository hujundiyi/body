<!--页面容器-->
<template>
  <div class="m-page-wrap">
    <main ref="pageContentWrap" :class="contentClass">
      <slot name="page-content-wrap"></slot>
    </main>
    <header :class="headerClass" v-show="showActionBar">
      <div>
        <slot name="page-head-wrap"></slot>
      </div>
    </header>
  </div>
</template>
<script>

export default {
  name: 'MPageWrap',
  props: {
    showActionBar: {
      type: Boolean,
      default() {
        return true;
      }
    },
    // 是否显示iOS安全区域距离
    showSafeArea: {
      type: Boolean,
      default() {
        return false;
      }
    },
  },
  computed: {
    contentClass() {
      const classes = ['m-page-content'];
      if (this.showActionBar) {
        // 有 ActionBar 时的顶部 padding
        classes.push(this.showSafeArea ? 'm-safe-area-top-padding' : 'm-page-content-padding');
      }
      if (this.showSafeArea) {
        // 底部安全区域
        classes.push('m-safe-area-bottom');
      }
      return classes;
    },
    headerClass() {
      return [
        'm-page-head',
        this.showSafeArea ? 'm-safe-area-top' : ''
      ].filter(Boolean);
    }
  },
  data() {
    return {}
  }
}

</script>
<style scoped lang="less">
.m-page-wrap {
  height: 100%;
}

.m-page-head {
  position: fixed;
  top: 0;
  width: 100%;
  background: @theme-bg-color;

  div {
    position: relative;
  }
}

.m-page-content {
  position: relative;
  // height: 100%;  // 如果需要滚动，则注释掉   2026-01-13  茂林 改bug 注释 后面有需要再打开
  overflow-y: auto;
}

.m-page-content-padding {
  padding-top: 70px;
}

// iOS 安全区域相关样式
.m-safe-area-top {
  // 顶部刘海屏适配
  padding-top: constant(safe-area-inset-top); // 兼容 iOS 11.0-11.2
  padding-top: env(safe-area-inset-top);
}

.m-safe-area-bottom {
  // 底部 home indicator 适配
  padding-bottom: constant(safe-area-inset-bottom); // 兼容 iOS 11.0-11.2
  padding-bottom: env(safe-area-inset-bottom);
}

.m-safe-area-top-padding {
  // 70px 基础高度 + iOS 顶部安全区域
  padding-top: calc(70px + constant(safe-area-inset-top)); // 兼容 iOS 11.0-11.2
  padding-top: calc(70px + env(safe-area-inset-top));
}
</style>
