<template>
  <m-page-wrap>
    <template #page-head-wrap>
      <m-action-bar :title="'Agora Demo'"/>
    </template>
    <template #page-content-wrap>
      <div class="page">
        <div class="form">
          <div class="field">
            <span class="label">App ID</span>
            <input class="input" v-model="appId" />
          </div>
          <div class="field">
            <span class="label">Channel</span>
            <input class="input" v-model="channel" />
          </div>
          <div class="field">
            <span class="label">Token</span>
            <input class="input" v-model="token" />
          </div>
          <div class="field">
            <span class="label">UID</span>
            <input class="input" v-model="uidText" placeholder="optional" />
          </div>
          <div class="actions">
            <button class="btn" :disabled="joining || joined" @click="join">Join</button>
            <button class="btn btn-danger" :disabled="joining || !joined" @click="leave">Leave</button>
          </div>
          <div class="env">
            <p>protocol: {{ envInfo.protocol }}</p>
            <p>secure: {{ envInfo.isSecureContext ? 'yes' : 'no' }}</p>
            <p>getUserMedia: {{ envInfo.hasGetUserMedia ? 'yes' : 'no' }}</p>
          </div>
          <p v-if="lastError" class="error">{{ lastError }}</p>
        </div>

        <div class="stage">
          <div class="players">
            <div class="local">
              <p class="title">Local</p>
              <div id="local-player" class="player"></div>
            </div>
            <div class="remote">
              <p class="title">Remote</p>
              <div class="remote-grid">
                <div v-for="u in remoteUsers" :key="u.uid" class="remote-item">
                  <p class="remote-title">{{ u.uid }}</p>
                  <div :id="'remote-player-' + u.uid" class="player"></div>
                </div>
                <div v-if="!remoteUsers.length" class="empty">No remote user</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </m-page-wrap>
</template>

<script>
import MActionBar from "@/components/MActionBar.vue";
import MPageWrap from "@/components/MPageWrap.vue";
import AgoraRTC from "agora-rtc-sdk-ng";
import {showCallToast} from "@/components/toast/callToast";

export default {
  name: 'PageAgoraDemo',
  components: {MPageWrap, MActionBar},
  data() {
    return {
      appId: '14b8ab695062411caa8821e00c982a76',
      token: '007eJxTYHDc5CJQWsx0/4C+foGHsn67+MZPDJ932dmnXN9RdmEr53IFBkOTJIvEJDNLUwMzIxNDw+TERAsLI8NUA4NkSwujRHMzg/zkzIZARobFDHuYGBkgEMRnZTA0AAIGBgCt2BwR',
      channel: '10000',
      uidText: '',
      lastError: '',
      envInfo: {
        protocol: '',
        isSecureContext: false,
        hasGetUserMedia: false
      },
      joining: false,
      joined: false,
      rtcClient: null,
      localTracks: {
        audioTrack: null,
        videoTrack: null
      },
      remoteUsers: []
    }
  },
  beforeDestroy() {
    this.leave();
  },
  mounted() {
    const protocol = (window && window.location && window.location.protocol) ? window.location.protocol : '';
    this.envInfo = {
      protocol,
      isSecureContext: !!(window && window.isSecureContext),
      hasGetUserMedia: this.hasGetUserMedia()
    };
  },
  methods: {
    hasGetUserMedia() {
      return !!(navigator && navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
    },
    formatJoinError(e) {
      if (!e) {
        return 'Join failed: unknown error';
      }
      const parts = [];
      if (e.name) {
        parts.push(e.name);
      }
      if (e.code !== undefined && e.code !== null && e.code !== '') {
        parts.push('code=' + e.code);
      }
      if (e.message) {
        parts.push(e.message);
      }
      if (typeof e === 'string') {
        parts.push(e);
      }
      if (!parts.length) {
        try {
          parts.push(JSON.stringify(e));
        } catch (err) {
          void err;
          parts.push(String(e));
        }
      }
      return 'Join failed: ' + parts.join(' | ');
    },
    async join() {
      if (this.joining || this.joined) {
        return;
      }
      this.joining = true;
      this.lastError = '';
      let joined = false;
      try {
        const appId = (this.appId || '').trim();
        const channel = (this.channel || '').trim();
        const token = (this.token || '').trim();
        const uidRaw = (this.uidText || '').trim();

        this.appId = appId;
        this.channel = channel;
        this.token = token;
        this.uidText = uidRaw;

        if (!/^[0-9a-fA-F]{32}$/.test(appId)) {
          this.lastError = 'Join failed: invalid App ID (should be 32 hex chars)';
          return;
        }
        if (!channel) {
          this.lastError = 'Join failed: channel is required';
          return;
        }
        if (token && token.length < 100) {
          this.lastError = 'Join failed: token looks incomplete (too short)';
          return;
        }

        AgoraRTC.checkSystemRequirements();

        const client = AgoraRTC.createClient({mode: "rtc", codec: "vp8"});
        this.rtcClient = client;

        client.on("user-published", this.onUserPublished);
        client.on("user-unpublished", this.onUserUnpublished);
        client.on("user-left", this.onUserLeft);

        const uid = uidRaw ? parseInt(uidRaw, 10) : null;
        if (uidRaw && (uid === null || Number.isNaN(uid))) {
          this.lastError = 'Join failed: UID must be a number';
          return;
        }

        await client.join(appId, channel, token || null, uid);
        joined = true;
        this.joined = true;

        if (!this.hasGetUserMedia()) {
          const hint = this.envInfo.isSecureContext ? 'Use a newer iOS/WebView.' : 'Use HTTPS/localhost.';
          this.lastError = 'Joined, but this browser has no getUserMedia (receive-only mode). ' + hint;
          return;
        }

        try {
          this.localTracks.audioTrack = await AgoraRTC.createMicrophoneAudioTrack({
            encoderConfig: "music_standard"
          });
          this.localTracks.videoTrack = await AgoraRTC.createCameraVideoTrack({
            encoderConfig: "720p_1"
          });

          this.localTracks.videoTrack.play('local-player');
          await client.publish([this.localTracks.audioTrack, this.localTracks.videoTrack]);
        } catch (e) {
          const errText = this.formatJoinError(e);
          this.lastError = errText.replace('Join failed:', 'Joined, but failed to access camera/mic:');
          console.error(this.lastError, e);
          showCallToast && showCallToast(this.lastError);
        }
      } catch (e) {
        const errText = this.formatJoinError(e);
        this.lastError = errText;
        console.error(errText, e);
        showCallToast && showCallToast(errText);
        if (!joined) {
          await this.leave();
        }
        return;
      } finally {
        this.joining = false;
      }
    },
    async leave() {
      this.joined = false;
      this.remoteUsers = [];

      const client = this.rtcClient;
      this.rtcClient = null;

      try {
        if (this.localTracks.videoTrack) {
          this.localTracks.videoTrack.stop();
          this.localTracks.videoTrack.close();
        }
        if (this.localTracks.audioTrack) {
          this.localTracks.audioTrack.stop();
          this.localTracks.audioTrack.close();
        }
      } catch (e) {
        void e;
      }
      this.localTracks.audioTrack = null;
      this.localTracks.videoTrack = null;

      try {
        if (client) {
          client.off("user-published", this.onUserPublished);
          client.off("user-unpublished", this.onUserUnpublished);
          client.off("user-left", this.onUserLeft);
          await client.leave();
        }
      } catch (e) {
        void e;
      }
    },
    upsertRemoteUser(uid) {
      const exists = this.remoteUsers.some((u) => u.uid === uid);
      if (!exists) {
        this.remoteUsers = [...this.remoteUsers, {uid}];
      }
    },
    removeRemoteUser(uid) {
      this.remoteUsers = this.remoteUsers.filter((u) => u.uid !== uid);
    },
    async onUserPublished(user, mediaType) {
      if (!this.rtcClient) {
        return;
      }
      await this.rtcClient.subscribe(user, mediaType);

      if (mediaType === "video") {
        this.upsertRemoteUser(user.uid);
        this.$nextTick(() => {
          if (user.videoTrack) {
            user.videoTrack.play('remote-player-' + user.uid);
          }
        });
      }
      if (mediaType === "audio") {
        if (user.audioTrack) {
          user.audioTrack.play();
        }
      }
    },
    onUserUnpublished(user, mediaType) {
      if (mediaType === "video") {
        this.removeRemoteUser(user.uid);
      }
    },
    onUserLeft(user) {
      this.removeRemoteUser(user.uid);
    }
  }
}
</script>

<style scoped lang="less">
.page {
  height: 100%;
  box-sizing: border-box;
  padding: 12px;
}

.form {
  background: rgba(255, 255, 255, 0.06);
  border-radius: 12px;
  padding: 12px;
}

.field {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.label {
  width: 70px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}

.input {
  flex: 1;
  height: 34px;
  padding: 0 10px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(0, 0, 0, 0.25);
  color: rgba(255, 255, 255, 0.92);
  outline: none;
  box-sizing: border-box;
}

.actions {
  display: flex;
  gap: 10px;
  margin-top: 6px;
}

.env {
  margin-top: 10px;
  color: rgba(255, 255, 255, 0.55);
  font-size: 12px;
  line-height: 16px;
}

.error {
  margin-top: 10px;
  color: rgba(255, 92, 60, 0.95);
  font-size: 12px;
  line-height: 16px;
  word-break: break-all;
}

.btn {
  flex: 1;
  height: 38px;
  border-radius: 10px;
  border: none;
  color: #2b2b2b;
  font-weight: 700;
  background: linear-gradient(135deg, #F6C084 0%, #FADEBF 100%);
}

.btn:disabled {
  opacity: 0.55;
}

.btn-danger {
  background: #ff3b30;
  color: #ffffff;
}

.stage {
  margin-top: 12px;
  height: calc(100% - 170px);
}

.players {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  height: 100%;
}

.title {
  color: rgba(255, 255, 255, 0.82);
  font-weight: 700;
  margin-bottom: 8px;
}

.player {
  width: 100%;
  height: 240px;
  background: #000;
  border-radius: 12px;
  overflow: hidden;
}

.remote-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
}

.remote-item {
  width: 100%;
}

.remote-title {
  color: rgba(255, 255, 255, 0.55);
  font-size: 12px;
  margin-bottom: 6px;
}

.empty {
  color: rgba(255, 255, 255, 0.45);
  text-align: center;
  padding: 18px 0;
}
</style>
