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
    let screenSize = UIScreen.main.bounds.size

    var body: some View {
        VStack {
            if let con = viewModel.conference {
                if let maps = con.maps, maps.count > 0 {
                    TabView {
                        ForEach(maps, id: \.id) { map in
                            if let file = map.file {
                                let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let fileManager = FileManager.default
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
