import Foundation
import SwiftUI

final class AppBundleToken: NSObject {}

enum AppLanguage: Equatable {
    case english
    case simplifiedChinese

    static func resolved(for locale: Locale = .autoupdatingCurrent) -> AppLanguage {
        let identifier = locale.identifier
            .replacingOccurrences(of: "-", with: "_")
            .lowercased()
        if identifier.hasPrefix("zh_hant")
            || identifier.hasPrefix("zh_tw")
            || identifier.hasPrefix("zh_hk")
            || identifier.hasPrefix("zh_mo") {
            return .english
        }
        if identifier.hasPrefix("zh") {
            return .simplifiedChinese
        }
        return .english
    }

    var localeIdentifier: String {
        switch self {
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        }
    }
}

enum AppStrings {
    static let bundle = Bundle(for: AppBundleToken.self)

    static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    static func string(_ key: String, table: String? = nil, localeIdentifier: String? = nil) -> String {
        localizedBundle(localeIdentifier: localeIdentifier)
            .localizedString(forKey: key, value: nil, table: table)
    }

    static func format(_ key: String, table: String? = nil, localeIdentifier: String? = nil, arguments: [CVarArg]) -> String {
        let format = string(key, table: table, localeIdentifier: localeIdentifier)
        let locale = Locale(identifier: localeIdentifier ?? Locale.autoupdatingCurrent.identifier)
        return String(format: format, locale: locale, arguments: arguments)
    }

    static func modelDisplayName(for model: ModelMetadata, locale: Locale = .autoupdatingCurrent) -> String {
        guard AppLanguage.resolved(for: locale) == .simplifiedChinese else {
            return model.displayName
        }

        switch model.id {
        case ModelManager.defaultModel.id:
            return string("model.default.displayName", localeIdentifier: AppLanguage.simplifiedChinese.localeIdentifier)
        case ModelManager.smallFallbackModel.id:
            return string("model.lite.displayName", localeIdentifier: AppLanguage.simplifiedChinese.localeIdentifier)
        default:
            return model.displayName
        }
    }

    private static func localizedBundle(localeIdentifier: String?) -> Bundle {
        guard let localeIdentifier,
              let path = bundle.path(forResource: localeIdentifier, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return bundle
        }
        return localizedBundle
    }
}
