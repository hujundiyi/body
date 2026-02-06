<template>
  <!-- 根据模式选择不同的上传组件 -->
  <div v-if="localPreview" class="upload-container" @click="triggerFileInput">
    <!-- 本地预览模式：使用原生input -->
    <input 
      ref="fileInput"
      type="file" 
      :accept="accept" 
      style="display: none"
      @change="handleLocalFileChange"
    />
    <slot></slot>
  </div>
  <el-upload v-else
             action="#"
             :accept="accept"
             :show-file-list="false"
             :before-upload="(f)=>{beforeUpload(f)}"
             :http-request="()=>{}">
    <!-- 原始模式：使用Element UI的el-upload -->
    <slot></slot>
  </el-upload>
</template>

<script>
// 保留原始的updateFileOos导入
import {updateFileOos} from "@/utils/system";

export default {
  name: "MUploadFile",
  props: {
    accept: {
      type: String,
      default() {
        return 'image/jpg,image/jpeg,image/png'
      }
    },
    // 新增prop：是否使用本地预览模式（true: 本地预览, false: 原始服务器上传）
    localPreview: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    // 保留原始的beforeUpload方法
    beforeUpload(file) {
      updateFileOos(file, (pro, url) => {
        if (url) {
          this.$emit('change', url)
        }
      })
    },
    
    // 本地预览模式：触发文件选择
    triggerFileInput() {
      this.$refs.fileInput.click();
    },
    
    // 本地预览模式：处理文件选择
    handleLocalFileChange(event) {
      const file = event.target.files[0];
      if (file) {
        this.handleLocalPreview(file);
      }
    },
    
    // 新增方法：处理本地预览
    handleLocalPreview(file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        // 将生成的DataURL传递给父组件
        this.$emit('change', e.target.result);
        // 清空文件输入，允许重复选择同一个文件
        this.$refs.fileInput.value = '';
      };
      reader.onerror = () => {
        this.$emit('error', 'Failed to read file');
        this.$refs.fileInput.value = '';
      };
      reader.readAsDataURL(file);
    }
  }
}
</script>

<style scoped lang="less">
.upload-container {
  cursor: pointer;
}
</style>

<style scoped lang="less">
</style>

