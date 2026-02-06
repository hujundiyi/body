<template>
  <button :class="['m-button','m-width-'+width,'m-type-'+type,'m-size-'+size]" @click="onClick">
    <span class="text">
      <slot></slot>
    </span>
  </button>
</template>

<script>

export default {
  name: "MButton",
  props: {
    // full 宽度沾满 auto 随内容
    width: {
      type: String,
      default() {
        return 'full';
      }
    },
    // size default smail
    size: {
      type: String,
      default() {
        return 'default';
      }
    },
    // 按钮类型 warning 警告
    type: {
      type: String,
      default() {
        return 'default';
      }
    }
  },
  methods: {
    onClick(e) {
      this.$emit('click', e)
    }
  }
}
</script>

<style scoped lang="less">
.m-button {
  height: 48px;
  border-radius: 24px;
  border: none;
  background: linear-gradient(135deg, #F6C084 0%, #FADEBF 100%);

  .text {
    flex: 1;
    color: @theme-select-text-color;
    text-align: center;
    font-size: @max-text-size;
    font-weight: bold;
  }
}

.m-width-full {
  width: 80%;
  margin-left: 10%;
}

.m-width-auto {
  padding: 0 20px;
  margin: auto;
}

.m-size-smail {
  height: 38px;
  border-radius: 19px;
}

.m-type-info {
  background: linear-gradient(135deg, #f8f8f8 0%, #dedede 100%);
}

.m-type-warning {
  background: #FF5C3C;

  .text {
    color: white
  }

}
</style>

