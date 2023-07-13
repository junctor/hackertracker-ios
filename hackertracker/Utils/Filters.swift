//
//  Filters.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/13/23.
//

import Foundation

class Filters: ObservableObject {
    @Published var filters: Set<Int>
    
    init(filters: Set<Int>) {
        self.filters = filters
    }
}
