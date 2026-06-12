# 🌟 Circular Travel (圆周旅迹) - Flutter 核心工程蓝图与开发需求库

> **System Prompt (给 AI 的指令):**
> 你是一个世界顶级的 Flutter 架构师与全栈开发专家。请仔细阅读以下项目的核心架构、已完成进度以及待开发的需求池（Backlog）。在理解所有上下文和“架构铁律”后，请回复：“我已就绪！请指示我们要先从哪一个 Phase 的哪个功能开始开发？”

---

## 🏗️ 一、 项目技术栈与架构铁律 (⚠️ 绝对不可违背)

1. **状态管理基建：原生 Riverpod**
   - **铁律**：本项目**严禁**使用 `@riverpod` 注解和 `build_runner` 代码生成工具。所有状态管理必须手写原生的 `Provider`、`FutureProvider`、`AsyncNotifierProvider`，以保证跨平台的极致稳定。
2. **地图双引擎解耦 (Map Adapter Pattern)**
   - **铁律**：业务 UI 层绝不允许直接 import 具体的地图 SDK。所有地图渲染必须经过 `ITravelMap` 接口与 `TravelMapFactory.build()`。
   - 目前已实现：`ChinaMapWidget` (加载高德底图+GCJ02偏移算法) 和 `OsmMapWidget` (加载 CartoDB 极速底图+WGS84坐标)。工厂会根据目的地的经纬度自动切换引擎。
3. **坐标系隔离 (WGS-84 唯一原则)**
   - **铁律**：Domain 实体、业务数据流、大模型交互、定位插件获取的 GPS，**永远且只能**使用 WGS-84 标准 (`LatLng84`)。任何向火星坐标系 (GCJ-02) 的转换，只能在底层的 Adapter 内部悄悄进行。
4. **网络与接口防护**
   - **铁律**：采用 Dio，所有请求大模型（OpenRouter）的流量必须走 Vercel Serverless 代理，防止直连墙/跨国超时。接口层配有严格的 `Future.timeout` 强制物理熔断机制。

---

## 🗺️ 二、 当前已闭环进度 (MVP 已完成)

- **AI 智能排程 (Module 1)**：Vercel 代理直连大模型，支持一键生成 JSON 行程结构，支持底部悬浮气泡自然语言对话，局部微调行程状态并重绘 UI。包含重置与刷新功能。
- **LBS 真实定位与智能交通 (Module 2)**：接入 `geolocator` 获取用户蓝点定位；接入 OSRM 开源路线 API，沿真实街道画出深蓝色轨迹，并在 UI 列表渲染交通耗时（如 `🚗 驾车 15分钟`）。内置极限兜底算法（Haversine），OSRM 超时 2 秒即瞬间切换本地预估并画虚线。

---

## 🚀 三、 需求池 / Backlog (接下来我们要开发的模块)

> *以下是我们接下来的开发蓝图，请在后续对话中根据我的指令，逐步提取并实现以下功能：*

### Phase 1: 极致顺滑与解压 (UI/UX 升级)
- [ ] **Task 1.1: 魔法 Loading 动画**：引入 `lottie` 或 `rive`。在 AI 思考的数十秒内，用高级的地球仪/粒子重组动画替换原有的 CircularProgressIndicator，并配合动态轮播的文案（"正在寻找最棒的咖啡馆..."）。
- [ ] **Task 1.2: 骨架屏加载 (Shimmer)**：引入 `shimmer` 插件。在行程列表尚未渲染时，展示带有灰色流光闪烁的占位卡片。
- [ ] **Task 1.3: 全局触觉反馈**：接入 `HapticFeedback.lightImpact()`。在发送对话指令、切换地图视角、点击刷新时提供清脆的物理震动。
- [ ] **Task 1.4: 景点智能配图**：修改 AI Prompt，让其返回行程的配图关键字或直接生成 Emoji 缩略图，在左侧结合 `Hero` 动画展示圆角卡片。

### Phase 2: “Aha Moment” 核心魔法功能
- [ ] **Task 2.1: 天气与穿搭智能解绑**：接入免费天气 API (如 OpenWeather)。在给大模型发送 Prompt 时附带当地天气，让 AI 在行程 JSON 中加入：“🌧️ 明天有雨，已为您将户外活动替换为室内美术馆”。
- [ ] **Task 2.2: 地理相册足迹点亮 (Module 3 核心)**：引入 `photo_manager`。一键扫描手机本地相册，提取照片的 EXIF 经纬度，自动匹配吸附到地图路线上的对应 POI 处，生成可视化旅行回忆。
- [ ] **Task 2.3: 一键生成长图分享**：引入 `screenshot` 和 `path_provider`。将用户的地图路线、AI 生成的每一天卡片，拼接成一张极具设计感的高清长图，保存至本地或分享至社交媒体。

### Phase 3: 商业化与底层工程基建
- [ ] **Task 3.1: 本地离线缓存 (No-Network 模式)**：引入 `isar` 数据库或 `shared_preferences`。AI 生成 JSON 后立刻落盘，断网状态下也能秒开上次规划的行程，彻底解决出国无网的痛点。
- [ ] **Task 3.2: 门面工程优化**：引入 `flutter_launcher_icons` (生成年轻化图标) 和 `flutter_native_splash` (顺滑过渡启动页，消灭白屏)。
- [ ] **Task 3.3: 动态深色模式 (Dark Mode)**：适配系统夜间模式。切换时，UI 变为高级黑，地图底图自动无缝切换至 `CartoDB Dark Matter` 风格。