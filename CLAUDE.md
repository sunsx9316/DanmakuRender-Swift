# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概述

DanmakuRender-Swift 是一个跨平台（iOS 10.0+ / tvOS 10.0+ / macOS 10.13+）弹幕渲染引擎，使用 Swift 5.0+ 编写，通过异步渲染实现高性能和可扩展性。

- **模块名**: `DanmakuRender`
- **分发方式**: CocoaPods (`DanmakuRender-Swift`) 和 Swift Package Manager
- **源码目录**: `DanmakuRender-Swift/Classes/`（SPM target 路径同此目录）

## 构建 & 校验

```bash
# SPM 构建
swift build

# CocoaPods 校验
pod lib lint DanmakuRender-Swift.podspec

# 运行 iOS 示例（需要 CocoaPods）
cd iOS-Example && pod install && open iOS-Example.xcworkspace

# 运行 MacOS 示例
cd MacOS-Example && pod install && open DanmakuRender-Swift.xcworkspace
```

测试目前仅存在于 MacOS-Example 项目中（`MacOS-Example/Tests/`），没有 SPM test target，不支持 `swift test`。

## 架构

### 入口: `DanmakuEngine`

`DanmakuEngine`（`DanmakuEngine.swift:10`）是核心类，调用方主要与之交互：

- `start()` / `stop()` / `pause()` — 生命周期控制
- `send(_ danmaku:)` — 将弹幕发射到画布上
- `update(_ danmaku:animateHandle:)` — 触发活跃弹幕的重新布局/绘制
- `time` / `speed` / `offsetTime` — 控制播放时间和速率
- `layoutStyle` — `.timely`（有弹幕就发射）或 `.nonOverlapping`（倾向不重叠，可能忽略部分弹幕）
- `delegate` — `DanmakuEngineDelegate` 生命周期回调

`DanmakuEngine` 持有一个 `Canvas`、一个 `Clock` 和两个容器池（`activeContainers` / `inactiveContainers`）。非活跃容器在 `send()` 时被回收复用。

### 时间系统: `Clock` + `DisplayLink`

- `Clock`（`Clock/Clock.swift`）以 `实际耗时 × speed + offset` 的方式追踪 `time`。每次 tick 通知 engine，engine 驱动每帧的弹幕更新。
- `DisplayLink`（`Clock/DisplayLink.swift`）封装平台差异：macOS 使用 `CVDisplayLink`，iOS 使用 `CADisplayLink`。
- 直接设置 `engine.time` 会重置时钟并停用所有容器——适用于 seek 场景。

### 画布与容器树

```
DanmakuCanvas (DRView)          ← 容器视图，通过 typealias 实现跨平台
  └── DanmakuContainer (DRView)  ← 每个活跃弹幕对应一个，从池中回收复用
        └── AsyncDisplayLayer (CALayer)  ← 异步绘制弹幕文字
```

- **`DanmakuCanvas`**（`DanmakuCanvas.swift`）：持有容器作为 subviews 的普通视图。布局时将全部容器标记为需要重新布局。macOS 上遵循 `NSViewLayerContentScaleDelegate` 以传递 scale 变化。
- **`DanmakuContainer`**（`DanmakuContainer.swift`）：桥接 `BaseDanmaku` 模型到视图层级。通过 `AsyncLayerDelegate` 将异步绘制委托给 `AsyncDisplayLayer`。`isActive` 标志——设为 `false` 后，engine 在下一 tick 将其从画布移除。

### 弹幕模型层级

```
BaseDanmaku（抽象类，遵循 AsyncLayerDisplayTask）
  ├── ScrollDanmaku  — 水平滚动弹幕（右→左 或 左→右）
  └── FloatDanmaku   — 固定位置弹幕（顶部或底部），在 lifeTime 后消失
```

- **`BaseDanmaku`**（`Danmaku/BaseDanmaku.swift`）：存储文字、字体、颜色、`effectStyle` 和 `appearTime`。`draw(_:size:isCancelled:)` 方法使用 `NSAttributedString` 绘制，支持描边/阴影/发光效果。根据文字颜色亮度自动计算 `effectColor`（黑色或白色）。
- **`ScrollDanmaku`**（`Danmaku/ScrollDanmaku.swift`）：通过防重叠逻辑（基于速度的追赶检测）管理轨道分配。`extraSpeed` 可针对单个弹幕调整速度。计算 `willDisappearTime` 和 `didDisappearTime` 用于轨道调度。
- **`FloatDanmaku`**（`Danmaku/FloatDanmaku.swift`）：选择活跃浮动弹幕最少的轨道（根据 `Position` 从上到下或从下到上）。超过 `lifeTime` 后消失。
- **`DanmakuContext`**（`Danmaku/DanmakuProtocol.swift`）：传给弹幕生命周期方法的只读快照，包含 engine/canvas/container 状态。
- **`DanmakuEngineDelegate`**（`Danmaku/DanmakuProtocol.swift`）：协议，定义 4 个生命周期回调（`shouldAddToCanvas`、`didLayout`、`update`、`willMoveOutCanvas`），均有默认空实现。
- **`DanmakuEffectStyle`** 枚举：`.none`、`.stroke`、`.shadow`、`.glow`。

### 异步渲染管线

渲染路径设计为将文字绘制工作放在主线程之外：

1. **`Transaction`**（`AsyncDisplayLayer/Transaction.swift`）：批量收集 `contentsNeedUpdated` 调用。`commit()` 时将自身插入静态 `Set<Transaction>`。一个 `MainRunLoopObserver` 在 `.beforeWaiting`/`.exit` 时触发，通过调用 target-selector 清空所有待处理事务。
2. **`AsyncDisplayLayer`**（`AsyncDisplayLayer/AsyncDisplayLayer.swift`）：在 `display()` 时从 delegate 获取绘制任务，加入 `AsyncDisplayQueue`。使用 `Sentinel`（原子递增计数器）检测过期任务——若绘制完成前 sentinel 值已变化，结果将被丢弃。
3. **`AsyncDisplayQueue`**（`AsyncDisplayLayer/AsyncDisplayQueue.swift`）：懒加载的 `OperationQueue`，`maxConcurrentOperationCount` = `activeProcessorCount`（上限 16）。

### 跨平台抽象

`Definition.swift` 定义了全局类型别名：

| 别名       | iOS          | macOS       |
|-----------|-------------|-------------|
| `DRView`  | `UIView`    | `NSView`    |
| `DRColor` | `UIColor`   | `NSColor`   |
| `DRImage` | `UIImage`   | `NSImage`   |
| `DRFont`  | `UIFont`    | `NSFont`    |

平台差异通过 `#if os(iOS)` / `#if os(macOS)` 在具体代码处处理（例如 `layer` vs `layer?`、`layoutSubviews()` vs `layout()`、`UIGraphicsBeginImageContext` vs `NSImage(size:flipped:)`）。

### 线程安全

- `Atomic.swift`：使用 `NSLock` 实现线程安全读写的 `@propertyWrapper`。被 `Transaction._transaction` 使用。
- `Sentinel`（`Transaction.swift`）：基于 `OSAtomicIncrement32` 的原子计数器，用于无效化过期的异步绘制任务。
- 异步绘制队列在后台线程创建位图，主线程负责设置 `layer.contents`。
