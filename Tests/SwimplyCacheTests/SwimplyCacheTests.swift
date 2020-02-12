import Foundation
@testable import SwimplyCache
import XCTest

final class SwimplyCacheTests: XCTestCase {
    var cache: SwimplyCache<String, String>!

    var testValues: [String] {
        return (0..<10000).map({ "Test\($0)" })
    }

    override func tearDown() {
        super.tearDown()
        cache = nil
    }
}

extension SwimplyCacheTests {
    func testInsert() {
        cache = SwimplyCache<String, String>()
        testValues.forEach({ cache.setValue($0, forKey: $0) })
        XCTAssertEqual(cache.count, 10000)
    }

    func testRemove() {
        cache = SwimplyCache<String, String>()
        let removeValues = testValues.suffix(5000)

        testValues.forEach({ cache.setValue($0, forKey: $0) })

        XCTAssertEqual(cache.count, 10000)
        removeValues.forEach({ cache.remove(.key(key: $0)) })
        XCTAssertEqual(cache.count, 5000)
    }

    func testRemoveAll() {
        cache = SwimplyCache<String, String>()
        testValues.forEach({ cache.setValue($0, forKey: $0) })

        XCTAssertEqual(cache.count, 10000)
        cache.remove(.all)
        XCTAssertEqual(cache.count, 0)
    }

    func testRemoveCount() {
        cache = SwimplyCache<String, String>()
        testValues.forEach({ cache.setValue($0, forKey: $0) })

        cache.remove(.byLimit(countLimit: 20))
        XCTAssertEqual(cache.count, 20)
    }

    func testRemoveCosts() {
        cache = SwimplyCache<String, String>()
        testValues.forEach({ cache.setValue($0, forKey: $0, cost: 10) })

        XCTAssertEqual(cache.costs, 10000 * 10)
        cache.remove(.byCost(costLimit: 50))
        XCTAssertEqual(cache.costs, 50)
    }

    func testKeepCount() {
        cache = SwimplyCache<String, String>(countLimit: 50)
        testValues.forEach({ cache.setValue($0, forKey: $0) })
        XCTAssertEqual(cache.count, 50)
    }

    func testKeepCosts() {
        cache = SwimplyCache<String, String>(costLimit: 50)
        testValues.forEach({ cache.setValue($0, forKey: $0, cost: 10) })
        XCTAssertEqual(cache.costs, 50)
    }

    func testMeasureInsertsSwimply() {
        let values = testValues.map({ $0 as NSString })
        let swimplyCache = SwimplyCache<NSString, NSString>()

        measure {
            values.forEach({ swimplyCache.setValue($0, forKey: $0, cost: 10) })
            values.forEach({ swimplyCache.remove(.key(key: $0)) })
        }
    }

    func testMeasureInsertsNSCache() {
        let values = testValues.map({ $0 as NSString })
        let nsCache = NSCache<NSString, NSString>()

        measure {
            values.forEach({ nsCache.setObject($0, forKey: $0, cost: 10) })
            values.forEach({ nsCache.removeObject(forKey: $0) })
        }
    }

    func testMeasureLimitCostsSwimply() {
        let values = testValues.map({ $0 as NSString })
        let swimplyCache = SwimplyCache<NSString, NSString>(costLimit: 5000 * 10)

        measure {
            values.forEach({ swimplyCache.setValue($0, forKey: $0, cost: 10) })
        }
    }

    func testMeasureLimitCostsNSCache() {
        let values = testValues.map({ $0 as NSString })
        let nsCache = NSCache<NSString, NSString>()
        nsCache.totalCostLimit = 5000 * 10

        measure {
            values.forEach({ nsCache.setObject($0, forKey: $0, cost: 10) })
        }
    }
}
