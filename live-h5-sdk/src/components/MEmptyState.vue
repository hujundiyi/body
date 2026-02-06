<template>
  <div class="empty-state">
    <img 
      class="empty-icon" 
      :src="require('@/assets/image/sdk/ic_empty@2x.png')" 
      alt="Empty"
    />
    <p class="empty-text">{{ message }}</p>
  </div>
</template>

<script>
export default {
  name: 'MEmptyState',
  props: {
    message: {
      type: String,
      default: 'Nothing Here Yet.'
    }
  }
}
</script>

<style scoped lang="less">
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  min-height: 300px;
}

.empty-icon {
  width: 120px;
  height: 120px;
  object-fit: contain;
  margin-bottom: 20px;
}

.empty-text {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.6);
  text-align: center;
  margin: 0;
}
</style>
