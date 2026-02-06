<template>
  <m-bottom-dialog ref="bottomDialog">
    <div class="gift-dialog">
      <div class="gift-dialog-header">
        <h2 class="gift-dialog-title">Gifts</h2>
      </div>
      
      <div class="gift-dialog-content">
        <div class="gift-grid">
          <div 
            v-for="(gift, index) in giftList" 
            :key="gift.id || index"
            :class="['gift-item', selectedGift && selectedGift.id === gift.id ? 'gift-item-selected' : '']"
            @click="selectGift(gift)"
          >
            <img :src="gift.image" :alt="gift.name" class="gift-image"/>
            <p class="gift-price">{{ gift.coin }} Coins</p>
          </div>
        </div>
      </div>
      
      <div class="gift-dialog-footer">
        <div class="footer-left" @click="showRechargeDialog">
          <img src="@/assets/image/message/ic-message-coin-icon.png" alt="" class="coin-icon"/>
          <span class="coin-balance">{{ userCoin }}</span>
          <span class="coin-more">></span>
        </div>
        
        <div class="footer-center">
          <button class="quantity-btn" @click="decreaseQuantity" :disabled="quantity <= 1">-</button>
          <input type="number" v-model.number="quantity" class="quantity-input" :min="1" @input="validateQuantity"/>
          <button class="quantity-btn" @click="increaseQuantity">+</button>
        </div>
        
        <button class="send-btn" @click="handleSend">Send</button>
      </div>
    </div>
  </m-bottom-dialog>
</template>

<script>
import { getGiftList, sendGift } from "@/api/sdk/call";
import { showRechargeDialog } from "@/components/dialog/index";
import MBottomDialog from "@/components/dialog/MBottomDialog.vue";

export default {
  name: "MGiftDialog",
  components: { MBottomDialog },
  props: {
    userId: {
      type: [String, Number],
      default: null
    },
    onSend: {
      type: Function,
      default: null
    }
  },
  data() {
    return {
      giftList: [],
      selectedGift: null,
      quantity: 1
    }
  },
  computed: {
    userInfo() {
      return this.$store.state.user.loginUserInfo || {}
    },
    userCoin() {
      return this.$store.state.user.loginUserInfo.coinBalance || 0
    },
    totalCost() {
      if (!this.selectedGift) return 0
      return this.selectedGift.price * this.quantity
    }
  },
  mounted() {
    this.loadGiftList()
  },
  methods: {
    showRechargeDialog,
    loadGiftList() {
      getGiftList().then(({ data }) => {
        this.giftList = data || []
        // 默认选中第三个礼物
        this.selectDefaultGift()
      }).catch((error) => {
        // 默认选中第三个礼物
        this.selectDefaultGift()
      })
    },
    selectDefaultGift() {
      // 默认选中第三个礼物（索引为2）
      if (this.giftList && this.giftList.length >= 3) {
        this.selectedGift = this.giftList[2]
        this.quantity = 1
      }
    },
    selectGift(gift) {
      this.selectedGift = gift
      this.quantity = 1
    },
    increaseQuantity() {
      this.quantity++
      this.validateQuantity()
    },
    decreaseQuantity() {
      if (this.quantity > 1) {
        this.quantity--
      }
    },
    validateQuantity() {
      if (this.quantity < 1) {
        this.quantity = 1
      }
      // 检查是否有足够的金币
      if (this.totalCost > this.userCoin) {
        // 可以提示用户金币不足
      }
    },
    async handleSend() {
      if (!this.selectedGift) {
        return
      }
      
      if (this.totalCost > this.userCoin) {
        // 金币不足，显示充值对话框
        showRechargeDialog()
        return
      }
      
      if (!this.userId) {
        console.error('User ID is required')
        return
      }

      //礼物数量 this.quantity
      if (this.onSend) {
        // 创建包含礼物数量的礼物对象
        const giftWithQuantity = {
          ...this.selectedGift,
          giftNum: this.quantity
        };
        this.onSend(giftWithQuantity);
      }
    }
  }
}
</script>

<style scoped lang="less">
.gift-dialog {
  background: #282828;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  min-height: 400px;
  display: flex;
  flex-direction: column;
}

.gift-dialog-header {
  padding: 20px 0 15px 0;
}

.gift-dialog-title {
  margin: 0;
  margin-left: 20px;
  font-size: 24px;
  font-weight: bold;
  color: #ffffff;
  text-align: left;
}

.gift-dialog-content {
  flex: 1;
  padding: 0 20px 20px 20px;
  overflow-y: auto;
  max-height: 400px;
}

.gift-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 15px;
}

.gift-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  transition: transform 0.2s;
  padding: 2px;
  border-radius: 15px;
  box-sizing: border-box;
  
  &:active {
    transform: scale(0.95);
  }
}

.gift-image {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: 15px;
  margin-bottom: 8px;
}

.gift-item-selected {
  border: 2px solid #FFFFFF;
  border-radius: 15px;
  box-sizing: border-box;
}

.gift-price {
  margin: 0;
  font-size: 12px;
  color: #999999;
  text-align: center;
}

.gift-dialog-footer {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding: 15px 20px;
  padding-bottom: calc(20px + env(safe-area-inset-bottom));
  padding-bottom: calc(20px + constant(safe-area-inset-bottom));
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: #282828;
}

.footer-left {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #ffffff;
  font-size: 16px;
  
  .coin-icon {
    width: 20px;
    height: 20px;
  }
  
  .coin-balance {
    font-weight: 500;
  }
  
  .coin-more {
    margin-left: 4px;
    cursor: pointer;
    color: white;
  }
}

.footer-center {
  height: 28px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: #1a1a1a;
  border-radius: 8px;
  padding: 4px;
  margin-left: auto;
  margin-right: 15px;
  box-sizing: border-box;
}

.quantity-btn {
  width: 16px;
  height: 16px;
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: background 0.2s;
  flex-shrink: 0;
  padding: 0;
  
  &:active:not(:disabled) {
    background: rgba(255, 255, 255, 0.1);
  }
  
  &:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }
}

.quantity-input {
  max-width: 50px;
  height: 28px;
  width: auto;
  min-width: 30px;
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 14px;
  text-align: center;
  outline: none;
  flex-shrink: 0;
  
  &::-webkit-inner-spin-button,
  &::-webkit-outer-spin-button {
    appearance: none;
    -webkit-appearance: none;
    margin: 0;
  }
  
  appearance: textfield;
  -moz-appearance: textfield;
}

.send-btn {
  height: 28px;
  width: 64px;
  border: none;
  border-radius: 14px;
  color: #000000;
  background: white;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;

}
</style>
