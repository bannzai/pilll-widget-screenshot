import WidgetKit
import SwiftUI
import Intents
import Foundation

enum Const {
  static let widgetKind = "com.mizuki.Ohashi.Pilll.widget"

  static let userIsPremiumOrTrial = "userIsPremiumOrTrial"

  static let pillSheetGroupTodayPillNumber = "pillSheetGroupTodayPillNumber"
  static let pillSheetTodayPillNumber = "pillSheetTodayPillNumber"
  static let pillSheetEndDisplayPillNumber = "pillSheetEndDisplayPillNumber"
  // Epoch milli second
  static let pillSheetLastTakenDate = "pillSheetLastTakenDate"
  // Epoch milli second
  static let pillSheetValueLastUpdateDateTime = "pillSheetValueLastUpdateDateTime"

  static let settingPillSheetAppearanceMode = "settingPillSheetAppearanceMode" // number or date or sequential
}

enum Plist {
  static var appGroupKey: String {
    Bundle.main.infoDictionary!["AppGroupKey"] as! String
  }
}


fileprivate var calendar: Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = .autoupdatingCurrent
  calendar.timeZone = .autoupdatingCurrent
  return calendar
}

fileprivate var dateFormater: DateFormatter {
  let dateFormater = DateFormatter()
  dateFormater.locale = .autoupdatingCurrent
  dateFormater.timeZone = .autoupdatingCurrent
  return dateFormater
}

func displayTodayPillNumber(todayPillNumber: Int, appearanceMode: Entry.SettingPillSheetAppearanceMode) -> String {
  switch appearanceMode {
  case .number:
    return "\(todayPillNumber)番"
  case .date:
    return "\(todayPillNumber)番"
  case .sequential:
    return "\(todayPillNumber)日目"
  case _:
    return ""
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry {
    .init(date: .now)
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
    completion(placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let intervalMinute = 15
    let oneDayLoopCount = 24 * (4 * intervalMinute)
    let entries: [Entry] = .init(repeating: .init(date: .now.addingTimeInterval(TimeInterval(intervalMinute * 60))), count: oneDayLoopCount)
    let nextTimelineSchedule = Calendar.current.date(byAdding: .minute, value: intervalMinute, to: .now)!
    let timeline = Timeline(entries: entries, policy: .after(nextTimelineSchedule))
    completion(timeline)
  }
}

struct Entry: TimelineEntry {
  // Timeline Entry required property
  let date: Date

  // PillSheet property
  var pillSheetTodayPillNumber: Int?
  var pillSheetGroupTodayPillNumber: Int?
  var pillSheetEndDisplayPillNumber: Int?
  var pillSheetLastTakenDate: Date?

  // Setting property
  var settingPillSheetAppearanceMode: SettingPillSheetAppearanceMode = .number
  enum SettingPillSheetAppearanceMode: String {
    case number, date, sequential
  }

  // Timestamp
  var pillSheetValueLastUpdateDateTime: Date?

  var userIsPremiumOrTrial = false

  init(date: Date) {
    self.date = date

    func contains(_ key: String) -> Bool {
      UserDefaults(suiteName: Plist.appGroupKey)?.dictionaryRepresentation().keys.contains(key) == true
    }

    if contains(Const.pillSheetTodayPillNumber), let pillSheetTodayPillNumber = UserDefaults(suiteName: Plist.appGroupKey)?.integer(forKey: Const.pillSheetTodayPillNumber) {
      self.pillSheetTodayPillNumber = pillSheetTodayPillNumber
    } else {
      self.pillSheetTodayPillNumber = nil
    }

    if contains(Const.pillSheetGroupTodayPillNumber), let pillSheetGroupTodayPillNumber = UserDefaults(suiteName: Plist.appGroupKey)?.integer(forKey: Const.pillSheetGroupTodayPillNumber) {
      self.pillSheetGroupTodayPillNumber = pillSheetGroupTodayPillNumber
    } else {
      self.pillSheetGroupTodayPillNumber = nil
    }

    if contains(Const.pillSheetEndDisplayPillNumber), let pillSheetEndDisplayPillNumber = UserDefaults(suiteName: Plist.appGroupKey)?.integer(forKey: Const.pillSheetEndDisplayPillNumber) {
      self.pillSheetEndDisplayPillNumber = pillSheetEndDisplayPillNumber
    } else {
      self.pillSheetEndDisplayPillNumber = nil
    }

    if contains(Const.pillSheetLastTakenDate), let pillSheetLastTakenDateEpochMilliSecond = UserDefaults(suiteName: Plist.appGroupKey)?.integer(forKey: Const.pillSheetLastTakenDate) {
      self.pillSheetLastTakenDate = Date(timeIntervalSince1970: TimeInterval(pillSheetLastTakenDateEpochMilliSecond / 1000))
    } else {
      self.pillSheetLastTakenDate = nil
    }

    if contains(Const.settingPillSheetAppearanceMode), let settingPillSheetAppearanceMode = UserDefaults(suiteName: Plist.appGroupKey)?.string(forKey: Const.settingPillSheetAppearanceMode) {
      self.settingPillSheetAppearanceMode = .init(rawValue: settingPillSheetAppearanceMode) ?? .number
    }

    if contains(Const.pillSheetValueLastUpdateDateTime), let pillSheetValueLastUpdateDateTimeEpochMilliSecond = UserDefaults(suiteName: Plist.appGroupKey)?.integer(forKey: Const.pillSheetValueLastUpdateDateTime) {
      self.pillSheetValueLastUpdateDateTime = Date(timeIntervalSince1970: TimeInterval(pillSheetValueLastUpdateDateTimeEpochMilliSecond / 1000))
    } else {
      self.pillSheetValueLastUpdateDateTime = nil
    }
  }

}

extension Entry {
  private var todayPillNumber: Int? {
    guard let pillSheetValueLastUpdateDateTime = pillSheetValueLastUpdateDateTime else {
      return nil
    }

    let todayPillNumberBase: Int
    switch settingPillSheetAppearanceMode {
    case .number, .date:
      guard let pillSheetTodayPillNumber = pillSheetTodayPillNumber else {
        return nil
      }
      todayPillNumberBase = pillSheetTodayPillNumber
    case .sequential:
      guard let recordedPillSheetGroupTodayPillNumber = pillSheetGroupTodayPillNumber else {
        return nil
      }
      todayPillNumberBase = recordedPillSheetGroupTodayPillNumber
    }

    guard let diff = calendar.dateComponents([.day], from: date, to: pillSheetValueLastUpdateDateTime).day else {
      return todayPillNumberBase
    }
    let todayPillNumber = todayPillNumberBase + diff

    if let pillSheetEndDisplayPillNumber = pillSheetEndDisplayPillNumber, todayPillNumber > pillSheetEndDisplayPillNumber {
      // 更新されるまで常に1で良い
      return 1
    } else {
      return todayPillNumber
    }
  }

  private var alreadyTaken: Bool {
    guard let pillSheetLastTakenDate = pillSheetLastTakenDate else {
      return false
    }
    return calendar.isDate(date, inSameDayAs: pillSheetLastTakenDate)
  }

  var status: Status {
    if userIsPremiumOrTrial {
      return .pill(todayPillNumber: todayPillNumber, alreadyTaken: alreadyTaken)
    } else {
      return .userIsNotPremiumOrTrial
    }
  }
}

protocol WidgetView: View {
  var entry: Entry { get }
}

extension WidgetView {
  var weekday: String {
    dateFormater.weekdaySymbols[calendar.component(.weekday, from: entry.date) - 1]
  }

  var day: Int {
    calendar.component(.day, from: entry.date)
  }
}

enum Status {
  case userIsNotPremiumOrTrial
  case pill(todayPillNumber: Int?, alreadyTaken: Bool)
}


struct AccessoryCircularWidget: WidgetView {
  let entry: Entry

  var body: some View {
    Group {
      switch entry.status {
      case let .pill(todayPillNumber, alreadyTaken):
        HStack {
          Image("pilll-widget-icon")


          if let todayPillNumber {
            Text(displayTodayPillNumber(todayPillNumber: todayPillNumber, appearanceMode: .number))


            if alreadyTaken {
              Image("check-icon-on")
                .resizable()
                .frame(width: 18, height: 18)
              }
            Spacer()
          }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
      case .userIsNotPremiumOrTrial:
        VStack {
          Image("pilll-widget-icon")
            .frame(width: 5.5, height: 8)

          Image(systemName: "xmark")
            .font(.system(size: 9))
        }
      }
    }
  }
}


extension Color {
  static let primary: Color = .init(red: 78 / 255, green: 98 / 255, blue: 135 / 255)
  static let orange: Color = .init(red: 229 / 255, green: 106 / 255, blue: 69 / 255)
  static let mainText: Color = .init(red: 41 / 255, green: 48 / 255, blue: 77 / 255, opacity: 0.87)
}

@main
struct Entrypoint: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: Const.widgetKind, provider: Provider()) { entry in
      AccessoryCircularWidget(entry: entry)
    }
    .supportedFamilies(supportedFamilies)
    .configurationDisplayName("今日飲むピルが一目でわかる")
    .description("This is a Pilll widget")
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .accessoryRectangular]
    } else {
      return [.systemSmall]
    }
  }
}

struct Widget_Previews: PreviewProvider {
  static var entry: Entry {
    var entry = Entry(date: .now)
    entry.userIsPremiumOrTrial = true
    entry.pillSheetGroupTodayPillNumber = 20
    entry.pillSheetTodayPillNumber = 20
    entry.pillSheetLastTakenDate = .now
    entry.pillSheetEndDisplayPillNumber = 100
    entry.pillSheetValueLastUpdateDateTime = .now
    return entry
  }
  static var previews: some View {
    AccessoryCircularWidget(entry: entry)
      .previewContext(WidgetPreviewContext(family: .accessoryInline))
    AccessoryCircularWidget(entry: {
      var copied = entry
      copied.pillSheetLastTakenDate = Date(timeIntervalSince1970: 0)
      return copied
    }())
      .previewContext(WidgetPreviewContext(family: .accessoryInline))
  }
}


