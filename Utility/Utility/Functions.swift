//
//  Functions.swift
//  Utility
//
//  Created by Nguyen Tuan on 7/5/17.
//  Copyright © 2017 Nguyen Tuan. All rights reserved.
//

public func sync(lock: NSObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

public func debounceLast(delay dispatchDelay:DispatchTimeInterval, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
    var lastFireTime = DispatchTime.now()
    return {
        lastFireTime = .now()
        let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
        queue.asyncAfter(deadline: dispatchTime, execute: {
            let when: DispatchTime = lastFireTime + dispatchDelay
            let now = DispatchTime.now()
            if now.rawValue >= when.rawValue {
                lastFireTime = DispatchTime.now()
                action()
            }
        })
    }
}

public func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
    var lastFireTime = DispatchTime.now()
    let dispatchDelay = DispatchTimeInterval.seconds(delay)
    
    return {
        let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
        queue.asyncAfter(deadline: dispatchTime, execute: {
            let when: DispatchTime = lastFireTime + dispatchDelay
            let now = DispatchTime.now()
            if now.rawValue >= when.rawValue {
                lastFireTime = DispatchTime.now()
                action()
            }
        })
    }
}

public func debounceMilisecond(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
    var lastFireTime = DispatchTime.now()
    let dispatchDelay = DispatchTimeInterval.milliseconds(delay)
    
    return {
        let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
        queue.asyncAfter(deadline: dispatchTime, execute: {
            let when: DispatchTime = lastFireTime + dispatchDelay
            let now = DispatchTime.now()
            if now.rawValue >= when.rawValue {
                lastFireTime = DispatchTime.now()
                action()
            }
        })
    }
}
