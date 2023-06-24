//
//  ProductsView.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI

struct ProductsView: View {
    var title: String
    var products: [Product]
    var body: some View {
        List {
            ForEach(products) { product in
                NavigationLink(destination: ProductView(product: product)) {
                    VStack(alignment: .leading) {
                        Text(product.title)
                            .font(.headline)
                        Text("$\(product.priceMin/100) - $\(product.priceMax/100)")
                            .font(.caption)
                    }
                }
                // ProductRow(product: product)
            }
        }.navigationTitle(title)
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView(title: "Merch", products: [])
    }
}
