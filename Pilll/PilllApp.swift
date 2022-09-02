//
//  PilllApp.swift
//  Pilll
//
//  Created by 廣瀬雄大 on 2022/09/02.
//

import SwiftUI

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

@main
struct PilllApp: App {
    init() {
        UserDefaults(suiteName: "abc")?.set(true, forKey: Const.userIsPremiumOrTrial)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
