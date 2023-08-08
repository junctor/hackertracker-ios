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
    @AppStorage("showMerchInfo") var showMerchInfo: Bool = true

    @State private var searchText = ""
    @State private var filters: [String] = []

    var body: some View {
        ScrollView {
            if showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                    HStack {
                        Button {
                            showMerchInfo = false
                        } label: {
                            Image(systemName: "x.circle")
                        }
                        VStack(alignment: .leading) {
                            Text(doc.title).font(.subheadline).fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(ThemeColors.red)
                    .cornerRadius(15)
                }
                Divider()
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
                                    Spacer()
                                    Image(systemName: "chevron.right")
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
            if !showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                    Image(systemName: "info.circle")
                }
            }
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
