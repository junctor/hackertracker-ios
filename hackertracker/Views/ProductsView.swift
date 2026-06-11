//
//  ProductsView.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI
import Kingfisher

struct ProductsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("showMerchInfo") var showMerchInfo: Bool = true
    @State private var searchText = ""
    @State private var showFilters = false
    @EnvironmentObject var filters: Filters
    
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    private var visibleProducts: [Product] {
        viewModel.products.search(text: searchText)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { product in
                filters.filters.count == 0 ||
                product.tagIds.filter({ filters.filters.contains($0) }).count > 0 ||
                product.variants.filter({ $0.tagIds.intersects(with: filters.filters) && $0.stockStatus == "IN" }).count > 0
            }
    }

    var body: some View {
        // Phase 5a: pull-to-refresh + empty-state UX.
        ScrollView {
            if showMerchInfo {
                MerchInfo()
            }
            Text(viewModel.conference?.merchMandatoryAck ?? "Tax Included. All Sales Final")
                .font(.subheadline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Divider()
            if visibleProducts.isEmpty {
                if searchText.isEmpty && filters.filters.isEmpty {
                    ContentUnavailableView(
                        "No Merch",
                        systemImage: "tshirt",
                        description: Text("Merchandise will appear here once it's published.")
                    )
                    .padding(.top, 40)
                } else if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 40)
                } else {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("No items match the current filters.")
                    )
                    .padding(.top, 40)
                }
            } else {
                LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                    ForEach(visibleProducts) { product in
                        ProductsRow(product: product)
                    }
                }
            }
        }
        .refreshable {
            if let code = viewModel.conference?.code {
                viewModel.fetchData(code: code)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Merch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if !showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Merch info")
            }
            Button {
              showFilters.toggle()
            } label: {
              Image(
                systemName: filters.filters
                  .isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel(filters.filters.isEmpty ? "Filters" : "Filters active")
            if let c = viewModel.conference, c.enableMerchCart {
                NavigationLink(destination: CartView()) {
                    Image(systemName: "qrcode")
                }
                .accessibilityLabel("Cart")
            }
        }
        .sheet(isPresented: $showFilters) {
          EventFilters(
            tagtypes: viewModel.tagtypes.filter {
                ($0.category == "merch-product" || $0.category == "merch-variant") && $0.isBrowsable == true
            }, showFilters: $showFilters, showBookmarks: false
          )
        }
        .padding(15)
        .analyticsScreen(name: "ProductsView")
    }
}

struct MerchInfo: View {
    @AppStorage("showMerchInfo") var showMerchInfo: Bool = true
    @Environment(InfoViewModel.self) private var viewModel
    
    var body: some View {
        if showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
            NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                HStack {
                    Button {
                        showMerchInfo = false
                    } label: {
                        Image(systemName: "x.circle")
                    }
                    .accessibilityLabel("Hide merch info")
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
    }
}

struct ProductsRow: View {
    var product: Product
    
    var body: some View {
        HStack {
            NavigationLink(destination: ProductView(product: product)) {
                ZStack(alignment: .bottomTrailing) {
                    if product.media.count > 0, let media_url = URL(string: product.media[0].url) {
                        KFImage(media_url)
                            .htDownsampled(side: 200)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(5)
                    } else {
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    }
                    if product.variants.filter({$0.stockStatus == "IN"}).count > 0 {
                        HStack {
                            Text(product.priceMin < product.priceMax ? "$\(product.priceMin / 100)+" : "$\(product.priceMin/100)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(5)
                        .background(Color(.systemGray6))
                        .cornerRadius(5)
                        .frame(alignment: .center)
                    } else {
                        HStack {
                            Text("Out of Stock")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(5)
                        .background(Color(.systemGray6))
                        .cornerRadius(5)
                        .frame(alignment: .center)
                    }
                }
            }
        }
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView()
    }
}
