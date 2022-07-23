//
//  WDatePicker.swift
//  WDatePicker
//
//  Created by Jie Weng on 2022/7/20.
//

import SwiftUI

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

/// A datepicker supporting both single and range selection modes.
public struct WDatePicker: View {
    /// Currently selected value.
    @Binding public var dateValue: WDateValue
    @State private var currentMonth = Date()
    @State private var isRangeMode = false
    @State private var tmpSelection: Date?
    @State private var days: [Date] = []

    private let daysInAWeek = 7
    private let weeksInAMonth = 5
    private let rangeModeLabel: String

    /// Create a WDatePicker
    /// - Parameter dateValue: pass a Binding object to get two-way connection
    /// - Parameter rangeModeLabel: pass your localized text for the label of range mode toggle
    public init(dateValue: Binding<WDateValue>, rangeModeLabel: String = "Range Mode") {
        self._dateValue = dateValue
        self.rangeModeLabel = rangeModeLabel
    }

    public var body: some View {
        VStack {
            HStack {
                Text(getMonthString(of: currentMonth))
                    .font(.title)
                Spacer()
                HStack {
                    Group {
                        Button {
                            if let date = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                                currentMonth = date
                            }
                        } label: {
                            Image(systemName: "arrowtriangle.left.fill")
                        }
                        Button {
                            if !Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                                currentMonth = Date()
                            }
                        } label: {
                            Image(systemName: "circle.fill")
                        }
                        Button {
                            if let date = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                                currentMonth = date
                            }
                        } label: {
                            Image(systemName: "arrowtriangle.right.fill")
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            Grid {
                GridRow {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                        Text(weekday)
                    }
                }
                Divider()
                if days.count == weeksInAMonth * daysInAWeek {
                    ForEach(0 ..< weeksInAMonth, id: \.self) { w in
                        GridRow {
                            ForEach(0 ..< daysInAWeek, id: \.self) { d in
                                Button {
                                    let currentDate = days[w * daysInAWeek + d]
                                    if isRangeMode {
                                        if let tmpSelection {
                                            let newValue: WDateValue
                                            if tmpSelection < currentDate {
                                                newValue = .range(tmpSelection, currentDate)
                                            } else {
                                                newValue = .range(currentDate, tmpSelection)
                                            }
                                            if dateValue != newValue {
                                                dateValue = newValue
                                            } else {
                                                updateStates(with: dateValue)
                                            }
                                        } else {
                                            tmpSelection = currentDate
                                        }
                                    } else {
                                        dateValue = .single(currentDate)
                                    }
                                } label: {
                                    Text(getDayString(of: days[w * daysInAWeek + d]))
                                        .foregroundColor(getDayColor(of: days[w * daysInAWeek + d]))
                                        .frame(minWidth: 30, minHeight: 30)
                                        .background {
                                            Circle()
                                                .fill(shouldHighlight(for: days[w * daysInAWeek + d]) ? Color(nsColor: .selectedControlColor) : .clear)
                                        }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            Divider()
            HStack {
                Spacer()
                Toggle(rangeModeLabel, isOn: $isRangeMode)
                    .toggleStyle(.switch)
            }
        }
        .padding()
        .onAppear {
            updateStates(with: dateValue)
            days = getCalendarDays(of: currentMonth)
        }
        .onChange(of: dateValue) { value in
            updateStates(with: value)
        }
        .onChange(of: currentMonth) { _ in
            days = getCalendarDays(of: currentMonth)
        }
        .onChange(of: isRangeMode) { isRangeMode in
            if isRangeMode {
                if case let .single(date) = dateValue {
                    tmpSelection = date
                }
            } else {
                if case .range = dateValue {
                    tmpSelection = nil
                }
            }
        }
    }

    private func shouldHighlight(for day: Date) -> Bool {
        let calendar = Calendar.current
        switch dateValue {
        case let .single(date):
            return calendar.isDate(day, inSameDayAs: date)
        case let .range(start, end):
            if let tmpSelection {
                return calendar.isDate(day, inSameDayAs: tmpSelection)
            } else {
                return start ... end ~= day
            }
        }
    }

    private func getMonthString(of month: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: month)
    }

    private func getDayString(of date: Date) -> String {
        let dc = Calendar.current.dateComponents([.day, .weekday], from: date)
        if let day = dc.day {
            return "\(day)"
        } else {
            return ""
        }
    }

    private func getDayColor(of date: Date) -> Color {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: Date()) {
            return Color(nsColor: .systemRed)
        } else {
            return Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .primary : .secondary
        }
    }

    private func updateStates(with dateValue: WDateValue) {
        switch dateValue {
        case let .single(date):
            if !Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = date
            }
            if isRangeMode {
                isRangeMode = false
            }
            tmpSelection = nil
        case let .range(_, end):
            if !Calendar.current.isDate(end, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = end
            }
            if !isRangeMode {
                isRangeMode = true
            }
            tmpSelection = nil
        }
    }

    private func getCalendarDays(of month: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let dateDc = calendar.dateComponents([.month, .year, .day], from: month)
        var firstDateInMonthDc = dateDc
        firstDateInMonthDc.day = 1
        let firstDateInMonth = calendar.date(from: firstDateInMonthDc)
        guard let firstDateInMonth = firstDateInMonth else {
            return []
        }
        firstDateInMonthDc = calendar.dateComponents([.year, .month, .day, .weekday], from: firstDateInMonth)
        guard var weekday = firstDateInMonthDc.weekday else {
            return []
        }
        weekday -= 1
        let count = weeksInAMonth * daysInAWeek
        for i in 0 ..< count {
            if let date = calendar.date(byAdding: .day, value: i - weekday, to: firstDateInMonth) {
                dates.append(date)
            }
        }
        return dates
    }
}

struct WDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        WDatePicker(dateValue: .constant(.single(Date())))
    }
}
