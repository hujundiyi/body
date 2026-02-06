<!--页面容器-->
<template>
  <transition :name="pageSwitchAnimationName">
    <keep-alive v-if="$route.meta.keepAlive">
      <router-view/>
    </keep-alive>
    <router-view v-else :key="key"/>
  </transition>
</template>
<script>

export default {
  name: 'MRouterView',
  computed: {
    key() {
      return this.$route.path;
    },
    pageSwitchAnimationName() {
      return this.$store.state.PageCache.pageSwitchAnimationName
    }
  }
}
</script>
