//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var settings = Settings()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmarks.id, ascending: true)],
        animation: .default)
    private var bookmarks: FetchedResults<Bookmarks>
    
    var colorScheme: ColorScheme = .dark

    var body: some View {
        NavigationView {
        
            TabView {
                ScheduleView()
                    .padding()
                    .tabItem({
                        Image(systemName: "house")
                        Text("Main")
                    })
                    .tag(1)
                    .preferredColorScheme(colorScheme)
                MapView()
                    .padding()
                    .tabItem({
                        Image(systemName: "map")
                        Text("Maps")
                    })
                    .tag(2)
                    .preferredColorScheme(colorScheme)

                InfoView()
                    .padding()
                    .tabItem({
                        Image(systemName: "info.circle")
                        Text("Info")
                    })
                    .tag(3)
                    .preferredColorScheme(colorScheme)

                SettingsView()
                    .padding()
                    .tabItem({
                        Image(systemName: "gear")
                        Text("Settings")
                    })
                    .tag(4)

            }
            .frame(maxWidth:.infinity)
            .navigationTitle("DEF CON 30")
        }
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.height)
        .navigationViewStyle(.stack)
    }

    private func addBookmark() {
        withAnimation {
            let newItem = Bookmarks(context: viewContext)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteBookmark(offsets: IndexSet) {
        withAnimation {
            offsets.map { bookmarks[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
