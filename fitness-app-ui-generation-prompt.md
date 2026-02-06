# 健身 App UI 生成提示词（给 AI 用）

把下面整段或按「单屏」复制到 Cursor / v0 / Claude 等，用于生成界面代码或设计稿。可根据需要改成英文再生成。

---

## 一、整体说明（每次生成前可先给 AI 看）

```
你正在为一个面向海外用户的健身 App 设计/实现 UI。产品有两个核心模块：
1. 场景化短时训练：用户按「时间/地点」选场景（如 Morning 5min, Desk Stretch），进入 3–10 分钟的计时训练。
2. 体态康复：用户选择身体部位（如 Lower Back, Neck），按多日计划每天完成一组 5–15 分钟的动作。

设计要求：
- 风格：简洁、偏现代，留白多，不花哨。参考 Apple Fitness+ 或 Calm 的克制感。
- 主色：一种主色（如深蓝/墨绿/深紫）配白底或浅灰底，强调色用于按钮和进度。
- 字体：清晰易读，标题与正文层级分明；支持英文为主。
- 平台：先做移动端（iOS/Android 或 React Native / Flutter），或响应式 Web 均可。
- 无账号时也能使用部分功能（试用），所以首页不要一上来就逼登录。
```

---

## 二、按屏幕生成的提示词（复制单段即可）

### 1. 首页（Home）

```
画一个健身 App 的首页（移动端竖屏）。

顶部：App 名称或 Logo，右侧可放「设置」图标。
中间主区域：
- 一句简短问候，如 "Good morning" 或 "Ready for a short session?"
- 一个突出的「今日推荐」卡片：大标题如 "Desk Stretch · 5 min"，副标题 "Right for now"，主按钮 "Start".
- 下方两个入口并排或上下排列：「Scenarios」场景训练、「Recovery」体态康复，点进去到对应列表。
底部可选：本周统计，如 "You did 3 sessions this week · 18 min".

整体简洁、留白多、主按钮用强调色，其余用灰字和细线。
```

---

### 2. 场景列表页（Scenarios）

```
画一个「场景化短时训练」列表页（移动端）。

顶部：标题 "Short Workouts" 或 "By Time & Place"，可选返回箭头。
下方为场景卡片列表（可滚动），每个卡片包含：
- 场景名称（如 "Morning 5 min", "Desk Stretch 5 min", "Before Bed 7 min"）
- 副标题（如 "Wake up" / "At desk" / "Wind down"）
- 时长标签（如 "5 min"）
- 右侧箭头或 "Start" 进入训练

可分组：By Time（Morning, Lunch, Evening, Before Bed）和 By Place（Office, Home, Outdoor）。卡片圆角、浅灰底或白底、阴影很轻。
```

---

### 3. 场景详情页（Scenario Detail）

```
画一个单个场景的详情页（移动端）。

顶部：返回 + 场景名称（如 "Desk Stretch"）。
中间：一张占位图或渐变块 + 总时长（如 "5 min"）、难度（如 "Easy"）、动作数量（如 "6 exercises"）、简短描述 1 行。
底部：一个全宽主按钮 "Start Workout"，次要链接 "View exercises" 可展开动作列表（名称 + 时长）。

风格简洁，主按钮醒目。
```

---

### 4. 训练进行页（Workout In Progress）

```
画一个训练进行中的全屏页（移动端）。

上半部分：当前动作名称（大号字）+ 一张示意图/占位图。
中间：大号倒计时数字（如 "0:45"）或环形进度。
下方：当前动作序号，如 "3 of 6"，可选进度条。
底部：两个按钮 "Pause" 和 "Skip"（文字按钮，不抢眼）。无「下一动」按钮，倒计时结束自动切换。

背景可浅色或深色模式，以不干扰看图为准。
```

---

### 5. 训练完成页（Workout Complete）

```
画一个训练完成后的结果页（移动端）。

顶部或中间：一句鼓励，如 "Nice work!" 或 "You did it."
显示本次数据：总时长（如 "5 min"）、完成动作数（如 "6/6 exercises"）。
两个按钮：主按钮 "Do Again"，次要 "Back to Scenarios" 或 "Home"。

简洁、正向，主按钮一个即可。
```

---

### 6. 康复入口 / 部位选择页（Recovery – Body Part）

```
画一个「体态康复」入口页（移动端）。

标题："Recovery" 或 "Posture & Relief"，副标题一句说明（如 "Choose the area you want to focus on."）。
下方为部位卡片网格或列表，每项包含：
- 图标或插画（颈、肩、下背、膝等）
- 名称（如 "Lower Back", "Neck & Upper Back", "Shoulders"）
- 可选简短描述（如 "Tightness, stiffness"）

底部或首次进入前有一行小字免责："Not medical advice. See a doctor if pain is severe." 加勾选 "I understand"。
风格与首页一致，卡片可点击。
```

---

### 7. 康复计划首页（Recovery Plan Home）

```
画一个康复计划的「计划首页」（移动端）。

顶部：返回 + 计划名称（如 "Lower Back · 7-Day Program"）。
中间：进度环或进度条 "Day 3 of 7"，今日标题 "Today: Core & Stretch" 和时长 "约 8 min"。
一个主按钮 "Start Today's Routine"。
下方可折叠 "Upcoming days" 列表：Day 4, Day 5... 每行标题 + 时长。

简洁、进度感明确。
```

---

### 8. 设置页（Settings）

```
画一个设置页（移动端）。

列表形式，每行一项，右侧箭头或开关：
- Notifications（开关）
- Language
- Units（可选）
- Restore Purchase
- Privacy Policy
- Terms / Disclaimer

顶部标题 "Settings"，可选账号区（未登录显示 "Sign in"）。
风格与系统设置类似，清晰不花哨。
```

---

### 9. 订阅/付费墙（Paywall，可选）

```
画一个简单的订阅墙（移动端）。

标题："Unlock all workouts & programs"
2–3 个权益点（如 All scenarios, All recovery programs, No ads）。
月付/年付两个选项，年付标 "Best value" 或折扣。
主按钮 "Subscribe"，小字 "Restore Purchase" 和 "Terms / Privacy" 链接。

风格与整体 App 一致，不夸张。
```

---

## 三、一次性生成多屏的汇总提示词（英文，适合 v0 / 英文 AI）

```
Create mobile UI (Figma or React/HTML) for a fitness app with 2 modules: (1) Scenario-based short workouts — user picks a scenario (e.g. Morning 5min, Desk Stretch) and does a 3–10 min timed workout; (2) Posture & Recovery — user picks body part (Lower Back, Neck…) and follows a multi-day program with daily routines.

Screens to design:
1. Home: greeting, one prominent "Today's suggestion" card (e.g. Desk Stretch 5min) with CTA "Start", and two entries "Scenarios" and "Recovery"; optional weekly stats.
2. Scenarios list: list of scenario cards (Morning 5min, Desk Stretch, Before Bed 7min…), each with title, subtitle, duration, and Start/arrow.
3. Scenario detail: hero area, duration/difficulty/exercise count, primary button "Start Workout".
4. Workout in progress: current exercise name, illustration, big countdown timer, Pause/Skip.
5. Workout complete: "Nice work!", total time, exercises done, "Do Again" and "Back".
6. Recovery body part selection: grid/list of body parts (Lower Back, Neck, Shoulders…) with short copy; disclaimer line with "I understand" checkbox.
7. Recovery plan home: "Day X of 7", today's routine title and duration, "Start Today's Routine", optional upcoming days list.
8. Settings: list (Notifications, Language, Restore Purchase, Privacy, Terms).

Style: clean, minimal, plenty of white space; one primary color (e.g. deep blue or green) for CTAs; Apple Fitness+ or Calm-like restraint. English copy.
```

---

## 四、使用建议

- **用中文 AI 生成**：用「二、按屏幕生成」里单屏的提示词，一次一屏，生成后再拼成完整 App。
- **用英文 AI / v0**：把「三、一次性生成多屏」整段复制过去，可一次出一套多屏；再按需微调某几屏。
- **生成代码时**：在提示词末尾加上技术栈，例如 "用 Vue 3 + 移动端适配" 或 "用 React Native / Flutter / 纯 HTML+CSS"。
- **生成设计稿时**：加上 "Figma" 或 "高保真移动端 UI，标注主色和字号"。

如果你愿意，我也可以按你指定的技术栈（如 Vue/React/Flutter）把某一屏写成更细的「可直接生成代码」的提示词。
