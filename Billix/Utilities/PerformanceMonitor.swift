//
//  PerformanceMonitor.swift
//  Billix
//
//  Created by Claude Code on 2/1/26.
//  Debug utility to monitor Rewards screen performance fixes
//

import Foundation
import os.log

/// Performance monitor for tracking animation/timer lifecycle in Rewards screen
/// Enable DEBUG_PERFORMANCE in scheme to see logs
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private let logger = Logger(subsystem: "com.billix.app", category: "Performance")

    // Track active resources
    private var activeAnimations: [String: Date] = [:]
    private var activeTimers: [String: Date] = [:]
    private var activeTasks: [String: Date] = [:]

    private let queue = DispatchQueue(label: "com.billix.performanceMonitor")

    // Enable/disable logging (set to false for production)
    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false
    #endif

    private init() {}

    // MARK: - Animation Tracking

    func animationStarted(_ id: String, in view: String) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            self?.activeAnimations[key] = Date()
            self?.log("🎬 ANIMATION START: \(key)")
            self?.logActiveCount()
        }
    }

    func animationStopped(_ id: String, in view: String) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            if let startTime = self?.activeAnimations.removeValue(forKey: key) {
                let duration = Date().timeIntervalSince(startTime)
                self?.log("🎬 ANIMATION STOP: \(key) (ran for \(String(format: "%.1f", duration))s)")
            } else {
                self?.log("🎬 ANIMATION STOP: \(key) (was not tracked)")
            }
            self?.logActiveCount()
        }
    }

    // MARK: - Timer Tracking

    func timerStarted(_ id: String, in view: String, interval: TimeInterval) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            self?.activeTimers[key] = Date()
            self?.log("⏱️ TIMER START: \(key) (interval: \(interval)s)")
            self?.logActiveCount()
        }
    }

    func timerStopped(_ id: String, in view: String) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            if let startTime = self?.activeTimers.removeValue(forKey: key) {
                let duration = Date().timeIntervalSince(startTime)
                self?.log("⏱️ TIMER STOP: \(key) (ran for \(String(format: "%.1f", duration))s)")
            } else {
                self?.log("⏱️ TIMER STOP: \(key) (was not tracked)")
            }
            self?.logActiveCount()
        }
    }

    // MARK: - Task Tracking

    func taskStarted(_ id: String, in view: String) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            self?.activeTasks[key] = Date()
            self?.log("📋 TASK START: \(key)")
            self?.logActiveCount()
        }
    }

    func taskCancelled(_ id: String, in view: String) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            let key = "\(view).\(id)"
            if let startTime = self?.activeTasks.removeValue(forKey: key) {
                let duration = Date().timeIntervalSince(startTime)
                self?.log("📋 TASK CANCELLED: \(key) (ran for \(String(format: "%.1f", duration))s)")
            } else {
                self?.log("📋 TASK CANCELLED: \(key) (was not tracked)")
            }
            self?.logActiveCount()
        }
    }

    // MARK: - View Lifecycle

    func viewAppeared(_ view: String) {
        guard isEnabled else { return }
        log("👁️ VIEW APPEAR: \(view)")
    }

    func viewDisappeared(_ view: String) {
        guard isEnabled else { return }
        log("👁️ VIEW DISAPPEAR: \(view)")

        // Check for leaked resources from this view
        queue.async { [weak self] in
            guard let self = self else { return }

            let leakedAnimations = self.activeAnimations.keys.filter { $0.hasPrefix(view) }
            let leakedTimers = self.activeTimers.keys.filter { $0.hasPrefix(view) }
            let leakedTasks = self.activeTasks.keys.filter { $0.hasPrefix(view) }

            if !leakedAnimations.isEmpty {
                self.log("⚠️ LEAK WARNING: \(leakedAnimations.count) animations still active after \(view) disappeared: \(leakedAnimations)")
            }
            if !leakedTimers.isEmpty {
                self.log("⚠️ LEAK WARNING: \(leakedTimers.count) timers still active after \(view) disappeared: \(leakedTimers)")
            }
            if !leakedTasks.isEmpty {
                self.log("⚠️ LEAK WARNING: \(leakedTasks.count) tasks still active after \(view) disappeared: \(leakedTasks)")
            }
        }
    }

    // MARK: - Status Report

    func printStatus() {
        guard isEnabled else { return }
        queue.async { [weak self] in
            guard let self = self else { return }

            self.log("═══════════════════════════════════════")
            self.log("📊 PERFORMANCE MONITOR STATUS")
            self.log("───────────────────────────────────────")
            self.log("Active Animations: \(self.activeAnimations.count)")
            for (key, startTime) in self.activeAnimations {
                let duration = Date().timeIntervalSince(startTime)
                self.log("  • \(key) (running \(String(format: "%.1f", duration))s)")
            }
            self.log("Active Timers: \(self.activeTimers.count)")
            for (key, startTime) in self.activeTimers {
                let duration = Date().timeIntervalSince(startTime)
                self.log("  • \(key) (running \(String(format: "%.1f", duration))s)")
            }
            self.log("Active Tasks: \(self.activeTasks.count)")
            for (key, startTime) in self.activeTasks {
                let duration = Date().timeIntervalSince(startTime)
                self.log("  • \(key) (running \(String(format: "%.1f", duration))s)")
            }
            self.log("═══════════════════════════════════════")
        }
    }

    // MARK: - Periodic Health Check

    /// Call this to start periodic status reports (every 10 seconds)
    func startPeriodicMonitoring() {
        guard isEnabled else { return }

        Task { @MainActor in
            log("🔄 Starting periodic performance monitoring (every 10s)")
            while true {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                printStatus()
            }
        }
    }

    // MARK: - Private

    private func log(_ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        print("[PerformanceMonitor] \(message)")
        #endif
    }

    private func logActiveCount() {
        let total = activeAnimations.count + activeTimers.count + activeTasks.count
        if total > 0 {
            log("📈 Active resources: \(activeAnimations.count) animations, \(activeTimers.count) timers, \(activeTasks.count) tasks")
        }
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// Shorthand for common view names
    enum ViewName: String {
        case floatingParticles = "FloatingParticles"
        case walletHeader = "WalletHeader"
        case tierProgressRing = "TierProgressRing"
        case arcadeHeroCard = "ArcadeHeroCard"
        case coinView = "CoinView"
        case dailyGameHeroCard = "DailyGameHeroCard"
        case dailyTasksSection = "DailyTasksSection"
        case weeklyTasksSection = "WeeklyTasksSection"
        case streakStatsCarousel = "StreakStatsCarousel"
        case rewardsHub = "RewardsHub"
    }
}
