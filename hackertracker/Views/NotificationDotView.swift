//
//  NotificationDotView.swift
//  hackertracker
//
//  Created by Seth Law on 8/2/24.
//

import SwiftUI

struct NotificationDot: View {
    var showDot: Bool = true
    @State var background: Color = .red
    private let size = 6.0
    private let x = 0.0
    private let y = 0.0
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(background)
                .frame(width: size, height: size, alignment: .topTrailing)
                .position(x: x, y: y)
        }
        .opacity(showDot ? 0.75 : 0)
    }
}

#Preview {
    NotificationDot()
}
