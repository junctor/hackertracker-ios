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
        ScrollView {
            VStack {
                Text("Code of Conduct")
                    .font(.title)
                Divider()
                Text(codeofconduct)
                    .font(.body)
            }
            .padding()
        }
    }
}

struct CodeOfConductView_Previews: PreviewProvider {
    static var previews: some View {
        CodeOfConductView(codeofconduct: "Be excellent to each other")
    }
}
