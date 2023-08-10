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
    @State private var total = 0
    @State private var totalItems = 0
    @State private var showingAlert = false

    var body: some View {
        ScrollView {
            if !viewModel.outOfStock && cart.count > 0 {
                QRCodeView(qrString: generateQRValue())
            } else {
                if viewModel.outOfStock {
                    Text("Out Of Stock Items Selected")
                        .font(.headline)
                    Text("Remove out of stock items from list")
                        .font(.subheadline)
                } else if cart.count == 0 {
                    Text("No Items Selected")
                        .font(.headline)
                    NavigationLink(destination: ProductsView()) {
                        Text("Select items to view QR Code")
                            .font(.subheadline)
                    }
                }
            }
            Divider()
            ForEach(cart, id: \.self) { (item: Cart) in
                let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) })[0]
                let variant = product.variants.filter({$0.variantId == item.variantId})[0]
                CartRow(product: product, item: item, variant: variant, total: $total, totalItems: $totalItems)
            }
            HStack {
                Text("Subtotal (\(totalItems) items)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("$\(total/100) USD")
                    .font(.headline)
                    .frame(alignment: .trailing)
            }
            
            DeleteAllView(showingAlert: $showingAlert)
                .alert("Are you sure", isPresented: $showingAlert) {
                    Button("Yes") {
                        total = 0
                        totalItems = 0
                        CartUtility.emptyCart(context: viewContext)
                    }
                    Button("No", role: .cancel) { }
                }
        }
        .onAppear {
            viewModel.outOfStock = false
            var mytotal = 0
            var mytotalItems = 0
            for item in cart {
                let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) })[0]
                let variant = product.variants.filter({$0.variantId == item.variantId})[0]
                if variant.stockStatus == "OUT" {
                    viewModel.outOfStock = true
                }
                mytotal += (variant.price*Int(item.count))
                mytotalItems += Int(item.count)
            }
            total = mytotal
            totalItems = mytotalItems
        }
        .onChange(of: totalItems) { _ in
            checkOutOfStock()
        }
        .analyticsScreen(name: "CartView")
        .navigationTitle("Merch")
        .padding(15)
    }
    
    func checkOutOfStock() {
        viewModel.outOfStock = false
        for item in cart {
            let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) })[0]
            let variant = product.variants.filter({$0.variantId == item.variantId})[0]
            if variant.stockStatus == "OUT" {
                viewModel.outOfStock = true
            }
        }
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

struct DeleteAllView: View {
    @Binding var showingAlert: Bool
    var body: some View {
        HStack {
            Button {
                showingAlert = true
            } label: {
                Label("Delete All", systemImage: "trash")
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(15)
        .background(ThemeColors.red.gradient)
        .cornerRadius(15)
    }
}

struct CartRow: View {
    var product: Product
    var item: Cart
    var variant: Variant
    @Binding var total: Int
    @Binding var totalItems: Int
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: InfoViewModel
    @State private var count: Int = 0
    
    init(product: Product, item: Cart, variant: Variant, total: Binding<Int>, totalItems: Binding<Int>) {
        self.product = product
        self.item = item
        self.variant = variant
        _total = total
        _totalItems = totalItems
        _count = State(initialValue: Int(item.count))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(product.title) (\(variant.code))")
                    .font(.headline)
                    .bold()
                HStack {
                    Text("\(count)")
                        .bold()
                    Stepper("", value: $count, in: 0...100)
                        .fixedSize()
                    VStack {
                        Text("$\((variant.price*Int(item.count))/100) USD")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                if variant.stockStatus == "OUT" {
                    HStack {
                        Button {
                            count = 0
                        } label: {
                            Label("Out of stock, remove from list", systemImage: "trash")
                                .font(.callout)
                        }
                    }
                    .foregroundColor(ThemeColors.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(15)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .frame(alignment: .center)
                    .onAppear {
                        viewModel.outOfStock = true
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: count) { value in
            if value == 0 {
                total -= (Int(item.count) * variant.price)
                totalItems -= Int(item.count)
                CartUtility.deleteItem(context: viewContext, variantId: variant.variantId)
            } else if count != Int(item.count) {
                total -= (Int(item.count) * variant.price)
                total += (value * variant.price)
                totalItems -= Int(item.count)
                totalItems += value
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
