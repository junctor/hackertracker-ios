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
    /// Local merch-size filter state. Variant titles carry the size
    /// label (e.g. "XS"); kept here rather than in the shared Filters
    /// env object so it does not collide with the Schedule tag filters.
    @State private var selectedSizes: Set<String> = []
    @EnvironmentObject var filters: Filters

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?
    /// iPad-only: selected product id for the detail column.
    @State private var ipadSelectedProductId: Int?
    /// iPad split-view: row taps update detail column instead of pushing.
    @Environment(\.iPadProductSelection) private var iPadProductSelection

    // iPad: GridItem(.adaptive) yields 2 columns on every iPhone width
    // and 4-6 columns on iPad portrait/landscape automatically.
    let gridItemLayout = IPadAdaptive.adaptiveGridColumns(minimum: 170)

    /// Sizes available across merch in the current conference. Sourced
    /// from `Variant.title` (e.g. "XS", "M") because this conference's
    /// Firestore data carries size as a variant title rather than a tag,
    /// so the original tag-based filter rendered empty.
    private var availableSizes: [String] {
        struct Entry { let title: String; let sortOrder: Int }
        var bestSortByTitle: [String: Int] = [:]
        for product in viewModel.products {
            for variant in product.variants {
                let key = variant.title
                guard !key.isEmpty else { continue }
                if let existing = bestSortByTitle[key] {
                    bestSortByTitle[key] = min(existing, variant.sortOrder)
                } else {
                    bestSortByTitle[key] = variant.sortOrder
                }
            }
        }
        return bestSortByTitle
            .map { (title: $0.key, sortOrder: $0.value) }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            .map(\.title)
    }

    private var visibleProducts: [Product] {
        viewModel.products.search(text: searchText)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { product in
                // No size selected -> show everything (after search).
                // Otherwise keep products that stock at least one variant
                // whose title matches a selected size. Out-of-stock SKUs
                // do not satisfy the filter so the grid only shows items
                // the user could actually buy in that size.
                guard !selectedSizes.isEmpty else { return true }
                return product.variants.contains { variant in
                    selectedSizes.contains(variant.title) && variant.stockStatus == "IN"
                }
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

    @ViewBuilder
    private var productsSidebar: some View {
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
                if !availableSizes.isEmpty {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: selectedSizes.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .tint(.primary)
                    .accessibilityLabel(selectedSizes.isEmpty ? "Filters" : "Filters active")
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
                if !showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documentsById[docId] {
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
            MerchSizeFilter(
                sizes: availableSizes,
                selected: $selectedSizes,
                showFilters: $showFilters
            )
        }
        .analyticsScreen(name: "ProductsView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                productsSidebar
                    .frame(width: 420)
                Divider()
                Group {
                    if let id = ipadSelectedProductId,
                       let product = viewModel.productsById[id] {
                        ProductView(product: product)
                            .id(id)
                    } else {
                        ContentUnavailableView(
                            "Select Merch",
                            systemImage: "tshirt",
                            description: Text("Tap an item in the grid to view details.")
                        )
                    }
                }
            }
            .environment(\.iPadProductSelection, $ipadSelectedProductId)
        } else {
            productsSidebar
        }
    }
}

struct MerchInfo: View {
    @AppStorage("showMerchInfo") var showMerchInfo: Bool = true
    @Environment(InfoViewModel.self) private var viewModel
    
    var body: some View {
        if showMerchInfo, let c = viewModel.conference, let docId = c.merchHelpDocId, let doc = viewModel.documentsById[docId] {
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
    @Environment(\.iPadProductSelection) private var iPadProductSelection

    var body: some View {
        HStack {
            if let sel = iPadProductSelection {
                Button {
                    sel.wrappedValue = product.id
                } label: {
                    productInner
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: ProductView(product: product)) {
                productInner
            }
            }
        }
    }


    @ViewBuilder private var productInner: some View {
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

struct MerchSizeFilter: View {
    let sizes: [String]
    @Binding var selected: Set<String>
    @Binding var showFilters: Bool

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    selected.removeAll()
                } label: {
                    Image(systemName: "x.circle")
                    Text("Clear")
                }
                Spacer()
                Text("Filter by Size").font(.headline)
                Spacer()
                Button {
                    showFilters = false
                } label: {
                    Text("Close")
                    Image(systemName: "checkmark.circle")
                }
            }
            .padding(10)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                    ForEach(sizes, id: \.self) { size in
                        let isOn = selected.contains(size)
                        Button {
                            if isOn { selected.remove(size) } else { selected.insert(size) }
                        } label: {
                            Text(size)
                                .font(.subheadline)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(isOn ? .white : .primary)
                                .background(isOn ? Color.accentColor : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isOn ? Color.clear : Color.accentColor, lineWidth: 2)
                                )
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(10)
            }
        }
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView()
    }
}
