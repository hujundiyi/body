import Vue from 'vue';
import MNotice from '@/components/MNotice/index.vue';
import store from '@/store';

class NoticeManager {
  constructor() {
    this.notices = new Map();
    this.zIndexBase = 5000;
    this.maxNotices = 5; // 最大显示数量
  }

  show(options) {
    const noticeId = `notice_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // 如果超过最大数量，移除最早的通知
    if (this.notices.size >= this.maxNotices) {
      const firstNoticeId = Array.from(this.notices.keys())[0];
      this.close(firstNoticeId);
    }

    // 计算层级 - 新的通知在最上面
    const zIndex = this.zIndexBase + this.notices.size;

    const instance = new Vue({
      store,
      render: (h) => h(MNotice, {
        props: {
          show: true,
          isBlur: options.isBlur,
          title: options.title || '',
          message: options.message || '',
          avatar: options.avatar,
          rightImage: options.rightImage,
          backgroundColor: options.backgroundColor,
          duration: options.duration || 3000,
          width: options.width || 'calc(100vw - 40px)',
          height: options.height || 'auto',
          zIndex: zIndex,
          showClose: options.showClose !== false,
          offsetTop: 0, // 所有通知都在同一位置，通过z-index堆叠
          country: options.country,
          age: options.age,
          isOnlineNotice: options.isOnlineNotice || false,
          isLikeNotice: options.isLikeNotice || false
        },
        on: {
          close: () => {
            this.close(noticeId);
            options.onClose && options.onClose();
          },
          click: () => {
            options.onClick && options.onClick();
          },
          swipe: (direction) => {
            options.onSwipe && options.onSwipe(direction);
          }
        }
      })
    });

    const el = instance.$mount().$el;
    document.getElementById('app').appendChild(el);

    this.notices.set(noticeId, {
      instance,
      zIndex
    });

    // 设置自动清理
    if (options.duration && options.duration > 0) {
      setTimeout(() => {
        this.close(noticeId);
      }, options.duration + 500);
    }

    return noticeId;
  }

  close(noticeId) {
    const notice = this.notices.get(noticeId);
    if (notice) {
      // 触发组件关闭动画
      notice.instance.$children[0].visible = false;

      // 延迟移除DOM
      setTimeout(() => {
        notice.instance.$destroy();
        notice.instance.$el.remove();
        this.notices.delete(noticeId);
      }, 500);
    }
  }

  closeAll() {
    this.notices.forEach((_, noticeId) => {
      this.close(noticeId);
    });
  }

  // 获取当前通知数量
  getCount() {
    return this.notices.size;
  }
}

// 创建单例
const noticeManager = new NoticeManager();

// 导出便捷方法
export const showNotice = (options) => {
  return noticeManager.show(options);
};

export const closeNotice = (noticeId) => {
  noticeManager.close(noticeId);
};

export const closeAllNotices = () => {
  noticeManager.closeAll();
};

export const getNoticeCount = () => {
  return noticeManager.getCount();
};

export default noticeManager;
