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
    var form: FeedbackForm
    @EnvironmentObject var viewModel: InfoViewModel
    @State var test: String = ""
    @State var answers: [Int: String] = [:]
    
    var body: some View {
        HStack {
            Text(form.name)
                .font(.title)
        }
        .padding(15)
            Divider()
            Text(item.title)
                .font(.title3)
            Divider()
            Form {
                ForEach(form.items) { i in
                    //Text(i.captionText)
                    if i.type == "select_one" {
                        Picker(i.captionText, selection: $answers[i.id]) {
                            ForEach(i.options) { o in
                                Text(o.captionText).tag(o.id)
                            }
                        }
                        .pickerStyle(.inline)
                    } else if i.type == "text" {
                        Text(i.captionText)
                        TextField("", text: $answers[i.id])
                    } else {
                        Text("Currently Unavailable")
                    }
                }
                Section {
                    TextField("Test", text: $test)
                }
            }
            Divider()
            HStack {
                Button(action: {
                    showFeedback.toggle()
                }, label: {
                    Text("Close")
                })
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(Color(.systemGray5))
                .cornerRadius(15)
                
                Button(action: {
                    showFeedback.toggle()
                }, label: {
                    Text("Submit")
                })
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(Color(.systemGray5))
                .cornerRadius(15)
            }
            .padding(15)
    }
}
