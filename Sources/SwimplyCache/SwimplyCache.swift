import Foundation
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

public class SwimplyCache<T: Hashable, S: Any> {
    private struct Store<S: Any> {
        let value: S
        let cost: Int
    }
    
    public enum RemoveOperation {
        case all
        case key(key: T)
        case byLimit(countLimit: Int)
        case byCost(costLimit: Int)
    }
    
    private let memoryPressure: DispatchSourceMemoryPressure
    private var storage: [T: Store<S>]
    private var sorted: [T]
    private var lock: os_unfair_lock_s
    
    public private(set) var costs: Int
    public private(set) var count: Int
    
    public let countLimit: Int?
    public let costLimit: Int?
    
    public init(countLimit: Int? = nil, costLimit: Int? = nil) {
        self.lock = os_unfair_lock_s()
        self.memoryPressure = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .global(qos: .background))
        self.storage = [:]
        self.sorted = []
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
    
    func set(_ execute: () -> Void) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        /*
         objc_sync_enter(self)
         defer { objc_sync_exit(self) } */
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
            self.storage[key] = Store(value: val, cost: cost)
            self.sorted.append(key)
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
                    self.sorted.removeAll()
                    self.costs = 0
                    self.count = 0
                    
                case .key(let key):
                    guard let removeValue = self.storage[key],
                        let removeIndex = self.sorted.firstIndex(of: key) else { return }
                    self.storage.removeValue(forKey: key)
                    self.sorted.remove(at: removeIndex)
                    self.costs -= removeValue.cost
                    self.count -= 1
                    
                case .byLimit(let countLimit):
                    guard count > countLimit else { return }
                    while count > countLimit {
                        let remove = sorted.removeFirst()
                        let value = storage[remove]
                        self.storage.removeValue(forKey: remove)
                        self.costs -= value?.cost ?? 0
                        self.count -= 1
                    }
                case .byCost(let costLimit):
                    while self.costs > costLimit {
                        let remove = sorted.removeFirst()
                        let value = storage[remove]
                        
                        self.storage.removeValue(forKey: remove)
                        self.costs -= value?.cost ?? 0
                        self.count -= 1
                    }
            }
        }
    }
}
