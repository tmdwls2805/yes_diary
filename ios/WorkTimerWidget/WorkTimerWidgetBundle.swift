import WidgetKit
import SwiftUI

@main
struct WorkTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkTimerWidget()
        WorkTimerWidgetControl()
    }
}
