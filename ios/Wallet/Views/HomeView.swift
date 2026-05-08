import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No cards yet",
                        systemImage: "wallet.pass",
                        description: Text("Tap the scanner to add your first card.")
                    )
                } else {
                    List {
                        ForEach(cards) { card in
                            NavigationLink(value: card) {
                                CardRow(card: card)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wallet")
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan barcode")
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                ScanFlow()
            }
        }
    }
}

private struct CardRow: View {
    let card: Card

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: card.backgroundColor) ?? .gray)
                .frame(width: 28, height: 40)
            VStack(alignment: .leading) {
                Text(card.label).font(.headline)
                Text(card.passType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(card.barcodeFormat.displayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
