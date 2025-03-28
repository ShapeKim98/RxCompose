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
    
    var state: State { get set }
    var action: PublishRelay<Action> { get }
    var disposeBag: DisposeBag { get set }
    
    func bindAction()
    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>>
}

extension Composer {
    public func bindAction() {
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
}


