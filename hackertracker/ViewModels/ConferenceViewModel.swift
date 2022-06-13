//
//  ConferenceViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import Combine

class ConferenceViewModel: ObservableObject  {
    private let conferenceRepository = ConferenceRepository()
    @Published var conference: Conference
    
    private var cancellables: Set<AnyCancellable> = []
    
    var id = 0
    
    init(conference: Conference) {
        self.conference = conference
        $conference
            .compactMap { $0.id }
            .assign(to: \.id, on: self)
            //.store(in: &cancellables)
    }
    
}
