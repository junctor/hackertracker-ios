//
//  AddEventView.swift
//  hackertracker
//
//  Created by Seth Law on 7/11/23.
//

import UIKit
import EventKit
import EventKitUI

class AddEventController: UIViewController, EKEventEditViewDelegate {
    let eventStore = EKEventStore()
    var event: Event?
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
        parent?.dismiss(animated: true, completion: nil)
    }
    
    func setEvent(newEvent: Event) {
        self.event = newEvent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let e = self.event {
            eventStore.requestAccess( to: EKEntityType.event, completion: { (granted, error) in
                DispatchQueue.main.async {
                    if (granted) && (error == nil) {
                        
                         let ek = EKEvent(eventStore: self.eventStore)
                         ek.title = e.title
                         ek.startDate = e.beginTimestamp
                         ek.endDate = e.endTimestamp
                         ek.timeZone = DateFormatterUtility.shared.timeZone
                         ek.location = e.location.name
                         ek.notes = e.description
                        
                        let eventController = EKEventEditViewController()
                        
                        eventController.eventStore = self.eventStore
                        eventController.event = ek
                        eventController.editViewDelegate = self
                        eventController.modalPresentationStyle = .overCurrentContext
                        eventController.modalTransitionStyle = .crossDissolve
                        
                        self.present(eventController, animated: true, completion: nil)
                    }
                }
            }
            )
        } else {
            print("AddEventController: event is nil")
        }
    }
}
