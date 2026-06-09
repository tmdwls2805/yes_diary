import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "퇴근 타이머" }
    static var description: IntentDescription { IntentDescription("퇴근까지 남은 시간을 보여줍니다.") }
}
