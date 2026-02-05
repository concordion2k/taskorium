//
//  ConstellationBackground.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI

struct ConstellationBackground: View {
    let constellation: ConstellationType

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark space background
                LinearGradient(
                    colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Stars
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                        .frame(width: CGFloat.random(in: 1...2))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }

                // Constellation pattern
                Canvas { context, size in
                    let points = constellation.points(in: size)

                    // Draw connecting lines
                    for connection in constellation.connections {
                        if connection.from < points.count && connection.to < points.count {
                            let path = Path { p in
                                p.move(to: points[connection.from])
                                p.addLine(to: points[connection.to])
                            }
                            context.stroke(
                                path,
                                with: .color(.white.opacity(0.3)),
                                lineWidth: 1
                            )
                        }
                    }

                    // Draw constellation stars
                    for point in points {
                        context.fill(
                            Circle().path(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
                            with: .color(.white.opacity(0.8))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

enum ConstellationType {
    case orion
    case ursa
    case cassiopeia
    case leo

    struct Connection {
        let from: Int
        let to: Int
    }

    var connections: [Connection] {
        switch self {
        case .orion:
            return [
                Connection(from: 0, to: 1),
                Connection(from: 1, to: 2),
                Connection(from: 2, to: 3),
                Connection(from: 3, to: 4),
                Connection(from: 1, to: 5),
                Connection(from: 5, to: 6)
            ]
        case .ursa:
            return [
                Connection(from: 0, to: 1),
                Connection(from: 1, to: 2),
                Connection(from: 2, to: 3),
                Connection(from: 3, to: 4),
                Connection(from: 4, to: 5),
                Connection(from: 5, to: 6)
            ]
        case .cassiopeia:
            return [
                Connection(from: 0, to: 1),
                Connection(from: 1, to: 2),
                Connection(from: 2, to: 3),
                Connection(from: 3, to: 4)
            ]
        case .leo:
            return [
                Connection(from: 0, to: 1),
                Connection(from: 1, to: 2),
                Connection(from: 2, to: 3),
                Connection(from: 3, to: 4),
                Connection(from: 2, to: 5),
                Connection(from: 5, to: 6)
            ]
        }
    }

    func points(in size: CGSize) -> [CGPoint] {
        let centerX = size.width / 2
        let centerY = size.height / 2

        switch self {
        case .orion:
            return [
                CGPoint(x: centerX - 40, y: centerY - 60),
                CGPoint(x: centerX - 20, y: centerY - 30),
                CGPoint(x: centerX, y: centerY),
                CGPoint(x: centerX + 20, y: centerY + 30),
                CGPoint(x: centerX + 40, y: centerY + 60),
                CGPoint(x: centerX - 50, y: centerY),
                CGPoint(x: centerX + 50, y: centerY)
            ]
        case .ursa:
            return [
                CGPoint(x: centerX - 60, y: centerY - 30),
                CGPoint(x: centerX - 40, y: centerY - 40),
                CGPoint(x: centerX - 10, y: centerY - 35),
                CGPoint(x: centerX + 20, y: centerY - 40),
                CGPoint(x: centerX + 40, y: centerY - 20),
                CGPoint(x: centerX + 30, y: centerY + 10),
                CGPoint(x: centerX - 20, y: centerY + 15)
            ]
        case .cassiopeia:
            return [
                CGPoint(x: centerX - 50, y: centerY),
                CGPoint(x: centerX - 25, y: centerY - 30),
                CGPoint(x: centerX, y: centerY),
                CGPoint(x: centerX + 25, y: centerY - 30),
                CGPoint(x: centerX + 50, y: centerY)
            ]
        case .leo:
            return [
                CGPoint(x: centerX - 50, y: centerY - 40),
                CGPoint(x: centerX - 30, y: centerY - 20),
                CGPoint(x: centerX, y: centerY),
                CGPoint(x: centerX + 30, y: centerY),
                CGPoint(x: centerX + 50, y: centerY + 20),
                CGPoint(x: centerX - 10, y: centerY + 30),
                CGPoint(x: centerX - 30, y: centerY + 40)
            ]
        }
    }
}

#Preview {
    ConstellationBackground(constellation: .orion)
}
