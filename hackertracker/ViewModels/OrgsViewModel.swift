//
//  OrgsViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class OrgsViewModel: ObservableObject {
    @Published var orgs = [Organization]()
    @Published var searchText = ""
    
    var filteredOrganizations: [Organization] {
        guard !searchText.isEmpty else {
            return orgs
        }
        return orgs.filter { orgs in
            orgs.name.lowercased().contains(searchText.lowercased())
        }
    }

    private var db = Firestore.firestore()

    func fetchData(code: String) {
        db.collection("conferences/\(code)/organizations")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.orgs = docs.compactMap { queryDocumentSnapshot -> Organization? in
                    do {
                        return try queryDocumentSnapshot.data(as: Organization.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
            }
    }
    
    func organizationGroup() -> [String.Element: [Organization]] {
        
        return Dictionary(grouping: filteredOrganizations, by: { $0.name.first ?? "-" })
    }
}
