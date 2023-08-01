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

    var body: some View {
        VStack {
            if show404 {
                Image("404")
                    .frame(width: 512)
            }
            Text(message)
                .font(.title)
            Image("beezle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
        }
        .analyticsScreen(name: "404View")
    }
}

struct _04View_Previews: PreviewProvider {
    static var previews: some View {
        _04View(message: "404 not found")
    }
}
