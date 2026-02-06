<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar :title="null"/>
    </template>
    <template #page-content-wrap>
      <div class="main">
        <!-- My photos section -->
        <div class="section photos-section">
          <div class="section-header">
            <div class="section-title">My photos</div>
            <div class="photo-count">{{ form.photos.length }}/6</div>
          </div>
          <div class="photos-container" :class="{ 'no-photos': form.photos.length === 0 }">
            <!-- 添加按钮始终在第一个位置，当图片数量达到6个时隐藏 -->
            <div
              class="photo-slot add-slot"
              v-show="form.photos.length < 6">
              <div class="add-photo" @click="openPhotoPicker">
<!--                <div class="add-photo-btn">+</div>-->
                <img src="@/assets/image/sdk/ic-ed-add-pic.png" class="add-photo-btn"/>
              </div>
              <!-- 隐藏的文件输入，用于拍照和相册选择 -->
              <input
                ref="photoInput"
                type="file"
                accept="image/*"
                capture="environment"
                style="display: none"
                @change="handlePhotoSelected"
              />
            </div>

            <!-- 图片列表，可左右滑动 -->
            <div class="photos-scroll-container">
              <div
                v-for="(photo, index) in form.photos"
                :key="index"
                class="photo-slot image-slot">
                <div class="photo-item">
                  <img
                    :src="photo || require('@/assets/image/ic-placeholder-avatar.png')"
                    :data-retry-count="0"
                    @error="handleImageError(index, $event)"
                    @load="handleImageLoad(index)"
                  />
                  <div class="photo-delete" @click="removePhoto(index)">×</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- User info section -->
        <div class="section">
          <div class="form-item">
            <div class="section-title">Nickname</div>
            <div class="nickname-container">
              <input
                type="text"
                v-model="form.nickname"
                class="nickname-input"
                placeholder="Please enter Nickname"
                @blur="handleNicknameChange"
              />
              <img src="@/assets/image/sdk/ic_ed_refresh.png" class="refresh-icon" @click="refreshNickname"/>
            </div>
          </div>

          <div class="form-item">
            <div class="section-title">Age</div>
            <div class="age-selector" @click="openAgePicker">
              <span>{{ form.age || '30' }}</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
          </div>

          <div class="form-item">
            <div class="section-title">Gender</div>
            <div class="gender-buttons">
              <div
                class="gender-btn"
                :class="{ active: form.gender === 0 }"
                @click="selectGender(0)">
                Man
              </div>
              <div
                class="gender-btn"
                :class="{ active: form.gender === 1 }"
                @click="selectGender(1)">
                Woman
              </div>
            </div>
          </div>

          <div class="form-item">
            <div class="section-title">Bio</div>
            <textarea
                v-model="form.bio"
                maxlength="200"
                rows="4"
                placeholder="Say more about yourself to catch the eye of other users"
                class="custom-textarea"
                @blur="handleBioChange">
            </textarea>
          </div>
        </div>

        <!-- Setting section -->
        <div class="section">
          <div class="section-title">Setting</div>
          <div class="setting-list">
            <div class="setting-item" @click="navigateTo('Coin Transactions')">
              <span>Coin Transactions</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
            <div class="setting-item" @click="navigateTo('Blacklist')">
              <span>Blacklist</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
<!--            <div class="setting-item" @click="navigateTo('Terms Of Use')">-->
<!--              <span>Terms Of Use</span>-->
<!--              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>-->
<!--            </div>-->
<!--            <div class="setting-item" @click="navigateTo('Clear Cache')">-->
<!--              <span>Clear Cache</span>-->
<!--              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>-->
<!--            </div>-->
            <div class="setting-item" @click="navigateTo('Contact Us')">
              <span>Contact Us</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
            <div class="setting-item" @click="navigateTo('Delete Account')">
              <span>Delete Account</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
            <div class="setting-item" @click="logout">
              <span>Log Out</span>
              <img src="@/assets/image/sdk/ic_ed_arrow.png" class="arrow-icon"/>
            </div>
          </div>
        </div>


      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import {updateUserInfo, setUserInfo} from "@/api/sdk/user";
import {getWebUserDetail} from "@/api";
import {batchAddUpdatePicture, removePicture} from "@/api/sdk/picture";
import {updateFileOos} from "@/utils/system";
import {showAgePickerDialog, showPhotoPickerDialog, showTipsDialog, showExitDialog, showCleanCacheDialog, showFeedbackDialog, showDeletePhotoDialog} from "@/components/dialog";
import {generateRandomNickname} from "@/utils/Utils";
import store from "@/store";
import {showLoading, hideLoading} from "@/components/MLoading";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'EditUserInfo',
  components: {},
  data() {
    let {nickname, age, gender, bio, photos} = this.$store.state.user.loginUserInfo;
    return {
      form: {
        nickname: nickname || '',
        age: age || '',
        gender: gender || 0,
        bio: bio || '',
        photos: photos || []
      },
      originalForm: {
        nickname: nickname || '',
        gender: gender || 0,
        bio: bio || ''
      },
      userPictures: [], // 存储完整的 userPictures 数据（包含 id 等信息）
      replacingPhotoIndex: null, // 正在替换的图片索引（用于替换第0张图片）
      showAgePicker: false,
      lastNicknameGenerateTime: 0, // 上次生成昵称的时间戳（用于限制频繁调用）
      rules: {
        nickname: [
          {required: true, message: 'Please enter', trigger: 'blur'}
        ]
      },
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo
    }
  },
  mounted() {
    this.fixIOSKeyboardIssue();
    this.loadUserInfo();
    // 重置滚动位置
    this.resetScrollPosition();
  },
  activated() {
    // keep-alive 激活时重置滚动位置，避免从其他页面返回时显示错误的滚动位置
    this.$nextTick(() => {
      this.resetScrollPosition();
    });
  },
  methods: {
    resetScrollPosition() {
      // 重置页面滚动位置到顶部
      // 方法1: 通过 $el 查找滚动容器
      const pageContent = this.$el && this.$el.closest('.m-page-content');
      if (pageContent) {
        pageContent.scrollTop = 0;
      }
      // 方法2: 直接查找所有可能的滚动容器
      const scrollContainers = document.querySelectorAll('.m-page-content');
      scrollContainers.forEach(container => {
        if (container.contains(this.$el) || this.$el.contains(container)) {
          container.scrollTop = 0;
        }
      });
      // 方法3: 重置 window 滚动位置
      if (window) {
        window.scrollTo(0, 0);
      }
      // 方法4: 重置 document.body 滚动位置
      if (document.body) {
        document.body.scrollTop = 0;
      }
      if (document.documentElement) {
        document.documentElement.scrollTop = 0;
      }
    },
    openAgePicker() {
      showAgePickerDialog(this.form.age || 30, (newAge) => {
        this.form.age = newAge;
        // 将年龄转换为生日时间戳并更新
        this.updateUserBirthday(newAge);
      });
    },

    // 更新用户生日
    updateUserBirthday(age) {
      if (!age || age <= 0) {
        console.warn('年龄无效，无法更新生日');
        return;
      }

      // 计算生日：当前日期减去年龄，使用当前日期作为生日
      // 例如：如果今天是2024年12月15日，用户30岁，则生日是1994年12月15日
      const today = new Date();
      const currentYear = today.getFullYear();
      const currentMonth = today.getMonth();
      const currentDay = today.getDate();
      const birthYear = currentYear - age;

      // 创建生日日期对象（使用当前月日）
      const birthday = new Date(birthYear, currentMonth, currentDay);
      // 转换为时间戳（秒）- API期望的是秒级时间戳
      const birthdayTimestamp = Math.floor(birthday.getTime() / 1000);

      setUserInfo({ birthday: birthdayTimestamp }).then((rsp) => {
        console.log('生日更新成功:', rsp);
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success)) {
          console.log('用户生日已更新');
        }
      }).catch((error) => {
        console.error('生日更新失败:', error);
        // 不显示错误提示，避免干扰用户
      });
    },
    submit() {
      this.$refs['form'].validate((valid) => {
        if (valid) {
          updateUserInfo(this.form).then((res) => {
            console.log(res)
            showCallToast('Profile updated successfully')
          })
        }
      })
    },

    // 添加图片（支持本地预览URL和真实URL）
    addPhoto(url, isRealUrl = false) {
      if (this.form.photos.length < 6) {
        // 确保URL有效，直接添加到数组中，Vue会自动响应式更新视图
        if (url && typeof url === 'string') {
          this.form.photos.push(url);
          // 同时添加到 userPictures 数组（新上传的图片暂时没有 id）
          this.userPictures.push({
            url: url,
            id: null, // 新上传的图片暂时没有 id，上传成功后会更新
            coin: 0,
            cover: false,
            type: 1,
            isPay: false
          });
          // 如果是真实URL，立即上传到服务器
          if (isRealUrl) {
            // 显示加载转子
            showLoading('Uploading...', false);
            // 传递正确的索引：新添加的图片索引是 form.photos.length - 1
            const newIndex = this.form.photos.length - 1;
            this.uploadPictureToServer(url, 1, newIndex);
          }
        } else {
          showCallToast('Invalid photo URL');
        }
      } else {
        showCallToast('Maximum 6 photos allowed');
      }
    },

    // 上传图片到服务器
    uploadPictureToServer(url, type = 1, targetIndex = null) {
      if (!this.userInfo || !this.userInfo.userId) {
        console.warn('用户信息不完整，无法上传图片');
        return;
      }

      // 如果 targetIndex 不为 null，说明是替换图片（特别是第0张）
      const isReplacing = targetIndex !== null && targetIndex !== undefined;
      const targetPicture = isReplacing && this.userPictures[targetIndex] ? this.userPictures[targetIndex] : null;

      // 确定目标索引
      // 如果是替换，使用 targetIndex
      // 如果是添加新图片，使用 form.photos 的长度减1（因为新图片已经被添加到 form.photos 中了）
      const actualIndex = isReplacing ? targetIndex : (this.form.photos.length > 0 ? this.form.photos.length - 1 : 0);

      // 判断是否是上传头像（只有第0张图片才是头像）
      const isUploadingAvatar = actualIndex === 0;

      // 如果是替换图片，使用原有的 id；如果是新增，id 为 0
      // 第0张图片的 cover 始终为 true
      const picId = isReplacing && targetPicture && targetPicture.id ? targetPicture.id : 0;
      const isCover = actualIndex === 0; // 第0张图片始终是封面

      const picData = {
        userId: this.userInfo.userId,
        pics: [{
          url: url,
          cover: isCover, // 第0张图片或第一张真实图片设为封面
          type: type, // 1: 图片, 2: 视频
          id: picId, // 替换时使用原有 id，新增时为 0
          coin: targetPicture ? targetPicture.coin : 0,
          isPay: targetPicture ? targetPicture.isPay : false
        }]
      };

      console.log('准备上传图片到服务器:', picData);
      batchAddUpdatePicture(picData).then((rsp) => {
        console.log('图片上传成功:', rsp);
        // 如果返回了图片ID，更新本地 userPictures 数据
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success)) {
          console.log('图片已保存到服务器');

          // 使用 actualIndex 作为更新索引
          const updateIndex = actualIndex;

          // 确保 userPictures[updateIndex] 存在
          if (updateIndex >= 0) {
            try {
              if (!this.userPictures[updateIndex]) {
                // 如果不存在，创建一个新对象
                this.$set(this.userPictures, updateIndex, {
                  url: url,
                  id: null,
                  coin: 0,
                  cover: updateIndex === 0,
                  type: type,
                  isPay: false
                });
              }

              // 处理服务器返回的数据
              // 服务器可能返回：1) data 是数字（图片ID） 2) data 是对象包含 pics 数组 3) data 是对象包含其他字段
              let picId = null;
              let serverUrl = url; // 默认使用原始URL
              let picInfo = null;

              if (rsp.data) {
                // 如果 data 是数字，说明只返回了图片ID
                if (typeof rsp.data === 'number') {
                  picId = rsp.data;
                  console.log('服务器返回图片ID:', picId);
                } 
                // 如果 data 是对象且包含 pics 数组
                else if (rsp.data.pics && Array.isArray(rsp.data.pics) && rsp.data.pics.length > 0) {
                  picInfo = rsp.data.pics[0];
                  picId = picInfo.id || null;
                  serverUrl = picInfo.url || url;
                  console.log('服务器返回图片数据:', picInfo);
                }
                // 如果 data 是对象但没有 pics，检查是否有其他字段
                else if (typeof rsp.data === 'object') {
                  // 检查是否直接包含图片信息
                  if (rsp.data.id) picId = rsp.data.id;
                  if (rsp.data.url) serverUrl = rsp.data.url;
                  console.log('服务器返回数据对象:', rsp.data);
                }
              }

              // 更新 userPictures 数据
              if (picId !== null) {
                this.$set(this.userPictures[updateIndex], 'id', picId);
              }
              if (picInfo) {
                this.$set(this.userPictures[updateIndex], 'url', serverUrl);
                this.$set(this.userPictures[updateIndex], 'cover', picInfo.cover !== undefined ? picInfo.cover : (updateIndex === 0));
                this.$set(this.userPictures[updateIndex], 'coin', picInfo.coin || 0);
                this.$set(this.userPictures[updateIndex], 'isPay', picInfo.isPay !== undefined ? picInfo.isPay : false);
              } else {
                // 如果没有返回图片详细信息，只更新 URL（使用原始URL）
                this.$set(this.userPictures[updateIndex], 'url', serverUrl);
              }

              // 确保 URL 是完整的
              let finalUrl = serverUrl;
              if (serverUrl && !serverUrl.startsWith('http://') && !serverUrl.startsWith('https://') && !serverUrl.startsWith('data:')) {
                console.warn('图片URL可能是相对路径:', serverUrl);
              }

              // 直接更新 form.photos，不再进行 URL 验证（避免异步操作导致错误）
              if (this.form.photos[updateIndex] !== undefined) {
                console.log('更新 form.photos[' + updateIndex + '] 从', this.form.photos[updateIndex], '到', finalUrl);
                this.$set(this.form.photos, updateIndex, finalUrl);
              } else {
                console.error('form.photos[' + updateIndex + '] 不存在，无法更新');
              }

              // 如果更新的是第0张图片（封面），需要同时更新用户头像
              if (updateIndex === 0) {
                const avatarUrl = finalUrl; // 使用 finalUrl 而不是 serverUrl
                // 上传头像时，等待头像更新成功后才隐藏 loading
                // 注意：updateUserAvatar 内部的错误不会影响这里的成功状态
                this.updateUserAvatar(avatarUrl, isUploadingAvatar).catch((avatarError) => {
                  // 头像更新失败不影响图片上传成功的状态
                  console.error('头像更新失败，但图片已上传成功:', avatarError);
                  // 仍然隐藏 loading 和显示成功提示
                  if (isUploadingAvatar) {
                    hideLoading();
                    showCallToast('Photo uploaded successfully');
                  }
                });
              } else {
                // 普通图片上传成功，立即隐藏 loading
                hideLoading();
                showCallToast('Photo uploaded successfully');
              }
            } catch (error) {
              // 捕获所有可能的错误，但不影响上传成功的状态
              console.error('更新本地数据时出错（但图片已上传成功）:', error);
              // 仍然隐藏 loading 和显示成功提示
              if (updateIndex === 0 && isUploadingAvatar) {
                hideLoading();
                showCallToast('Photo uploaded successfully');
              } else if (updateIndex !== 0) {
                hideLoading();
                showCallToast('Photo uploaded successfully');
              }
            }
          } else {
            console.warn('updateIndex 无效:', updateIndex);
            // updateIndex 无效时，也要隐藏 loading
            hideLoading();
          }

          // 清除替换标记
          if (isReplacing) {
            this.replacingPhotoIndex = null;
          }

          // 强制更新视图
          this.$forceUpdate();
        } else {
          // 服务器返回失败状态
          console.error('服务器返回失败状态:', rsp);
          showCallToast('Failed to upload picture');
          hideLoading();
          if (isReplacing) {
            this.replacingPhotoIndex = null;
          }
        }
      }).catch((error) => {
        // 只有真正的网络错误或 API 调用失败才会进入这里
        console.error('图片上传失败（API 调用失败）:', error);
        showCallToast('Failed to upload picture');
        hideLoading(); // 上传失败，隐藏 loading
        // 清除替换标记
        if (isReplacing) {
          this.replacingPhotoIndex = null;
        }
      });
    },

    // 更新用户头像
    updateUserAvatar(avatarUrl, isUploadingAvatar = false) {
      if (!avatarUrl) {
        console.warn('头像URL为空，无法更新');
        if (isUploadingAvatar) {
          hideLoading(); // 如果是在上传头像过程中，隐藏 loading
        }
        return Promise.resolve(); // 返回 resolved Promise，避免影响调用链
      }

      return setUserInfo({ avatar: avatarUrl }).then((rsp) => {
        console.log('头像更新成功:', rsp);
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success)) {
          console.log('用户头像已更新');
          store.dispatch('GetInfo');
          // 如果是上传头像，等待头像更新成功后才隐藏 loading
          if (isUploadingAvatar) {
            hideLoading();
            showCallToast('Photo uploaded successfully');
          }
        } else {
          // 头像更新失败，也要隐藏 loading
          if (isUploadingAvatar) {
            hideLoading();
            showCallToast('Failed to update avatar');
          }
        }
      }).catch((error) => {
        console.error('头像更新失败:', error);
        // 头像更新失败，隐藏 loading
        if (isUploadingAvatar) {
          hideLoading();
          showCallToast('Failed to update avatar');
        }
        // 抛出错误，让调用者知道头像更新失败
        throw error;
      });
    },

    removePhoto(index) {
      // 如果点击的是第0张图片（封面），弹出选择照片弹窗进行替换
      if (index === 0) {
        this.replacingPhotoIndex = 0;
        this.openPhotoPicker();
        return;
      }

      // 其他位置的图片，先显示删除确认弹窗
      showDeletePhotoDialog({
        onConfirm: () => {
          this.doDeletePhoto(index);
        },
        onCancel: () => {
          // 取消删除，不做任何操作
        }
      });
    },

    // 执行删除图片的实际操作
    handleImageError(index, event) {
      // 图片加载失败时的处理
      const currentUrl = this.form.photos[index];
      console.error(`图片加载失败 (index: ${index}):`, currentUrl);
      
      // 如果是 data: URL（本地预览），不替换为占位图，保持预览
      if (currentUrl && currentUrl.startsWith('data:')) {
        console.log('保持 data: URL 预览，不替换为占位图');
        return;
      }
      
      // 如果是真实 URL 加载失败，检查是否是首次上传（URL 可能还未准备好）
      // 如果是首次上传，延迟重试，而不是立即替换为占位图
      if (currentUrl && (currentUrl.startsWith('http://') || currentUrl.startsWith('https://'))) {
        // 检查是否是最近更新的 URL（可能是首次上传）
        const retryCount = event.target.dataset.retryCount || 0;
        if (retryCount < 3) {
          // 重试加载，延迟递增
          const delay = (parseInt(retryCount) + 1) * 500; // 500ms, 1000ms, 1500ms
          console.log(`图片加载失败，${delay}ms 后重试 (第 ${parseInt(retryCount) + 1} 次)`);
          setTimeout(() => {
            event.target.dataset.retryCount = parseInt(retryCount) + 1;
            event.target.src = currentUrl + '?t=' + Date.now(); // 添加时间戳避免缓存
          }, delay);
          return;
        }
      }
      
      // 重试失败后，使用占位符
      console.log('图片加载重试失败，使用占位图');
      event.target.src = require('@/assets/image/ic-placeholder-avatar.png');
    },
    handleImageLoad(index) {
      // 图片加载成功
      console.log(`图片加载成功 (index: ${index}):`, this.form.photos[index]);
    },
    doDeletePhoto(index) {
      if (!this.userInfo || !this.userInfo.userId) {
        console.warn('用户信息不完整，无法删除图片');
        showCallToast('User information incomplete');
        return;
      }

      // 获取要删除的图片信息
      const pictureToRemove = this.userPictures[index];

      // 如果是新上传的图片（没有 id），直接从本地删除
      if (!pictureToRemove || !pictureToRemove.id) {
        this.form.photos.splice(index, 1);
        this.userPictures.splice(index, 1);
        return;
      }

      // 调用删除接口
      const removeData = {
        userId: this.userInfo.userId,
        ids: [pictureToRemove.id]
      };

      removePicture(removeData).then((rsp) => {
        console.log('图片删除成功:', rsp);
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success)) {
          // 删除成功，从本地数组中移除
          this.form.photos.splice(index, 1);
          this.userPictures.splice(index, 1);
          showCallToast('Photo deleted successfully');
        } else {
          showCallToast('Failed to delete photo');
        }
      }).catch((error) => {
        console.error('图片删除失败:', error);
        showCallToast('Failed to delete photo');
      });
    },

    // 处理昵称变化
    handleNicknameChange() {
      const newNickname = this.form.nickname.trim();
      if (newNickname && newNickname !== this.originalForm.nickname) {
        this.saveUserInfo({ nickname: newNickname });
        this.originalForm.nickname = newNickname;
      }
    },

    // 处理Bio变化
    handleBioChange() {
      const newBio = this.form.bio.trim();
      if (newBio !== this.originalForm.bio) {
        this.saveUserInfo({ signature: newBio });
        this.originalForm.bio = newBio;
      }
    },

    // 保存用户信息到服务器
    saveUserInfo(data) {
      setUserInfo(data).then((rsp) => {
        console.log('用户信息保存成功:', rsp);
        if (rsp && (rsp.code === 200 || rsp.code === 0 || rsp.success)) {
          // 可以显示成功提示
          // showCallToast('Saved successfully');
          store.dispatch('GetInfo');
        }
      }).catch((error) => {
        console.error('用户信息保存失败:', error);
        showCallToast('Failed to save');
      });
    },

    navigateTo(path) {
      // 根据路径进行路由跳转
      if (path === 'Coin Transactions') {
        this.$router.push({ name: 'CoinDetails' });
      } else if (path === 'Blacklist') {
        this.$router.push({ name: 'PageBlackList' });
      } else if (path === 'Delete Account') {
        this.$router.push({ name: 'PageDeleteAccount' });
      } else if (path === 'Clear Cache') {
        showCleanCacheDialog({
          onConfirm: () => {
            // 实现清理缓存的逻辑
            showCallToast('Cache cleared successfully');
            // 可以在这里添加实际的清理缓存代码
          },
          onCancel: () => {
            // 取消操作
          }
        });
      } else if (path === 'Contact Us') {
        showFeedbackDialog();
      } else if (path === 'Terms Of Service') {
        // 跳转到 WebView 页面，传入服务条款的 URL
        this.$router.push({
          name: 'PageWebView',
          query: {
            title: 'Terms Of Service',
            url: 'www.baidu.com' // 默认地址，可以根据实际需求修改
          }
        });
      } else if (path === 'Terms Of Use') {
        // 跳转到 WebView 页面，传入使用条款的 URL
        this.$router.push({
          name: 'PageWebView',
          query: {
            title: 'Terms Of Use',
            url: 'www.baidu.com' // 默认地址，可以根据实际需求修改
          }
        });
      } else {
      showCallToast(`Navigating to ${path}`)
        // 其他路径的跳转逻辑可以在这里添加
      }
    },

    logout() {
      showExitDialog({
        onConfirm: () => {
          // 实现登出逻辑
      showCallToast('Logging out')
      // this.$store.dispatch('user/logout')
        },
        onCancel: () => {
          // 取消登出，不需要做任何事
        }
      });
    },

    refreshNickname() {
      // 限制频繁调用：两次生成之间至少间隔 3 秒
      const now = Date.now();
      const timeSinceLastGenerate = now - this.lastNicknameGenerateTime;
      const minInterval = 3000; // 3秒

      if (timeSinceLastGenerate < minInterval) {
        const remainingTime = Math.ceil((minInterval - timeSinceLastGenerate) / 1000);
        showCallToast(`Please wait ${remainingTime} second${remainingTime > 1 ? 's' : ''} before generating again`);
        return;
      }

      // 更新最后生成时间
      this.lastNicknameGenerateTime = now;

      // 生成随机昵称
      const randomNickname = generateRandomNickname();
      this.form.nickname = randomNickname;

      // 保存到服务器
      this.saveUserInfo({ nickname: randomNickname });
      this.originalForm.nickname = randomNickname;
      showCallToast('Nickname generated successfully');
    },

    // 选择性别
    selectGender(gender) {
      // 如果点击的性别和当前性别相同，不需要调用接口
      if (gender === this.form.gender) {
        return;
      }

      // 如果选择女性，先显示提示弹窗
      if (gender === 1) {
        showTipsDialog({
          onConfirm: () => {
            // 确认后设置为女性
            this.form.gender = 1;
            this.saveUserInfo({ gender: 1 });
            this.originalForm.gender = 1;
          },
          onCancel: () => {
            // 取消后不调用接口，保持当前性别不变
            // 不修改 form.gender 和 originalForm.gender，也不调用 saveUserInfo
          }
        });
      } else {
        // 选择男性直接设置
        this.form.gender = 0;
        this.saveUserInfo({ gender: 0 });
        this.originalForm.gender = 0;
      }
    },

    // 打开照片选择弹窗
    openPhotoPicker() {
      if (this.form.photos.length >= 6) {
        showCallToast('Maximum 6 photos allowed');
        return;
      }

      showPhotoPickerDialog({
        onTakePhoto: () => {
          // 拍照模式：设置 capture 属性
          this.$refs.photoInput.setAttribute('capture', 'environment');
          this.$refs.photoInput.click();
        },
        onPhotoLibrary: () => {
          // 相册选择模式：移除 capture 属性
          this.$refs.photoInput.removeAttribute('capture');
          this.$refs.photoInput.click();
        },
        onCancel: () => {
          // 取消操作，不需要做任何事
        }
      });
    },

    // 处理照片选择
    handlePhotoSelected(event) {
      const file = event.target.files[0];
      if (file) {
        // 只允许图片文件
        const isImage = file.type.startsWith('image/');

        if (!isImage) {
          showCallToast('Please select an image file');
          this.$refs.photoInput.value = '';
          return;
        }

        // 检查文件大小（例如：最大 10MB）
        const maxSize = 10 * 1024 * 1024; // 10MB
        if (file.size > maxSize) {
          showCallToast('File size should be less than 10MB');
          this.$refs.photoInput.value = '';
          return;
        }

        // 先显示本地预览
        const reader = new FileReader();
        reader.onload = (e) => {
          const previewUrl = e.target.result;

          // 如果是替换图片（特别是第0张），直接替换预览；否则添加新图片
          if (this.replacingPhotoIndex !== null && this.replacingPhotoIndex !== undefined) {
            // 替换指定位置的图片
            this.$set(this.form.photos, this.replacingPhotoIndex, previewUrl);
            // 如果 userPictures 中对应位置存在，更新 url；否则创建新对象
            if (this.userPictures[this.replacingPhotoIndex]) {
              this.$set(this.userPictures[this.replacingPhotoIndex], 'url', previewUrl);
            } else {
              this.$set(this.userPictures, this.replacingPhotoIndex, {
                url: previewUrl,
                id: null,
                coin: 0,
                cover: this.replacingPhotoIndex === 0,
                type: 1,
                isPay: false
              });
            }
          } else {
            // 添加本地预览（临时显示）
            this.addPhoto(previewUrl, false);
          }
        };
        reader.onerror = () => {
          showCallToast('Failed to read file');
          this.$refs.photoInput.value = '';
          // 清除替换标记
          this.replacingPhotoIndex = null;
        };
        reader.readAsDataURL(file);

        // 上传文件到亚马逊S3
        this.uploadFileToAmazon(file);
      }
    },

    // 上传文件到亚马逊S3
    uploadFileToAmazon(file) {
      // 只允许图片，固定为 type 1
      const fileType = 1; // 1: 图片

      // 显示加载转子
      showLoading('Uploading...', false);

      updateFileOos(file, (progress, url) => {
        if (progress < 100) {
          // 上传中，可以显示进度
          console.log(`Upload progress: ${progress}%`);
        } else if (progress === 100 && url) {
          // 上传完成，获取到真实URL
          console.log('File uploaded successfully, URL:', url);

          // 延迟100毫秒后再处理，确保图片在S3上已准备好
          setTimeout(() => {
            // 确定目标索引：如果是替换图片，使用 replacingPhotoIndex；否则使用最后一张
            const targetIndex = this.replacingPhotoIndex !== null && this.replacingPhotoIndex !== undefined
              ? this.replacingPhotoIndex
              : (this.form.photos.length - 1);

            // 找到对应的预览图片，准备上传到服务器
            // 注意：不要在这里立即更新 form.photos 为S3 URL，等待服务器返回最终的URL后再更新
            if (this.form.photos.length > 0 && targetIndex >= 0 && targetIndex < this.form.photos.length) {
              const previewUrl = this.form.photos[targetIndex];

              // 如果是DataURL（本地预览），继续显示预览，等待服务器返回URL后再更新
              if (previewUrl && previewUrl.startsWith('data:')) {
                // 暂时只更新 userPictures 中的 url（用于服务器上传），form.photos 保持预览URL
                if (this.userPictures[targetIndex]) {
                  this.$set(this.userPictures[targetIndex], 'url', url);
                } else {
                  // 如果 userPictures 中对应位置不存在，创建新对象
                  this.$set(this.userPictures, targetIndex, {
                    url: url,
                    id: null,
                    coin: 0,
                    cover: targetIndex === 0,
                    type: fileType,
                    isPay: false
                  });
                }
                // 上传到服务器，传递 targetIndex 用于替换，服务器返回后会自动更新 form.photos
                this.uploadPictureToServer(url, fileType, targetIndex);
              } else {
                // 如果没有找到 data: URL，仍然调用上传到服务器的逻辑
                console.warn('预览URL不是data:格式，但继续上传到服务器');
                // 更新 userPictures 中的 url（用于服务器上传）
                if (this.userPictures[targetIndex]) {
                  this.$set(this.userPictures[targetIndex], 'url', url);
                } else {
                  this.$set(this.userPictures, targetIndex, {
                    url: url,
                    id: null,
                    coin: 0,
                    cover: targetIndex === 0,
                    type: fileType,
                    isPay: false
                  });
                }
                // 上传到服务器，服务器返回后会自动更新 form.photos
                this.uploadPictureToServer(url, fileType, targetIndex);
              }
            } else {
              console.error('无法找到目标索引或数组为空', { targetIndex, photosLength: this.form.photos.length });
              showCallToast('Failed to update photo URL');
              hideLoading(); // 出错时隐藏 loading
            }
          }, 100);
        } else if (progress === 0 || !url) {
          // 上传失败（progress === 0 或 url 为 null）
          console.error('File upload to S3 failed. Progress:', progress, 'URL:', url);
          showCallToast('Failed to upload file to S3');
          hideLoading(); // 上传失败，隐藏 loading
          // 上传失败，移除预览图片和 userPictures
          if (this.replacingPhotoIndex !== null && this.replacingPhotoIndex !== undefined) {
            // 如果是替换失败，恢复原图片（如果有的话）
            const targetIndex = this.replacingPhotoIndex;
            if (this.userPictures[targetIndex] && this.userPictures[targetIndex].url && !this.userPictures[targetIndex].url.startsWith('data:')) {
              this.$set(this.form.photos, targetIndex, this.userPictures[targetIndex].url);
            } else {
              // 如果没有原图片，移除预览
              if (this.form.photos[targetIndex] && this.form.photos[targetIndex].startsWith('data:')) {
                this.form.photos.splice(targetIndex, 1);
                if (this.userPictures.length > targetIndex) {
                  this.userPictures.splice(targetIndex, 1);
                }
              }
            }
            this.replacingPhotoIndex = null;
          } else if (this.form.photos.length > 0) {
            const lastIndex = this.form.photos.length - 1;
            const previewUrl = this.form.photos[lastIndex];
            if (previewUrl && previewUrl.startsWith('data:')) {
              this.form.photos.splice(lastIndex, 1);
              if (this.userPictures.length > lastIndex) {
                this.userPictures.splice(lastIndex, 1);
              }
            }
          }
        }
      }).catch((error) => {
        console.error('File upload failed:', error);
        showCallToast('Failed to upload file');
        hideLoading(); // 上传失败，隐藏 loading
        // 上传失败，移除预览图片和 userPictures
        if (this.replacingPhotoIndex !== null && this.replacingPhotoIndex !== undefined) {
          // 如果是替换失败，恢复原图片（如果有的话）
          const targetIndex = this.replacingPhotoIndex;
          if (this.userPictures[targetIndex] && this.userPictures[targetIndex].url && !this.userPictures[targetIndex].url.startsWith('data:')) {
            this.$set(this.form.photos, targetIndex, this.userPictures[targetIndex].url);
          } else {
            // 如果没有原图片，移除预览
            if (this.form.photos[targetIndex] && this.form.photos[targetIndex].startsWith('data:')) {
              this.form.photos.splice(targetIndex, 1);
              if (this.userPictures.length > targetIndex) {
                this.userPictures.splice(targetIndex, 1);
              }
            }
          }
          this.replacingPhotoIndex = null;
        } else if (this.form.photos.length > 0) {
          const lastIndex = this.form.photos.length - 1;
          const previewUrl = this.form.photos[lastIndex];
          if (previewUrl && previewUrl.startsWith('data:')) {
            this.form.photos.splice(lastIndex, 1);
            if (this.userPictures.length > lastIndex) {
              this.userPictures.splice(lastIndex, 1);
            }
          }
        }
      });
    },

    // 加载用户信息
    loadUserInfo() {
      console.log('=== EditUserInfo: 开始加载用户信息 ===');
      getWebUserDetail().then((rsp) => {
        console.log('=== API 请求成功 ===');
        console.log('API 响应数据:', rsp);

        // 根据 Request.js 的逻辑，成功的响应 code 应该是 200
        // 但有些 API 可能返回 code 0 表示成功，所以同时检查两种情况
        if (rsp && (rsp.code === 0 || rsp.code === 200 || rsp.success) && rsp.data) {
          const userData = rsp.data;

          // 从 userPictures 数组中提取 url 字段来填充 photos，同时保存完整的 userPictures 数据
          let photos = [];
          let userPictures = [];
          if (userData.userPictures && Array.isArray(userData.userPictures)) {
            userPictures = userData.userPictures;
            photos = userData.userPictures.map(pic => pic.url || '').filter(url => url);
          } else if (userData.photos && Array.isArray(userData.photos)) {
            // 如果没有 userPictures，使用 photos 作为后备
            photos = userData.photos;
            userPictures = userData.photos.map(url => ({ url, id: null })); // 创建临时对象，id 为 null
          }

          // 更新表单数据
          this.form = {
            nickname: userData.nickname || '',
            age: userData.age || '',
            gender: userData.gender || 0,
            bio: userData.bio || userData.signature || '',
            photos: photos
          };
          // 保存完整的 userPictures 数据（包含 id 等信息）
          this.userPictures = userPictures;
          // 更新原始表单数据，用于比较变化
          this.originalForm = {
            nickname: userData.nickname || '',
            gender: userData.gender || 0,
            bio: userData.bio || userData.signature || ''
          };
          console.log('更新后的表单数据:', this.form);
          console.log('从 userPictures 提取的 photos:', photos);
        } else {
          console.warn('API 返回的数据格式不符合预期:', rsp);
        }
      }).catch((error) => {
        console.error('=== API 请求失败 ===');
        console.error('错误信息:', error);
        // 错误已经被 Request.js 的拦截器处理并显示 toast，这里只记录日志
        // 如果 API 失败，保持使用 store 中的初始数据
      });
    },

    // 修复 iOS 键盘弹起/收起导致的界面异常
    fixIOSKeyboardIssue() {
      // 监听键盘收起事件
      const handleResize = () => {
        // 键盘收起时，恢复页面滚动位置
        if (document.activeElement && document.activeElement.tagName === 'TEXTAREA') {
          setTimeout(() => {
            window.scrollTo(0, 0);
            // 确保页面回到顶部
            const scrollContainer = document.querySelector('.m-page-content');
            if (scrollContainer) {
              scrollContainer.scrollTop = 0;
            }
          }, 100);
        }
      };

      // 监听窗口大小变化（键盘弹起/收起会触发）
      window.addEventListener('resize', handleResize);

      // 监听 textarea 失焦事件
      this.$nextTick(() => {
        const textareas = this.$el.querySelectorAll('textarea');
        textareas.forEach(textarea => {
          textarea.addEventListener('blur', () => {
            setTimeout(() => {
              window.scrollTo(0, 0);
              const scrollContainer = document.querySelector('.m-page-content');
              if (scrollContainer) {
                scrollContainer.scrollTop = 0;
              }
            }, 100);
          });
        });
      });

      // 组件销毁时移除监听器
      this.$once('hook:beforeDestroy', () => {
        window.removeEventListener('resize', handleResize);
      });
    }
  }
}
</script>

<style scoped lang="less">
/* 顶部安全区域适配 */
/deep/ .m-action-bar {
  padding-top: constant(safe-area-inset-top); /* iOS < 11.2，状态栏高度 */
  padding-top: env(safe-area-inset-top); /* 状态栏高度 */
}

.main {
  padding-top: env(safe-area-inset-top);
  padding-left: 20px;
  padding-right: 20px;
  border-bottom: 20px;
  box-sizing: border-box;
  background-color: #141414;
  min-height: 100%;
  color: white;
  /* 修复 iOS 键盘弹起时的布局问题 */
  position: relative;
  -webkit-overflow-scrolling: touch;
}

.section {
  margin-bottom: 30px;

  &-title {
    font-size: 20px;
    color: white;
    margin-bottom: 6px;
    padding-left: 12px;
  }
}

// Setting section 的底部间距由 setting-list 控制
.section:last-of-type {
  margin-bottom: 0;
}

/* Photos section header - 实现标题和数量垂直居中 */
.photos-section {
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
  }

  /* 图片数量 - 与section-title垂直居中 */
  .photo-count {
    font-size: 12px;
    color: #999;
    height: 18px;
    display: flex;
    align-items: center;
  }
}

/* Photos section */
.photos-container {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 30px;

  /* 无图片时，添加按钮样式不同 */
  &.no-photos {
    .add-slot {
      width: 69px;
      height: 135px;
    }

    .add-photo {
      background-color: #1e1e1e;

      .add-photo-btn {
        width: 48px;
        height: 48px;
        object-fit: contain;
      }
    }

    .photos-scroll-container {
      display: none;
    }
  }

  /* 添加按钮槽位 */
  .add-slot {
    width: 69px;
    height: 135px;
    flex-shrink: 0;
  }

  /* 图片槽位 */
  .image-slot {
    width: 105px;
    height: 135px;
    flex-shrink: 0;
  }

  /* 图片滚动容器 */
  .photos-scroll-container {
    display: flex;
    gap: 10px;
    overflow-x: auto;
    overflow-y: hidden;
    padding-bottom: 0px;
    flex-shrink: 1;

    /* 隐藏滚动条 */
    &::-webkit-scrollbar {
      display: none;
    }
    -ms-overflow-style: none;
    scrollbar-width: none;
  }

  /* 图片项 */
  .photo-item {
    width: 100%;
    height: 100%;
    position: relative;
    border-radius: 8px;
    overflow: hidden;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .photo-delete {
      position: absolute;
      top: 5px;
      right: 5px;
      width: 20px;
      height: 20px;
      background-color: rgba(0, 0, 0, 0.7);
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      cursor: pointer;
      z-index: 30; // 确保删除按钮在最上层
    }

    // 遮罩层（如果有）
    .premium-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      z-index: 20;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      backdrop-filter: blur(4px);
    }

    // 视频播放按钮（应该在遮罩层前面）
    .video-play-button {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 25; // 高于遮罩层的 z-index: 20，确保播放按钮在遮罩层前面
      pointer-events: none;

      img {
        width: 67px;
        height: 67px;
        object-fit: contain;
      }
    }
  }

  /* 添加按钮 */
  .add-photo {
    width: 100%;
    height: 100%;
    background-color: #1e1e1e;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;

    .add-photo-btn {
      width: 32px;
      height: 32px;
      object-fit: contain;
    }
  }
}

/* Form styles */
.form-item {
  margin-bottom: 25px;

  .form-label {
    font-size: 14px;
    color: #999;
    margin-bottom: 8px;
    display: block;
  }

  .custom-input,
  .custom-textarea {
    width: 100%;
    min-height: 100px;
    background-color: transparent;
    border: 3px solid #3a3a3a;
    border-radius: 20px;
    color: #FFFFFF;
    font-size: 16px;
    padding: 12px;
    box-sizing: border-box;
    outline: none;
    resize: none;
    font-family: inherit;
    line-height: 1.5;

    /* 修复占位文字颜色 */
    &::placeholder {
      color: #999999;
    }

    /* 修复 iOS 键盘问题 */
    -webkit-appearance: none;
    appearance: none;
  }

  /* Nickname container */
  .nickname-container {
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #282828;
    border-radius: 15px;
    height: 63px;
    position: relative;

    .nickname-input {
      flex: 1;
      background: transparent;
      border: none;
      outline: none;
      font-size: 16px;
      color: white;
      font-weight: 500;
      text-align: center;
      padding: 0;
      margin: 0;

      &::placeholder {
        color: #666;
      }
    }

    .refresh-icon {
      position: absolute;
      right: 20px;
      width: 20px;
      height: 20px;
      cursor: pointer;
      opacity: 0.7;
      transition: opacity 0.3s;

      &:hover {
        opacity: 1;
      }
    }
  }
}

/* Gender buttons */
.gender-buttons {
  display: flex;
  gap: 7px;

  .gender-btn {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0px;
    background-color: transparent;
    border: 2px solid #373737;
    border-radius: 15px;
    cursor: pointer;
    transition: all 0.3s;
    color: #999999;
    font-size: 20px;
    height: 60px;
    &.active {
      background-color: transparent;
      border-color: #FFFFFF;
      color: #FFFFFF;
    }
  }
}

/* Age selector */
.age-selector {
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #2a2a2a;
  border: 1px solid #3a3a3a;
  border-radius: 15px;
  height: 63px;
  cursor: pointer;
  position: relative;

  span {
    color: white;
  }

  .arrow-icon {
    position: absolute;
    right: 15px;
    width: 16px;
    height: 16px;
    opacity: 0.5;
  }
}

/* Setting list */
.setting-list {
  border-radius: 20px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: calc(32px + constant(safe-area-inset-bottom)) !important; /* iOS < 11.2 */
  margin-bottom: calc(32px + env(safe-area-inset-bottom)) !important;

  .setting-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 15px;
    background-color: #282828;
    border-radius: 20px;
    cursor: pointer;

    &.logout {
      color: #ff4d4f;
    }

    span {
      font-size: 16px;
      color: #999999;
    }

    .arrow-icon {
      width: 16px;
      height: 16px;
      opacity: 0.5;
    }
  }
}

/* Button style */
:deep(.el-button) {
  width: 100%;
  height: 44px;
  border-radius: 22px;
  background-color: @theme-color;
  border: none;
  font-size: 16px;

  &:hover,
  &:focus {
    background-color: darken(@theme-color, 10%);
  }
}
</style>
