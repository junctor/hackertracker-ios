//
//  ProductRow.swift
//  hackertracker
//
//  Created by Seth Law on 6/22/23.
//

import SwiftUI

struct ProductRow: View {
    var product: Product
    @State private var value: Int = 0
    @State private var isExpanded: Bool = false
    
    var body: some View {
            Image(systemName: "")
            DisclosureGroup(product.title, isExpanded: $isExpanded) {
                ForEach(product.variants, id: \.variantId) { variant in
                    VariantRow(variant: variant)
                }
            }
    }
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        Text("ProductRow()")
        // ProductRow()
    }
}
