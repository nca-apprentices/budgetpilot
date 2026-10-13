import Foundation
import SwiftData

@Model
final class Expense {
    var title: String
    var amount: Decimal
    var category: ExpenseCategory
    var date: Date
    var paymentMethod: PaymentMethod?
    var note: String?
    var isCorrected: Bool

    init(
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        date: Date,
        paymentMethod: PaymentMethod? = nil,
        note: String? = nil,
        isCorrected: Bool = false
    ) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.paymentMethod = paymentMethod
        self.note = note
        self.isCorrected = isCorrected
    }
}
