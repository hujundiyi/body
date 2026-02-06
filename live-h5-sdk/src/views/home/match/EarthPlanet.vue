<script>
/**
 * 星球组件（纯 UI）
 * 3D 立体星球 + 头像近大远小 + 手指拖动旋转 + 不拖动时自动缓慢旋转
 * 可嵌入 match 页或独立星球页使用
 */
const DEFAULT_AVATAR = require('@/assets/image/ic-placeholder-avatar.png');

function sphericalToCartesian(lat, lng) {
  const phi = (lat * Math.PI) / 180;
  const theta = (lng * Math.PI) / 180;
  const r = 1;
  return {
    x: r * Math.cos(phi) * Math.sin(theta),
    y: r * Math.sin(phi),
    z: r * Math.cos(phi) * Math.cos(theta)
  };
}

function rotateY(p, angle) {
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  return { x: p.x * c - p.z * s, y: p.y, z: p.x * s + p.z * c };
}

function rotateX(p, angle) {
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  return { x: p.x, y: p.y * c - p.z * s, z: p.y * s + p.z * c };
}

function project(p, d = 2.8) {
  const factor = d / (d + p.z);
  return {
    x: p.x * factor,
    y: -p.y * factor,
    z: p.z,
    scale: Math.max(0.15, Math.min(1.2, factor))
  };
}

// 生成集中在赤道附近的点分布（用于头像）
// 确保南北极附近各有一个头像，其余集中在中间
function fibonacciSphereCentered(n) {
  const pts = [];
  if (n <= 0) return pts;
  
  // 如果只有1个或2个头像，直接放在南北极
  if (n === 1) {
    pts.push({ lat: 90, lng: 0 }); // 北极
    return pts;
  }
  if (n === 2) {
    pts.push({ lat: 90, lng: 0 }); // 北极
    pts.push({ lat: -90, lng: 0 }); // 南极
    return pts;
  }
  
  // 3个或更多：第一个在北极附近，最后一个在南极附近，中间的在赤道附近
  const golden = Math.PI * (3 - Math.sqrt(5));
  const middleCount = n - 2; // 中间的头像数量
  
  // 第一个：北极附近（lat 约 75-85 度）
  pts.push({ lat: 80, lng: 0 });
  
  // 中间的头像：集中在赤道附近
  const denom = middleCount <= 1 ? 1 : middleCount - 1;
  for (let i = 0; i < middleCount; i++) {
    const yRaw = 1 - (i / denom) * 2; // -1 到 1
    // 将 y 值压缩到 -0.6 到 0.6 之间，集中在赤道附近
    const y = yRaw * 0.6;
    const r = Math.sqrt(Math.max(0, 1 - y * y));
    const theta = golden * (i + 1); // 偏移一下，避免和南北极重叠
    const x = Math.cos(theta) * r;
    const z = Math.sin(theta) * r;
    const lat = (Math.asin(y) * 180) / Math.PI;
    const lng = (Math.atan2(x, z) * 180) / Math.PI;
    pts.push({ lat, lng });
  }
  
  // 最后一个：南极附近（lat 约 -75 到 -85 度）
  pts.push({ lat: -80, lng: 180 });
  
  return pts;
}

// 原始的均匀分布（用于球体点）
function fibonacciSphere(n) {
  const pts = [];
  if (n <= 0) return pts;
  const golden = Math.PI * (3 - Math.sqrt(5));
  const denom = n <= 1 ? 1 : n - 1;
  for (let i = 0; i < n; i++) {
    const y = 1 - (i / denom) * 2;
    const r = Math.sqrt(Math.max(0, 1 - y * y));
    const theta = golden * i;
    const x = Math.cos(theta) * r;
    const z = Math.sin(theta) * r;
    const lat = (Math.asin(y) * 180) / Math.PI;
    const lng = (Math.atan2(x, z) * 180) / Math.PI;
    pts.push({ lat, lng });
  }
  return pts;
}

export default {
  name: 'EarthPlanet',
  props: {
    /** 可选。传入则使用，否则组件内部拉取 */
    avatarList: {
      type: Array,
      default: null
    }
  },
  data() {
    return {
      width: 0,
      height: 0,
      centerX: 0,
      centerY: 0,
      radius: 0,
      rotY: 0,
      rotX: 0.15,
      isDragging: false,
      lastX: 0,
      lastY: 0,
      lastRotY: 0,
      lastRotX: 0,
      rafId: null,
      list: [],
      projectedAvatars: [],
      dotPositions: [],
      autoSpeed: 0.12 * (Math.PI / 180),
      pixelRatio: 1,
      // 性能优化：控制渲染频率
      lastRenderTime: 0,
      renderInterval: 1000 / 30, // 30fps，降低到 30 帧/秒
      isVisible: true,
      resizeTimer: null,
      initRetryCount: 0,
      initRetryTimer: null,
      lastHeight: 0 // 用于检测高度是否稳定
    };
  },
  mounted() {
    this.initDots();
    // 延迟加载头像数据，先确保尺寸正确
    this.resolveAvatars();
    
    // 使用双重 nextTick + 延迟，确保父容器 earth-bg 尺寸已稳定
    this.$nextTick(() => {
      this.$nextTick(() => {
        // 延迟执行，确保父容器的 bottom 计算已完成
        setTimeout(() => {
          this.ensureSizeStable();
        }, 0);
      });
    });
    
    window.addEventListener('resize', this.onResize);
    // 优化：监听页面可见性，不可见时暂停渲染
    document.addEventListener('visibilitychange', this.handleVisibilityChange);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.onResize);
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    this.unbindPointer();
    if (this.rafId) cancelAnimationFrame(this.rafId);
    if (this.resizeTimer) clearTimeout(this.resizeTimer);
    if (this.initRetryTimer) clearTimeout(this.initRetryTimer);
  },
  watch: {
    avatarList: {
      handler(v) {
        this.resolveAvatars();
      },
      immediate: false
    }
  },
  methods: {
    resolveAvatars() {
      if (Array.isArray(this.avatarList) && this.avatarList.length > 0) {
        this.list = this.avatarList.slice(0, 12).map((it) => {
          // 优先使用 nickname，如果不存在或为空字符串，则使用 name
          const name = (it.nickname && String(it.nickname).trim()) || (it.name && String(it.name).trim()) || 'Unknown';
          return {
            avatar: it.avatar || DEFAULT_AVATAR,
            name: name
          };
        });
        return;
      }
      this.loadAvatars();
    },
    initSize() {
      const wrap = this.$refs.wrap;
      if (!wrap) return false;
      const rect = wrap.getBoundingClientRect();
      // 确保尺寸有效（大于0）
      if (rect.width <= 0 || rect.height <= 0) {
        return false;
      }
      this.width = rect.width;
      this.height = rect.height;
      this.centerX = this.width / 2;
      this.centerY = this.height / 2;
      this.radius = Math.min(this.width, this.height) * 0.38;
      this.pixelRatio = Math.min(2, window.devicePixelRatio || 1);
      return true;
    },
    /**
     * 确保尺寸稳定后再初始化渲染
     * 通过多次检测，确保高度不再变化
     */
    ensureSizeStable() {
      const wrap = this.$refs.wrap;
      if (!wrap) {
        // 如果 wrap 还不存在，延迟重试
        if (this.initRetryCount < 5) {
          this.initRetryCount++;
          this.initRetryTimer = setTimeout(() => {
            this.ensureSizeStable();
          }, 50);
        }
        return;
      }
      
      const rect = wrap.getBoundingClientRect();
      const currentHeight = rect.height;
      
      // 如果高度无效，延迟重试
      if (currentHeight <= 0) {
        if (this.initRetryCount < 5) {
          this.initRetryCount++;
          this.initRetryTimer = setTimeout(() => {
            this.ensureSizeStable();
          }, 50);
        }
        return;
      }
      
      // 如果高度和上次一样，说明已经稳定
      if (this.lastHeight > 0 && Math.abs(currentHeight - this.lastHeight) < 1) {
        // 尺寸已稳定，初始化完成
        this.initRetryCount = 0;
        this.lastHeight = 0;
        this.syncSizeAndCanvas();
        this.startRender();
        this.bindPointer();
        return;
      }
      
      // 高度还在变化，记录当前高度，继续检测
      this.lastHeight = currentHeight;
      
      // 如果重试次数过多，直接使用当前尺寸
      if (this.initRetryCount >= 5) {
        this.initRetryCount = 0;
        this.lastHeight = 0;
        this.syncSizeAndCanvas();
        this.startRender();
        this.bindPointer();
        return;
      }
      
      // 延迟再次检测
      this.initRetryCount++;
      this.initRetryTimer = setTimeout(() => {
        this.ensureSizeStable();
      }, 50);
    },
    /**
     * 同步尺寸并更新 canvas
     */
    syncSizeAndCanvas() {
      if (!this.initSize()) {
        return;
      }
      const canvas = this.$refs.canvas;
      const wrap = this.$refs.wrap;
      if (!canvas || !wrap) return;
      
      const rect = wrap.getBoundingClientRect();
      if (rect.width <= 0 || rect.height <= 0) {
        return;
      }
      
      const w = Math.floor(rect.width * this.pixelRatio);
      const h = Math.floor(rect.height * this.pixelRatio);
      canvas.width = w;
      canvas.height = h;
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
    },
    onResize() {
      // 优化：节流 resize 事件，避免频繁计算
      if (this.resizeTimer) {
        clearTimeout(this.resizeTimer);
      }
      this.resizeTimer = setTimeout(() => {
        this.syncSizeAndCanvas();
      }, 150);
    },
    bindPointer() {
      const wrap = this.$refs.wrap;
      if (!wrap) return;
      wrap.addEventListener('touchstart', this.onTouchStart, { passive: false });
      wrap.addEventListener('touchmove', this.onTouchMove, { passive: false });
      wrap.addEventListener('touchend', this.onTouchEnd, { passive: false });
      wrap.addEventListener('touchcancel', this.onTouchEnd, { passive: false });
      wrap.addEventListener('mousedown', this.onMouseDown);
      window.addEventListener('mousemove', this.onMouseMove);
      window.addEventListener('mouseup', this.onMouseUp);
    },
    unbindPointer() {
      const wrap = this.$refs.wrap;
      if (wrap) {
        wrap.removeEventListener('touchstart', this.onTouchStart);
        wrap.removeEventListener('touchmove', this.onTouchMove);
        wrap.removeEventListener('touchend', this.onTouchEnd);
        wrap.removeEventListener('touchcancel', this.onTouchEnd);
        wrap.removeEventListener('mousedown', this.onMouseDown);
      }
      window.removeEventListener('mousemove', this.onMouseMove);
      window.removeEventListener('mouseup', this.onMouseUp);
    },
    initDots() {
      // 优化：减少点的数量，从 18*32=576 降低到 12*20=240，减少约 58% 的绘制
      const rows = 12;
      const cols = 20;
      const pts = [];
      for (let i = 0; i <= rows; i++) {
        const lat = -90 + (180 * i) / rows;
        for (let j = 0; j < cols; j++) {
          const lng = (360 * j) / cols;
          pts.push({ lat, lng });
        }
      }
      this.dotPositions = pts;
    },
    async loadAvatars() {
      try {
        const list = await this.$store.dispatch('anchor/fetchVideoPlaylist');
        if (list && list.length > 0) {
          this.list = list.slice(0, 10).map((it) => {
            // 优先使用 nickname，如果不存在或为空字符串，则使用 name
            const name = (it.nickname && String(it.nickname).trim()) || (it.name && String(it.name).trim()) || 'Unknown';
            return {
              avatar: it.avatar || DEFAULT_AVATAR,
              name: name
            };
          });
          return;
        }
      } catch (e) {
        console.warn('EarthPlanet: fetchVideoPlaylist fail', e);
      }
      try {
        const anchors = await this.$store.dispatch('anchor/loadRecommendAnchors');
        if (anchors && anchors.length > 0) {
          // 优化：限制头像数量，最多 10 个，减少 DOM 元素和计算量
          this.list = anchors.slice(0, 12).map((a) => {
            // 优先使用 nickname，如果不存在或为空字符串，则使用 name
            const name = (a.nickname && String(a.nickname).trim()) || (a.name && String(a.name).trim()) || 'Unknown';
            return {
              avatar: a.avatar || DEFAULT_AVATAR,
              name: name
            };
          });
          return;
        }
      } catch (e) {
        console.warn('EarthPlanet: loadRecommendAnchors fail', e);
      }
      this.list = this.getMockAvatars();
    },
    getMockAvatars() {
      const names = ['Amelia', 'Noah', 'Ethan', 'Lily', 'James', 'Emma', 'Oliver', 'Ava'];
      return names.map((name, i) => ({
        avatar: DEFAULT_AVATAR,
        name: `${name} ${i}`
      }));
    },
    projectAvatar(item, lat, lng) {
      let p = sphericalToCartesian(lat, lng);
      p = rotateY(p, this.rotY);
      p = rotateX(p, this.rotX);
      const proj = project(p);
      const x = this.centerX + proj.x * this.radius;
      const y = this.centerY + proj.y * this.radius;
      const dx = x - this.centerX;
      const dy = y - this.centerY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      const distanceFactor = 1 - Math.min(1, distance / Math.max(1, this.radius));
      const sizeScale = 0.5 + 1.25 * distanceFactor;
      const scale = Math.max(0.3, Math.min(1.75, proj.scale * sizeScale));
      return { ...item, x, y, scale, z: p.z };
    },
    updateProjectedAvatars() {
      const n = this.list.length;
      if (n === 0) {
        this.projectedAvatars = [];
        return;
      }
      // 使用集中在赤道附近的分布算法，让头像更集中在球体中间
      const positions = fibonacciSphereCentered(n);
      this.projectedAvatars = this.list
        .map((item, i) => this.projectAvatar(item, positions[i].lat, positions[i].lng))
        .filter((a) => a.z > -0.85)
        .sort((a, b) => a.z - b.z);
    },
    draw(ctx) {
      if (!ctx || !this.dotPositions.length || this.width <= 0 || this.height <= 0) return;
      const pr = this.pixelRatio;
      ctx.save();
      ctx.scale(pr, pr);
      const cx = this.centerX;
      const cy = this.centerY;
      const R = this.radius;
      
      // 优化：使用更高效的清空方式
      ctx.clearRect(0, 0, this.width, this.height);
      
      // 优化：缓存渐变对象，避免每帧重新创建（但这里需要每次重新创建因为位置可能变化）
      const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, R * 1.5);
      gradient.addColorStop(0, 'rgba(80,50,120,0.25)');
      gradient.addColorStop(0.6, 'rgba(40,25,80,0.12)');
      gradient.addColorStop(1, 'rgba(20,10,40,0)');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, this.width, this.height);
      
      // 优化：批量绘制点，减少状态切换
      ctx.fillStyle = 'rgba(180,200,255,0.5)'; // 设置默认颜色
      for (const { lat, lng } of this.dotPositions) {
        let p = sphericalToCartesian(lat, lng);
        p = rotateY(p, this.rotY);
        p = rotateX(p, this.rotX);
        // 优化：提前剔除背面点，减少计算
        if (p.z < -0.6) continue;
        const proj = project(p);
        const x = cx + proj.x * R;
        const y = cy + proj.y * R;
        const alpha = 0.3 + 0.7 * (p.z + 1) / 1.6;
        
        // 根据纬度调整点的大小：越靠近南北极（|lat|接近90度）点越小
        // 使用 cos(lat) 来计算，赤道处最大，两极处最小
        const latRad = (lat * Math.PI) / 180;
        const latFactor = Math.abs(Math.cos(latRad)); // 0-1，赤道=1，两极=0
        const baseRadius = 1.5 + 2 * proj.scale;
        const r = baseRadius * (0.3 + 0.7 * latFactor); // 两极最小为 30%，赤道最大为 100%
        
        // 优化：只在颜色变化时更新 fillStyle
        if (alpha < 0.5) {
          ctx.fillStyle = `rgba(180,200,255,${alpha})`;
        }
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();
      }
      
      // 优化：只在需要时更新头像位置（每帧都更新，但减少计算量）
      this.updateProjectedAvatars();
      ctx.restore();
    },
    render() {
      // 优化：页面不可见时，不渲染
      if (!this.isVisible) {
        this.rafId = requestAnimationFrame(this.render);
        return;
      }
      
      const now = performance.now();
      const deltaTime = now - this.lastRenderTime;
      
      // 优化：控制帧率，不拖动时降低到 30fps，拖动时保持 60fps
      const targetInterval = this.isDragging ? (1000 / 60) : this.renderInterval;
      
      if (deltaTime < targetInterval) {
        this.rafId = requestAnimationFrame(this.render);
        return;
      }
      
      this.lastRenderTime = now;
      
      // 优化：不拖动时，如果旋转角度变化很小，可以跳过渲染
      if (!this.isDragging) {
        this.rotY += this.autoSpeed;
      }
      
      const canvas = this.$refs.canvas;
      const wrap = this.$refs.wrap;
      if (!canvas || !wrap) {
        this.rafId = requestAnimationFrame(this.render);
        return;
      }
      
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        this.rafId = requestAnimationFrame(this.render);
        return;
      }
      
      this.draw(ctx);
      this.rafId = requestAnimationFrame(this.render);
    },
    startRender() {
      const canvas = this.$refs.canvas;
      const wrap = this.$refs.wrap;
      if (!canvas || !wrap) return;
      // 确保尺寸计算正确
      this.syncSizeAndCanvas();
      // 启动渲染循环
      if (!this.rafId) {
        this.render();
      }
    },
    getClientXY(e) {
      if (e.touches && e.touches.length) {
        return { x: e.touches[0].clientX, y: e.touches[0].clientY };
      }
      return { x: e.clientX, y: e.clientY };
    },
    onTouchStart(e) {
      e.preventDefault();
      const { x, y } = this.getClientXY(e);
      this.isDragging = true;
      this.lastX = x;
      this.lastY = y;
      this.lastRotY = this.rotY;
      this.lastRotX = this.rotX;
    },
    onTouchMove(e) {
      if (!this.isDragging) return;
      e.preventDefault();
      const { x, y } = this.getClientXY(e);
      const dx = x - this.lastX;
      const dy = y - this.lastY;
      // 水平：手指右滑时星球向右转（与手指同向），故 rotY 减去 dx
      this.rotY = this.lastRotY - dx * 0.008;
      this.rotX = Math.max(-0.5, Math.min(0.5, this.lastRotX + dy * 0.006));
      this.lastX = x;
      this.lastY = y;
      this.lastRotY = this.rotY;
      this.lastRotX = this.rotX;
    },
    onTouchEnd() {
      this.isDragging = false;
    },
    onMouseDown(e) {
      this.isDragging = true;
      this.lastX = e.clientX;
      this.lastY = e.clientY;
      this.lastRotY = this.rotY;
      this.lastRotX = this.rotX;
    },
    onMouseMove(e) {
      if (!this.isDragging) return;
      const dx = e.clientX - this.lastX;
      const dy = e.clientY - this.lastY;
      // 水平：鼠标右移时星球向右转（与拖动同向），故 rotY 减去 dx
      this.rotY = this.lastRotY - dx * 0.008;
      this.rotX = Math.max(-0.5, Math.min(0.5, this.lastRotX + dy * 0.006));
      this.lastX = e.clientX;
      this.lastY = e.clientY;
      this.lastRotY = this.rotY;
      this.lastRotX = this.rotX;
    },
    onMouseUp() {
      this.isDragging = false;
    },
    handleAvatarError(e) {
      e.target.src = DEFAULT_AVATAR;
    },
    onAvatarClick(a, i) {
      this.$emit('avatar-click', { avatar: a, index: i });
    },
    /**
     * 处理页面可见性变化
     */
    handleVisibilityChange() {
      this.isVisible = !document.hidden;
      if (!this.isVisible) {
        // 页面不可见时，暂停渲染
        if (this.rafId) {
          cancelAnimationFrame(this.rafId);
          this.rafId = null;
        }
      } else {
        // 页面可见时，恢复渲染
        if (!this.rafId) {
          this.startRender();
        }
      }
    }
  }
};
</script>

<template>
  <div ref="wrap" class="earth-planet-wrap">
    <canvas ref="canvas" class="earth-planet-canvas" />
    <div class="earth-planet-avatars">
      <div
        v-for="(a, i) in projectedAvatars"
        :key="i"
        class="earth-planet-node"
        :style="{
          left: a.x + 'px',
          top: a.y + 'px',
          transform: `translate(-50%,-50%) scale(${a.scale})`,
          zIndex: Math.round(100 + (a.z + 1) * 50)
        }"
        @click="onAvatarClick(a, i)"
      >
        <div class="earth-planet-ring">
          <img :src="a.avatar" class="earth-planet-img" @error="handleAvatarError" alt="" />
          <span class="earth-planet-dot" />
        </div>
        <div class="earth-planet-name">{{ a.name }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="less">
.earth-planet-wrap {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
  touch-action: none;
  cursor: grab;
  user-select: none;
  &:active {
    cursor: grabbing;
  }
}

.earth-planet-canvas {
  display: block;
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.earth-planet-avatars {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
}

.earth-planet-node {
  position: absolute;
  pointer-events: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  will-change: transform;
  cursor: pointer;
}

.earth-planet-ring {
  position: relative;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  //padding: 3px;
  //background: linear-gradient(135deg, rgba(120,80,200,0.6), rgba(80,120,220,0.5));
  //box-shadow: 0 0 12px rgba(140,100,255,0.4);
  flex-shrink: 0;
}

.earth-planet-img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  display: block;
}

.earth-planet-dot {
  position: absolute;
  right: 2px;
  bottom: 2px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #4ade80;
  border: 2px solid rgba(20,20,40,0.9);
  box-shadow: 0 0 6px rgba(74,222,128,0.8);
}

.earth-planet-name {
  margin-top: 4px;
  font-size: 11px;
  color: rgba(255,255,255,0.95);
  text-shadow: 0 1px 2px rgba(0,0,0,0.6);
  white-space: nowrap;
  max-width: 72px;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
