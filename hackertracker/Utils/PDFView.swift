//
//  PDFView.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import PDFKit
import SwiftUI

struct PDFView: UIViewRepresentable {
    var url: URL

    func makeUIView(context _: Context) -> PDFKit.PDFView {
        let pdfView = PDFKit.PDFView()
        print("PDFView makUIview - Showing pdf from: \(url)")
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFKit.PDFView, context _: Context) {
        print("PDFView updateUIView - \(url)")
        pdfView.document = PDFDocument(url: url)
    }
}
