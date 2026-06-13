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
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var theme: Theme
    @State var loading: Bool = false

    var body: some View {
        // Polish: wrap in NavigationStack so the screen has the same frosted
        // title bar as the other tabs. MapView is a TabView item with no
        // surrounding NavigationStack, so without this wrapper the
        // .navigationTitle modifier has nothing to attach to.
        NavigationStack {
        VStack {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documentsById[emergId] {
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
                                            Log.ui.debug("MapView loading \(mLocal, privacy: .public)")
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    // Perf/UX: keep the page indicator visible (default on dark
                    // backgrounds is barely-visible white-on-white). Background
                    // color set on the VStack below stops the system from
                    // flashing black between pages while a PDF parses.
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
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
        .background(Color(.systemBackground))
        .navigationTitle("Maps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        }
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
