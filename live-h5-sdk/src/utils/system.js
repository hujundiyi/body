import axios from "axios";
import request from "@/utils/Request";

/**
 * 获取文件上传表单数据
 * @param file file
 * @param collPro
 * @returns {Promise<AxiosResponse<any>>}
 */
export function updateFileOos(file, collPro) {
  // 根据文件类型判断 type 参数
  // 图片格式一律是 "picture"，视频格式都是 "video"
  let fileType = '';
  if (file.type.startsWith('image/')) {
    // 图片类型统一使用 "picture"
    fileType = 'picture';
  } else if (file.type.startsWith('video/')) {
    // 视频类型统一使用 "video"
    fileType = 'video';
  } else {
    // 其他类型，根据文件扩展名判断
    const fileName = file.name.toLowerCase();
    if (fileName.endsWith('.mp4') || fileName.endsWith('.mov') || fileName.endsWith('.avi') || fileName.endsWith('.webm')) {
      fileType = 'video';
    } else {
      fileType = 'picture'; // 默认使用 picture
    }
  }
  
  // 生成随机文件名：时间戳 + 随机字符串（不包含文件扩展名）
  const timestamp = Date.now();
  const randomStr = Math.random().toString(36).substring(2, 15); // 生成13位随机字符串
  const generatedFileName = `${timestamp}_${randomStr}`;
  
  return request({
    url: 'system/getPutFileUrl',
    method: 'post',
    data: {
      type: fileType,
      fileName: generatedFileName+".jpg",
      contentLength: file.size
    }
  }).then(response => {
    const {contentType, preUrl, url} = response.data;
    let reader = new FileReader();

    reader.onload = function (e) {
      axios({
        method: 'PUT',
        url: preUrl,
        headers: {
          'Content-Type': contentType,
          'Cache-Control': 'max-age=31536000'
        },
        data: e.target.result,
        onUploadProgress: function (progressEvent) {
          if (progressEvent.lengthComputable) {
            const upLoadProgress = progressEvent.loaded / progressEvent.total * 100
            if (progressEvent.loaded === progressEvent.total) {
              collPro(upLoadProgress, url);
            } else {
              collPro(upLoadProgress, null);
            }
          }
        }
      }).catch((error) => {
        console.error('File upload to S3 failed:', error);
        collPro(0, null); // 上传失败，传递错误信息
      });
    };
    
    reader.onerror = function () {
      console.error('FileReader error');
      collPro(0, null);
    };
    
    reader.readAsArrayBuffer(file);

  });
}
