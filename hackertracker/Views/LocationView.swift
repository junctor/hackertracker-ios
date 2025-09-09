//
//  LocationView.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import SwiftUI

struct LocationView: View {
    var locations: [Location]
    var childLocations: [Int: [Location]]
    
    @State private var searchText = ""

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { _ in
                    ForEach(locations.filter { $0.hierDepth == 1 }.sorted { $0.hierExtentLeft < $1.hierExtentLeft }) { loc in
                        // Text(loc.name)
                        LocationCell(location: loc, childLocations: childLocations)
                    }.listRowBackground(Color.clear)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accentColor(.primary)
            .navigationTitle("Locations")
            .searchable(text: $searchText)
            .analyticsScreen(name: "LocationView")
        }
        .padding(5)
    }

    init(locations: [Location]) {
        self.locations = locations
        childLocations = childrenLocations(locations: locations)
    }
}

struct LocationCell: View {
    var location: Location
    var childLocations: [Int: [Location]]
    var dfu = DateFormatterUtility.shared
    @State private var showChildren = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showChildren.toggle()
            }, label: {
                HStack(alignment: .center) {
                    if location.hierDepth != 1 {
                        Circle().foregroundColor(circleStatus(location: location))
                            .frame(width: heirCircle(heirDepth: location.hierDepth), height: heirCircle(heirDepth: location.hierDepth), alignment: .leading)
                    }
                    Text(location.shortName).font(heirFont(heirDepth: location.hierDepth)).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.leading)
                    Spacer()
                    if !(childLocations[location.id]?.isEmpty ?? false) {
                        showChildren ? Image(systemName: "chevron.down") : Image(systemName: "chevron.right")
                    }
                    if location.hierDepth != 1 {
                        Spacer().frame(width: 10)
                    }
                }.padding(.leading, CGFloat(location.hierDepth - 1) * 20.0)
            }).disabled(childLocations[location.id]?.isEmpty ?? true).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if showChildren {
                ForEach(childLocations[location.id] ?? []) { loc in
                    LocationCell(location: loc, childLocations: childLocations)
                }
            }
        }
    }
}

func childrenLocations(locations: [Location]) -> [Int: [Location]] {
    return locations.sorted { $0.hierExtentLeft < $1.hierExtentLeft }.reduce(into: [Int: [Location]]()) { dict, loc in
        dict[loc.id] = locations.filter { $0.parentId == loc.id }
    }
}

func circleStatus(location: Location) -> Color {
    let curDate = Date()
    let dfu = DateFormatterUtility.shared

    if !location.schedule.isEmpty {
        if location.schedule.contains(where: { $0.status == "open" && curDate >= dfu.iso8601Formatter.date(from: $0.begin) ?? Date() && curDate <= dfu.iso8601Formatter.date(from: $0.end) ?? Date() }) {
            return .green
        } else if location.schedule.contains(where: { $0.status == "closed" && curDate >= dfu.iso8601Formatter.date(from: $0.begin) ?? Date() && curDate <= dfu.iso8601Formatter.date(from: $0.end) ?? Date() }) {
            return .red
        } else if location.schedule.allSatisfy({ $0.status == "closed" }) {
            return .red
        }
    }

    switch location.defaultStatus {
    case "open":
        return .green
    case "closed":
        return .red
    default:
        return .gray
    }
}

func heirCircle(heirDepth: Int) -> CGFloat {
    switch heirDepth {
    case 1:
        return 18
    case 2:
        return 15
    case 3:
        return 12
    case 4:
        return 10
    case 5:
        return 8
    default:
        return 5
    }
}

func heirFont(heirDepth: Int) -> Font {
    switch heirDepth {
    case 1:
        return Font.title.bold()
    case 2:
        return Font.headline
    case 3:
        return Font.callout
    case 4:
        return Font.subheadline
    case 5:
        return Font.body
    case 6:
        return Font.footnote
    default:
        return Font.caption
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView(locations: [])
    }
}
