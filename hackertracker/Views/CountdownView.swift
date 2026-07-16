//
//  CountdownView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct CountdownView: View {
    let start: Date
    @State private var countdownTimer: CountdownComps?
    @Environment(ThemeManager.self) private var themeManager

    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                // Four DISTINCT colors, all derived from the theme accent
                // hue (accentSpectrum), so each unit reads differently
                // while still matching the theme — even on a mono-accent
                // theme like DEF CON Red (a spread of reds/oranges) where
                // accent/success/danger would otherwise collapse to one
                // color.
                let unitColors = themeManager.accentSpectrum(4)
                Text("\(countdownTimer?.days ?? 0)").font(themeManager.titleFont).foregroundColor(unitColors[0])
                Text("days").font(themeManager.captionFont).foregroundColor(.primary)

                Text("\(countdownTimer?.hours ?? 0)").font(themeManager.titleFont).foregroundColor(unitColors[1])
                Text("hours").font(themeManager.captionFont).foregroundColor(.primary)

                Text("\(countdownTimer?.minutes ?? 0)").font(themeManager.titleFont).foregroundColor(unitColors[2])
                Text("min").font(themeManager.captionFont).foregroundColor(.primary)

                Text("\(countdownTimer?.seconds ?? 0)").font(themeManager.titleFont).foregroundColor(unitColors[3])
                Text("sec").font(themeManager.captionFont).foregroundColor(.primary)
            }
        }.frame(maxWidth: .infinity)
            .accentColor(.primary)
            // Recessed pill: this sits on top of the InfoView card
            // (cardSurface), so use the theme's base background — darker
            // than the card — to make the countdown read as an inset panel
            // that stands out without the harsh systemGray of before.
            .background(themeManager.background)
            .cornerRadius(5)
            .onAppear {
                countdownTimer = getCountdown(start: start)
            }
            .onReceive(timer) { _ in
                withAnimation {
                    countdownTimer = getCountdown(start: start)
                }
            }
    }
}

struct CountdownComps {
    var days: Int
    var hours: Int
    var minutes: Int
    var seconds: Int
}

func getCountdown(start: Date) -> CountdownComps {
    let timeUntilConfStart = start.timeIntervalSinceNow

    let day = timeUntilConfStart / (24 * 60 * 60)
    let hour = day.truncatingRemainder(dividingBy: 1) * 24
    let min = hour.truncatingRemainder(dividingBy: 1) * 60
    let sec = min.truncatingRemainder(dividingBy: 1) * 60

    return CountdownComps(
        days: Int(day.rounded(.down)),
        hours: Int(hour.rounded(.down)),
        minutes: Int(min.rounded(.down)),
        seconds: Int(sec.rounded(.down))
    )
}

struct Countdown_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(start: getPreviewStart())
    }
}

func getPreviewStart() -> Date {
    let newFormatter = ISO8601DateFormatter()
    let date = newFormatter.date(from: "2022-08-11T00:00:00-0700")
    return date ?? Date()
}
