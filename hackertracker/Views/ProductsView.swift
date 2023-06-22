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
                Text("\(product.title) - \(product.code)")
            }
        }.navigationTitle(title)
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductsView(title: "Merch", products: [])
    }
}
