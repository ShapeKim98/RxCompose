//
//  PresentState.swift
//  DoBongShopping
//
//  Created by 김도형 on 3/1/25.
//

import Foundation

@propertyWrapper
public struct PresentState<State> {
    private var value: State {
        didSet { count += 1 }
    }
    var count: UInt = .min
    
    public init(wrappedValue: State) {
        value = wrappedValue
    }
    
    public var wrappedValue: State {
        get { value }
        set { value = newValue }
    }
    
    public var projectedValue: PresentState<State> { self }
}
