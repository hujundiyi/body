<template>
  <m-page-wrap :show-action-bar="false">
    <template #page-content-wrap>
      <div class="main">
        <div class="head">
          <swiper class="banner" :options="swiperOption">
            <swiper-slide v-for="(item,index) in info.picList" :key="index">
              <img style="width: 100%" :src="item.url" :data-preview="item.url"/>
            </swiper-slide>
            <div class="swiper-pagination" slot="pagination"></div>
          </swiper>
          <div class="action-bar">
            <m-action-bar :title="''">
              <template #right>
                <page-action-bar-more :user-id="userId"/>
              </template>
            </m-action-bar>
          </div>
          <div class="bottom">
            <div class="content">
              <div class="left">
                <div class="nickname">
                  <span>{{ info.nickname }},{{ info.age }}</span>
                </div>
                <div class="split-bar"></div>
                <div class="user-id">
                  ID:{{ info.userId }}
                </div>
              </div>
              <div class="right">
                <user-online :size="'max'" :info="{online:info.status,statusDesc:info.statusDesc}"/>
                <div class="split-bar"></div>
                <call-coin size="max" :coin="info.price"/>
              </div>
            </div>
          </div>
        </div>
        <div class="bottom-warp">
          <div class="content" style="position: relative">
            <div class="user-sign">
              <img src="@/assets/image/sdk/ic-user-sign-icon.png"/>
              <span>{{ info.signature || 'A wonderful day .' }}</span>
            </div>
            <m-list ref="refList" url="video/getVideoList" :get-params="()=>{return {userId:$route.query.userId}}">
              <template v-slot:m-list-item="{items}">
                <div class="list-items" v-for="(it,index) in items" :key="index">
                  <img class="cover" :src="it.coverUrl" @click="playClick(it)"/>
                  <div v-if="it.buyId!==0||it.videoPrice===0" class="like-wrap" @click="onLikeClick(it)">
                    <img
                      :src="require('@/assets/image/sdk/'+(it.praiseId===0?'ic-video-un-like.png':'ic-video-like.png'))"/>
                    <span>{{ it.praiseNum }}</span>
                  </div>
                  <div class="un-lock-mask" v-if="it.buyId===0&&it.videoPrice>0">
                    <p>
                      <img src="@/assets/image/sdk/ic-coin-min.png"/>
                      <span>{{ it.videoPrice }}</span>
                    </p>
                    <span class="btn-unlock" @click="onLockClick(it)">Unlock</span>
                  </div>
                </div>
              </template>
            </m-list>
          </div>
        </div>
        <footer class="footer">
          <div>
            <div class="follow" @click="clickFollow">
              <img :src="followIcon[info.followStatus]"/>
            </div>
            <m-button class="call" width="auto" @click="requestCall(info.userId)">
              <img src="@/assets/image/sdk/ic-to-call.png"/>
              <span>Call Me</span>
            </m-button>
            <div class="chat" @click="()=>{openChat(info.userId)}">
              <img src="@/assets/image/sdk/ic-to-chat.png"/>
            </div>
          </div>
        </footer>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import 'swiper/dist/css/swiper.css'
import {swiper, swiperSlide} from 'vue-awesome-swiper'
import {getUserInfo} from "@/api";
import UserOnline from "@/components/sdk/UserOnline.vue";
import CallCoin from "@/components/sdk/CallCoin.vue";
import {followIcon} from "@/utils/Constant";
import {followStatus} from "@/api/sdk/user";
import MList from "@/components/MList.vue";
import {videoBuy, videoPraise} from "@/api/sdk/video";
import {openChat, requestCall} from "@/utils/PageUtils";
import PageActionBarMore from "@/components/sdk/PageActionBarMore.vue";
import {showCallToast} from "@/components/toast/callToast";


export default {
  name: 'UserInformation',
  components: {PageActionBarMore, MList, CallCoin, UserOnline, swiper, swiperSlide},
  data() {
    return {
      userId: null,
      info: {},
      followIcon,
      swiperOption: {
        pagination: '.swiper-pagination',
        //点击事件
        on: {
          click: (e) => {
            console.log(e)
          }
        },
        // 自动播放
        autoplay: {
          delay: 10000,
          disableOnInteraction: false
        },
        // 循环
        loop: true,
        // 轮播图左右间距
        spaceBetween: 0,
        // 一屏显示的slide个数，图片宽度
        // 居中的slide是否标记为active，默认是最左active,这样样式即可生效
        centeredSlides: true,
        // 点击的slide会居中
        slideToClickedSlide: true
      }
    }
  },
  mounted() {
    this.userId = parseInt(this.$route.query.userId || null);
    this.loadData()
  },
  methods: {
    requestCall,
    openChat,
    loadData() {
      getUserInfo(this.userId).then((rsp) => {
        this.info = rsp.data;
      })
    },
    async clickFollow() {
      const userId = this.info.userId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        // 判断当前是否已关注：followStatus !== 1 表示已关注
        const currentFollowStatus = this.info.followStatus || 1;
        const isCurrentlyFollowed = currentFollowStatus !== 1;
        const follow = !isCurrentlyFollowed; // 如果当前已关注，则取消关注；如果未关注，则关注

        const {success, data} = await followStatus(userId, follow);
        if (success) {
          // 更新关注状态：1 表示未关注，其他值表示已关注
          this.info.followStatus = follow ? 2 : 1;
          showCallToast(follow ? 'Liked' : 'Unliked');
        } else {
          showCallToast('Operation failed');
        }
      } catch (error) {
        console.error('Follow/Unfollow error:', error);
        showCallToast('Operation failed');
      }
    },
    onLikeClick(it) {
      videoPraise(it.id).then((rsp) => {
        if (rsp.success) {
          this.$refs.refList.refresh();
        }
      })
    },
    onLockClick(it) {
      this.$showHintDialog('Unlock or not ?', (isOk) => {
        if (isOk) {
          videoBuy(it.id).then((rsp) => {
            if (rsp.success) {
              showCallToast('Success .');
              this.$refs.refList.refresh();
            }
          })
        }
        return true
      })
    },
    playClick(it) {
      if (it.buyId >= 0) {
        this.$router.push({name: 'PageVideoPlay', query: {params: JSON.stringify(it)}});
      }
    }
  },
}
</script>

<style scoped lang="less">
.head {
  position: relative;
  max-height: 350px;
  overflow: hidden;

  .action-bar {
    position: fixed;
    width: 100%;
    top: 0;
    z-index: 999;
  }

  .bottom {
    position: absolute;
    z-index: 1;
    bottom: 0;
    width: 100%;

    .content {
      position: relative;
      padding: 15px 15px 30px 15px;

      .left {
        display: inline-block;
        width: 50%;

        .nickname {
          font-size: @max-big-text-size;
          font-weight: bold;
        }

        .user-id {
          color: #dedede;
        }
      }

      .split-bar {
        height: 8px;
      }

      .right {
        display: inline-block;
        width: 50%;
        text-align: right;
      }
    }
  }

}

.bottom-warp {
  background: @theme-bg-color;
  border-radius: 10px;
  margin-top: -20px;
  width: 100%;
  z-index: 111;
  position: fixed;

  .content {
    padding: 20px;
  }

  .user-sign {
    margin-bottom: 10px;

    img {
      width: 24px;
      vertical-align: middle;
      margin-right: 10px;
    }

    span {
      display: inline-block;
    }
  }
}

.list-items {
  display: inline-block;
  height: 160px;
  width: 32%;
  margin-right: 1%;
  position: relative;
  border-radius: 4px;


  .cover {
    width: 100%;
    height: 100%
  }

  .like-wrap {
    display: inline-block;
    position: absolute;
    top: 10px;
    left: 10px;
    background: rgba(255, 255, 255, 0.65);
    height: 22px;
    border-radius: 11px;
    color: white;
    box-sizing: border-box;
    text-align: center;
    padding: 0 10px;

    img {
      width: 16px;
      height: 16px;
      vertical-align: middle;
    }

    span {
      display: inline-block;
      margin-left: 5px;
    }

  }

  .un-lock-mask {
    position: absolute;
    width: 100%;
    height: 100%;
    left: 0;
    right: 0;
    bottom: 0;
    top: 0;
    background: rgba(255, 255, 255, 0.24);
    text-align: center;

    p {
      width: 100%;
      margin-top: 80px;

      img {
        margin-right: 5px;
        vertical-align: middle;
      }

      span {
        vertical-align: middle;
      }
    }

    .btn-unlock {
      display: inline-block;
      height: 25px;
      text-align: center;
      line-height: 25px;
      border-radius: 12.5px;
      margin-top: 5px;
      background: linear-gradient(135deg, #F6C084 0%, #FADEBF 100%);
      width: 78%;
      color: #333333;
    }

  }
}

.footer {
  position: fixed;
  bottom: 0;
  width: 100%;
  z-index: 999;

  div {
    height: 80px;
    align-items: center;
    align-self: center;
    justify-content: center;
    display: flex;
    position: relative;
  }

  .call {
    flex: 1;
    background: linear-gradient(45deg, #FF3333 0%, #F6C084 100%);

    img {
      width: 30px;
      vertical-align: middle;
      margin-right: 15px;
    }

    span {
      display: inline-block;
      vertical-align: middle;
      color: white;
    }
  }

  .follow, .chat {
    display: inline-block;
    width: 50px;
    height: 50px;
    text-align: center;
    line-height: 50px;
    margin-left: 20px;
    margin-right: 20px;
    border-radius: 25px;
    background: @theme-select-text-color;

    img {
      width: 30px;
      height: 30px;
      vertical-align: middle;
    }
  }

}
</style>
install
