import Foundation
@testable import SwimplyCache
import XCTest

final class SwimplyCacheMeasureTests: XCTestCase {
    var testValues: [String] {
        return (0 ..< 35000).map { "Test\($0)" }
    }
}

extension SwimplyCacheMeasureTests {
    func testMeasureInsertsRemovalSwimply() {
        let values = testValues.map { $0 as NSString }
        let insertsValues = values.shuffled()
        let removeValues = values.shuffled()
        let swimplyCache = SwimplyCache<NSString, NSString>()

        measure {
            insertsValues.forEach { swimplyCache.setValue($0, forKey: $0, cost: 10) }
            removeValues.forEach { swimplyCache.remove(.key(key: $0)) }
        }
    }

    func testMeasureInsertsRemovalNSCache() {
        let values = testValues.map { $0 as NSString }
        let insertsValues = values.shuffled()
        let removeValues = values.shuffled()
        let nsCache = NSCache<NSString, NSString>()

        measure {
            insertsValues.forEach { nsCache.setObject($0, forKey: $0, cost: 10) }
            removeValues.forEach { nsCache.removeObject(forKey: $0) }
        }
    }

    func testMeasureLimitCostsSwimply() {
        let values = testValues.map { $0 as NSString }
        let swimplyCache = SwimplyCache<NSString, NSString>(costLimit: 5000 * 10)

        measure {
            values.forEach { swimplyCache.setValue($0, forKey: $0, cost: 10) }
        }
    }

    func testMeasureLimitCostsNSCache() {
        let values = testValues.map { $0 as NSString }
        let nsCache = NSCache<NSString, NSString>()
        nsCache.totalCostLimit = 5000 * 10

        measure {
            values.forEach { nsCache.setObject($0, forKey: $0, cost: 10) }
        }
    }
}
