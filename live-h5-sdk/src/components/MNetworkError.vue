<template>
  <div class="network-error">
    <p class="network-title">Network Error</p>
    <p class="network-text">{{ message }}</p>
    <button v-if="showRetry" class="retry-btn" @click="$emit('retry')">
      Retry
    </button>
  </div>
</template>

<script>
export default {
  name: 'MNetworkError',
  props: {
    message: {
      type: String,
      default: 'Please check your network connection.'
    },
    showRetry: {
      type: Boolean,
      default: true
    }
  }
}
</script>

<style scoped lang="less">
.network-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  min-height: 300px;
}

.network-title {
  font-size: 22px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
  text-align: center;
  margin: 0 0 12px 0;
  line-height: 1.4;
}

.network-text {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.6);
  text-align: center;
  margin: 0 0 30px 0;
  max-width: 200px;
  line-height: 1.4;
}

.retry-btn {
  width: 200px;
  height: 50px;
  background: #fff;
  border: none;
  border-radius: 25px;
  font-size: 16px;
  font-weight: 600;
  color: #1C1C1E;
  cursor: pointer;
  transition: all 0.2s;
  
  &:active {
    transform: scale(0.95);
    opacity: 0.9;
  }
}
</style>
