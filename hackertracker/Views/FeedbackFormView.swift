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
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @State var test: String = ""
    @State var answers: [Int: AnyObject] = [:]
    let dfu = DateFormatterUtility.shared
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @FetchRequest(sortDescriptors: []) var feedbacks: FetchedResults<Feedbacks>
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
        VStack {
            Text(form.name)
                .font(themeManager.titleFont)
            Divider()
            Text(item.title)
                .font(themeManager.title3Font)
        }
        .padding(15)
        Divider()
        Form {
            ForEach(form.items.sorted(by: {$0.sortOrder < $1.sortOrder})) { i in
                FeedbackRow(item: i,answers: $answers)
            }
        }
        Divider()
        VStack(alignment: .center) {
            Text("A minimum of one answer is required for submission.")
                .font(themeManager.captionFont)
            HStack {
                Button(action: {
                    showFeedback = false
                    // showFeedback.toggle()
                }, label: {
                    Text("Close")
                })
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(Color(.systemGray5))
                .cornerRadius(15)
                
                Button(action: {
                    // print("Answers: \(answers.values.count)")
                    if answers.values.count > 1 {
                        uploadFeedback(item: item, form: form, answers: answers, viewModel: viewModel, dfu: dfu)
                        showFeedback = false
                    }
                }, label: {
                    Text("Submit")
                })
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(Color(.systemGray5))
                .cornerRadius(15)
            }
        }
        .padding(15)
    }
}

extension FeedbackFormView {
    
    func uploadFeedback(item: Content, form: FeedbackForm, answers: [Int: AnyObject], viewModel: InfoViewModel, dfu: DateFormatterUtility) {
        var feedback: [String: Any] = [:]
        feedback["client"] = "HackerTracker iOS v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\( Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"
        feedback["conference_id"] = viewModel.conference?.id ?? 0
        feedback["content_id"] = item.id
        feedback["device_id"] = UIDevice.current.identifierForVendor?.uuidString ?? "no-ios-uuid-found"
        feedback["feedback_form_id"] = form.id
        feedback["items"] = []
        feedback["timestamp"] = dfu.iso8601ColonFormatter.string(from: Date())
        
        for a in answers {
            var opt: [String: Any] = [:]
            var existingItems = feedback["items"] as? [[String: Any]] ?? [[String: Any]]()
            
            if let str = a.value as? String {
                opt["item_id"] = a.key
                opt["text"] = str
                existingItems.append(opt)
            } else if let i = a.value as? Int {
                opt["item_id"] = a.key
                opt["options"] = [i]
                existingItems.append(opt)
            }
            feedback["items"] = existingItems
        }
        
        if let url = URL(string: form.submissionUrl) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try? JSONSerialization.data(withJSONObject: feedback)
                request.httpBody = jsonData
                if let jd = jsonData, let fb = String(data: jd, encoding: .utf8) {
                    NSLog("Feedback form for submission: \(fb)")
                }
                let capturedItemId = item.id
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.alertMessage = "Failed to send feedback: \(error.localizedDescription)"
                            self.showAlert.toggle()
                        }
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        DispatchQueue.main.async {
                            self.alertMessage = "Failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                            self.showAlert.toggle()
                        }
                        NSLog("Failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                        return
                    }
                    DispatchQueue.main.async {
                        self.alertMessage = "Feedback Sent"
                        FeedbackUtility.addFeedback(context: viewContext, id: capturedItemId)
                        self.showAlert.toggle()
                    }
                    NSLog("Feedback sent successfully")
                }.resume()
            }
        }
    }
}

struct FeedbackRow: View {
    var item: FeedbackItem
    @Binding var answers: [Int: AnyObject]
    @Environment(ThemeManager.self) private var themeManager
    @State var answer: String = ""
    
    var body: some View {
        if item.type == "select_one" {
            Picker(selection: $answer, label: Text(item.captionText).font(themeManager.headingFont), content: {
                ForEach(item.options) {
                    Text($0.captionText).tag($0.captionText)
                }
            })
            .pickerStyle(.inline)
            .onChange(of: answer) { _, val in 
                if let option = item.options.first(where: {$0.captionText == val}) {
                    answers[item.id] = option.id as AnyObject
                }
            }
        } else if item.type == "text" {
            Text(item.captionText).textCase(.uppercase).font(themeManager.subheadlineFont).bold()
            TextField("Optional", text: $answer, axis: .vertical)
                .lineLimit(5...5)
                .onReceive(answer.publisher.collect()) {
                    answer = String($0.prefix(item.textMaxLength ?? 1024))
                    answers[item.id] = answer as AnyObject
                }
        } else {
            Text("Currently Unavailable")
        }

    }
}
