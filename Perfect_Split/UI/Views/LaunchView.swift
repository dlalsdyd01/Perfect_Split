import SwiftUI

struct LaunchView: View {
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isLoaded = false
    @State private var isSplit = false
    @State private var fadeOpacity: Double = 1
    @State private var titleGlow: Double = 0.35
    @State private var cutStart: CGPoint?
    @State private var cutEnd: CGPoint?
    @State private var trail: [CGPoint] = []
    @State private var splitDistance: CGFloat = 0
    @State private var impactFlash: Double = 0
    @State private var symbolRotation: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let overscan = max(size.width, size.height) * 0.9
            let line = currentCutLine(in: size)
            let normal = splitNormal(for: line)

            ZStack {
                if let line {
                    splitLayer(size: size, overscan: overscan, line: line, positiveSide: true)
                        .offset(x: normal.dx * splitDistance, y: normal.dy * splitDistance)

                    splitLayer(size: size, overscan: overscan, line: line, positiveSide: false)
                        .offset(x: -normal.dx * splitDistance, y: -normal.dy * splitDistance)
                } else {
                    launchContent(size: size)
                }

                loadingBar
                    .frame(height: 12)
                    .padding(.horizontal, 54)
                    .position(x: size.width * 0.5, y: size.height * 0.625)
                    .opacity(isSplit ? 0 : 1)

                if isLoaded, !isSplit {
                    VStack(spacing: 8) {
                        Text("화면을 자르세요")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .green.opacity(0.75), .mint, .green.opacity(0.75), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 104, height: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(.black.opacity(0.24))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                    .position(x: size.width * 0.5, y: size.height * 0.74)
                        .transition(.opacity.combined(with: .scale))
                }

                if !trail.isEmpty, !isSplit {
                    SwipeTrail(points: trail)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: .green.opacity(0.65), radius: 10)
                        .shadow(color: .mint.opacity(0.45), radius: 18)
                }

                if let line, isSplit {
                    CutLine(start: line.start, end: line.end)
                        .stroke(
                            LinearGradient(
                                colors: [.clear, .white, .mint, .green, .white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                }

                Color.white
                    .opacity(impactFlash)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { value in
                        guard isLoaded, !isSplit else { return }
                        cutStart = value.startLocation
                        cutEnd = value.location
                        if trail.isEmpty {
                            trail = [value.startLocation]
                        }
                        trail.append(value.location)
                    }
                    .onEnded { value in
                        guard isLoaded, !isSplit else { return }
                        cutStart = value.startLocation
                        cutEnd = value.location
                        trail.append(value.location)
                        splitAlongCut(in: size)
                    }
            )
        }
        .opacity(fadeOpacity)
        .ignoresSafeArea()
        .task {
            runSequence()
        }
    }

    private func splitLayer(
        size: CGSize,
        overscan: CGFloat,
        line: (start: CGPoint, end: CGPoint),
        positiveSide: Bool
    ) -> some View {
        let canvasSize = CGSize(
            width: size.width + overscan * 2,
            height: size.height + overscan * 2
        )
        let shiftedLine = (
            start: CGPoint(x: line.start.x + overscan, y: line.start.y + overscan),
            end: CGPoint(x: line.end.x + overscan, y: line.end.y + overscan)
        )

        return ZStack(alignment: .topLeading) {
            launchBackdrop(size: canvasSize)
            launchContent(size: size)
                .frame(width: size.width, height: size.height)
                .offset(x: overscan, y: overscan)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .mask(
            CutHalfMask(
                lineStart: shiftedLine.start,
                lineEnd: shiftedLine.end,
                positiveSide: positiveSide
            )
        )
        .offset(x: -overscan, y: -overscan)
    }

    private func launchContent(size: CGSize) -> some View {
        ZStack {
            launchBackdrop(size: size)

            VStack(spacing: 22) {
                Spacer()

                DiamondMark()
                    .stroke(
                        LinearGradient(
                            colors: [.green.opacity(0.72), .mint.opacity(0.9), .white.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(symbolRotation))

                VStack(spacing: 8) {
                    Text("PERFECT")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                    Text("SPLIT")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text(isLoaded ? "READY" : "LOADING")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.top, 4)

                Spacer()
                    .frame(height: max(86, size.height * 0.32))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func launchBackdrop(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.005, green: 0.006, blue: 0.01),
                    Color(red: 0.018, green: 0.022, blue: 0.032),
                    Color(red: 0.0, green: 0.0, blue: 0.004)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryGrid()
                .stroke(.white.opacity(0.055), lineWidth: 1)
                .frame(width: size.width, height: size.height)
        }
        .frame(width: size.width, height: size.height)
    }

    private var loadingBar: some View {
        GeometryReader { proxy in
            VStack(spacing: 9) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.95, blue: 0.42),
                                    Color(red: 0.58, green: 1.0, blue: 0.72),
                                    .white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(2, proxy.size.width * progress))
                }
                .frame(height: 12)

                HStack {
                    Text("LOADING")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.46))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func runSequence() {
        withAnimation(.easeInOut(duration: 1.1)) {
            progress = 0.72
            titleGlow = 0.75
            symbolRotation = 9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.55)) {
                progress = 1
                symbolRotation = -6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.68) {
            withAnimation(.easeOut(duration: 0.28)) {
                isLoaded = true
            }
        }
    }

    private func splitAlongCut(in size: CGSize) {
        guard let line = currentCutLine(in: size) else { return }
        let dx = line.end.x - line.start.x
        let dy = line.end.y - line.start.y
        guard dx * dx + dy * dy > 900 else { return }

        SoundManager.shared.playEffect(.slice)
        isSplit = true
        withAnimation(.easeOut(duration: 0.06)) {
            impactFlash = 0.75
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.easeIn(duration: 0.28)) {
                impactFlash = 0
            }
        }
        withAnimation(.easeInOut(duration: 0.9)) {
            splitDistance = max(size.width, size.height) * 0.72
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.24)) {
                fadeOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete()
        }
    }

    private func currentCutLine(in size: CGSize) -> (start: CGPoint, end: CGPoint)? {
        guard let cutStart, let cutEnd else { return nil }
        let dx = cutEnd.x - cutStart.x
        let dy = cutEnd.y - cutStart.y
        guard dx * dx + dy * dy > 64 else { return nil }

        let length = sqrt(dx * dx + dy * dy)
        let ux = dx / length
        let uy = dy / length
        let extend = max(size.width, size.height) * 1.4

        return (
            CGPoint(x: cutStart.x - ux * extend, y: cutStart.y - uy * extend),
            CGPoint(x: cutEnd.x + ux * extend, y: cutEnd.y + uy * extend)
        )
    }

    private func splitNormal(for line: (start: CGPoint, end: CGPoint)?) -> CGVector {
        guard let line else { return CGVector(dx: 0, dy: 1) }
        let dx = line.end.x - line.start.x
        let dy = line.end.y - line.start.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        return CGVector(dx: -dy / length, dy: dx / length)
    }
}

private struct CutLine: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

private struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.08)
        let right = CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.08)
        let left = CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.closeSubpath()

        path.move(to: top)
        path.addLine(to: center)
        path.addLine(to: bottom)
        path.move(to: left)
        path.addLine(to: center)
        path.addLine(to: right)
        return path
    }
}

private struct GeometryGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 82
        var x = rect.minX - rect.height
        while x < rect.maxX + rect.height {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x + rect.height * 0.38, y: rect.maxY))
            x += spacing
        }

        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: midY - 90))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: midY + 52))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: midY + 132))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: midY - 124))
        return path
    }
}

private struct SwipeTrail: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

private struct CutHalfMask: Shape {
    let lineStart: CGPoint
    let lineEnd: CGPoint
    let positiveSide: Bool

    func path(in rect: CGRect) -> Path {
        var points = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        points = clipped(points, keepingPositiveSide: positiveSide)

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    private func clipped(_ polygon: [CGPoint], keepingPositiveSide: Bool) -> [CGPoint] {
        guard !polygon.isEmpty else { return [] }
        var output: [CGPoint] = []

        for index in polygon.indices {
            let current = polygon[index]
            let previous = polygon[(index - 1 + polygon.count) % polygon.count]
            let currentInside = isInside(current, positiveSide: keepingPositiveSide)
            let previousInside = isInside(previous, positiveSide: keepingPositiveSide)

            if currentInside {
                if !previousInside, let intersection = intersection(from: previous, to: current) {
                    output.append(intersection)
                }
                output.append(current)
            } else if previousInside, let intersection = intersection(from: previous, to: current) {
                output.append(intersection)
            }
        }

        return output
    }

    private func isInside(_ point: CGPoint, positiveSide: Bool) -> Bool {
        let value = sideValue(point)
        return positiveSide ? value >= 0 : value <= 0
    }

    private func sideValue(_ point: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        return dx * (point.y - lineStart.y) - dy * (point.x - lineStart.x)
    }

    private func intersection(from a: CGPoint, to b: CGPoint) -> CGPoint? {
        let av = sideValue(a)
        let bv = sideValue(b)
        let denominator = av - bv
        guard abs(denominator) > 0.0001 else { return nil }
        let t = av / denominator
        return CGPoint(
            x: a.x + (b.x - a.x) * t,
            y: a.y + (b.y - a.y) * t
        )
    }
}
