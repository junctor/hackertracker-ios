//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import SwiftUI
import FirebaseAnalytics

struct MapView: View {
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @State var loading: Bool = false

    let screenSize = UIScreen.main.bounds.size

    var body: some View {
        VStack {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documents.first(where: {$0.id == emergId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: ThemeColors.red, systemImage: "exclamationmark.triangle.fill")) {
                    CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: ThemeColors.red, subtitle: "Tap for more details")
                        .frame(height: 40)
                        .cornerRadius(0)
                }
            }
            if let con = viewModel.conference {
                if let maps = con.maps?.sorted(by: {$0.sortOrder < $1.sortOrder}), maps.count > 0 {
                    TabView {
                        ForEach(maps, id: \.id) { map in
                            if let url = URL(string: map.url) {
                                let path = "\(selected.code)/\(url.lastPathComponent)"
                                let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let mLocal = docDir.appendingPathComponent(path)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    PDFView(url: mLocal)
                                        .onAppear() {
                                            print("MapView: Loading \(mLocal)")
                                        }
                                        .frame(width: screenSize.width)
                                    if let desc = map.description {
                                        HStack {
                                            Text(desc)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(5)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(5)
                                        .frame(alignment: .center)
                                    }
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .scaledToFill()
                    .analyticsScreen(name: "MapView")
                } else {
                    _04View(message: "No Maps Provided For \(con.name)",show404: false)
                        .frame(maxHeight: .infinity)
                }
            } else {
                _04View(message: "Loading...", show404: false).preferredColorScheme(theme.colorScheme)
            }
        }
        .padding(10)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}

struct SpinnerView: View {
      var body: some View {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.blue))
              .scaleEffect(2.0, anchor: .center) // Makes the spinner larger
              .onAppear {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

                  }
            }
      }
}
