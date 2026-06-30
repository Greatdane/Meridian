import Foundation

public struct ZoneDisplay: Equatable, Sendable {
    public let time: String
    public let compactTime: String
    public let dayLabel: String
    public let dateLine: String
    public let gmtOffset: String
    public let dayOffset: Int
}

public enum TimeZoneDisplay {
    public static func displayDate(baseDate: Date, sliderMinutes: Int) -> Date {
        baseDate.addingTimeInterval(TimeInterval(sliderMinutes * 60))
    }

    public static func snappedSliderMinutes(
        baseDate: Date,
        proposedSliderMinutes: Double,
        timeZone: TimeZone = .autoupdatingCurrent,
        minuteStep: Int = 5,
        range: ClosedRange<Int> = -720...720
    ) -> Int {
        let clamped = min(max(Int(proposedSliderMinutes.rounded()), range.lowerBound), range.upperBound)
        guard clamped != 0, minuteStep > 1 else {
            return clamped
        }

        let adjustedDate = displayDate(baseDate: baseDate, sliderMinutes: clamped)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let minute = calendar.component(.minute, from: adjustedDate)
        let remainder = minute % minuteStep
        guard remainder != 0 else {
            return clamped
        }

        let downCorrection = -remainder
        let upCorrection = minuteStep - remainder
        let correction = abs(downCorrection) <= abs(upCorrection) ? downCorrection : upCorrection
        return min(max(clamped + correction, range.lowerBound), range.upperBound)
    }

    public static func zoneDisplay(
        for timeZone: TimeZone,
        baseDate: Date,
        sliderMinutes: Int,
        referenceTimeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent,
        timeFormat: ClockTimeFormat = .twentyFourHour
    ) -> ZoneDisplay {
        let adjustedDate = displayDate(baseDate: baseDate, sliderMinutes: sliderMinutes)
        let dayOffset = calendarDayOffset(
            referenceDate: baseDate,
            displayDate: adjustedDate,
            referenceTimeZone: referenceTimeZone,
            timeZone: timeZone
        )

        return ZoneDisplay(
            time: formattedTime(adjustedDate, timeZone: timeZone, locale: locale, format: timeFormat.dateFormat),
            compactTime: formattedTime(adjustedDate, timeZone: timeZone, locale: locale, format: timeFormat.dateFormat),
            dayLabel: dayLabel(for: dayOffset),
            dateLine: formattedTime(adjustedDate, timeZone: timeZone, locale: locale, format: "EEE d MMM"),
            gmtOffset: gmtOffset(for: timeZone, at: adjustedDate),
            dayOffset: dayOffset
        )
    }

    public static func sliderLabel(
        baseDate: Date,
        sliderMinutes: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        referenceTimeZone: TimeZone = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent,
        timeFormat: ClockTimeFormat = .twentyFourHour
    ) -> String {
        guard sliderMinutes != 0 else {
            return "Now"
        }

        let adjustedDate = displayDate(baseDate: baseDate, sliderMinutes: sliderMinutes)
        let time = formattedTime(adjustedDate, timeZone: timeZone, locale: locale, format: timeFormat.dateFormat)
        let dayOffset = calendarDayOffset(
            referenceDate: baseDate,
            displayDate: adjustedDate,
            referenceTimeZone: referenceTimeZone,
            timeZone: timeZone
        )
        return "\(time) \(dayLabel(for: dayOffset))"
    }

    public static func calendarDayOffset(
        referenceDate: Date,
        displayDate: Date,
        referenceTimeZone: TimeZone = .autoupdatingCurrent,
        timeZone: TimeZone
    ) -> Int {
        let localComponents = dateComponents(for: referenceDate, timeZone: referenceTimeZone)
        let zoneComponents = dateComponents(for: displayDate, timeZone: timeZone)

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        guard
            let localDay = utcCalendar.date(from: localComponents),
            let zoneDay = utcCalendar.date(from: zoneComponents),
            let offset = utcCalendar.dateComponents([.day], from: localDay, to: zoneDay).day
        else {
            return 0
        }

        return offset
    }

    public static func dayLabel(for dayOffset: Int) -> String {
        switch dayOffset {
        case -1:
            return "Yesterday"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        case let offset where offset < 0:
            return "\(abs(offset)) days ago"
        default:
            return "+\(dayOffset) days"
        }
    }

    public static func inlineDaySuffix(for dayOffset: Int) -> String {
        switch dayOffset {
        case -1:
            return "(-1 day)"
        case 0:
            return ""
        case 1:
            return "(+1 day)"
        case let offset where offset < 0:
            return "(\(offset) days)"
        default:
            return "(+\(dayOffset) days)"
        }
    }

    public static func gmtOffset(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3_600
        let minutes = (absolute % 3_600) / 60
        return String(format: "GMT%@%02d:%02d", sign, hours, minutes)
    }

    public static func utcOffsetShort(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        guard seconds != 0 else {
            return "UTC"
        }

        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3_600
        let minutes = (absolute % 3_600) / 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }

        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    private static func formattedTime(
        _ date: Date,
        timeZone: TimeZone,
        locale: Locale,
        format: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }

    private static func dateComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
