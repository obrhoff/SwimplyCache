import Foundation
@testable import SwimplyCache
import XCTest

final class SwimplyCacheTests: XCTestCase {
    struct TestValue {
        let key: String
        let value: String
    }

    var cache: SwimplyCache<String, String>!

    var testValues: [TestValue] {
        return (0 ..< 10000).map { TestValue(key: "Key-\($0)", value: "Value-\($0)") }
    }

    override func tearDown() {
        super.tearDown()
        cache = nil
    }
}

extension SwimplyCacheTests {
    func testInsert() {
        cache = SwimplyCache<String, String>()
        let testValue = "Insert String"

        cache.setValue(testValue, forKey: "TestKey")

        let storedValue = cache.value(forKey: "TestKey")
        XCTAssertEqual(testValue, storedValue)
        XCTAssertEqual(cache.itemsCount, 1)
    }

    func testRemoveValue() {
        cache = SwimplyCache<String, String>()
        let testValue = "Insert String"
        cache.setValue(testValue, forKey: "TestKey")
        let storedValue = cache.value(forKey: "TestKey")

        XCTAssertNotNil(storedValue)
        cache.remove(.key(key: "TestKey"))

        let deleted = cache.value(forKey: "TestKey")
        XCTAssertNil(deleted)
        XCTAssertEqual(cache.itemsCount, 0)
    }

    func testRemoveAll() {
        cache = SwimplyCache<String, String>()
        testValues.forEach { cache.setValue($0.value, forKey: $0.key) }

        XCTAssertEqual(cache.itemsCount, 10000)
        cache.remove(.all)
        XCTAssertEqual(cache.itemsCount, 0)

        let deletedValue = cache.value(forKey: testValues.first!.key)
        XCTAssertNil(deletedValue)
    }

    func testRemoveRandomized() {
        cache = SwimplyCache<String, String>()
        let testValues = self.testValues
        let randomizedValues = testValues.shuffled()

        testValues.forEach { cache.setValue($0.value, forKey: $0.key) }
        XCTAssertEqual(cache.itemsCount, 10000)

        randomizedValues.forEach { cache.remove(.key(key: $0.key)) }

        XCTAssertEqual(cache.itemsCount, 0)
        XCTAssertEqual(cache.totalCosts, 0)
    }

    func testRemoveCount() {
        cache = SwimplyCache<String, String>()
        testValues.forEach { cache.setValue($0.value, forKey: $0.key) }

        cache.remove(.byLimit(countLimit: 20))
        XCTAssertEqual(cache.itemsCount, 20)
    }

    func testRemoveCosts() {
        cache = SwimplyCache<String, String>()
        testValues.forEach { cache.setValue($0.value, forKey: $0.key, cost: 10) }

        XCTAssertEqual(cache.totalCosts, 10000 * 10)
        cache.remove(.byCost(costLimit: 50))
        XCTAssertEqual(cache.totalCosts, 50)
    }

    func testLruCache() {
        cache = SwimplyCache<String, String>()
        testValues.forEach { cache.setValue($0.value, forKey: $0.key, cost: 10) }

        let lruValue = testValues.first!
        cache.setValue(lruValue.value, forKey: lruValue.key)
        cache.remove(.byLimit(countLimit: 1))

        let stored = cache.value(forKey: lruValue.key)

        XCTAssertEqual(cache.itemsCount, 1)
        XCTAssertEqual(stored, lruValue.value)
    }

    func testKeepCount() {
        cache = SwimplyCache<String, String>(countLimit: 50)
        testValues.forEach { cache.setValue($0.value, forKey: $0.key) }
        XCTAssertEqual(cache.itemsCount, 50)
    }

    func testKeepCosts() {
        cache = SwimplyCache<String, String>(costLimit: 50)
        testValues.forEach { cache.setValue($0.value, forKey: $0.key, cost: 10) }
        XCTAssertEqual(cache.totalCosts, 50)
    }
}
