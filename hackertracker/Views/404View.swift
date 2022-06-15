//
//  404View.swift
//  hackertracker
//
//  Created by Seth Law on 6/14/22.
//

import SwiftUI

struct _04View: View {
    var message: String
    
    var body: some View {
        VStack {
            Image("404")
                .frame(width:512)
            Text(message)
                .font(.title)
            Image("skull")
                .frame(width: 50)
        }
    }
}

struct _04View_Previews: PreviewProvider {
    static var previews: some View {
        _04View(message:"404 not found")
    }
}
