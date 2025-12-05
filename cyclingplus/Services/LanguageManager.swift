//
//  LanguageManager.swift
//  cyclingplus
//
//  Created by Codex on 2025/12/04.
//

import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    
    static let userDefaultsKey = "appLanguage"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
    
    static func currentFromDefaults() -> AppLanguage {
        let raw = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey)
        return AppLanguage(rawValue: raw ?? "") ?? .english
    }
}

final class LanguageManager: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
    }
    
    init() {
        self.language = AppLanguage.currentFromDefaults()
    }
}
