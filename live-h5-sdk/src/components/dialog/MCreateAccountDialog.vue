<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'create-account-dialog'">
    <div class="dialog-content">
      <div class="dialog-header">Create Your Account</div>

      <div class="form-group">
        <div class="label">Nickname</div>
        <div class="input-field">
          <span>{{ nickname }}</span>
          <i class="el-icon-refresh" @click="refreshNickname"></i>
        </div>
      </div>

      <div class="form-group">
        <div class="label">Age</div>
        <div class="input-field" @click="openAgePicker">
          <span>{{ age }}</span>
          <i class="el-icon-arrow-right"></i>
        </div>
      </div>

      <div class="form-group">
        <div class="label">Gender</div>
        <div class="gender-selector">
          <div
            class="gender-option"
            :class="{ active: gender === 1 }"
            @click="gender = 1"
          >
            Man
          </div>
          <div
            class="gender-option"
            :class="{ active: gender === 2 }"
            @click="gender = 2"
          >
            Woman
          </div>
        </div>
      </div>

      <div class="submit-btn" @click="confirm">
        Submit
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";
import { showAgePickerDialog } from "@/components/dialog/index.js";
import { setUserInfo } from "@/api/sdk/user";

export default {
  name: "MCreateAccountDialog",
  components: { MBottomDialog },
  props: {
    onConfirm: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    return {
      nickname: "Johnson Roy",
      age: 30,
      gender: 1 // 1: Man, 2: Woman
    };
  },
  methods: {
    async confirm() {
      try {
        // 调用接口保存用户信息
        const res = await setUserInfo({
          nickname: this.nickname,
          age: this.age,
          gender: this.gender
        });
        console.log(res);
        if (res && (res.code === 200 || res.code === 0 || res.success)) {
          // this.$r
        }
        // 保存成功后执行回调
        // if (this.onConfirm) {
        //   this.onConfirm(true);
        // }
        this.$refs.bottomDialog.closeDialog();
      } catch (error) {
        console.error('保存用户信息失败:', error);
      }
    },
    refreshNickname() {
      // Mock refresh logic
      const names = ["Johnson Roy", "David Smith", "Mike Jones", "Chris Brown"];
      const randomName = names[Math.floor(Math.random() * names.length)];
      this.nickname = randomName;
    },
    openAgePicker() {
      showAgePickerDialog(this.age, (newAge) => {
        this.age = newAge;
      });
    }
  }
}
</script>

<style scoped lang="less">
.dialog-content {
  background: #1A1A1A;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 20px;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

.dialog-header {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 24px;
}

.form-group {
  margin-bottom: 20px;

  .label {
    font-size: 14px;
    color: #888;
    margin-bottom: 8px;
  }
}

.input-field {
  background: #2C2C2C;
  border-radius: 12px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
  font-size: 16px;
  position: relative;

  i {
    color: #888;
    font-size: 18px;
    position: absolute;
    right: 16px;
  }
}

.gender-selector {
  display: flex;
  gap: 12px;

  .gender-option {
    flex: 1;
    height: 50px;
    border-radius: 12px;
    border: 1px solid #444;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    color: #888;
    background: transparent;
    transition: all 0.2s;

    &.active {
      border-color: #FFD700; /* Gold/Yellow border */
      color: #FFD700;
      background: rgba(255, 215, 0, 0.1);
    }
  }
}

.submit-btn {
  background: white;
  color: black;
  height: 50px;
  border-radius: 25px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 600;
  margin-top: 30px;
  margin-bottom: 10px;
}
</style>
