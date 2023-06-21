//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI

struct MapView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @AppStorage("launchScreen") var launchScreen: String = "Maps"
    @EnvironmentObject var selected: SelectedConference

    var body: some View {
        VStack {
            if let con = viewModel.conference {
                if let maps = con.maps, maps.count > 0 {
                    TabView {
                        ForEach(maps, id: \.id) { map in
                            if let map_url = URL(string: map.url) {
                                PDFView(url: map_url)
                                    .onAppear{
                                        print("MapView: Loading")
                                    }
                                    .scaledToFit()
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .scaledToFill()
                } else {
                    _04View(message: "No Maps Found")
                }
            } else {
                Text("loading...")
            }
        }
        .onAppear {
            launchScreen = "Maps"
            viewModel.fetchData(code: selected.code)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}
