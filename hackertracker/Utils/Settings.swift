//
//  Settings.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import Combine

class Settings: ObservableObject {
    @Published var isDark: Bool {
        didSet {
            UserDefaults.standard.set(isDark, forKey: "isDark")
        }
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "isDark") == nil {
            self.isDark = true
            UserDefaults.standard.set(self.isDark, forKey: "isDark")
        } else {
            self.isDark = UserDefaults.standard.bool(forKey: "isDark")
        }
    }
}
