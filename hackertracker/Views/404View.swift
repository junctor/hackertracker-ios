//
//  404View.swift
//  hackertracker
//
//  Created by Seth Law on 6/14/22.
//

import SwiftUI

struct _04View: View {
    var message: String
    var show404: Bool = true
    @AppStorage(AppStorageKeys.conferenceCode) var conferenceCode: String = "INIT"
    @StateObject var selected = SelectedConference()
    @State private var viewModel = InfoViewModel()
    @Environment(\.colorScheme) private var beezleColorScheme

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            VStack {
                if show404 {
                    Image("404")
                        .frame(width: 512)
                }
                Text(message)
                    .font(themeManager.titleFont)
                    .multilineTextAlignment(.center)
                
                Image("beezle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140)
                    .beezleAdaptiveColor(beezleColorScheme)
                    .frame(maxHeight: .infinity)
                
                    NavigationLink(destination: ConferencesView()) {
                        CardView(systemImage: "list", text:"Choose Conference", color: themeManager.cardSurface, subtitle: "Not loading? Choose a conference now.")
                            .frame(maxWidth: .infinity, maxHeight: 35)
                            .padding(25)
                    }
            }
        }
        .analyticsScreen(name: "404View")
    }
}

struct _04View_Previews: PreviewProvider {
    static var previews: some View {
        _04View(message: "404 not found")
    }
}
