import Foundation
@testable import SwimplyCache
import XCTest

final class SwimplyCacheMeasureTests: XCTestCase {
    var testValues: [String] {
        return (0..<10000).map({ "Test\($0)" })
    }
}

extension SwimplyCacheMeasureTests {
    func testMeasureSwimplyRemoveKey() {
        let values = testValues.map({ $0 as NSString })
        let swimplyCache = SwimplyCache<NSString, NSString>()
        values.forEach({ swimplyCache.setValue($0, forKey: $0, cost: 10) })

        measure {
            swimplyCache.remove(.key(key: "Test5000"))
        }
    }

    func testMeasureNSCacheRemoveKey() {
        let values = testValues.map({ $0 as NSString })
        let nsCache = NSCache<NSString, NSString>()

        values.forEach({ nsCache.setObject($0, forKey: $0, cost: 10) })

        measure {
            nsCache.removeObject(forKey: "Test5000")
        }
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
