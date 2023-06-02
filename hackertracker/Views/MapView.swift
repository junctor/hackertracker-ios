//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI

struct MapView: View {
    @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @AppStorage("launchScreen") var launchScreen: String = "Map"

    var body: some View {
        if let con = conferences.first, let maps = con.maps {
            Text("Maps goes here")
        } else {
            _04View(message: "No Maps Found")
        }
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
