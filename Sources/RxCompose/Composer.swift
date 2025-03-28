//
//  Composer.swift
//  RxCompose
//
//  Created by 김도형 on 2/23/25.
//

import Foundation

import RxSwift
import RxCocoa

@MainActor
public protocol Composer: AnyObject, ReactiveCompatible {
    associatedtype Action
    associatedtype State
    
    var state: State { get }
    var action: PublishRelay<Action> { get }
    var disposeBag: DisposeBag { get }
    
    func bindAction()
    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>>
    func send(_ action: Action)
}

public extension Composer {
    internal(set) var state: State {
        get { self.state }
        set { }
    }
    
    func bindAction() {
        action
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .map { this, action in
                var state = this.state
                this.reducer(&state, action)
                    .observe(on: MainScheduler.asyncInstance)
                    .compactMap(\.action)
                    .bind(to: this.action)
                    .disposed(by: this.disposeBag)
                return state
            }
            .bind(with: self) { this, state in
                this.state = state
            }
            .disposed(by: disposeBag)
    }
    
    func send(_ action: Action) {
        self.action.accept(action)
    }
}

@MainActor
public extension Reactive where Base: Composer {
    var send: Binder<Base.Action> {
        Binder(base) { base, action in
            base.action.accept(action)
        }
    }
}
