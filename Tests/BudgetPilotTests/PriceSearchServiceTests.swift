@testable import BudgetPilot
import Foundation
import Testing

struct PriceSearchServiceTests {
    @Test(arguments: [
        ("39.50", Decimal(string: "39.50")),
        ("4'529.00", Decimal(string: "4529.00")),
        ("CHF 1’890.–", Decimal(1890)),
        ("12.-", Decimal(12)),
        ("n/a", nil),
    ])
    func parsesSwissPrices(text: String, expected: Decimal?) {
        #expect(PriceSearchService.parsePrice(text) == expected)
    }

    @Test
    func buildsSearchURL() {
        let url = PriceSearchService.searchURL(for: "usb-c ladegerät 65w")

        #expect(url.absoluteString == "https://www.toppreise.ch/produktsuche?q=usb-c%20ladeger%C3%A4t%2065w")
    }

    @Test
    func readsProductsInPageOrder() throws {
        let offers = try PriceSearchService.parse(Self.resultsPage)

        #expect(offers.map(\.title) == [
            "HP USB-C-Ladegerät 65 W, USB-C, EU-Stecker",
            "SONY Playstation 5 Slim Digital Edition, 2x DualSense",
            "Apple MacBook Pro 14",
        ])
        #expect(offers.map(\.offerCount) == [2, 8, 1])
        #expect(offers.first?.url.absoluteString == "https://www.toppreise.ch/preisvergleich/HP-p1153325")
    }

    @Test
    func prefersPriceIncludingShipping() throws {
        let offers = try PriceSearchService.parse(Self.resultsPage)

        #expect(offers.map(\.price) == [
            Decimal(string: "44.40"),
            Decimal(string: "549.00"),
            Decimal(string: "4529.00"),
        ])
    }

    @Test
    func returnsNothingForUnknownMarkup() throws {
        #expect(try PriceSearchService.parse("<html><body><p>Error 403</p></body></html>").isEmpty)
    }

    /// Same structure as a toppreise.ch results page: a product with two
    /// offers; a series of two variants, whose products have no .product-name,
    /// listed most expensive first; a product with a thousands separator and
    /// only a product price; a series repeating the first product; and a
    /// product without a price.
    private static let resultsPage = """
    <div class="Plugin_Product f_clickable" data-link="/preisvergleich/HP-p1153325">
      <div class="product-name">
        <a class="bold" href="/preisvergleich/HP-p1153325">
          HP <em>USB-C</em>-Ladegerät 65 W, <em>USB-C</em>, EU-Stecker</a>
      </div>
      <div class="offersLabel"> 2 Angebote ab </div>
      <div class="priceContainer shippingPrice"><div class="Plugin_Price "> 44.40 </div></div>
      <div class="priceContainer productPrice "><div class="Plugin_Price "> 39.50 </div></div>
    </div>
    <div class="Plugin_ProductCollItem">
      <div class="product-name"><div class="bold col">SONY Playstation 5 Slim Digital Edition</div></div>
      <div class="Plugin_Product f_clickable f_collection" data-link="/preisvergleich/PS5-Slim-p820250">
        <a href="/preisvergleich/PS5-Slim-p820250" class="bold">SONY Playstation 5 Slim Digital Edition, 825 GB</a>
        <div class="offersLabel"> 12 Angebote ab </div>
        <div class="priceContainer shippingPrice"><div class="Plugin_Price "> 712.75 </div></div>
      </div>
      <div class="Plugin_Product f_clickable f_collection" data-link="/preisvergleich/PS5-p867338">
        <a href="/preisvergleich/PS5-p867338" class="bold">SONY Playstation 5 Slim Digital Edition, 2x DualSense</a>
        <div class="offersLabel"> 8 Angebote ab </div>
        <div class="priceContainer shippingPrice"><div class="Plugin_Price "> 549.00 </div></div>
      </div>
    </div>
    <div class="Plugin_Product f_clickable" data-link="/preisvergleich/MacBook-p42">
      <div class="product-name"><a href="/preisvergleich/MacBook-p42" class="bold">Apple MacBook Pro 14</a></div>
      <div class="offersLabel"> 1 Angebot ab </div>
      <div class="priceContainer productPrice "><div class="Plugin_Price "> 4&#39;529.00 </div></div>
    </div>
    <div class="Plugin_ProductCollItem">
      <div class="Plugin_Product f_clickable f_collection" data-link="/preisvergleich/HP-p1153325">
        <a href="/preisvergleich/HP-p1153325" class="bold">HP USB-C-Ladegerät 65 W</a>
        <div class="priceContainer shippingPrice"><div class="Plugin_Price "> 44.40 </div></div>
      </div>
    </div>
    <div class="Plugin_Product f_clickable" data-link="/preisvergleich/Old-p7">
      <div class="product-name"><a href="/preisvergleich/Old-p7" class="bold">Discontinued charger</a></div>
    </div>
    """
}
