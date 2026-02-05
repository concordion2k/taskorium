//
//  PlanetView.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI

struct PlanetView: View {
    let planetType: PlanetType
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: planetColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )

            // Add some texture circles for visual interest
            Circle()
                .fill(
                    RadialGradient(
                        colors: [planetColors[0].opacity(0.3), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size / 3
                    )
                )

            // Shadow for depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: size / 3,
                        endRadius: size / 2
                    )
                )
        }
        .frame(width: size, height: size)
    }

    var planetColors: [Color] {
        switch planetType {
        case .mercury:
            return [Color(hex: "B0BEC5"), Color(hex: "78909C")]
        case .venus:
            return [Color(hex: "FFE082"), Color(hex: "FFB300")]
        case .earth:
            return [Color(hex: "64B5F6"), Color(hex: "1976D2")]
        case .mars:
            return [Color(hex: "EF5350"), Color(hex: "C62828")]
        case .jupiter:
            return [Color(hex: "FFAB91"), Color(hex: "D84315")]
        case .saturn:
            return [Color(hex: "FFF59D"), Color(hex: "F57F17")]
        case .uranus:
            return [Color(hex: "80DEEA"), Color(hex: "00838F")]
        case .neptune:
            return [Color(hex: "7986CB"), Color(hex: "283593")]
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        VStack {
            PlanetView(planetType: .mercury, size: 80)
            Text("Mercury")
        }
        VStack {
            PlanetView(planetType: .venus, size: 80)
            Text("Venus")
        }
        VStack {
            PlanetView(planetType: .earth, size: 80)
            Text("Earth")
        }
        VStack {
            PlanetView(planetType: .mars, size: 80)
            Text("Mars")
        }
    }
    .padding()
}
