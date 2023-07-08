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

    var body: some View {
        List {
            ForEach(self.viewModel.products.search(text: searchText).sorted {
                $0.sortOrder < $1.sortOrder
            }) { product in
                NavigationLink(destination: ProductView(product: product)) {
                    HStack {
                        if product.media.count > 0, let media_url = URL(string: product.media[0].url) {
                            KFImage(media_url)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                        }
                        VStack(alignment: .leading) {
                            Text(product.title).font(.subheadline).fontWeight(.bold).multilineTextAlignment(.leading)
                            Text("$\(product.priceMin / 100) - $\(product.priceMax / 100)")
                                .font(.subheadline)
                        }
                    }
                    .frame(idealHeight: 50)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Merch")
        .toolbar {
            NavigationLink(destination: CartView()) {
                    Image(systemName: "cart")
            }
        }
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
