import Foundation

enum CardKind: String, Codable, CaseIterable, Identifiable {
    case loyalty
    case ticket
    case membership
    case gift
    case library
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loyalty:    "Loyalty"
        case .ticket:     "Ticket"
        case .membership: "Membership"
        case .gift:       "Gift card"
        case .library:    "Library"
        case .other:      "Other"
        }
    }

    // Maps a user-facing card kind to the Apple Wallet pass type the backend
    // expects. Loyalty/gift map to storeCard, ticket maps to eventTicket; the
    // remaining kinds use the generic pass type because Wallet doesn't model
    // them distinctly.
    var passType: PassType {
        switch self {
        case .loyalty, .gift:        .storeCard
        case .ticket:                .eventTicket
        case .membership, .library,
             .other:                 .generic
        }
    }
}
