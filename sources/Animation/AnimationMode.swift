//
//  AnimationMode.swift
//  Squirrel (Fluid fork)
//
//  Created for squirrel-fluid — adds Sogou-style candidate bar animations.
//
//  模仿搜狗输入法 Mac 版的候选条动画行为。三种模式：
//    - sogou  : 与逆向得到的搜狗真值一致
//               · 窗口 frame 过渡 = NSViewAnimation 0.2s (default curve)
//               · 候选项 frame 过渡 = [view animator] 0.25s (AppKit default)
//               · 隐藏 = 瞬切（orderOut, 无动画）
//    - smooth : 响应更跟手的短 duration + easeOut
//    - off    : 完全关闭动画（等价于 Squirrel upstream 行为）
//
//  这个 enum 不依赖 SquirrelTheme / SquirrelConfig 等任何 Squirrel 内部类型，
//  是为了让 Animation 模块可以被单独 import 到 demo / 测试 app 里验证。

import AppKit

enum AnimationMode: Int, CaseIterable {
  case sogou = 0
  case smooth = 1
  case off = 2

  /// 候选条**整个 NSPanel** 的 frame 变化 duration。
  /// 搜狗真值 0.2 来自 `*(double*)0x1007cc2f8`（-[SGCandidatesController updateWindow:] 内）。
  var windowDuration: TimeInterval {
    switch self {
    case .sogou:  return 0.20
    case .smooth: return 0.12
    case .off:    return 0
    }
  }

  /// 候选项 cell 的 frame 变化 duration。
  /// 搜狗没显式 setDuration，走 AppKit animator 默认 0.25s。
  var candidateDuration: TimeInterval {
    switch self {
    case .sogou:  return 0.25
    case .smooth: return 0.14
    case .off:    return 0
    }
  }

  /// 候选条隐藏动画 duration。
  /// 搜狗 -[SGCandidatesController hideWindow] 直接 orderOut:，无动画。
  /// smooth 模式给一个短 fade，观感更柔。
  var hideDuration: TimeInterval {
    switch self {
    case .sogou:  return 0
    case .smooth: return 0.08
    case .off:    return 0
    }
  }

  /// Timing function（曲线）。
  /// 搜狗的候选项用 AppKit default curve（近似 easeInEaseOut）。
  var timingFunction: CAMediaTimingFunction {
    switch self {
    case .sogou:  return CAMediaTimingFunction(name: .default)
    case .smooth: return CAMediaTimingFunction(name: .easeOut)
    case .off:    return CAMediaTimingFunction(name: .linear)
    }
  }

  /// 从 YAML 字符串解析（用在 SquirrelTheme.load 里）。
  static func parse(_ raw: String?) -> AnimationMode {
    switch raw?.lowercased() {
    case "sogou":  return .sogou
    case "smooth": return .smooth
    case "off":    return .off
    case nil:      return .sogou  // 默认开启搜狗风（这是本 fork 的卖点）
    default:       return .sogou
    }
  }
}
