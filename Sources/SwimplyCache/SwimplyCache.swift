import Foundation
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

public final class SwimplyCache<T: Hashable, S: Any> {
    private struct Store<T: Hashable, S: Any> {
        let value: S
        let cost: Int
        var prev: T?
        var next: T?
        
        mutating func setPrev(_ prev: T?) {
            self.prev = prev
        }
        
        mutating func setNext(_ next: T?) {
            self.next = next
        }
    }
    
    public enum RemoveOperation {
        case all
        case key(key: T)
        case byLimit(countLimit: Int)
        case byCost(costLimit: Int)
    }
    
    private let memoryPressure: DispatchSourceMemoryPressure
    private var storage: [T: Store<T, S>]
    private var lock: os_unfair_lock_s
    private var rootKey: T?
    private var endKey: T?
    
    public private(set) var costs: Int
    public private(set) var count: Int
    
    public let countLimit: Int?
    public let costLimit: Int?
    
    public init(countLimit: Int? = nil, costLimit: Int? = nil) {
        self.lock = os_unfair_lock_s()
        self.memoryPressure = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .global(qos: .background))
        self.storage = [:]
        self.countLimit = countLimit
        self.costLimit = costLimit
        self.costs = 0
        self.count = 0
        registerObservers()
    }
    
    deinit {
        memoryPressure.cancel()
        remove(.all)
    }
}

private extension SwimplyCache {
    func registerObservers() {
        let center = NotificationCenter.default
        let queue = DispatchQueue.global(qos: .background)
        
        let cleanup = { [weak self] (_: Notification) -> Void in
            queue.async { self?.remove(.all) }
        }
        
        let pressure = { [weak self] () -> Void in
            self?.remove(.all)
        }
        
        memoryPressure.setEventHandler(handler: pressure)
        memoryPressure.resume()
        
        var notifications: [NSNotification.Name] = []
        
        #if os(OSX)
            notifications += [NSWindow.didMiniaturizeNotification, NSApplication.didHideNotification]
        #elseif os(iOS) || os(tvOS)
            notifications += [UIApplication.didEnterBackgroundNotification]
        #endif
        
        notifications.forEach({
            center.addObserver(forName: $0, object: nil, queue: nil, using: cleanup)
        })
    }
    
    func removeKey(_ key: T) {
        guard let removeValue = self.storage[key] else {
            return
        }
        
        if key == rootKey, let nextKey = self.storage[key]?.next, var nextRoot = self.storage[nextKey] {
            nextRoot.setPrev(nil)
            rootKey = nextKey
            storage[nextKey] = nextRoot
        }
        
        if key == endKey {
            endKey = removeValue.prev
        }
        
        if let prevKey = removeValue.prev, var prevValue = self.storage[prevKey] {
            prevValue.setNext(removeValue.next)
            storage[prevKey] = prevValue
        }
        
        if let nextKey = removeValue.next, var nextValue = self.storage[nextKey] {
            nextValue.setPrev(removeValue.prev)
            storage[nextKey] = nextValue
        }
        
        storage.removeValue(forKey: key)
        costs -= removeValue.cost
        count -= 1
    }
    
    func set(_ execute: () -> Void) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        execute()
    }
}

public extension SwimplyCache {
    func trim() {
        if let countLimit = self.countLimit {
            remove(.byLimit(countLimit: countLimit))
        }
        
        if let costLimit = self.costLimit {
            remove(.byCost(costLimit: costLimit))
        }
    }
    
    func value(forKey key: T) -> S? {
        var value: S?
        set {
            value = storage[key]?.value
        }
        return value
    }
    
    func setValue(_ val: S, forKey key: T, cost: Int = 0) {
        set {
            if rootKey == nil {
                rootKey = key
            }
            
            if let endKey = self.endKey, var endValue = self.storage[endKey] {
                endValue.setNext(key)
                self.storage[endKey] = endValue
            }
            
            self.storage[key] = Store(value: val, cost: cost, prev: endKey, next: nil)
            self.endKey = key
            self.costs += cost
            self.count += 1
        }
        trim()
    }
    
    func remove(_ operation: RemoveOperation = .all) {
        set {
            switch operation {
                case .all:
                    self.storage.removeAll()
                    self.endKey = nil
                    self.rootKey = nil
                    self.costs = 0
                    self.count = 0
                    
                case .key(let key):
                    removeKey(key)
                    
                case .byLimit(let countLimit):
                    guard count > countLimit else { return }
                    
                    while count > countLimit {
                        guard let nextKey = rootKey else { break }
                        removeKey(nextKey)
                    }
                case .byCost(let costLimit):
                    guard costs > costLimit else { return }
                    
                    while costs > costLimit {
                        guard let nextKey = rootKey else { break }
                        removeKey(nextKey)
                    }
            }
        }
    }
}
