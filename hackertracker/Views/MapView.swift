//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI

struct MapView: View {
    var conference: Conference
    @ObservedObject private var viewModel = MapViewModel()
    @AppStorage("launchScreen") var launchScreen: String = "Maps"


    var body: some View {
        ScrollView {
            if conference.maps.count > 0 {
                Text("Conference has \(conference.maps.count) maps")
            } else {
                _04View(message: "No Maps Found")
            }
        }
        .onAppear {
            launchScreen = "Maps"
        }
        /* .onAppear {
            viewModel.fetchData(code: conference.code)
        } */
    }
    /*
     .onAppear {
                $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
            }
     */
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}
