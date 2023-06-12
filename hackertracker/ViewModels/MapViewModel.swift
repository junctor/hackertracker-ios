//
//  MapViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var maps = [Map]()

    private var db = Firestore.firestore()

    func fetchData(code: String) {
        db.collection("conferences/\(code)/maps")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.maps = docs.compactMap { queryDocumentSnapshot -> Map? in
                    do {
                        return try queryDocumentSnapshot.data(as: Map.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("MapViewModel: Maps: \(self.maps.count)")
            }
    }
}
