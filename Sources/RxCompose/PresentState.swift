//
//  PresentState.swift
//  DoBongShopping
//
//  Created by 김도형 on 3/1/25.
//

import Foundation

@propertyWrapper
struct PresentState<State> {
    private var value: State {
        didSet { count += 1 }
    }
    var count: UInt = .min
    
    init(wrappedValue: State) {
        value = wrappedValue
    }
    
    var wrappedValue: State {
        get { value }
        set { value = newValue }
    }
    
    var projectedValue: PresentState<State> { self }
}
