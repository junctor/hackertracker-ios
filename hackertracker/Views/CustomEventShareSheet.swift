//
//  CustomEventShareSheet.swift
//  hackertracker
//
//  Modal that presents a QR-code-encoded deep link for a CustomEvent.
//  Anyone scanning the QR with the iOS camera lands in HackerTracker
//  with the form pre-filled, ready to save the same event on their
//  own device.
//

import SwiftUI

struct CustomEventShareSheet: View {
    let event: CustomEvent

    @Environment(\.dismiss) private var dismiss

    private var shareURL: URL? { CustomEventShare.url(for: event) }

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                if let url = shareURL {
                    content(for: url)
                } else {
                    ContentUnavailableView(
                        "Cannot Share",
                        systemImage: "qrcode.viewfinder",
                        description: Text("This event is missing a title or time, so it can\u{2019}t be encoded into a QR code yet. Edit the event and try again.")
                    )
                    .padding(.top, 60)
                }
            }
            .navigationTitle("Share Event")
            .themedNavTitle("Share Event", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder private func content(for url: URL) -> some View {
        VStack(spacing: 20) {
            Text(event.title ?? "")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // White-on-white card so the QR has a known background — some
            // dark-mode themes invert the SwiftUI Image's transparency and
            // make the code unscannable. The fixed white block prevents
            // that.
            QRCodeView(qrString: url.absoluteString)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            Text("Open the iPhone camera, point it at this code, and tap the link that appears. The other device will open HackerTracker with this event pre-filled.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Always offer a system Share — lets the user AirDrop or
            // copy the link as text when scanning isn’t practical.
            ShareLink(item: url) {
                Label("Share Link\u{2026}", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            urlPreview(url: url)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func urlPreview(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Link")
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
            Text(url.absoluteString)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(themeManager.cardSurface)
                .cornerRadius(8)
                .textSelection(.enabled)
        }
        .padding(.horizontal)
    }
}
