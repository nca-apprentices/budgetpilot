import Foundation

/// The expenses of one period, with their total and count.
struct ExpenseHistory {
    let expenses: [Expense]
    let period: ExpensePeriod
    let now: Date

    var expensesInPeriod: [Expense] {
        expenses.filter {
            Calendar.current.isDate($0.date, equalTo: now, toGranularity: period.granularity)
        }
    }

    var total: Decimal {
        expensesInPeriod.reduce(0) { $0 + $1.amount }
    }

    var count: Int {
        expensesInPeriod.count
    }

    var groups: [ExpenseGroup] {
        let byStart = Dictionary(grouping: expensesInPeriod) { expense in
            Calendar.current.dateInterval(of: groupingUnit, for: expense.date)?.start ?? expense.date
        }
        return byStart.keys.sorted(by: >).map { start in
            ExpenseGroup(
                title: title(forGroupStartingAt: start),
                expenses: byStart[start, default: []].sorted { $0.date > $1.date }
            )
        }
    }

    private var groupingUnit: Calendar.Component {
        period == .year ? .month : .weekOfYear
    }

    private func title(forGroupStartingAt start: Date) -> String {
        if period == .year {
            return start.formatted(.dateTime.month(.wide))
        }

        let thisWeek = Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start
        if start == thisWeek {
            return "This week"
        }

        let lastWeek = thisWeek.flatMap { Calendar.current.date(byAdding: .weekOfYear, value: -1, to: $0) }
        if start == lastWeek {
            return "Last week"
        }

        return "Week of \(start.formatted(.dateTime.day().month()))"
    }
}
