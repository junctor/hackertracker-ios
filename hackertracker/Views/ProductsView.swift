//
//  ProductsView.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI
import Kingfisher

struct ProductsView: View {
    @EnvironmentObject var viewModel: InfoViewModel

    @State private var searchText = ""
    @State private var filters: [String] = []

    var body: some View {
        ScrollView {
            if let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text(doc.title)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(viewModel.colorMode ? ThemeColors.blue : Color(.systemGray6))
                    .cornerRadius(15)
                }
            }
                ForEach(self.viewModel.products.search(text: searchText).sorted {
                    $0.sortOrder < $1.sortOrder
                }) { product in
                    if filters.count == 0 || product.variants.filter({ filters.contains($0.code) }).count > 0 {
                        HStack {
                            NavigationLink(destination: ProductView(product: product)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        if product.media.count > 0, let media_url = URL(string: product.media[0].url) {
                                            KFImage(media_url)
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(5)
                                        } else {
                                            Image(systemName: "tshirt")
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .frame(width: 75)
                                    VStack(alignment: .leading) {
                                        Text(product.title).font(.subheadline).fontWeight(.bold).multilineTextAlignment(.leading)
                                        Text(product.priceMin < product.priceMax ? "$\(product.priceMin / 100) - $\(product.priceMax / 100)" : "$\(product.priceMin/100)")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    VStack(alignment: .trailing) {
                                        Image(systemName: "chevron.right")
                                    }
                                    .frame(alignment: .trailing)
                                }
                                .frame(idealHeight: 50)
                            }
                        }
                    }
                }
        }
        .searchable(text: $searchText)
        .navigationTitle("Merch")
        .toolbar {
            NavigationLink(destination: CartView()) {
                Image(systemName: "qrcode")
            }
        }
        .padding(15)
        .analyticsScreen(name: "ProductsView")
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView()
    }
}

/*
 ForEach(self.viewModel.news.search(text: searchText).sorted {
     $0.updatedAt < $1.updatedAt
 }) { article in
     articleRow(article: article)
 }
 */
