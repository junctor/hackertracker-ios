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
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var selected: SelectedConference
    @State private var searchText = ""
    var theme = Theme()
    
    let gridItemLayout = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]
    
    var filteredOrgs: [Organization] {
        guard !searchText.isEmpty else {
            return viewModel.orgs
        }
        return viewModel.orgs.filter { orgs in
            orgs.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                ForEach(self.filteredOrgs, id: \.id) { org in
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
        .searchable(text: $searchText)
        .navigationTitle(title)

    }
}

struct OrgsView_Previews: PreviewProvider {
    static var previews: some View {
        OrgsView(title: "Vendors", tagId: 45695)
    }
}
