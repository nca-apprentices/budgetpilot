@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

struct WishlistTests {
    @Test
    func copiesTheOffer() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        let wish = Wish(offer: Self.playstation, addedAt: date)

        #expect(wish.title == "SONY Playstation 5 Slim Digital Edition")
        #expect(wish.price == 549)
        #expect(wish.url == Self.playstation.url)
        #expect(wish.addedAt == date)
    }

    @Test
    func addsAProductOnlyOnce() throws {
        let context = try Self.makeContext()
        let cheaperLater = PriceOffer(
            title: Self.playstation.title,
            price: 499,
            offerCount: 20,
            url: Self.playstation.url
        )

        try Wishlist.add(Self.playstation, in: context)
        try Wishlist.add(cheaperLater, in: context)

        let wishes = try context.fetch(FetchDescriptor<Wish>())
        #expect(wishes.count == 1)
        #expect(wishes.first?.price == 549)
    }

    @Test
    func addsDifferentProducts() throws {
        let context = try Self.makeContext()

        try Wishlist.add(Self.playstation, in: context)
        try Wishlist.add(Self.charger, in: context)

        #expect(try context.fetchCount(FetchDescriptor<Wish>()) == 2)
    }

    @Test
    func removesOnlyThatProduct() throws {
        let context = try Self.makeContext()
        try Wishlist.add(Self.playstation, in: context)
        try Wishlist.add(Self.charger, in: context)

        try Wishlist.remove(Self.playstation.url, in: context)

        let wishes = try context.fetch(FetchDescriptor<Wish>())
        #expect(wishes.map(\.url) == [Self.charger.url])
    }

    @Test
    func togglesAProductOnAndOff() throws {
        let context = try Self.makeContext()

        try Wishlist.toggle(Self.playstation, in: context)
        #expect(try context.fetchCount(FetchDescriptor<Wish>()) == 1)

        try Wishlist.toggle(Self.playstation, in: context)
        #expect(try context.fetchCount(FetchDescriptor<Wish>()) == 0)
    }

    @Test
    func totalsAllWishes() {
        let wishes = [Wish(offer: Self.playstation), Wish(offer: Self.charger)]

        #expect(Wishlist.total(of: wishes) == Decimal(string: "593.40"))
    }

    @Test(arguments: [
        (Decimal(1000), Decimal(0)),
        (Decimal(string: "593.40")!, Decimal(0)),
        (Decimal(500), Decimal(string: "93.40")!),
        (Decimal(-100), Decimal(string: "693.40")!),
    ])
    func comparesWithTheAvailableBudget(available: Decimal, shortfall: Decimal) {
        let wishes = [Wish(offer: Self.playstation), Wish(offer: Self.charger)]

        #expect(Wishlist.shortfall(of: wishes, available: available) == shortfall)
    }

    private static let playstation = PriceOffer(
        title: "SONY Playstation 5 Slim Digital Edition",
        price: 549,
        offerCount: 14,
        url: URL(string: "https://www.toppreise.ch/preisvergleich/PS5-p867338")!
    )

    private static let charger = PriceOffer(
        title: "HP USB-C-Ladegerät 65 W",
        price: Decimal(string: "44.40")!,
        offerCount: 2,
        url: URL(string: "https://www.toppreise.ch/preisvergleich/HP-p1153325")!
    )

    private static func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContext(ModelContainer(for: Wish.self, configurations: config))
    }
}
