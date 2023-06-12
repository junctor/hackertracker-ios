//
//  OrgsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct OrgsView: View {
    var title: String
    var tagId: Int
    @EnvironmentObject var selected: SelectedConference
    @ObservedObject private var viewModel = OrgsViewModel()
    
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                ForEach(self.viewModel.orgs, id: \.id) { org in
                    if org.tag_ids.contains(tagId) {
                        NavigationLink(destination: DocumentView(title_text: org.name, body_text: org.description)) {
                            VStack {
                                if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
                                    AsyncImage(url: logo_url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        default:
                                            if let f = org.name.first {
                                                Text(f.uppercased())
                                                    .padding()
                                                    .font(.largeTitle)
                                                    .background(Color.gray)
                                                    .foregroundColor(.white)
                                                    .frame(width: 125, height: 100)
                                            } else {
                                                Text("X")
                                                    .padding()
                                                    .font(.largeTitle)
                                                    .background(Color.gray)
                                                    .foregroundColor(.white)
                                                    .frame(width: 125, height: 100)
                                            }
                                        }
                                    }
                                    .frame(width: 125)
                                    .padding(10)
                                    
                                } else {
                                    if let f = org.name.first {
                                        Text(f.uppercased())
                                            .padding()
                                            .font(.largeTitle)
                                            .background(Color.gray)
                                            .foregroundColor(.white)
                                            .frame(width: 125, height: 100)
                                    } else {
                                        Text("X")
                                            .padding()
                                            .font(.largeTitle)
                                            .background(Color.gray)
                                            .foregroundColor(.white)
                                            .frame(width: 125, height: 100)
                                    }
                                }
                                Text(org.name)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
            }
            
        }
        .navigationTitle(title)
        .onAppear {
            viewModel.fetchData(code: selected.code)
        }
    }
}

struct OrgsView_Previews: PreviewProvider {
    static var previews: some View {
        OrgsView(title: "Vendors", tagId: 45695)
    }
}
