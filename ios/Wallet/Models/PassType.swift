import Foundation

enum PassType: String, Codable, CaseIterable, Identifiable {
    case storeCard
    case generic
    case coupon
    case eventTicket
    case boardingPass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .storeCard: "Store Card"
        case .generic: "Generic"
        case .coupon: "Coupon"
        case .eventTicket: "Event Ticket"
        case .boardingPass: "Boarding Pass"
        }
    }
}
