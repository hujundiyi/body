# 用 Pencil MCP 生成健身 App 界面的使用说明

## 一、前置条件（必须完成）

1. **安装 Pencil**  
   从 https://pencil.dev 安装 Pencil 并完成激活（桌面端或 Cursor 扩展，按官方文档为准）。

2. **在 Cursor 里连接 Pencil MCP**  
   - 安装 Pencil 的 Cursor 扩展并完成激活。  
   - 保持 **Pencil 应用处于运行状态**（MCP 随 Pencil 启动）。  
   - 打开 **Cursor → Settings → Tools & MCP**，确认列表里出现 Pencil 的 MCP 连接。

3. **准备设计文件**  
   - 在你要做健身 App 的项目中**新建或打开一个 `.pen` 文件**（例如 `fitness-app.pen`）。  
   - 确保 Cursor 当前打开的是包含该 `.pen` 文件的项目。

---

## 二、连接成功后，让 AI 生成界面的提示词（复制给 Cursor AI 用）

下面每段可以单独复制到 Cursor 对话里，让 AI 用 Pencil MCP 在**当前打开的 .pen 文件**里生成对应界面。

### 生成首页

```
请用 Pencil MCP 在当前打开的 .pen 文件里生成健身 App 的首页（移动端竖屏）。要求：顶部 App 名称或 Logo、右侧设置图标；中间一句问候如 "Ready for a short session?"；一个突出的「今日推荐」卡片，标题 "Desk Stretch · 5 min"，副标题 "Right for now"，主按钮 "Start"；下方两个入口「Scenarios」和「Recovery」；底部可选本周统计 "You did 3 sessions this week · 18 min"。风格简洁、留白多、主按钮用强调色。
```

### 生成场景列表页

```
请用 Pencil MCP 在当前 .pen 里生成「Short Workouts」场景列表页（移动端）。顶部标题 "Short Workouts"；下方为可滚动的场景卡片，每张卡片包含：场景名（如 "Morning 5 min", "Desk Stretch 5 min", "Before Bed 7 min"）、副标题、时长标签、右侧箭头。可分组 By Time 和 By Place。卡片圆角、浅灰底、轻阴影。
```

### 生成训练进行页

```
请用 Pencil MCP 在当前 .pen 里生成训练进行中的全屏页（移动端）。上半部分：当前动作名称 + 示意图占位；中间大号倒计时如 "0:45" 或环形进度；下方 "3 of 6" 和进度条；底部 "Pause" 和 "Skip" 文字按钮。背景简洁不抢眼。
```

### 生成康复部位选择页

```
请用 Pencil MCP 在当前 .pen 里生成体态康复入口页（移动端）。标题 "Recovery"，副标题 "Choose the area you want to focus on."；下方为部位卡片（Lower Back, Neck & Upper Back, Shoulders 等），每项带图标和名称；底部免责小字 "Not medical advice. See a doctor if pain is severe." 和 "I understand" 勾选。
```

### 一次性生成多屏（英文，适合 Pencil 文档里的风格）

```
Using Pencil MCP, in the current .pen file create mobile UI frames for a fitness app:

1. Home: greeting, one "Today's suggestion" card (e.g. Desk Stretch 5min) with "Start" CTA, two entries "Scenarios" and "Recovery", optional weekly stats.
2. Scenarios list: scenario cards (Morning 5min, Desk Stretch, Before Bed 7min…) with title, subtitle, duration, Start/arrow.
3. Scenario detail: hero area, duration/difficulty/exercise count, "Start Workout" button.
4. Workout in progress: exercise name, illustration area, big countdown, Pause/Skip.
5. Workout complete: "Nice work!", total time, "Do Again" and "Back".
6. Recovery body part selection: grid of Lower Back, Neck, Shoulders with disclaimer and "I understand" checkbox.
7. Recovery plan home: "Day X of 7", today's routine, "Start Today's Routine", upcoming days list.
8. Settings: list (Notifications, Language, Restore Purchase, Privacy, Terms).

Style: clean, minimal, one primary color for CTAs, plenty of white space. English labels.
```

---

## 三、若 Cursor 里仍看不到 Pencil MCP

- 确认 **Pencil 已启动**（桌面端或扩展要求的方式）。  
- 在 Cursor 的 **Settings → Tools & MCP** 中查看是否有 Pencil，若没有则按 Pencil 官方文档添加/配置 MCP。  
- 重启 Cursor 和 Pencil 后再试。  
- 官方故障排除：https://docs.pencil.dev/troubleshooting

---

## 四、相关文档位置（均在桌面 BODY 文件夹内）

- **产品功能规格**：`BODY/fitness-app-feature-spec.md`  
- **UI 生成提示词（通用，不依赖 Pencil）**：`BODY/fitness-app-ui-generation-prompt.md`
