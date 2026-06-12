# 圆周旅迹 (Circular Travel) - 项目上下文与开发指南

## 一、 项目愿景与技术栈
- **产品定位**：一款融合 AI 智能排程、LBS 实时防走散、地理相册与社交 Feed 的年轻化旅行 App。
- **目标平台**：Flutter (iOS + Android 双端)。
- **网络层架构**：Dio + Vercel Serverless (作为 OpenRouter/AI 代理层，绕过直连限制)。
- **架构模式**：严格的 Clean Architecture (Domain / Data / Presentation)。

### ⚠️ 状态管理严格约束 (必须遵守)
- **核心框架**：Riverpod。
- **语法规范**：统一采用**原生手写 Riverpod 语法**（如 `AsyncNotifier`、`Notifier`、`Provider`、`StateNotifier`）。
- **禁止事项**：**绝对不要使用 `@riverpod` 注解**，严禁引入 `build_runner` 代码生成，以防止编译报错并保持编译纯净度。

---

## 二、 核心架构约束 (⚠️ 开发红线)

### 1. 地图多引擎动态适配 (Map Adapter Pattern)
- **UI 隔离**：绝对禁止在 UI 业务代码中直接 `import` 具体的地图 SDK 或底层地图包。
- **调度机制**：所有地图渲染必须统一通过 `ITravelMap` 接口和 `TravelMapFactory.build()` 工厂方法动态调度。
- **引擎分流**：
  - **国内逻辑**：使用 `ChinaMapWidget`（底层为 `flutter_map` 加载高德免费瓦片，配合代码强转 GCJ-02 火星坐标系防止偏移）。
  - **海外逻辑**：使用 `OsmMapWidget`（加载 CartoDB 极速底图，直接使用 WGS-84 坐标）。

### 2. 坐标系隔离机制
- **标准数据流**：本地数据库、Domain 层实体、业务逻辑层（Providers/UseCases）统一强制使用 **WGS-84 (LatLng84)** 坐标系。
- **转换边界**：WGS-84 到 GCJ-02 的纠偏转换**仅允许在 MapAdapter 内部（如 ChinaMapWidget 渲染前）发生**，禁止污染业务层。

---

## 三、 当前已完成进度 (MVP 状态)

### Module 1: AI Planner & Copilot (已闭环)
- **一键生成**：用户输入目的地和天数，通过 Vercel 代理请求大模型，生成标准的行程 JSON（包含每天的 POI 列表与经纬度）。
- **对话微调**：底部悬浮“AI伴游”气泡，支持通过自然语言局部修改现有行程状态，UI 实时刷新。
- **快捷操作**：左上角支持“清空返回首页”，右上角支持“带参一键重新生成(刷新)”。

### Module 2: LBS & 智能路线 (已闭环)
- **GPS定位**：集成 `geolocator` 申请双端定位权限，地图渲染实时闪烁的“蓝色定位点”，支持一键平滑飞回“我的位置”或“行程目的地”。
- **OSRM 真实道路**：提取行程中 POI 之间的轨迹，在地图绘制真实贴地公路，并在列表中渲染如“🚗 驾车 15 分钟 (3.2km)”。
- **极限防崩溃兜底**：网络请求严格限时 2 秒，一旦超时或算路失败（如跨海），瞬间切换为本地 `Haversine` 物理公式测算距离时间，并用虚线连结地图，保证 UI 绝对不卡死。

---

## 四、 项目核心目录结构

```text
lib/
├── core/
│   ├── coordinate/
│   │   └── coordinate_converter.dart     # WGS84 <-> GCJ02 转换算法
│   └── map_adapter/
│       ├── i_travel_map.dart             # 地图抽象接口
│       ├── map_factory.dart              # 智能调度工厂 (根据坐标判断境内外)
│       ├── china_map_widget.dart         # 国内引擎 (高德底图 + GCJ02偏移)
│       └── osm_map_widget.dart           # 海外引擎 (CartoDB底图 + WGS84)
├── domain/
│   ├── entities/
│   │   └── itinerary.dart                # POI, Itinerary, ItineraryDay 实体类
│   └── repositories/
│       └── i_ai_planner_repository.dart 
├── data/
│   ├── datasources/
│   │   └── ai_remote_datasource.dart     # 请求 Vercel 接口获取 AI 响应
│   └── repositories_impl/
│       └── ai_planner_repository_impl.dart # 组装 Prompt、解析 AI 吐出的 JSON
└── presentation/
    ├── lbs_tracking/
    │   └── providers/
    │       └── lbs_providers.dart        # locationProvider & osrmRouteProvider(带本地兜底)
    ├── planner/
    │   ├── pages/
    │   │   └── planner_page.dart         # 主页 (包含地图层与交互式行程列表)
    │   ├── providers/
    │   │   └── planner_providers.dart    # 手写的 CurrentItineraryNotifier (无CodeGen)
    │   └── widgets/
    │       ├── ai_generation_form.dart   # 初始生成表单
    │       ├── ai_copilot_fab.dart       # 悬浮伴游按钮
    │       └── ai_copilot_chat_sheet.dart# 对话微调 BottomSheet
    ├── memories/                         # Module 3 (相册归档，待开发)
    └── social_feed/                      # Module 4 (社区动态，待开发)
```

---

## 五、 AI 协作增量开发指南
当接收到后续的开发指令时，AI 助手必须：
1. 编写 State 相关的 Provider 时，直接编写 `AsyncNotifierProvider` 或 `StateNotifierProvider` 的手写实现，杜绝类上方的 `@riverpod` 标签。
2. 涉及新增地理数据输入时，确保其处于 `WGS-84` 状态。
3. 任何涉及 UI 层渲染地图的组件，必须引用 `TravelMapFactory`。
