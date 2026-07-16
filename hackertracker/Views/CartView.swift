//
//  CartView.swift
//  hackertracker
//
//  Created by Seth Law on 7/8/23.
//

import SwiftUI

struct CartView: View {
    @FetchRequest(sortDescriptors: []) var cart: FetchedResults<Cart>
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var total = 0
    @State private var totalItems = 0
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            if !viewModel.outOfStock && cart.count > 0 {
                QRCodeView(qrString: generateQRValue())
            } else {
                if viewModel.outOfStock {
                    Text("Out Of Stock Items Selected")
                        .font(themeManager.headingFont)
                    Text("Remove out of stock items from list")
                        .font(themeManager.subheadlineFont)
                } else if cart.count == 0 {
                    Text("No Items Selected")
                        .font(themeManager.headingFont)
                    NavigationLink(destination: ProductsView()) {
                        Text("Select items to view QR Code")
                            .font(themeManager.subheadlineFont)
                    }
                }
            }
            Divider()
            ForEach(cart, id: \.self) { (item: Cart) in
                if let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) }).first, let variant = product.variants.filter({$0.variantId == item.variantId}).first {
                    CartRow(product: product, item: item, variant: variant, total: $total, totalItems: $totalItems)
                }
            }
            HStack {
                Text("Subtotal (\(totalItems) items)")
                    .font(themeManager.headingFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("$\(total/100) USD")
                    .font(themeManager.headingFont)
                    .frame(alignment: .trailing)
            }
            Divider()
            Text(viewModel.conference?.merchTaxStatement ?? "Tax Included")
                .font(themeManager.subheadlineFont)
                .multilineTextAlignment(.center)
            Divider()
            
            DeleteAllView(showDeleteAlert: $showDeleteAlert)
                .alert("Are you sure", isPresented: $showDeleteAlert) {
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
                if let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) }).first, let variant = product.variants.filter({$0.variantId == item.variantId}).first {
                    if variant.stockStatus == "OUT" {
                        viewModel.outOfStock = true
                    }
                    mytotal += (variant.price*Int(item.count))
                    mytotalItems += Int(item.count)
                }
            }
            total = mytotal
            totalItems = mytotalItems
            Log.cart.debug("recalculated total=\(total) totalItems=\(totalItems)")
        }
        .onChange(of: totalItems) { 
            checkOutOfStock()
            Log.cart.debug("totalItems changed")
        }
        .onDisappear {
            Log.cart.debug("closing")
        }
        .analyticsScreen(name: "CartView")
        .navigationTitle("Merch")
        .themedNavTitle("Merch", themeManager)
        .padding(15)
        .themedBackground(themeManager)
    }
    
    func checkOutOfStock() {
        viewModel.outOfStock = false
        for item in cart {
            if let product = viewModel.products.filter({ $0.variants.contains(where: { $0.variantId == item.variantId }) }).first, let variant = product.variants.filter({$0.variantId == item.variantId}).first {
                if variant.stockStatus == "OUT" {
                    viewModel.outOfStock = true
                }
            }
        }
    }
    
    func generateQRValue() -> String {
        var qrCart: QRCart
        
        qrCart = QRCart(i: cart.map {QRItem(v: Int($0.variantId), q: Int($0.count))})
        
        let version = 1
        let items = qrCart.i.map { "\($0.v):\($0.q)" }.joined(separator: ";")
        let compact = "\(version):\(viewModel.conference?.id ?? 0):i\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""):\(items):"
        Log.cart.debug("QR encoded: \(compact, privacy: .public)")
        return compact
        
        // let encoder = JSONEncoder()
        /* if let jsonData = try? encoder.encode(qrCart) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                Log.cart.debug("QR json: \(jsonString, privacy: .public)")
                return jsonString
            }
        }
        return "" */
    }
}

struct DeleteAllView: View {
    @Binding var showDeleteAlert: Bool
    @Environment(ThemeManager.self) private var themeManager
    var body: some View {
        HStack {
            Button {
                showDeleteAlert = true
            } label: {
                Label("Delete All", systemImage: "trash")
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(15)
        .background(themeManager.danger)
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
    @Environment(InfoViewModel.self) private var viewModel
    @State private var count: Int = 0
    
    init(product: Product, item: Cart, variant: Variant, total: Binding<Int>, totalItems: Binding<Int>) {
        self.product = product
        self.item = item
        self.variant = variant
        _total = total
        _totalItems = totalItems
        _count = State(initialValue: Int(item.count))
    }

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(product.title) (\(variant.code))")
                    .font(themeManager.headingFont)
                    .bold()
                HStack {
                    Text("\(count)")
                        .bold()
                    Stepper("", value: $count, in: 0...100)
                        .fixedSize()
                    VStack {
                        Text("$\((variant.price*Int(item.count))/100) USD")
                            .font(themeManager.subheadlineFont)
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
                    .foregroundColor(themeManager.danger)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(15)
                    .background(themeManager.cardSurface)
                    .cornerRadius(15)
                    .frame(alignment: .center)
                    .onAppear {
                        viewModel.outOfStock = true
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: count) { _, value in 
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
