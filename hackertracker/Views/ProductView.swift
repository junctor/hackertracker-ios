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
    @EnvironmentObject var viewModel: InfoViewModel
    @FetchRequest(sortDescriptors: []) var cart: FetchedResults<Cart>
    @State private var selectedVariant: Int
    @State private var count: Int = 1
    @State private var showAlert: Bool = false
    @State private var message = ""

    init(product: Product) {
        self.product = product
        _selectedVariant = State(initialValue: product.variants[0].variantId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(product.title)
                    .font(.title)
                if product.description != "" {
                    Divider()
                    Text(product.description)
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(Color(.systemGray6))
            .cornerRadius(15)
            
            VStack {
                if product.media.count > 0 {
                    VStack {
                        TabView {
                            ForEach(product.media, id: \.assetId) { med in
                                if let media_url = URL(string: med.url) {
                                    KFImage(media_url)
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
                    Stepper("Quantity: \(count)", value: $count, in: 1...100)
                        .fixedSize()
                }
                Divider()
                Text(viewModel.conference?.merchTaxStatement ?? "Tax Included")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                Divider()
                HStack {
                    if let v = product.variants.first(where: { $0.variantId == selectedVariant }) {
                        if v.stockStatus == "OUT" {
                            Button { } label: {
                                Text("Out of stock")
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(15)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        } else {
                            Button {
                                if count > 0 {
                                    CartUtility.addItem(context: viewContext, variantId: selectedVariant, count: count)
                                    print("ProductView: Add \(selectedVariant) - \(count) to list")
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
                            .background(ThemeColors.blue.gradient)
                            .cornerRadius(15)
                            .alert("Quantity must be 1 or more", isPresented: $showAlert) {
                                Button("Ok") { }
                            }
                         }
                    }
                }
                
                Text(message.uppercased())
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(15)
        .onAppear {
            self.selectedVariant = self.product.variants[0].variantId
        }
        .toolbar {
            NavigationLink(destination: CartView()) {
                ZStack {
                    Image(systemName: "qrcode")
                }
            }
        }
        .analyticsScreen(name: "ProductView")
    }
    
    func addToCart(variant: Variant) {
        print("ProductView: Add \(variant.variantId) to cart")
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ProductView()")
    }
}
