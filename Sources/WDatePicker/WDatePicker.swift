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
    @Binding public var includesTime: Bool
    @State private var currentMonth = Date()
    @State private var isRangeMode = false
    @State private var tmpDateSelection: Date?
    @State private var tmpStartTimeSelection: Date = .init()
    @State private var tmpEndTimeSelection: Date = .init()
    @State private var days: [Date]

    static let daysInAWeek = 7
    static let weeksInAMonth = 5
    private let rangeModeLabel: String
    private let includesTimeLabel: String

    private var startDateString: String {
        if let dateValue {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("dd MMMM yyyy")
            switch dateValue {
            case let .single(date):
                return formatter.string(from: date)
            case let .range(start, _):
                return formatter.string(from: start)
            }
        } else {
            return "Choose date"
        }
    }

    private var endDateString: String {
        if let dateValue {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("dd MMMM yyyy")
            switch dateValue {
            case let .single(date):
                return formatter.string(from: date)
            case let .range(_, end):
                return formatter.string(from: end)
            }
        } else {
            return "Choose date"
        }
    }

    /// Create a WDatePicker
    /// - Parameter dateValue: pass a Binding object to get two-way connection
    /// - Parameter rangeModeLabel: pass your localized text for the label of range mode toggle
    public init(dateValue: Binding<WDateValue?>, includesTime: Binding<Bool>, rangeModeLabel: String = "Range Mode", includesTimeLabel: String = "Include Time") {
        _dateValue = dateValue
        _includesTime = includesTime
        self.rangeModeLabel = rangeModeLabel
        self.includesTimeLabel = includesTimeLabel
        _days = .init(initialValue: Self.getCalendarDays(of: Date()))
        updateStates(with: dateValue.wrappedValue)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Title and upper options

            HStack {
                Button {
                    dateValue = nil
                } label: {
                    Text("Clear")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)

                Spacer()

                Toggle(rangeModeLabel, isOn: $isRangeMode)
                    .toggleStyle(TinyToggleStyle())
                    .font(.footnote)
            }
            .padding([.top], 40)
            .padding([.bottom], 10)

            Divider()
                .padding([.bottom], 10)

            ZStack {
                HStack {
                    Text(getMonthString(of: currentMonth))
                        .font(.headline)
                    if !Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                        Button {
                            currentMonth = Date()
                        } label: {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                    }
                }
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
            .padding([.bottom], 14)

            // MARK: - Date grids

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
                                        if let tmpDateSelection {
                                            let newValue: WDateValue
                                            if tmpDateSelection < currentDate {
                                                newValue = .range(tmpDateSelection, currentDate)
                                            } else {
                                                newValue = .range(currentDate, tmpDateSelection)
                                            }
                                            if dateValue != newValue {
                                                dateValue = newValue
                                            } else {
                                                updateStates(with: dateValue)
                                            }
                                        } else {
                                            tmpDateSelection = currentDate
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
            .padding(.bottom, 4)

            Divider()
                .padding([.bottom], 10)

            // MARK: - Bottom options

            HStack {
                Toggle(includesTimeLabel, isOn: $includesTime)
                    .toggleStyle(.checkbox)
                    .font(.footnote)
                Spacer()
            }
            .padding(.bottom, 5)

            if includesTime {
                HStack {
                    Text(startDateString)
                    DatePicker("", selection: $tmpStartTimeSelection, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .scaledToFit()
                        .disabled(dateValue == nil)
                    Spacer()
                }
                if isRangeMode {
                    HStack {
                        Text(endDateString)
                        DatePicker("", selection: $tmpEndTimeSelection, displayedComponents: .hourAndMinute)
                            .scaledToFit()
                            .labelsHidden()
                            .disabled(dateValue == nil)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .padding([.top], -40) // fix arrow color
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
        .onChange(of: isRangeMode) { _ in
            tmpDateSelection = nil
            dateValue = nil
        }
        .onChange(of: tmpStartTimeSelection) {
            guard let dateValue else {
                return
            }
            switch dateValue {
            case let .single(date):
                self.dateValue = .single(combine(date: date, time: $0))
            case let .range(start, end):
                self.dateValue = .range(combine(date: start, time: $0), end)
            }
        }
        .onChange(of: tmpEndTimeSelection) {
            guard isRangeMode,
                  case let .range(start, end) = dateValue
            else {
                return
            }
            dateValue = .range(start, combine(date: end, time: $0))
        }
    }

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        return calendar.date(from: components) ?? date
    }

    private func shouldHighlight(for day: Date) -> Bool {
        let calendar = Calendar.current
        switch dateValue {
        case let .single(date):
            return calendar.isDate(day, inSameDayAs: date)
        case let .range(start, end):
            if let tmpDateSelection {
                return calendar.isDate(day, inSameDayAs: tmpDateSelection)
            } else {
                return start ... end ~= day
            }
        case nil:
            if let tmpDateSelection {
                return calendar.isDate(day, inSameDayAs: tmpDateSelection)
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
            tmpDateSelection = nil
            tmpStartTimeSelection = date
        case let .range(start, end):
            if !Calendar.current.isDate(end, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = end
            }
            if !isRangeMode {
                isRangeMode = true
            }
            tmpDateSelection = nil
            tmpStartTimeSelection = start
            tmpEndTimeSelection = end
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
        WDatePicker(dateValue: .constant(.single(Date())), includesTime: .init(get: { true }, set: { _ in }))
    }
}

// MARK: - TinyToggleStyle

struct TinyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 20, height: 10)
                    .foregroundColor(configuration.isOn ? Color(nsColor: .controlAccentColor) : .gray)
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.white)
                    .padding(.all, 1)
                    .shadow(radius: 1)
            }
            .onTapGesture {
                configuration.$isOn.wrappedValue.toggle()
            }
            .animation(.easeInOut(duration: 0.1), value: configuration.isOn)
        }
    }
}
