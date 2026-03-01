//
//  HomeWidget.swift
//  boringNotch
//
//  Configurable widgets for the home view right column.
//  Music is always fixed on the left — these fill the right side.
//

import Defaults

enum HomeWidget: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case calendar
    case market
    case pomodoro

    var id: String { rawValue }

    static let defaultOrder: [HomeWidget] = [.calendar, .market, .pomodoro]

    var displayName: String {
        switch self {
        case .calendar: return "Calendar & Weather"
        case .market: return "Market Ticker"
        case .pomodoro: return "Pomodoro Timer"
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .market: return "chart.line.uptrend.xyaxis"
        case .pomodoro: return "timer"
        }
    }

    var isEnabled: Bool {
        switch self {
        case .calendar: return Defaults[.showCalendar]
        case .market: return Defaults[.enableMarketTicker]
        case .pomodoro: return Defaults[.enablePomodoro]
        }
    }
}
