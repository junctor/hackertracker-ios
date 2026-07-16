//
//  ProductView.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI
import Kingfisher

struct ProductView: View {
    var product: Product
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(InfoViewModel.self) private var viewModel
    @FetchRequest(sortDescriptors: []) var cart: FetchedResults<Cart>
    @State private var selectedVariant: Int
    @State private var count: Int = 1
    @State private var showAlert: Bool = false
    @State private var message = ""

    init(product: Product) {
        self.product = product
        _selectedVariant = State(initialValue: product.variants[0].variantId)
    }
    
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(product.title)
                    .font(themeManager.titleFont)
                if product.description != "" {
                    Divider()
                    Text(product.description)
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(themeManager.cardSurface)
            .cornerRadius(15)
            
            VStack {
                if product.media.count > 0 {
                    VStack {
                        TabView {
                            ForEach(product.media, id: \.assetId) { med in
                                if let media_url = URL(string: med.url) {
                                    KFImage(media_url)
                                        .htDownsampled(side: 600)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }
                        .tabViewStyle(.page)
                    }
                    // .frame(ide: 300)
                    .frame(maxWidth: .infinity, idealHeight: 300)
                    .padding(10)
                }
                HStack {
                    VStack(alignment: .leading) {
                        Picker("Options", selection: $selectedVariant) {
                            ForEach(product.variants, id: \.variantId) { variant in
                                Text("\(variant.code) - $\(variant.price/100)\((variant.stockStatus == "LOW") ? " - Low Stock" : "" )\((variant.stockStatus == "OUT") ? " - Out of Stock" : "" )")
                                    .tag(variant.variantId)
                            }
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                    }
                    .frame(maxWidth: .infinity)
                    // Polish: quantity only makes sense when an actual cart
                    // exists. Browse-only mode (enableMerch=true,
                    // enableMerchCart=false) keeps just the variant dropdown.
                    if viewModel.conference?.enableMerchCart == true {
                        Stepper("Quantity: \(count)", value: $count, in: 1...100)
                            .fixedSize()
                    }
                }
                Divider()
                Text(viewModel.conference?.merchTaxStatement ?? "Tax Included")
                    .font(themeManager.subheadlineFont)
                    .multilineTextAlignment(.center)
                Divider()
                // Polish: honor Conference.enableMerchCart. When the cart is
                // disabled for this conference, show product info but suppress
                // the "Add to List" affordance entirely (still surface
                // "Out of stock" so shoppers know variants are unavailable).
                if viewModel.conference?.enableMerchCart == true {
                    HStack {
                        if let v = product.variants.first(where: { $0.variantId == selectedVariant }) {
                            if v.stockStatus == "OUT" {
                                Button { } label: {
                                    Text("Out of stock")
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(15)
                                .background(themeManager.cardSurface)
                                .cornerRadius(15)
                            } else {
                                Button {
                                    if count > 0 {
                                        CartUtility.addItem(context: viewContext, variantId: selectedVariant, count: count)
                                        Log.cart.debug("ProductView add variant=\(selectedVariant) count=\(count)")
                                        message = "Added \(count) \(v.code) \(product.title) to list"
                                    } else {
                                        showAlert = true
                                    }
                                } label: {
                                    Text("Add to List")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(15)
                                .background(themeManager.accent)
                                .cornerRadius(15)
                                .alert("Quantity must be 1 or more", isPresented: $showAlert) {
                                    Button("Ok") { }
                                }
                             }
                        }
                    }
                } else if let v = product.variants.first(where: { $0.variantId == selectedVariant }), v.stockStatus == "OUT" {
                    // Cart disabled but still want to communicate out-of-stock.
                    Text("Out of stock")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(15)
                        .background(themeManager.cardSurface)
                        .cornerRadius(15)
                }
                
                Text(message.uppercased())
                    .foregroundColor(ThemeColors.muted)
                    .font(themeManager.captionFont)
            }
        }
        .themedBackground(themeManager)
        .padding(15)
        .task {
            self.selectedVariant = self.product.variants[0].variantId
        }
        .toolbar {
            // Polish: only show the Cart link when the conference enables the cart.
            // iPad split-view: ProductsView sidebar already provides the
            // Cart link in the shared parent NavigationStack; suppress
            // here to avoid a duplicate QR icon in the navbar.
            if !IPadAdaptive.isIPad, viewModel.conference?.enableMerchCart == true {
                NavigationLink(destination: CartView()) {
                    ZStack {
                        Image(systemName: "qrcode")
                    }
                }
                .accessibilityLabel("Cart")
            }
        }
        .analyticsScreen(name: "ProductView")
    }
    
    func addToCart(variant: Variant) {
        Log.cart.debug("ProductView add variant=\(variant.variantId)")
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ProductView()")
    }
}
