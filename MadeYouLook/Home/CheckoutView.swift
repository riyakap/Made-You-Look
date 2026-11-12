import SwiftUI

/// Checkout, presented as a sheet from the bag.
///
/// This is a SIMULATED checkout: there is no payment processor behind it, so nothing is charged
/// and card details are never stored (only the card brand and last four digits go on the order).
/// To take real payments, replace `placeOrder()` with a Stripe / Apple Pay call to your own server.
struct CheckoutView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvc = ""
    @State private var placed: Order?
    @State private var triedToSubmit = false

    private var digits: String { cardNumber.filter(\.isNumber) }

    /// Plain-language list of what still needs fixing, shown after a failed attempt.
    private var problems: [String] {
        var list: [String] = []
        if name.trimmingCharacters(in: .whitespaces).isEmpty { list.append("Enter the name for the delivery.") }
        if street.trimmingCharacters(in: .whitespaces).isEmpty { list.append("Enter a street address.") }
        if city.trimmingCharacters(in: .whitespaces).isEmpty { list.append("Enter a city.") }
        if state.trimmingCharacters(in: .whitespaces).count != 2 { list.append("Enter a two-letter state, like CA.") }
        if zip.filter(\.isNumber).count != 5 { list.append("Enter a five-digit ZIP code.") }
        if !(13...19).contains(digits.count) { list.append("Enter a valid card number.") }
        if !Self.isValidExpiry(expiry) { list.append("Enter the expiry as MM/YY.") }
        if !(3...4).contains(cvc.filter(\.isNumber).count) { list.append("Enter the 3 or 4 digit security code.") }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if let placed {
                    OrderConfirmationView(order: placed) { dismiss() }
                } else {
                    form
                }
            }
            .appBackground()
            .navigationTitle(placed == nil ? "Checkout" : "Order placed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if placed == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
            }
        }
        .onAppear { if name.isEmpty { name = store.profile.name } }
        .interactiveDismissDisabled(placed != nil)
    }

    // MARK: Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Demo checkout. No payment is processed and your card details are not saved.",
                      systemImage: "info.circle")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.primaryDark)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                section("Ship to") {
                    LabeledField(title: "Full name", text: $name, contentType: .name)
                    LabeledField(title: "Street address", text: $street, contentType: .streetAddressLine1)
                    LabeledField(title: "City", text: $city, contentType: .addressCity)
                    HStack(spacing: 12) {
                        LabeledField(title: "State", text: $state, contentType: .addressState)
                        LabeledField(title: "ZIP", text: $zip, contentType: .postalCode, keyboard: .numberPad)
                    }
                }

                section("Delivery") {
                    HStack {
                        Text("Standard (3–5 business days)")
                        Spacer()
                        Text(store.bagShipping == 0 ? "Free" : Product.formatPrice(store.bagShipping))
                            .fontWeight(.semibold)
                    }
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                    if store.bagShipping > 0 {
                        Text("Free shipping on bags of \(Product.formatPrice(AppStore.freeShippingThreshold)) or more.")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }

                section("Payment") {
                    LabeledField(title: "Card number", text: $cardNumber, contentType: .creditCardNumber, keyboard: .numberPad)
                    HStack(spacing: 12) {
                        LabeledField(title: "Expiry (MM/YY)", text: $expiry, keyboard: .numbersAndPunctuation)
                        LabeledField(title: "CVC", text: $cvc, keyboard: .numberPad)
                    }
                }

                section("Order summary") {
                    ForEach(store.bag) { item in
                        if let product = Catalog.product(item.productID) {
                            HStack {
                                Text("\(item.quantity) × \(product.brand) \(product.cardName)")
                                    .lineLimit(2)
                                Spacer()
                                Text(Product.formatPrice(product.price * Double(item.quantity)))
                            }
                            .font(Theme.body(13))
                            .foregroundStyle(Theme.ink)
                        }
                    }
                    Divider()
                    totalRow("Subtotal", Product.formatPrice(store.bagSubtotal))
                    if store.bagDiscount > 0 {
                        totalRow("First order (10% off)", "−" + Product.formatPrice(store.bagDiscount))
                    }
                    totalRow("Shipping", store.bagShipping == 0 ? "Free" : Product.formatPrice(store.bagShipping))
                    totalRow("Total", Product.formatPrice(store.bagTotal), bold: true)
                    Text("Sales tax is not included in this demo.")
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.inkSecondary)
                }

                if triedToSubmit && !problems.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(problems, id: \.self) { Text("• \($0)") }
                    }
                    .font(Theme.body(13))
                    .foregroundStyle(.red)
                }

                Button("Place order · \(Product.formatPrice(store.bagTotal))") { placeOrder() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(Theme.display(20)).foregroundStyle(Theme.ink)
            content()
        }
    }

    private func totalRow(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .font(Theme.body(14, bold ? .semibold : .regular))
        .foregroundStyle(Theme.ink)
    }

    // MARK: Actions

    private func placeOrder() {
        triedToSubmit = true
        guard problems.isEmpty else { return }
        let address = "\(street.trimmingCharacters(in: .whitespaces)), \(city.trimmingCharacters(in: .whitespaces)), "
            + "\(state.trimmingCharacters(in: .whitespaces).uppercased()) \(zip.filter(\.isNumber))"
        let payment = "\(Self.cardBrand(digits)) •••• \(digits.suffix(4))"
        placed = store.placeOrder(
            shipToName: name.trimmingCharacters(in: .whitespaces),
            shipToAddress: address,
            paymentSummary: payment
        )
    }

    private static func cardBrand(_ digits: String) -> String {
        switch digits.first {
        case "4": "Visa"
        case "5", "2": "Mastercard"
        case "3": "Amex"
        case "6": "Discover"
        default: "Card"
        }
    }

    /// Accepts "MM/YY" for a month 01–12 that is not in the past.
    private static func isValidExpiry(_ text: String) -> Bool {
        let parts = text.split(separator: "/")
        guard parts.count == 2, let month = Int(parts[0]), let year = Int(parts[1]),
              (1...12).contains(month), parts[1].count == 2 else { return false }
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        let fullYear = 2000 + year
        return fullYear > (now.year ?? 0) || (fullYear == now.year && month >= (now.month ?? 0))
    }
}

// MARK: - Confirmation

struct OrderConfirmationView: View {
    let order: Order
    let onDone: () -> Void

    private var firstName: String {
        order.shipToName.split(separator: " ").first.map { String($0) } ?? "friend"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 24)
                Text("Thank you, \(firstName)!")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("Order \(order.number) is confirmed. This was a demo order, so nothing was charged.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                OrderCard(order: order)

                Button("Done", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(20)
        }
    }
}

// MARK: - Order history

struct OrdersView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if store.orders.isEmpty {
                    EmptyStateView(symbol: "shippingbox", title: "No orders yet",
                                   message: "Orders you place from your bag will show up here.")
                }
                ForEach(store.orders) { OrderCard(order: $0) }
            }
            .padding(20)
        }
        .appBackground()
        .navigationTitle("My Orders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(order.number).font(Theme.body(15, .semibold))
                Spacer()
                Text(order.date, style: .date).font(Theme.body(12)).foregroundStyle(Theme.inkSecondary)
            }
            ForEach(order.lines) { line in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(line.quantity) × \(line.brand) \(line.name)").font(Theme.body(13))
                        Text(line.shadeName).font(Theme.body(11)).foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Text(Product.formatPrice(line.total)).font(Theme.body(13))
                }
            }
            Divider()
            HStack {
                Text("Total").font(Theme.body(14, .semibold))
                Spacer()
                Text(Product.formatPrice(order.total)).font(Theme.body(14, .semibold))
            }
            Text("Ship to \(order.shipToName), \(order.shipToAddress)")
                .font(Theme.body(11)).foregroundStyle(Theme.inkSecondary)
            Text("Paid with \(order.paymentSummary)")
                .font(Theme.body(11)).foregroundStyle(Theme.inkSecondary)
        }
        .foregroundStyle(Theme.ink)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 12)
    }
}
