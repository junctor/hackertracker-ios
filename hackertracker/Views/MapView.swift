//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI
import FirebaseAnalytics
import FirebaseAnalyticsSwift

struct MapView: View {
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @State var loading: Bool = false

    let screenSize = UIScreen.main.bounds.size

    var body: some View {
        VStack {
            if let con = viewModel.conference {
                if let maps = con.maps, maps.count > 0 {
                    TabView {
                        ForEach(maps, id: \.id) { map in
                            if let file = map.file {
                                let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let mLocal = docDir.appendingPathComponent("\(con.code)/\(file)")
                                
                                PDFView(url: mLocal)
                                    .onAppear {
                                        print("MapView: Loading \(mLocal)")
                                    }
                                    .frame(width: screenSize.width)
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .scaledToFill()
                    .analyticsScreen(name: "MapView")
                } else {
                    _04View(message: "No Maps Found")
                }
            } else {
                _04View(message: "Loading", show404: false).preferredColorScheme(theme.colorScheme)
            }
        }

        .onAppear {
            print("MapView: Current launchscreen is: \(launchScreen)")
            // viewModel.fetchData(code: selected.code)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}
