//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct MapView: View {
    @State var conference: Conference?
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    var body: some View {
        if let con = conference, let maps = con.maps {
            Text("Maps goes here")
        } else {
            _04View(message:"No Maps Found")
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}
