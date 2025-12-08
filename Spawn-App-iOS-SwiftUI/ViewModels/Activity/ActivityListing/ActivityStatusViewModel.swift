//
//  ActivityStatusViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/14/25.
//
import Foundation

@Observable
@MainActor
final class ActivityStatusViewModel {
	var status: ActivityStatus = .laterToday
	/// Timer for periodic status updates
	/// - Note: `nonisolated(unsafe)` allows safe access from nonisolated deinit.
	/// Thread safety is ensured by only accessing from MainActor context (via Timer's main runloop)
	/// and in deinit (which runs after all other accesses complete).
	@ObservationIgnored private nonisolated(unsafe) var timer: Timer?
	private let activityStartTime: Date
	private let activityDuration: TimeInterval  // in seconds
	private var refresh: Double = -1
	private var previousRefresh: Double?

	init(activity: FullFeedActivityDTO) {
		if let activityStart: Date = activity.startTime {
			self.activityStartTime = activityStart
		} else {
			self.activityStartTime = Date()
		}
		if let activityEnd: Date = activity.endTime {
			self.activityDuration = activityEnd.timeIntervalSince(activityStartTime)
		} else {
			self.activityDuration = TimeInterval.greatestFiniteMagnitude
		}
		updateStatus()
		startTimer()
	}

	deinit {
		// Safe to access nonisolated(unsafe) timer here - deinit runs after all references are released
		timer?.invalidate()
		timer = nil
	}

	private func startTimer() {
		// Update every minute
		guard refresh > 0 else { return }
		timer = Timer.scheduledTimer(withTimeInterval: refresh, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.updateStatus()
			}
		}
	}

	private func updateStatus() {
		let now = Date()
		let timeUntilStart: TimeInterval = activityStartTime.timeIntervalSince(now)
		let timeAfterStart: TimeInterval = now.timeIntervalSince(activityStartTime)
		let todayComponents = Calendar.current.dateComponents([.day], from: now)
		let today = todayComponents.day ?? 1
		let hourOfToday = todayComponents.hour ?? 1
		let activityDay = Calendar.current.dateComponents([.day], from: activityStartTime).day ?? 1

		if timeAfterStart >= 0 && timeAfterStart <= activityDuration {
			// Activity is currently happening
			status = .happeningNow
			refresh = activityDuration - timeAfterStart
		} else if timeUntilStart > 0 {
			let hoursUntilStart: Double = timeUntilStart / 3600

			if hoursUntilStart < 1 {
				let minutesUntilStart: Int = max(1, Int(round(timeUntilStart / 60)))
				status = .inMinutes(minutesUntilStart)
				refresh = 60
			} else if hoursUntilStart <= 3 {  // Show specific hours if within 3 hours
				let roundedHours = max(1, Int(round(hoursUntilStart)))
				status = .inHours(roundedHours)
				let floorHoursUntilInSeconds = floor(hoursUntilStart) * 3600 * -1
				let nextUpdateDate = activityStartTime.advanced(by: floorHoursUntilInSeconds)
				refresh = max(5, nextUpdateDate.timeIntervalSinceNow)  // Defensive check
			} else if today != activityDay && hoursUntilStart <= 24 {
				status = .inDays(1)
				let hoursUntilMidnight = 24 - hourOfToday
				let secondsUntilMidnight = Double(hoursUntilMidnight * 3600 * -1)
				let nextUpdateDate = activityStartTime.advanced(by: secondsUntilMidnight)
				refresh = max(5, nextUpdateDate.timeIntervalSinceNow)
			} else {
				status = .laterToday
				let hoursUntil3HoursAway = hoursUntilStart - 3
				refresh = hoursUntil3HoursAway * 3600
			}
		} else {
			// Activity has already ended
			status = .past
			refresh = -1
		}
		if let prev = previousRefresh, refresh == prev {
			return  // No need to restart timer
		}
		if previousRefresh == nil {
			previousRefresh = refresh
			return
		}
		if refresh != previousRefresh {
			timer?.invalidate()
			previousRefresh = refresh
			startTimer()
		}
	}
}
