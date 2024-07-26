//
//  FeedbackFormView.swift
//  hackertracker
//
//  Created by Seth Law on 7/25/24.
//

import SwiftUI

struct FeedbackFormView: View {
    @Binding var showFeedback: Bool
    var item: Content
    @EnvironmentObject var viewModel: InfoViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Submit Feedback")
                    .font(.title)
                Text(item.title)
                    .font(.title3)
                Divider()
                Text("Question 1")
                Divider()
                Text("Question 2")
                Divider()
                Text("Question 3")
                Divider()
                HStack {
                    Button("Submit") {
                        showFeedback = false
                    }
                    Button("Cancel") {
                        showFeedback = false
                    }
                }
            }
        }
    }
}
