<template>
  <div :class="['call-coin','size-'+size]">
    <img src="@/assets/image/sdk/ic-coin-min.png"/>
    <span>{{ coin }}/min</span>
  </div>
</template>

<script>
export default {
  name: "CallCoin",
  props: {
    coin: {
      type: Number,
      default() {
        return 0
      }
    },
    size: {
      type: String,
      default() {
        // min max
        return 'min';
      }
    }
  }
}
</script>

<style scoped lang="less">

.call-coin {
  display: inline-block;
  background: rgba(0, 0, 0, 0.35);
  border-radius: 13px;
  height: 25px;
  line-height: 25px;
  padding-left: 8px;
  padding-right: 8px;

  img {
    display: inline-block;
    width: 16px;
    height: 16px;
    vertical-align: middle;
  }

  span {
    display: inline-block;
    margin-left: 5px;
  }
}

.size-min {
  height: 20px;
  line-height: 20px;
  box-sizing: border-box;
  font-size: 14px;

  img {
    vertical-align: middle;
    display: inline-block;
  }

  span {
    display: inline-block;
  }

}

</style>

