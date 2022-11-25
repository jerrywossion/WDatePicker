//
//  WDatePicker.swift
//  WDatePicker
//
//  Created by Jie Weng on 2022/7/20.
//

import SwiftUI

/// A datepicker supporting both single and range selection modes.
public struct WDatePicker: View {
    /// Currently selected value.
    @Binding public var dateValue: WDateValue?
    @State private var currentMonth = Date()
    @State private var isRangeMode = false
    @State private var tmpSelection: Date?
    @State private var days: [Date]

    static let daysInAWeek = 7
    static let weeksInAMonth = 5
    private let rangeModeLabel: String

    /// Create a WDatePicker
    /// - Parameter dateValue: pass a Binding object to get two-way connection
    /// - Parameter rangeModeLabel: pass your localized text for the label of range mode toggle
    public init(dateValue: Binding<WDateValue?>, rangeModeLabel: String = "Range Mode") {
        self._dateValue = dateValue
        self.rangeModeLabel = rangeModeLabel
        self._days = .init(initialValue: Self.getCalendarDays(of: Date()))
        updateStates(with: dateValue.wrappedValue)
    }

    public var body: some View {
        VStack {
            ZStack {
                Text(getMonthString(of: currentMonth))
                    .font(.headline)
                HStack {
                    Button {
                        if let date = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                            currentMonth = date
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Button {
                        if let date = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                            currentMonth = date
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding([.top], 40)
            .padding([.bottom], 14)
            Grid(horizontalSpacing: 0, verticalSpacing: 2) {
                GridRow {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                        Text(weekday)
                            .font(.headline)
                    }
                }
                .padding([.bottom], 4)
                if days.count == Self.weeksInAMonth * Self.daysInAWeek {
                    ForEach(0 ..< Self.weeksInAMonth, id: \.self) { w in
                        GridRow {
                            ForEach(0 ..< Self.daysInAWeek, id: \.self) { d in
                                Button {
                                    let currentDate = days[w * Self.daysInAWeek + d]
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
                                    Text(getDayString(of: days[w * Self.daysInAWeek + d]))
                                        .font(.body)
                                        .foregroundColor(getDayColor(of: days[w * Self.daysInAWeek + d]))
                                        .frame(width: 30, height: 30)
                                        .background {
                                            shouldHighlight(for: days[w * Self.daysInAWeek + d]) ? Color(nsColor: .selectedControlColor).opacity(0.5) : Color.clear
                                        }
                                        .cornerRadius(isRangeMode ? 0 : 15)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            HStack {
                Button {
                    if !Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                        currentMonth = Date()
                    }
                } label: {
                    Text("Today")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                .padding([.horizontal])
                Spacer()
                Toggle(rangeModeLabel, isOn: $isRangeMode)
                    .toggleStyle(.switch)
                    .font(.footnote)
            }
        }
        .padding()
        .background(.white)
        .padding([.top], -40)
        .onAppear {
            updateStates(with: dateValue)
            days = Self.getCalendarDays(of: currentMonth)
        }
        .onChange(of: dateValue) { value in
            updateStates(with: value)
        }
        .onChange(of: currentMonth) { _ in
            days = Self.getCalendarDays(of: currentMonth)
        }
        .onChange(of: isRangeMode) { isRangeMode in
            tmpSelection = nil
            dateValue = nil
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
        case nil:
            if let tmpSelection {
                return calendar.isDate(day, inSameDayAs: tmpSelection)
            } else {
                return false
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

    private func updateStates(with dateValue: WDateValue?) {
        guard let dateValue else {
            currentMonth = Date()
            return
        }
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

    private static func getCalendarDays(of month: Date) -> [Date] {
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
