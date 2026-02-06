<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar/>
      <div style="height: 30px"/>
      <m-switch-tab :tabs="tabs" :action="actionName" :avg-width="true" @change="(tab)=>{actionName=tab.title}"/>
    </template>
    <template #page-content-wrap>
      <div style="margin-top: 80px;">
        <m-list v-show="actionName==='Follower'" :url="'/status/followList'">
          <template v-slot:m-list-item="{items}">
            <div class="list-items" v-for="(it,index) in items" :key="index">
              <img :src="it.headImage"/>
              <div>
                <p>{{ it.nickname }}</p>
                <span>ID:{{ it.userId }}</span>
              </div>
              <img :src="followIcon[it['followStatus']]" @click="clickFollow(it)"/>
            </div>
          </template>
        </m-list>
        <m-list v-show="actionName==='Following'" :url="'/status/followedList'">
          <template v-slot:m-list-item="{items}">
            <div class="list-items" v-for="(it,index) in items" :key="index">
              <img :src="it.headImage"/>
              <div>
                <p>{{ it.nickname }}</p>
                <span>ID:{{ it.userId }}</span>
              </div>
              <img :src="followIcon[it['followStatus']]" @click="clickFollow(it)"/>
            </div>
          </template>
        </m-list>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>

import MSwitchTab from "@/components/MSwitchTab.vue";
import MList from "@/components/MList.vue";
import {followStatus} from "@/api/sdk/user";
import {followIcon} from "@/utils/Constant";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'FavouriteList',
  components: {MList, MSwitchTab},
  data() {
    const actionName = 'Follower'
    return {
      actionName: actionName,
      tabs: [
        {
          title: actionName
        },
        {
          title: 'Following'
        }
      ],
      followIcon: followIcon
    }
  },
  methods: {
    async clickFollow(it) {
      const userId = it.userId;
      if (!userId) {
        showCallToast('User ID not found');
        return;
      }

      try {
        // 判断当前是否已关注：followStatus !== 1 表示已关注
        const currentFollowStatus = it.followStatus || 1;
        const isCurrentlyFollowed = currentFollowStatus !== 1;
        const follow = !isCurrentlyFollowed; // 如果当前已关注，则取消关注；如果未关注，则关注

        const {success, data} = await followStatus(userId, follow);
        if (success) {
          // 更新关注状态：1 表示未关注，其他值表示已关注
          it.followStatus = follow ? 2 : 1;
          showCallToast(follow ? 'Liked' : 'Unliked');
        } else {
          showCallToast('Operation failed');
        }
      } catch (error) {
        console.error('Follow/Unfollow error:', error);
        showCallToast('Operation failed');
      }
    }
  }
}
</script>

<style scoped lang="less">

.list-items {
  margin-top: 35px;
  display: flex;
  padding: 0 20px;

  img:first-child {
    width: 60px;
    height: 60px;
    border-radius: 30px;
    border: @theme-color solid 1px;
  }

  div {
    flex: 1;
    margin-left: 20px;

    p {
      margin-top: 10px;
      color: white;
    }

    span {
      margin-top: 5px;
      display: block;
      color: #777777;
    }
  }

  img:last-child {
    width: 30px;
    height: 30px;
  }
}

.content {
  margin-top: 40px;
}

</style>
