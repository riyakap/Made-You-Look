import Foundation

/// One purchased line, copied from the bag at checkout so old orders never change
/// if the catalog changes later.
struct OrderLine: Codable, Identifiable, Hashable {
    var id = UUID()
    let productID: String
    let brand: String
    let name: String
    let shadeName: String
    let unitPrice: Double
    let quantity: Int

    var total: Double { unitPrice * Double(quantity) }
}

struct Order: Codable, Identifiable, Hashable {
    var id = UUID()
    let number: String
    let date: Date
    let lines: [OrderLine]
    let subtotal: Double
    let discount: Double
    let shipping: Double
    let total: Double
    let shipToName: String
    let shipToAddress: String
    /// For example "Visa •••• 4242". The full card number is never stored.
    let paymentSummary: String
}
