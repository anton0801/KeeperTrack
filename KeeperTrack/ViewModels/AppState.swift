import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("colorThemeRaw") private var colorThemeRaw: String = "system"
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"

    var colorTheme: ColorTheme {
        get { ColorTheme(rawValue: colorThemeRaw) ?? .system }
        set { colorThemeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch colorTheme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    enum ColorTheme: String, CaseIterable {
        case dark = "dark"
        case light = "light"
        case system = "system"

        var label: String {
            switch self {
            case .dark: return "Dark"
            case .light: return "Light"
            case .system: return "System"
            }
        }
    }

    var springAnimation: Animation {
        .spring(response: 0.4 / animationSpeed, dampingFraction: 0.7)
    }
}
