//
//  CartView.swift
//  hackertracker
//
//  Created by Seth Law on 7/8/23.
//

import SwiftUI

struct CartView: View {
    @FetchRequest(sortDescriptors: []) var cart: FetchedResults<Cart>
    @EnvironmentObject var viewModel: InfoViewModel
    @Environment(\.managedObjectContext) private var viewContext
    // @EnvironmentObject var theme: Theme
    @State private var total = 0
    @State private var total_items = 0

    var body: some View {
        ScrollView {
            QRCodeView(qrString: generateQRValue())
            Divider()
            ForEach(cart, id: \.self) { (item: Cart) in
                let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) })[0]
                let variant = product.variants.filter({$0.variantId == item.variantId})[0]
                CartRow(product: product, item: item, variant: variant, total: $total)
                /* .onAppear {
                    total += (variant.price*Int(item.count))
                    total_items += Int(item.count)
                }*/
                
            }
            HStack {
                Text("Subtotal (\(total_items) items)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("$\(total/100) USD")
                    .font(.headline)
                    .frame(alignment: .trailing)
            }
            
            HStack {
                Button {
                    total = 0
                    total_items = 0
                    CartUtility.emptyCart(context: viewContext)
                } label: {
                    Label("Empty Cart", systemImage: "trash")
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(15)
            .background(ThemeColors.red.gradient)
            .cornerRadius(15)
            
        }
        .onAppear {
            for item in cart {
                let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) })[0]
                let variant = product.variants.filter({$0.variantId == item.variantId})[0]
                total += (variant.price*Int(item.count))
                total_items += Int(item.count)
            }
        }
        .navigationTitle("Merch")
        .padding(15)
    }
    
    func generateQRValue() -> String {
        var qrCart: QRCart
        
        qrCart = QRCart(i: cart.map {QRItem(v: Int($0.variantId), q: Int($0.count))})
        
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(qrCart) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("QRCodeView: JSON Value: \(jsonString)")
                return jsonString
            }
        }
        return ""
    }
}

struct CartRow: View {
    var product: Product
    var item: Cart
    var variant: Variant
    @Binding var total: Int
    @Environment(\.managedObjectContext) private var viewContext
    @State private var count: Int = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(product.title) (\(variant.code))")
                    .font(.headline)
                    .bold()
                HStack {
                    Text("\(count)")
                        .bold()
                    Stepper("", value: $count)
                        .onAppear {
                            count = Int(item.count)
                        }
                        .fixedSize()
                    VStack {
                        Text("$\((variant.price*Int(item.count))/100) USD")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: count) { value in
            if value == 0 {
                total -= (Int(item.count) * variant.price)
                CartUtility.deleteItem(context: viewContext, variantId: variant.variantId)
            } else {
                total -= (Int(item.count) * variant.price)
                total += (value * variant.price)
                CartUtility.updateItem(context: viewContext, variantId: variant.variantId, count: value)
            }
        }
        Divider()
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
