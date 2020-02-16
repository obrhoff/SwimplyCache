import Foundation
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

public final class SwimplyCache<T: Hashable, S: Any> {
    private final class Store<T: Hashable, S: Any> {
        let value: S
        let cost: Int
        var prevKey: T?
        var nextKey: T?
        
        init(value: S, cost: Int, prevKey: T? = nil, nextKey: T? = nil) {
            self.value = value
            self.cost = cost
            self.prevKey = prevKey
            self.nextKey = nextKey
        }
    }
    
    public enum RemoveOperation {
        case all
        case key(key: T)
        case byLimit(countLimit: Int)
        case byCost(costLimit: Int)
    }
    
    private let pressure: DispatchSourceMemoryPressure
    private var storage: [T: Store<T, S>]
    private var notificationObservers: [NSObjectProtocol]?
    private var lock: os_unfair_lock_s
    private var rootKey: T?
    private var endKey: T?
    
    public private(set) var totalCosts: Int
    
    public let countLimit: Int
    public let costLimit: Int
    
    public var itemsCount: Int {
        return storage.count
    }
    
    public init(countLimit: Int = .max, costLimit: Int = .max) {
        self.lock = os_unfair_lock_s()
        self.pressure = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .global(qos: .background))
        self.storage = [:]
        self.totalCosts = 0
        self.countLimit = max(0, countLimit)
        self.costLimit = max(0, costLimit)
        registerObservers()
    }
    
    deinit {
        removeAll()
        pressure.cancel()
        notificationObservers?.forEach({ NotificationCenter.default.removeObserver($0) })
    }
}

private extension SwimplyCache {
    func registerObservers() {
        pressure.setEventHandler { [weak self] in
            self?.remove(.all)
        }
        pressure.resume()
        
        var notifications: [NSNotification.Name] = []
        
        #if os(OSX)
            notifications += [NSWindow.didMiniaturizeNotification, NSApplication.didHideNotification]
        #elseif os(iOS) || os(tvOS)
            notifications += [UIApplication.didEnterBackgroundNotification]
        #endif
        
        notificationObservers = notifications.map {
            NotificationCenter.default.addObserver(forName: $0, object: nil, queue: nil) { [weak self] _ in
                DispatchQueue.global(qos: .background).async { self?.remove(.all) }
            }
        }
    }
    
    func get(forKey key: T) -> S? {
        let store = storage[key]
        
        if let store = store {
            removeKey(key)
            insert(store.value, forKey: key, cost: store.cost)
        }
        
        return store?.value
    }
    
    func insert(_ val: S, forKey key: T, cost: Int) {
        removeKey(key)
        
        if rootKey == nil {
            rootKey = key
        }
        
        if let endKey = self.endKey {
            storage[endKey]?.nextKey = key
        }
        
        storage[key] = Store(value: val, cost: cost, prevKey: endKey)
        endKey = key
        totalCosts += cost
        
        removeByLimit(countLimit)
        removeByCosts(costLimit)
    }
    
    func removeKey(_ key: T) {
        let removeValue = storage.removeValue(forKey: key)
        
        if key == rootKey {
            rootKey = removeValue?.nextKey
        }
        
        if key == endKey {
            endKey = removeValue?.prevKey
        }
        
        if let prevKey = removeValue?.prevKey {
            storage[prevKey]?.nextKey = removeValue?.nextKey
        }
        
        if let nextKey = removeValue?.nextKey {
            storage[nextKey]?.prevKey = removeValue?.prevKey
        }
        
        totalCosts -= removeValue?.cost ?? 0
    }
    
    func removeAll() {
        storage.removeAll()
        endKey = nil
        rootKey = nil
        totalCosts = 0
    }
    
    func removeByLimit(_ countLimit: Int) {
        while itemsCount > countLimit {
            guard let nextKey = rootKey else { break }
            removeKey(nextKey)
        }
    }
    
    func removeByCosts(_ costsLimit: Int) {
        while totalCosts > costsLimit {
            guard let nextKey = rootKey else { break }
            removeKey(nextKey)
        }
    }
    
    func set(_ execute: () -> Void) {
        os_unfair_lock_lock(&lock)
        execute()
        os_unfair_lock_unlock(&lock)
    }
}

public extension SwimplyCache {
    func value(forKey key: T) -> S? {
        var value: S?
        set {
            value = get(forKey: key)
        }
        return value
    }
    
    func setValue(_ val: S, forKey key: T, cost: Int = 0) {
        set {
            insert(val, forKey: key, cost: cost)
        }
    }
    
    func remove(_ operation: RemoveOperation = .all) {
        set {
            switch operation {
                case .all:
                    removeAll()
                case .key(let key):
                    removeKey(key)
                case .byLimit(let countLimit):
                    removeByLimit(countLimit)
                case .byCost(let costLimit):
                    removeByCosts(costLimit)
            }
        }
    }
}
