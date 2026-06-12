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

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?

    // iPad: GridItem(.adaptive) yields 2 columns on every iPhone width
    // and 4-6 columns on iPad portrait/landscape automatically.
    let gridItemLayout = IPadAdaptive.adaptiveGridColumns(minimum: 170)

    /// Polish: the merch filter sheet renders Sections per TagType. If no
    /// browsable merch-product / merch-variant tag types exist in the
    /// current conference data, the sheet would open empty. Compute the
    /// eligible list once and use it to (a) decide whether to show the
    /// floating Filter button at all, and (b) feed the sheet itself.
    private var availableFilterTagTypes: [TagType] {
        viewModel.tagtypes.filter {
            ($0.category == "merch-product" || $0.category == "merch-variant")
            && $0.isBrowsable == true
        }
    }

    private var visibleProducts: [Product] {
        viewModel.products.search(text: searchText)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { product in
                filters.filters.count == 0 ||
                product.tagIds.filter({ filters.filters.contains($0) }).count > 0 ||
                product.variants.filter({ $0.tagIds.intersects(with: filters.filters) && $0.stockStatus == "IN" }).count > 0
            }
    }

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search merch", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var searchToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                searchFocused = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : "Search merch")
    }

    @ViewBuilder private var jumpMenu: some View {
        Menu {
            Button {
                jumpTarget = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                jumpTarget = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    var body: some View {
        VStack(spacing: 0) {
            inlineSearchBar
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
                ScrollViewReader { proxy in
                    Color.clear.frame(height: 1).id("__top")
                    LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                        ForEach(visibleProducts) { product in
                            ProductsRow(product: product)
                        }
                    }
                    Color.clear.frame(height: 1).id("__bottom")
                        .onChange(of: jumpTarget) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { jumpTarget = nil }
                        }
                }
            }
        }
        .refreshable {
            if let code = viewModel.conference?.code {
                viewModel.fetchData(code: code)
            }
        }
        .padding(15)
        }
        .overlay(alignment: .bottom) {
            HStack {
                // Polish: don't render the filter button when there are no
                // applicable merch tag types -- opening the sheet would just
                // show empty Sections.
                if !availableFilterTagTypes.isEmpty {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: filters.filters.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .tint(.primary)
                    .accessibilityLabel(filters.filters.isEmpty ? "Filters" : "Filters active")
                }

                Spacer()

                jumpMenu
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Jump")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("Merch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documents.first(where: {$0.id == docId}) {
                    NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Merch info")
                }
                searchToggleButton
                if let c = viewModel.conference, c.enableMerchCart {
                    NavigationLink(destination: CartView()) {
                        Image(systemName: "qrcode")
                    }
                    .accessibilityLabel("Cart")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
          EventFilters(
            tagtypes: availableFilterTagTypes,
            showFilters: $showFilters,
            showBookmarks: false
          )
        }
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
