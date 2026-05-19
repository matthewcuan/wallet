import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    @Environment(\.modelContext) private var modelContext
    @State private var query: String = ""
    @State private var isShowingScanner = false
    @State private var openCard: Card?

    private var filteredCards: [Card] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return cards }
        let needle = trimmed.lowercased()
        return cards.filter {
            $0.name.lowercased().contains(needle)
                || $0.subtitle.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.stashBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    searchBar
                        .padding(.horizontal, 22)
                        .padding(.top, 12)

                    ScrollView {
                        contentBody
                            .padding(.horizontal, 22)
                            .padding(.top, 16)
                            .padding(.bottom, 140)
                    }
                }

                ScanButton(action: { isShowingScanner = true })
                    .padding(.bottom, 34)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openCard) { card in
                CardDetailView(card: card)
            }
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            ScanFlow()
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WALLET")
                    .font(.stash(12, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.stashInk.opacity(0.4))
                Text(headlineText)
                    .font(.stash(34, weight: .bold))
                    .tracking(-1.2)
                    .foregroundStyle(Color.stashInk)
            }
            Spacer()
            Text(dateString)
                .font(.stashMono(12))
                .tracking(0.5)
                .foregroundStyle(Color.stashInk.opacity(0.45))
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var headlineText: String {
        switch cards.count {
        case 0: "Empty wallet"
        case 1: "1 card"
        default: "\(cards.count) cards"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: .now)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.stashInk.opacity(0.5))
            TextField("Search cards", text: $query)
                .font(.stash(15))
                .foregroundStyle(Color.stashInk)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button("Clear") { query = "" }
                    .font(.stash(11))
                    .foregroundStyle(Color.stashInk.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.stashInkTint)
        )
    }

    @ViewBuilder
    private var contentBody: some View {
        if filteredCards.isEmpty {
            EmptyWalletState(hasQuery: !query.isEmpty, onScan: { isShowingScanner = true })
                .padding(.top, 40)
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(filteredCards) { card in
                    CardTile(
                        card: card,
                        onTap: { openCard = card },
                        onDelete: { modelContext.delete(card) }
                    )
                }
            }
        }
    }
}

private struct EmptyWalletState: View {
    let hasQuery: Bool
    let onScan: () -> Void

    var body: some View {
        if hasQuery {
            Text("No cards match.")
                .font(.stash(15))
                .foregroundStyle(Color.stashInk.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
        } else {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.stashInk.opacity(0.06))
                    Image(systemName: "viewfinder")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.stashInk.opacity(0.45))
                }
                .frame(width: 64, height: 64)

                VStack(spacing: 4) {
                    Text("Your wallet is empty")
                        .font(.stash(17, weight: .semibold))
                        .foregroundStyle(Color.stashInk)
                    Text("Scan any barcode or QR code to save it.")
                        .font(.stash(14))
                        .foregroundStyle(Color.stashInk.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .accessibilityElement(children: .combine)
            .onTapGesture { onScan() }
        }
    }
}

private struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                Text("Scan a code")
                    .font(.stash(16, weight: .semibold))
                    .tracking(-0.2)
            }
            .foregroundStyle(Color.stashCream)
            .padding(.horizontal, 26)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.stashInk)
                    .shadow(color: Color.stashInk.opacity(0.32), radius: 24, x: 0, y: 8)
                    .shadow(color: Color.stashInk.opacity(0.16), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a code")
    }
}
