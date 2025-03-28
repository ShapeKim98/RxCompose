//
//  ComposableState.swift
//  DoBongShopping
//
//  Created by 김도형 on 3/1/25.
//

import Foundation

import RxSwift
import RxCocoa

@propertyWrapper
public struct ComposableState<State> {
    private let relay: BehaviorRelay<State>
    
    public init(wrappedValue: State) {
        relay = BehaviorRelay(value: wrappedValue)
    }
    
    public var wrappedValue: State {
        get { relay.value }
        set { relay.accept(newValue) }
    }
    
    public var projectedValue: ComposableState<State> { self }
    
    public var observable: Driver<State> { relay.asDriver() }
    
    public func present<Result>(
        _ selector: @escaping (State) -> PresentState<Result>
    ) -> Driver<Result> {
        observable
            .map(selector)
            .distinctUntilChanged(\.count)
            .map(\.wrappedValue)
    }
}
