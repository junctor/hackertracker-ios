//
    //  EventDetailView.swift
    //  hackertracker
    //
    //  Created by Seth W Law on 6/14/22.
    //

import SwiftUI

struct EventDetailView: View {
    var event: Event
    @State var bookmarks: [Int]
    
    var body: some View {
        ScrollView {
            VStack {
                Text(event.title).font(.largeTitle)
                HStack {
                    Circle().fill(Color(UIColor(hex: event.type.color) ?? UIColor.blue)).frame(width: 10, height: 10)
                    Text(event.type.name)
                }
                .rectangleBackground()

                HStack {
                    Image(systemName: "clock")
                    Text(dateSection(date: event.beginTimestamp))
                }
                .rectangleBackground()

                HStack {
                    Image(systemName: "map")
                    Text(event.location.name)
                }
                .rectangleBackground()

                Text(event.description).padding(.top).padding()

                Text("Speakers").font(.headline).padding(.top)

                VStack(alignment: .leading) {
                    ForEach(event.speakers) { speaker in
                        HStack {
                            Rectangle().fill(Color.yellow).frame(width: 10, height: .infinity)
                            VStack(alignment: .leading) {
                                Text(speaker.name).fontWeight(.bold)
                                Text(speaker.title ?? "Hacker")
                            }
                        }
                    }
                }
                .rectangleBackground()

                Spacer()
            }
            .navigationTitle(event.title)
        }
    }
}

struct RectangleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(10).multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Rectangle().fill(Color(UIColor(hex: "#2d2d2D") ?? UIColor.gray))).cornerRadius(5)
    }
}

extension View {
    func rectangleBackground() -> some View {
        modifier(RectangleBackground())
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView().preferredColorScheme(.dark)
        }
    }
}
