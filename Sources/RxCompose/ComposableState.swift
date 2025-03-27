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
struct ComposableState<State> {
    private let relay: BehaviorRelay<State>
    
    init(wrappedValue: State) {
        relay = BehaviorRelay(value: wrappedValue)
    }
    
    var wrappedValue: State {
        get { relay.value }
        set { relay.accept(newValue) }
    }
    
    var projectedValue: ComposableState<State> { self }
    
    var observable: Driver<State> { relay.asDriver() }
    
    func present<Result>(
        _ selector: @escaping (State) -> PresentState<Result>
    ) -> Driver<Result> {
        observable
            .map(selector)
            .distinctUntilChanged(\.count)
            .map(\.wrappedValue)
    }
}
