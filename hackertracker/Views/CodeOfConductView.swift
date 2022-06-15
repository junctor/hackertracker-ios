//
//  CodeOfConductView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import SwiftUI

struct CodeOfConductView: View {
    var codeofconduct: String
    var body: some View {
        VStack {
            Divider()
            Text(codeofconduct)
                .font(.body)
        }
        .padding()
    }
}

struct CodeOfConductView_Previews: PreviewProvider {
    static var previews: some View {
        CodeOfConductView(codeofconduct: "Be good to each other")
    }
}
