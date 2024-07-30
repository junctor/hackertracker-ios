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
    @State var answers: [Int: AnyObject] = [:]
    let dfu = DateFormatterUtility.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                     FeedbackRow(item: i,answers: $answers)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Submit Feedback"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    showFeedback.toggle()
                })
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
                    /* Format for Upload:
                    */
                    // NSLog("Full value of answers for Content \(item.title): \(answers)")
                    uploadFeedback(item: item, form: form, answers: answers, viewModel: viewModel, dfu: dfu)
                    // showFeedback.toggle()
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
    @State var answer: String = ""
    
    var body: some View {
        if item.type == "select_one" {
            Picker(selection: $answer, label: Text(item.captionText).font(.headline), content: {
                ForEach(item.options) {
                    Text($0.captionText).tag($0.captionText)
                }
            })
            .pickerStyle(.inline)
            .onChange(of: answer, perform: {val in
                if let option = item.options.first(where: {$0.captionText == val}) {
                    answers[item.id] = option.id as AnyObject
                }
            })
        } else if item.type == "text" {
            Text(item.captionText).textCase(.uppercase).font(.subheadline).bold()
            TextField("Optional", text: $answer)
                .onChange(of: answer, perform: {val in
                    answers[item.id] = val as AnyObject
                })
        } else {
            Text("Currently Unavailable")
        }

    }
}
