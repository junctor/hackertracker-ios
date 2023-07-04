//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import CoreData
import FirebaseStorage
import SwiftUI

struct ConferencesView: View {
    // var conferences: [Conference]
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @AppStorage("showHidden") var showHidden: Bool = false

    var body: some View {
        if viewModel.conferences.count > 0 {
                Text("Select Conference")
                    .font(.headline)
                Divider()
                List(viewModel.conferences, id: \.code) { conference in
                    ConferenceRow(conference: conference, code: selected.code)
                        .onTapGesture {
                            if conference.code == selected.code {
                                print("Already selected \(conference.name)")
                            } else {
                                print("Selected \(conference.name)")
                                selected.code = conference.code
                                conferenceCode = conference.code
                                viewModel.fetchData(code: conference.code)
                            }
                            
                            let fileManager = FileManager.default
                            let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let storageRef = Storage.storage().reference()
                            
                            if let maps = conference.maps, maps.count > 0 {
                                for map in maps {
                                    if let file = map.file {
                                        let path = "\(conference.code)/\(file)"
                                        let mRef = storageRef.child(path)
                                        let mLocal = docDir.appendingPathComponent(path)
                                        if fileManager.fileExists(atPath: mLocal.path) {
                                            // TODO: Add logic to check md5 hash and re-update if it has changed
                                            print("ConferencesView (\(selected.code): Map file (\(path)) already exists")
                                        } else {
                                            _ = mRef.write(toFile: mLocal) { _, error in
                                                if let error = error {
                                                    print("ConferencesView (\(selected.code)): Error \(error) retrieving \(path)")
                                                } else {
                                                    print("ConferencesView (\(selected.code)): Got map \(path)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }
                .listStyle(.plain)
        } else {
            Text("loading")
                .onAppear {
                    viewModel.fetchConferences(hidden: showHidden)
                }
        }
    }
}

struct ConferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ConferencesView()
    }
}
