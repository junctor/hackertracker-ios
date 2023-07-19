//
//  QRCodeView.swift
//  hackertracker
//
//  Created by Seth Law on 7/8/23.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    // @FetchRequest(sortDescriptors: []) var cart: FetchedResults<Cart>
    var qrString: String
    
    var body: some View {
        VStack {
            Image(uiImage: generateQRCode(from: qrString))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
            let data = Data(string.utf8)
            
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
            
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(qrString: "Just a test QR Code String here")
    }
}
