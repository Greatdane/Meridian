import SwiftUI

struct TimeScrubberView: View {
    @Binding var value: Double

    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let centerX = xPosition(for: 0, width: width)
            let thumbX = xPosition(for: value, width: width)
            let fillStart = min(centerX, thumbX)
            let fillWidth = abs(thumbX - centerX)

            ZStack(alignment: .leading) {
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.15))
                            .frame(height: 10)

                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: fillWidth, height: 10)
                            .offset(x: fillStart)

                        Circle()
                            .fill(.background)
                            .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 1)
                            .overlay {
                                Circle()
                                    .stroke(Color.primary.opacity(0.16), lineWidth: 1)
                            }
                            .frame(width: 24, height: 24)
                            .offset(x: thumbX - 12)
                    }
                    .frame(width: width, height: 28, alignment: .leading)
                    .clipped()

                    ZStack(alignment: .leading) {
                        ForEach(ticks, id: \.self) { tick in
                            Capsule()
                                .fill(Color.primary.opacity(tickOpacity(tick)))
                                .frame(width: tickWidth(tick), height: tickHeight(tick))
                                .offset(x: xPosition(for: tick, width: width) - tickWidth(tick) / 2)
                        }
                    }
                    .frame(width: width, height: 24, alignment: .leading)
                    .clipped()
                }
                .frame(width: width, alignment: .leading)
            }
            .frame(width: width, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        updateValue(from: drag.location.x, width: width)
                    }
            )
        }
        .frame(height: 60)
        .accessibilityLabel("Time slider")
    }

    private var ticks: [Double] {
        stride(from: range.lowerBound, through: range.upperBound, by: 15).map { $0 }
    }

    private func xPosition(for candidate: Double, width: Double) -> Double {
        let clamped = min(max(candidate, range.lowerBound), range.upperBound)
        let progress = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
        return progress * width
    }

    private func updateValue(from x: Double, width: Double) {
        let clampedX = min(max(x, 0), width)
        let progress = clampedX / width
        let rawValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        value = min(max((rawValue / step).rounded() * step, range.lowerBound), range.upperBound)
    }

    private func tickHeight(_ tick: Double) -> CGFloat {
        if tick.truncatingRemainder(dividingBy: 60) == 0 {
            return 22
        }
        if tick.truncatingRemainder(dividingBy: 30) == 0 {
            return 16
        }
        return 10
    }

    private func tickWidth(_ tick: Double) -> CGFloat {
        tick.truncatingRemainder(dividingBy: 60) == 0 ? 3 : 2
    }

    private func tickOpacity(_ tick: Double) -> Double {
        tick.truncatingRemainder(dividingBy: 60) == 0 ? 0.34 : 0.22
    }
}
