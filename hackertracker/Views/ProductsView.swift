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
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.showMerchInfo) var showMerchInfo: Bool = true
    @State private var searchText = ""
    /// Perf C: debounced mirror of `searchText`. Updated on a 200ms
    /// .task(id:) so visibleProducts re-filters once per pause rather
    /// than on every keystroke.
    @State private var debouncedSearch = ""
    @State private var showFilters = false
    /// Merch-size selection lives in `MerchFiltersStore` (injected via
    /// environment from ContentView). Hoisting out of @State lets the
    /// selection survive tab switches; the store also persists it
    /// across cold launches via UserDefaults.
    @EnvironmentObject private var merchFilters: MerchFiltersStore
    @AppStorage(AppStorageKeys.filterMatchModeMerch) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    private var filterMatchMode: FilterMatchMode {
        FilterMatchMode(rawOrDefault: filterMatchModeRaw)
    }
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
        viewModel.products.search(text: debouncedSearch)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { product in
                // No size selected -> show everything (after search).
                // Otherwise keep products that stock at least one variant
                // whose title matches a selected size. Out-of-stock SKUs
                // do not satisfy the filter so the grid only shows items
                // the user could actually buy in that size.
                guard !merchFilters.sizes.isEmpty else { return true }
                // In-stock variant titles available for this product.
                let inStockTitles = Set(
                    product.variants
                        .filter { $0.stockStatus == "IN" }
                        .map { $0.title }
                )
                switch filterMatchMode {
                case .any:
                    // Any of the selected sizes is available.
                    return !inStockTitles.isDisjoint(with: merchFilters.sizes)
                case .all:
                    // Every selected size is available — for users
                    // who need a specific bundle of sizes (e.g. both
                    // M and L for two recipients).
                    return merchFilters.sizes.isSubset(of: inStockTitles)
                }
            }
    }

    @ViewBuilder
    private var productsSidebar: some View {
        VStack(spacing: 0) {
            InlineSearchBar(placeholder: "Search merch", text: $searchText, isFocused: $searchFocused, visible: isSearching)
        ScrollView {
            if showMerchInfo {
                MerchInfo()
            }
            Text(viewModel.conference?.merchMandatoryAck ?? "Tax Included. All Sales Final")
                .font(themeManager.subheadlineFont)
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
                        Image(systemName: merchFilters.sizes.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .font(themeManager.title2Font)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .tint(.primary)
                    .accessibilityLabel(merchFilters.sizes.isEmpty ? "Filters" : "Filters active")
                }

                Spacer()

                JumpMenuOverlay(target: $jumpTarget)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("Merch")
        .themedNavTitle("Merch", themeManager)
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
                SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search merch")
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
                selected: $merchFilters.sizes,
                showFilters: $showFilters,
                matchedCount: visibleProducts.count
            )
        }
        .task(id: searchText) {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if !Task.isCancelled { debouncedSearch = searchText }
        }
        .analyticsScreen(name: "ProductsView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                productsSidebar
                    .frame(width: IPadAdaptive.sidebarWidth)
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
    @AppStorage(AppStorageKeys.showMerchInfo) var showMerchInfo: Bool = true
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    
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
                        Text(doc.title).font(themeManager.subheadlineFont).fontWeight(.bold)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(themeManager.cardSurface)
                .cornerRadius(15)
            }
            Divider()
        }
    }
}

struct ProductsRow: View {
    var product: Product
    @Environment(\.iPadProductSelection) private var iPadProductSelection

    @Environment(ThemeManager.self) private var themeManager

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
                                .font(themeManager.subheadlineFont)
                                .foregroundColor(.primary)
                        }
                        .padding(5)
                        .background(themeManager.cardSurface)
                        .cornerRadius(5)
                        .frame(alignment: .center)
                    } else {
                        HStack {
                            Text("Out of Stock")
                                .font(themeManager.subheadlineFont)
                                .foregroundColor(.red)
                        }
                        .padding(5)
                        .background(themeManager.cardSurface)
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
    @Environment(ThemeManager.self) private var themeManager
    /// Number of products that would survive the current selection.
    /// Same shape as FiltersView.matchedCount; caller computes from
    /// the already-filtered list to keep the sheet stateless.
    var matchedCount: Int = 0

    @AppStorage(AppStorageKeys.filterMatchModeMerch) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        // Matches the Schedule's FiltersView: NavigationStack-wrapped
        // for rounded sheet corners + native toolbar buttons; Match
        // Any/All segmented picker at the top.
        NavigationStack {
            ScrollView {
                MatchModePickerRow(raw: $filterMatchModeRaw)
                FilterMatchCountLabel(count: matchedCount, unit: "product")

                LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                    ForEach(sizes, id: \.self) { size in
                        let isOn = selected.contains(size)
                        Button {
                            if isOn { selected.remove(size) } else { selected.insert(size) }
                        } label: {
                            Text(size)
                                .font(themeManager.subheadlineFont)
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
            .navigationTitle("Filter by Size")
            .themedNavTitle("Filter by Size", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        selected.removeAll()
                    }
                    .disabled(selected.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFilters = false }
                        .bold()
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
