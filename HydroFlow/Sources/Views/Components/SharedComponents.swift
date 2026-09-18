import SwiftUI

// MARK: - Card

/// Elevated inset-grouped card used across every screen (Tier 1 elevation).
struct FlowCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                // Stitch Tier-2 elevation: diffuse azure ambient glow plus a
                // faint neutral drop (0 8px 32px rgba(0,122,255,.08)).
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.azure.opacity(0.08), radius: 16, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                    .strokeBorder(Theme.hairline.opacity(0.5), lineWidth: 0.5)
            )
    }
}

// MARK: - Icon tile

/// Soft tinted squircle with an SF Symbol — list-row leading glyph.
struct IconTile: View {
    let systemName: String
    var tint: Color = Theme.azure
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(tint.opacity(0.14))
            Image(systemName: systemName)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section header

/// Section label above grouped lists (stitch uses title-case, not caps).
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(FlowFont.bodyBold(13))
            .foregroundStyle(Theme.labelSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
    }
}

// MARK: - Toast

/// Transient feedback pill (e.g. "+16 oz logged").
struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.aqua)
            Text(text)
                .font(FlowFont.bodyBold())
                .foregroundStyle(Theme.labelPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.10), radius: 12, y: 4)
    }
}

// MARK: - Button style

/// Primary pill button style: azure→aqua gradient, press scales to 0.97.
struct FlowButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FlowFont.headlineSmall())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(
                    enabled ? AnyShapeStyle(Theme.flowGradient) : AnyShapeStyle(Color.gray.opacity(0.35))
                )
            )
            .shadow(color: Theme.azure.opacity(enabled ? 0.35 : 0), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Chip

/// Rounded selection chip used for filters and presets.
struct SelectableChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(FlowFont.subhead())
            .fontWeight(isSelected ? .bold : .medium)
            .foregroundStyle(isSelected ? .white : Theme.labelSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.azure) : AnyShapeStyle(Theme.azure.opacity(0.08)))
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? .clear : Theme.azure.opacity(0.25), lineWidth: 0.5)
            )
    }
}

// MARK: - Toggle row

/// Settings-style row with an iOS toggle.
struct ToggleRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, tint: iconTint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(FlowFont.bodyBold(16))
                Text(subtitle).font(FlowFont.caption()).foregroundStyle(Theme.labelSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.azure)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Navigation row

/// Settings-style tappable row with trailing value + chevron.
struct NavigationRow<Trailing: View>: View {
    let icon: String
    let iconTint: Color
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, tint: iconTint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(FlowFont.bodyBold(16))
                if let subtitle {
                    Text(subtitle).font(FlowFont.caption()).foregroundStyle(Theme.labelSecondary)
                }
            }
            Spacer()
            trailing
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.labelTertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Floating glass tab bar

/// One item in the floating glass tab bar.
struct FloatingTabItem: Identifiable {
    let id: String
    let symbol: String
    let label: String
}

/// Dribbble-style detached Liquid Glass tab bar: a single frosted capsule
/// floating above the safe area with content scrolling behind it, an active
/// item lifted by a sliding frosted pill, and a soft azure-tinted drop shadow.///
/// Uses the native `.bar` material on iOS 26+ so it inherits the system
/// Liquid Glass rendering; falls back to systemUltraThinMaterial below.
struct FloatingGlassTabBar: View {
    let items: [FloatingTabItem]
    @Binding var selection: String
    var onAdd: (() -> Void)? = nil

    @Namespace private var pillNamespace
    @State private var barAppeared = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(5)
        .background(
            // Frosted glass capsule (.bar inherits the system Liquid Glass
            // material on iOS 26+).
            Capsule().fill(Material.bar)
        )
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: Theme.azure.opacity(0.16), radius: 18, x: 0, y: 10)
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
        .scaleEffect(barAppeared ? 1 : 0.9)
        .opacity(barAppeared ? 1 : 0)
        .offset(y: barAppeared ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: barAppeared)
        .onAppear {
            if !barAppeared {
                barAppeared = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab bar")
    }

    @ViewBuilder
    private func tabButton(_ item: FloatingTabItem) -> some View {
        let isSelected = selection == item.id
        Button {
            guard selection != item.id else { return }
            Feedback.tick(enabled: true)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if item.id == "add" {
                    onAdd?()
                } else {
                    selection = item.id
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(item.label)
                    .font(FlowFont.caption(9.5))
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Theme.azure : Theme.labelSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    // Sliding active pill (matchedGeometryEffect).
                    Capsule()
                        .fill(Color.white.opacity(0.92))
                        .overlay(Capsule().strokeBorder(Theme.azure.opacity(0.15), lineWidth: 0.5))
                        .shadow(color: Theme.azure.opacity(0.22), radius: 6, y: 2)
                        .matchedGeometryEffect(id: "active-pill", in: pillNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
