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
    var theme = Theme()
    
    let gridItemLayout = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                ForEach(self.viewModel.orgs, id: \.id) { org in
                    if org.tag_ids.contains(tagId) {
                        NavigationLink(destination: DocumentView(title_text: org.name, body_text: org.description)) {
                                if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
                                    VStack {
                                        Text(org.name)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        AsyncImage(url: logo_url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .frame(maxWidth: .infinity)
                                                    .aspectRatio(contentMode: .fit)
                                                    .cornerRadius(15)
                                            default:
                                                Text(org.name)
                                                    .foregroundColor(.white)
                                                    .background(theme.carousel().gradient)
                                                    .cornerRadius(15)
                                            }
                                        }
                                        
                                    }
                                    .padding(5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(theme.carousel().gradient)
                                    .cornerRadius(15)
                                    
                                } else {
                                    Text(org.name)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(15)
                                        .background(theme.carousel().gradient)
                                        .cornerRadius(15)
                                }

                        }
                    }
                }
                
            }
            
        }
        // Need to figure out search here
        // .searchable(text: $viewModel.searchText)
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
