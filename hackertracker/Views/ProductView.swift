//
//  ProductView.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI

struct ProductView: View {
    var product: Product

    var body: some View {
        Text(product.title)
            .font(.title)
        Divider()
        ScrollView {
            VStack {
                if product.media.count > 0 {
                    VStack {
                        TabView {
                            ForEach(product.media, id: \.assetId) { med in
                                if let media_url = URL(string: med.url) {
                                    AsyncImage(url: media_url) { phase in
                                        switch phase {
                                        case let .success(image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        default:
                                            Text(med.name.uppercased())
                                                .padding()
                                                .font(.caption)
                                                .background(Color.gray)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .tabViewStyle(.page)
                        .scaledToFill()
                    }
                    .padding(10)
                }
                ForEach(product.variants, id: \.variantId) { variant in
                    VariantRow(variant: variant)
                }
                Text("Add to cart")
                    .onTapGesture {
                        print("ProductView: Add \(product.code) to cart")
                    }
            }
        }
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
