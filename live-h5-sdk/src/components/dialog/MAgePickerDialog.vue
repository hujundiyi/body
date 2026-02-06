<template>
  <m-bottom-dialog ref="bottomDialog" :dialog-class="'age-picker-dialog'" :enable-swipe-close="false">
    <div class="dialog-content">
      <div class="dialog-header">What's your age?</div>
      
      <div class="picker-container">
        <div class="highlight-bar"></div>
        <div class="scroll-list" ref="scrollList" @scroll="onScroll">
          <div class="spacer"></div>
          <div 
            v-for="age in ages" 
            :key="age" 
            class="picker-item"
            :class="{ active: currentAge === age }"
            @click="scrollToAge(age)"
          >
            {{ age }}
          </div>
          <div class="spacer"></div>
        </div>
      </div>

      <div class="submit-btn" @click="confirm">
        Select
      </div>
    </div>
    <div class="bottom-spacer"></div>
  </m-bottom-dialog>
</template>

<script>
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MAgePickerDialog",
  components: { MBottomDialog },
  props: {
    initialAge: {
      type: Number,
      default: 25
    },
    onConfirm: {
      type: Function,
      default: () => {}
    }
  },
  data() {
    return {
      ages: Array.from({ length: 83 }, (_, i) => i + 18), // 18 to 100
      currentAge: 25,
      itemHeight: 50
    };
  },
  mounted() {
    this.currentAge = this.initialAge;
    this.$nextTick(() => {
      this.scrollToAge(this.currentAge, false);
    });
  },
  methods: {
    onScroll() {
      const scrollTop = this.$refs.scrollList.scrollTop;
      const index = Math.round(scrollTop / this.itemHeight);
      if (index >= 0 && index < this.ages.length) {
        this.currentAge = this.ages[index];
      }
    },
    scrollToAge(age, smooth = true) {
      this.currentAge = age;
      const index = this.ages.indexOf(age);
      if (index !== -1 && this.$refs.scrollList) {
        this.$refs.scrollList.scrollTo({
          top: index * this.itemHeight,
          behavior: smooth ? 'smooth' : 'auto'
        });
      }
    },
    confirm() {
      if (this.onConfirm) {
        this.onConfirm(this.currentAge);
      }
      this.$refs.bottomDialog.closeDialog();
    }
  }
}
</script>

<style scoped lang="less">
//.dialog-content {
//  background: #1A1A1A;
//  border-top-left-radius: 20px;
//  border-top-right-radius: 20px;
//  padding: 20px;
//  color: white;
//  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
//  text-align: center;
//}
.dialog-content {
  background: #282828;
  border-radius: 30px;
  padding: 20px;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  text-align: center;
  margin: 0 20px;
  box-sizing: border-box;
  overflow: hidden;
  position: relative;
  z-index: 1;
}

.bottom-spacer {
  width: 100%;
  height: calc(15px + constant(safe-area-inset-bottom)); /* iOS < 11.2，底部间距 15px + 安全区域 */
  height: calc(15px + env(safe-area-inset-bottom)); /* 底部间距 15px + 安全区域 */
  flex-shrink: 0;
  background: transparent;
}
.dialog-header {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 24px;
}

.picker-container {
  position: relative;
  height: 250px;
  overflow: hidden;
  margin-bottom: 20px;
  /* Mask effects for top and bottom fade */
  -webkit-mask-image: linear-gradient(to bottom, transparent, black 20%, black 80%, transparent);
  mask-image: linear-gradient(to bottom, transparent, black 20%, black 80%, transparent);
}

.highlight-bar {
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 50px;
  margin-top: -25px;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  pointer-events: none;
  z-index: 10;
}

.scroll-list {
  height: 100%;
  overflow-y: auto;
  scroll-snap-type: y mandatory;
  -webkit-overflow-scrolling: touch;
  
  /* Hide scrollbar */
  &::-webkit-scrollbar {
    display: none;
  }
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.picker-item {
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #666;
  scroll-snap-align: center;
  transition: all 0.2s;
  
  &.active {
    color: white;
    font-size: 24px;
    font-weight: 600;
  }
}

.spacer {
  height: 100px; /* (Container Height - Item Height) / 2 = (250 - 50) / 2 = 100 */
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
  margin-top: 10px;
  margin-bottom: 10px;
}
</style>
