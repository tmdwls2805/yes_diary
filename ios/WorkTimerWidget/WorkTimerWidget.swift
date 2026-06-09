import WidgetKit
import SwiftUI
import AppIntents

private let appGroupId = "group.com.jjcompany.yesdiary"
private let endTimeKey = "workEndTime"
private let startTimeKey = "workStartTime"
private let offWorkDateKey = "offWorkDate"
private let wakeUpLeadMinutes = 180

enum TimeState {
    case wakeUp        // 출근 준비중
    case work          // 업무중
    case afterWork     // 퇴근! (탭 가능)
    case bedTime       // 출근 카운트다운 (이미 퇴근 처리 완료)
}

struct WorkTimerEntry: TimelineEntry {
    let date: Date
    let startTime: (Int, Int)?  // (hour, minute)
    let endTime: (Int, Int)?
    let isOffWork: Bool
    let configuration: ConfigurationAppIntent
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WorkTimerEntry {
        WorkTimerEntry(
            date: Date(),
            startTime: (9, 0),
            endTime: (18, 0),
            isOffWork: false,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> WorkTimerEntry {
        return currentEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<WorkTimerEntry> {
        let now = Date()
        // 다음 1시간 동안 5분 간격으로 entry 생성 (상태 변화 부드럽게 반영)
        var entries: [WorkTimerEntry] = []
        for offset in stride(from: 0, to: 60, by: 5) {
            if let date = Calendar.current.date(byAdding: .minute, value: offset, to: now) {
                entries.append(currentEntry(configuration: configuration, at: date))
            }
        }
        let refresh = Calendar.current.date(byAdding: .minute, value: 60, to: now) ?? now.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(refresh))
    }

    private func currentEntry(configuration: ConfigurationAppIntent, at date: Date = Date()) -> WorkTimerEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let rawStart = defaults?.string(forKey: startTimeKey) ?? ""
        let rawEnd = defaults?.string(forKey: endTimeKey) ?? ""
        let offDate = defaults?.string(forKey: offWorkDateKey) ?? ""

        return WorkTimerEntry(
            date: date,
            startTime: parseHM(rawStart),
            endTime: parseHM(rawEnd),
            isOffWork: !offDate.isEmpty && offDate == dateString(date),
            configuration: configuration
        )
    }
}

private func parseHM(_ s: String) -> (Int, Int)? {
    let parts = s.split(separator: ":")
    if parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) {
        return (h, m)
    }
    return nil
}

private func dateString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

// MARK: - 홈탭 로직 그대로 이식
private func toMinutes(_ hm: (Int, Int)) -> Int { hm.0 * 60 + hm.1 }
private func normalize(_ m: Int) -> Int { ((m % 1440) + 1440) % 1440 }

private func isInRange(_ value: Int, _ start: Int, _ end: Int) -> Bool {
    if start == end { return true }
    if start < end { return value >= start && value < end }
    return value >= start || value < end
}

private func computeState(entry: WorkTimerEntry) -> (TimeState, String) {
    let now = entry.date
    let start = entry.startTime ?? (9, 0)
    let end = entry.endTime ?? (18, 0)
    let startMin = toMinutes(start)
    let endMin = toMinutes(end)
    let wakeMin = normalize(startMin - wakeUpLeadMinutes)
    let nowMin = Calendar.current.component(.hour, from: now) * 60
                 + Calendar.current.component(.minute, from: now)

    // 1) 기상 준비
    if isInRange(nowMin, wakeMin, startMin) {
        return (.wakeUp, "출근 준비중...")
    }
    // 2) 업무중
    if isInRange(nowMin, startMin, endMin) {
        let remaining = workEndDate(now: now, end: end, start: start).timeIntervalSince(now)
        let mins = max(0, Int(remaining / 60))
        let suffixes = [".", "..", "..."]
        let dot = suffixes[Calendar.current.component(.second, from: now) % 3]
        if mins <= 60 {
            return (.work, "H-0 M-\(mins) 업무중\(dot)")
        }
        let hours = Int(ceil(Double(mins) / 60.0))
        return (.work, "H-\(hours) 업무중\(dot)")
    }
    // 3) 퇴근 후 (이미 처리됐으면 bedTime, 아니면 afterWork)
    if entry.isOffWork {
        let hoursToStart = remainingUntilWorkStartHours(now: now, start: start)
        return (.bedTime, "출근 H-\(hoursToStart)")
    } else {
        let elapsed = elapsedAfterWorkHours(now: now, end: end, start: start)
        return (.afterWork, "H+\(elapsed) 퇴근!")
    }
}

private func workEndDate(now: Date, end: (Int, Int), start: (Int, Int)) -> Date {
    let cal = Calendar.current
    var comps = cal.dateComponents([.year, .month, .day], from: now)
    comps.hour = end.0
    comps.minute = end.1
    var d = cal.date(from: comps) ?? now
    let nowMin = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    if toMinutes(end) <= toMinutes(start) && nowMin >= toMinutes(start) {
        d = cal.date(byAdding: .day, value: 1, to: d) ?? d
    }
    return d
}

private func remainingUntilWorkStartHours(now: Date, start: (Int, Int)) -> Int {
    let cal = Calendar.current
    var comps = cal.dateComponents([.year, .month, .day], from: now)
    comps.hour = start.0
    comps.minute = start.1
    var s = cal.date(from: comps) ?? now
    if !s.isAfter(now) {
        s = cal.date(byAdding: .day, value: 1, to: s) ?? s
    }
    let remaining = s.timeIntervalSince(now)
    return max(0, Int(ceil(remaining / 3600.0)))
}

private func elapsedAfterWorkHours(now: Date, end: (Int, Int), start: (Int, Int)) -> Int {
    let cal = Calendar.current
    let nowMin = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    let startMin = toMinutes(start)
    let endMin = toMinutes(end)
    let wakeMin = normalize(startMin - wakeUpLeadMinutes)
    let afterWraps = endMin > wakeMin

    var anchor = now
    if afterWraps && nowMin < wakeMin {
        anchor = cal.date(byAdding: .day, value: -1, to: now) ?? now
    }
    var comps = cal.dateComponents([.year, .month, .day], from: anchor)
    comps.hour = end.0
    comps.minute = end.1
    let lastEnd = cal.date(from: comps) ?? now
    let elapsed = now.timeIntervalSince(lastEnd)
    return max(0, Int(elapsed / 3600.0))
}

extension Date {
    func isAfter(_ other: Date) -> Bool { self > other }
}

// MARK: - View
private func imageName(for state: TimeState) -> String {
    switch state {
    case .wakeUp: return "wake_up_time"
    case .work: return "work_time"
    case .afterWork: return "night_work_time"
    case .bedTime: return "bed_time"
    }
}

struct WorkTimerWidgetEntryView: View {
    var entry: WorkTimerEntry

    var body: some View {
        let (state, label) = computeState(entry: entry)

        ZStack {

            // 하단 라벨 / 버튼 + 우측 하단 새로고침
            VStack {
                Spacer()
                ZStack(alignment: .trailing) {
                    if state == .afterWork {
                        if #available(iOS 17.0, *) {
                            Button(intent: OffWorkIntent()) {
                                Text(label)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(red: 1.0, green: 0.32, blue: 0.32).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(label)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(red: 1.0, green: 0.32, blue: 0.32).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Text(label)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.23, green: 0.23, blue: 0.23).opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // 우측 하단 새로고침 버튼 (버튼 위에 살짝 띄움)
                    if #available(iOS 17.0, *) {
                        Button(intent: RefreshIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkTimerWidget: Widget {
    let kind: String = "WorkTimerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            let (state, _) = computeState(entry: entry)
            if #available(iOS 17.0, *) {
                WorkTimerWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        ZStack {
                            Color(red: 0.10, green: 0.10, blue: 0.10)
                            Image(imageName(for: state))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .offset(y: state == .bedTime ? 24 : -4)
                        }
                    }
            } else {
                WorkTimerWidgetEntryView(entry: entry)
                    .background(
                        ZStack {
                            Color(red: 0.10, green: 0.10, blue: 0.10)
                            Image(imageName(for: state))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    )
            }
        }
        .configurationDisplayName("퇴근 타이머")
        .description("업무중/퇴근 후 상태를 보여줘요. 퇴근 시간이 되면 탭해서 처리할 수 있어요.")
        .supportedFamilies([.systemSmall])
    }
}
