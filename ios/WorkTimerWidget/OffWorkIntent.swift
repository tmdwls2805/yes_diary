import AppIntents
import WidgetKit
import Foundation

@available(iOS 17.0, *)
struct OffWorkIntent: AppIntent {
    static var title: LocalizedStringResource = "퇴근 처리"
    static var description: IntentDescription = IntentDescription("오늘 퇴근을 완료 상태로 표시합니다.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let appGroupId = "group.com.jjcompany.yesdiary"
        let offWorkDateKey = "offWorkDate"

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())

        if let defaults = UserDefaults(suiteName: appGroupId) {
            defaults.set(today, forKey: offWorkDateKey)
            defaults.synchronize()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "WorkTimerWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
