//
//  AnimationCoordinator.swift
//  Squirrel (Fluid fork)
//
//  统一的动画调度入口。所有候选条动画都走这里，方便：
//    - 三种模式（sogou/smooth/off）的 NSAnimationContext 配置
//    - 未来加日志 / debug / A-B 切换
//    - fastPath: mode == .off 时跳过所有动画代码，零 overhead
//
//  设计约束：
//    1. **不依赖 SquirrelTheme / SquirrelConfig**，只接收 AnimationMode 参数
//    2. 所有公开 API 都是 `static`，保持无状态（调度器本身无需持有状态）
//    3. 两个独立方法：`animateWindow` 和 `animateCandidates`，对应搜狗的两层动画

import AppKit

enum AnimationCoordinator {

  /// 候选条窗口层动画（对应搜狗 `-[SGCandidatesController updateWindow:]` 的 NSViewAnimation）。
  ///
  /// - Parameters:
  ///   - mode: 动画模式
  ///   - animations: 在闭包内做 window/view 的 frame/alpha 赋值，会被包进 NSAnimationContext
  ///   - completion: 动画结束后回调
  ///
  /// fastPath: mode == .off 时直接同步执行 animations 闭包 + 立即调用 completion，无 NSAnimationContext overhead。
  static func animateWindow(
    mode: AnimationMode,
    animations: () -> Void,
    completion: (() -> Void)? = nil
  ) {
    guard mode != .off else {
      animations()
      completion?()
      return
    }
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = mode.windowDuration
      ctx.timingFunction = mode.timingFunction
      ctx.allowsImplicitAnimation = true
      animations()
    }, completionHandler: completion)
  }

  /// 候选项层动画（对应搜狗 `-[SGCandidatesTextViewBase showCandidates]` 的 `[[layer animator] setFrame:]`）。
  /// 与 `animateWindow` 分开是因为搜狗的两层 duration 不同（窗口 0.2s，候选项 0.25s）。
  static func animateCandidates(
    mode: AnimationMode,
    animations: () -> Void,
    completion: (() -> Void)? = nil
  ) {
    guard mode != .off else {
      animations()
      completion?()
      return
    }
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = mode.candidateDuration
      ctx.timingFunction = mode.timingFunction
      ctx.allowsImplicitAnimation = true
      animations()
    }, completionHandler: completion)
  }

  /// 候选条隐藏动画。搜狗模式下是瞬切（mode.hideDuration == 0）。
  static func animateHide(
    mode: AnimationMode,
    animations: () -> Void,
    completion: (() -> Void)? = nil
  ) {
    guard mode.hideDuration > 0 else {
      animations()
      completion?()
      return
    }
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = mode.hideDuration
      ctx.timingFunction = mode.timingFunction
      ctx.allowsImplicitAnimation = true
      animations()
    }, completionHandler: completion)
  }
}
