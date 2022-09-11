//
//  WDateValue.swift
//
//
//  Created by Jie Weng on 2022/11/25.
//

import Foundation

/// Currently selected value of a WDatePicker.
public enum WDateValue: Equatable {
    /// Value for single selection mode.
    case single(Date)
    /// Value for range selection mode, with a start Date and an end Date.
    case range(Date, Date)

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.single(l), .single(r)):
            return l == r
        case let (.range(ll, lr), .range(rl, rr)):
            return ll == rl && lr == rr
        default:
            return false
        }
    }

    /// Information of current value, "date" for single mode "start - end" for range mode.
    public var description: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM dd")
        switch self {
        case let .single(date):
            return formatter.string(from: date)
        case let .range(date, date2):
            return "\(formatter.string(from: date)) - \(formatter.string(from: date2))"
        }
    }
}
