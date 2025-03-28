//
//  Compose.swift
//  RxCompose
//
//  Created by 김도형 on 3/28/25.
//

import Foundation

import RxSwift

@MainActor
@propertyWrapper
public struct Compose<C: Composer>: ReactiveCompatible {
    private var composer: C
    
    public init(wrappedValue: C) {
        composer = wrappedValue
        composer.bindAction()
    }
    
    public var wrappedValue: C {
        get { composer }
        set {
            composer = newValue
            composer.disposeBag = DisposeBag()
            composer.bindAction()
        }
    }
    
    public var projectedValue: Compose<C> { self }
    
    public func send(_ action: C.Action) {
        composer.action.accept(action)
    }
}
