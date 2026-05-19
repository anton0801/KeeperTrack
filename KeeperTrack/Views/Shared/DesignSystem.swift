import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgDark       = Color(hex: "#052E16")
    static let bgStadium    = Color(hex: "#14532D")
    static let bgNight      = Color(hex: "#111827")
    // Accents
    static let accentGreen  = Color(hex: "#22C55E")
    static let accentOrange = Color(hex: "#F97316")
    static let accentYellow = Color(hex: "#FACC15")
    static let accentWhite  = Color(hex: "#FFFFFF")
    // Chart
    static let chartSave    = Color(hex: "#22C55E")
    static let chartMiss    = Color(hex: "#EF4444")
    static let chartNeutral = Color(hex: "#FACC15")
    static let chartZone    = Color(hex: "#3B82F6")
    // Text
    static let textPrimary  = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5F5")
    // Glow
    static let glowGreen    = Color(hex: "#22C55E").opacity(0.3)
    static let glowOrange   = Color(hex: "#F97316").opacity(0.35)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography
struct AppFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Background Gradient
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.bgDark, Color.bgStadium.opacity(0.6), Color.bgNight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card
struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bgStadium.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentGreen.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    init(_ title: String, icon: String? = nil, color: Color = .accentGreen, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.headline(16))
            }
            .foregroundColor(.bgDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(AppFont.body())
            }
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentGreen.opacity(0.4), lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgStadium.opacity(0.3)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.title(22))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.headline())
                .foregroundColor(.textPrimary)
            Spacer()
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(AppFont.caption())
                        .foregroundColor(.accentGreen)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Zone Direction
enum PenaltyZone: String, CaseIterable, Codable {
    case topLeft = "TL"
    case topCenter = "TC"
    case topRight = "TR"
    case middleLeft = "ML"
    case middleCenter = "MC"
    case middleRight = "MR"
    case bottomLeft = "BL"
    case bottomCenter = "BC"
    case bottomRight = "BR"

    var label: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .middleLeft: return "Mid Left"
        case .middleCenter: return "Mid Center"
        case .middleRight: return "Mid Right"
        case .bottomLeft: return "Bot Left"
        case .bottomCenter: return "Bot Center"
        case .bottomRight: return "Bot Right"
        }
    }

    var row: Int {
        switch self {
        case .topLeft, .topCenter, .topRight: return 0
        case .middleLeft, .middleCenter, .middleRight: return 1
        case .bottomLeft, .bottomCenter, .bottomRight: return 2
        }
    }

    var col: Int {
        switch self {
        case .topLeft, .middleLeft, .bottomLeft: return 0
        case .topCenter, .middleCenter, .bottomCenter: return 1
        case .topRight, .middleRight, .bottomRight: return 2
        }
    }
}

enum DiveDirection: String, CaseIterable, Codable {
    case left = "Left"
    case center = "Center"
    case right = "Right"
}

enum PenaltyOutcome: String, CaseIterable, Codable {
    case saved = "Saved"
    case scored = "Scored"
    case missed = "Missed"

    var color: Color {
        switch self {
        case .saved: return .chartSave
        case .scored: return .chartMiss
        case .missed: return .chartNeutral
        }
    }

    var icon: String {
        switch self {
        case .saved: return "hand.raised.fill"
        case .scored: return "soccerball"
        case .missed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.accentGreen.opacity(0.4))
            Text(title)
                .font(AppFont.headline())
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(AppFont.body())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
