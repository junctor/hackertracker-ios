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
    @State private var selectedVariant: Int = 0
    @State private var count: Int = 0

    /* init(product: Product) {
        self.product = product
        _selectedVariant = State(initialValue: product.variants[0])
    } */
    
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
            .foregroundColor(.white)
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
                    Picker("Options", selection: $selectedVariant) {
                        ForEach(product.variants, id: \.variantId) { variant in
                            Text("Size: \(variant.code) - $\(variant.price/100)")
                                .foregroundColor(.white)
                                .tag(variant.variantId)
                                .onTapGesture {
                                    selectedVariant = variant.variantId
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Stepper("", value: $count)
                }
                /* ForEach(product.variants, id: \.variantId) { variant in
                    VariantRow(variant: variant)
                } */
                
                HStack {
                    Button {
                        if count > 0 {
                            CartUtility.addItem(context: viewContext, variantId: selectedVariant, count: count)
                            print("ProductView: Add \(selectedVariant) - \(count) to cart")
                        } else {
                            print("Add item failed: \(selectedVariant) - \(count)")
                        }
                    } label: {
                        if count > 0 {
                            Text("Add to cart (\(count))")
                        } else {
                            Text("Add to cart")
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(ThemeColors.blue.gradient)
                .cornerRadius(15)
                
            }
        }
        .onAppear {
            self.selectedVariant = self.product.variants[0].variantId
        }
    }
    
    func addToCart(variant: Variant) {
        print("ProductView: Add \(variant.variantId) to cart")
    }
}

struct VariantRow: View {
    var variant: Variant
    @State var value: Int = 0

    var body: some View {
        HStack {
            Text("$\(variant.price / 100).00 -")
            Stepper("Size: \(variant.code)", value: $value)
            Text("\(value)")
        }
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ProductView()")
    }
}
