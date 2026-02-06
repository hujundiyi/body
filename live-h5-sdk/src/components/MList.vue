<template>
  <div class="list-wrap">
    <m-list-drop-down-refresh v-if="openDropDownRefresh" ref="downRefresh" :on-refresh="onRefresh">
      <m-list-pull-up-reload ref="upReload"
                             :open-load-more="openLoadMore"
                             :on-infinite-load="onInfiniteLoad"
                             :parent-pull-up-state="pullUpState">
        <page-status :page-status="pageStatus" :error-msg="errorMsg" @click="statusViewClick"/>
        <slot name="m-list-item" v-bind:items="listData"></slot>
      </m-list-pull-up-reload>
    </m-list-drop-down-refresh>
    <m-list-pull-up-reload v-else ref="upReload"
                           :open-load-more="openLoadMore"
                           :on-infinite-load="onInfiniteLoad"
                           :parent-pull-up-state="pullUpState">
      <page-status :page-status="pageStatus" :error-msg="errorMsg" @click="statusViewClick"/>
      <slot name="m-list-item" v-bind:items="listData"></slot>
    </m-list-pull-up-reload>
  </div>
</template>
<script>
import MListPullUpReload from "@/components/MListPullUpReload.vue";
import MListDropDownRefresh from "@/components/MListDropDownRefresh.vue";
import request from "@/utils/Request";
import PageStatus from "@/components/sdk/PageStatus.vue";

export default {
  name: "MList",
  components: {PageStatus, MListPullUpReload, MListDropDownRefresh},
  props: {
    url: {
      type: String,
      default() {
        return null
      }
    },
    getParams: {
      type: Function,
      default() {
        return null;
      }
    },
    // 是否将 num 映射为 page（用于兼容需要 page 参数的接口）
    mapNumToPage: {
      type: Boolean,
      default() {
        return false;
      }
    },
    // 是否支持加载更多
    openLoadMore: {
      type: Boolean,
      default() {
        return true
      }
    },
    // 是否支持下拉刷新
    openDropDownRefresh: {
      type: Boolean,
      default() {
        return true
      }
    },
    // 当加载完成
    onRefreshCallBack: {
      type: Function,
      default() {
        return null
      }
    },
    // 当加载完成
    onLoadSuccess: {
      type: Function,
      default() {
        return null
      }
    }
  },
  data() {
    return {
      num: 0,
      size: 12,
      listData: [],
      // 1:加载更多, 2:加载中……, 3:没有数据
      pullUpState: 0,
      // 1: 内容页面 2:空页面 3:加载出错页面
      pageStatus: 1,
      errorMsg: ''
    }
  },
  mounted() {
    if (this.openDropDownRefresh) {
      this.refresh();
    }
  },
  methods: {
    refresh() {
      if (this.$refs.downRefresh) {
        this.$refs.downRefresh.refresh();
      }
    },
    onRefresh() {
      this.loadData(true);
      this.onRefreshCallBack && this.onRefreshCallBack()
    },
    onInfiniteLoad() {
      this.loadData(false)
    },
    statusViewClick() {
      if (this.$refs.downRefresh) {
        this.$refs.downRefresh.refresh()
      } else {
        // 如果没有下拉刷新，直接重新加载数据
        this.loadData(true);
      }
    },
    // 加载数据
    loadData(isRefresh) {
      if (!this.url) {
        return
      }

      this.pageStatus = 1
      let pageNum = isRefresh ? this.num = 1 : ++this.num;
      let params = {num: pageNum, size: this.size}
      
      // 如果启用了 mapNumToPage，将 num 映射为 page
      if (this.mapNumToPage) {
        // page 从 0 开始，num 从 1 开始，所以 page = num - 1
        params.page = pageNum - 1;
        delete params.num;
      }
      
      if (this.getParams) {
        params = {...params, ...this.getParams()};
      }
      request({
        url: this.url,
        method: 'post',
        data: params,
      }).then((rsp) => {
        this.initResult(isRefresh, rsp.data)
      }).catch((e) => {
        this.num = 0;
        // 隐藏加载更多
        this.pullUpState = 0;
        if (this.$refs.downRefresh) {
          this.$refs.downRefresh.refreshDone(false);
        }
        // 将 Error 对象转换为字符串
        this.errorMsg = e && typeof e === 'object' ? (e.message || String(e)) : String(e || 'Unknown error');
        setTimeout(() => {
          // 显示状态页面
          this.pageStatus = 3;
        }, 500)
      });
    },
    initResult(isRefresh, data) {
      if (isRefresh) {
        this.listData = data;
      } else if (data.length > 0) {
        this.listData = [...this.listData, ...data]
      }
      // 只有在启用下拉刷新且 downRefresh 存在时才调用 refreshDone
      if (this.openDropDownRefresh && this.$refs.downRefresh) {
        this.$refs.downRefresh.refreshDone(true);
      }
      this.pageStatus = isRefresh && this.listData.length <= 0 ? 2 : 1;

      this.pullUpState = this.pageStatus === 2 ? 0 : data.length < this.size ? 3 : 1;
      if (this.onLoadSuccess) {
        this.onLoadSuccess(isRefresh);
      }
    }
  }
}
</script>

<style scoped lang="less">
.list-wrap {
  height: 100%;
  overflow: hidden;
  position: relative;
  top: 0;
  bottom: 0;
}

</style>

