import ActivityKit
import SwiftUI
import WidgetKit

@main
struct MaRoutineWidgets: WidgetBundle {
    var body: some Widget {
        JourneeWidget()
        SeanceLiveActivity()
    }
}

struct EntreeJournee: TimelineEntry {
    let date: Date
}

struct FournisseurJournee: TimelineProvider {
    func placeholder(in context: Context) -> EntreeJournee { EntreeJournee(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (EntreeJournee) -> Void) { completion(EntreeJournee(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<EntreeJournee>) -> Void) {
        completion(Timeline(entries: [EntreeJournee(date: .now)], policy: .after(.now.addingTimeInterval(1800))))
    }
}

struct JourneeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "journee", provider: FournisseurJournee()) { _ in
            Text("Ma routine")
                .containerBackground(for: .widget) { Color.pink }
        }
        .configurationDisplayName("Ma journée")
        .description("Où tu en es dans ta routine.")
    }
}

struct SeanceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SeanceAttributes.self) { context in
            Text(context.state.exercice).padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) { Text(context.state.exercice) }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(context.state.faites)/\(context.state.total)")
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}
