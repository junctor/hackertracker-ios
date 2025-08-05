//
//  ShareBookmarksView.swift
//  hackertracker
//
//  Created by Seth Law on 7/29/25.
//
import SwiftUI

struct ShareBookmarksView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var viewModel: InfoViewModel
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @AppStorage("colorMode") var colorMode: Bool = false
    @State private var message = "Tap link to copy"
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .frame(alignment: .leading)
                        .padding(5)
                    Text("Share Schedule")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(colorMode ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(colorMode ? theme.carousel(): Color(.systemGray6))
                .cornerRadius(15)
                Divider()
                if let conf = viewModel.conference, bookmarks.filter({viewModel.events.map{Int32($0.id)}.contains($0.id)}).count > 0 {
                    let shareString = "hackertracker://\(conf.code)/s?ids=\(bookmarks.filter({viewModel.events.map{Int32($0.id)}.contains($0.id)}).map{ String($0.id) }.joined(separator: ","))"
                    QRCodeView(qrString: shareString)
                    Divider()
                    Button {
                        UIPasteboard.general.string = shareString
                        message = "Copied!"
                    } label: {
                        Label("hackertracker://\(conf.code)/s?...", systemImage: "doc.on.doc")
                    }
                    Text(message)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    Divider()
                    showEvents(eventIds: bookmarks.filter({viewModel.events.map{Int32($0.id)}.contains($0.id)}).map{Int($0.id)}, title: "Share \(bookmarks.filter({viewModel.events.map{Int32($0.id)}.contains($0.id)}).count) Events")
                } else {
                    Text("No bookmarks to share.")
                        /*.onAppear {
                            for id in bookmarks.map({$0.id}) {
                                if let e = viewModel.events.first(where: {$0.id == id}) {
                                    sharedIds.append(Int(e.id))
                                }
                            }
                        } */
                }
                Divider()
            }
        }
        .analyticsScreen(name: "ShareBookmarksView")
        .padding(15)
    }
}
