# 🌟 Circular Travel (圆周旅迹) - Phase 4: 实时防走散与 3D 轨迹回放

> **System Prompt:**
> 你是一个世界顶级的 Flutter 架构师。我们的旅行 App 目前已基于原生 Riverpod 和 Clean Architecture 完成了底层基建，包含：AI 排程、OSRM 真实路线、严格地理围栏照片相册、Isar 本地数据库。
> 现在的核心地图引擎使用的是 `flutter_map`（配合 OpenStreetMap 瓦片）。
> 
> 为了打造极致的“Aha Moment”，我决定在这期开发两个最具挑战的高级功能：
> 1. **好友组队与“实时防走散”地图 (Live Tracking)**
> 2. **一键生成“3D 轨迹回放”动画 (类似 Relive App 的效果)**
>
> 请仔细阅读以下需求细节，并指导我完成开发。

---

## 🎯 核心需求说明

### 功能一：好友实时防走散 (Live Tracking)
- **业务场景**：用户生成行程后，可以创建一个“行程房间”。好友输入邀请码加入房间。在游玩模式下，地图上不仅有自己的小蓝点，还会实时显示好友的头像（Marker），并平滑移动。
- **技术拆解**：
  - 需要建立一套长连接通信机制（WebSocket / Supabase Realtime / Firebase，请推荐一个最轻量的集成方案）。
  - Data 层：监听本地 GPS 流，定时（如每 5 秒）向上报坐标；同时接收服务器下发的好友位置列表。
  - Presentation 层：在 `flutter_map` 上渲染好友头像，并在收到新坐标时，使用插值动画（Tween Animation）让头像平滑移动到新位置，避免瞬移卡顿。

### 功能二：3D 轨迹回放动画 (Route Playback)
- **业务场景**：行程结束后，点击“生成回忆视频”按钮。地图自动隐藏多余 UI，进入上帝视角。镜头从起点开始，沿着 OSRM 画出的蓝色轨迹平滑飞行。当途径某个有照片的 POI 时，画面自动弹出一张该照片的“拍立得”缩略图。
- **技术拆解**：
  - 利用 `flutter_map` 的 `MapController`，编写一个基于 `Ticker` 或 `AnimationController` 的插值运算工具。
  - 算法需要能解析由 `LatLng` 组成的路线点阵，分帧改变相机的 `center` 和 `zoom`（甚至 `rotation` 产生 3D 环绕感）。
  - 与之前写好的本地数据库结合，提取特定节点的 Photo 数据并在特定帧触发 UI 弹窗。

---

## 🛠️ 我的指令：

由于这两个功能非常庞大，**我们严格分步骤进行，绝对不要一次性给我所做完。**

### 第一步：技术选型与防走散基础建设
请先针对 **【功能一：好友实时防走散】** 给出一套轻量级的后端/通信选型方案（尽量白嫖且好集成）。
然后，在不写具体后端代码的前提下，为我编写 Flutter 端的核心逻辑：
1. **Domain & Data 层**：如何定义 `LiveLocation` 实体，以及如何手写一个管理 WebSocket/实时流的 `LiveTrackingRepository`。
2. **State 层**：用原生 Riverpod 编写一个 `LiveTrackingNotifier`，把本地 GPS 上报与合并远端好友位置的逻辑串联起来。
