//
//  Effect.swift
//  RxCompose
//
//  Created by 김도형 on 2/21/25.
//

import Foundation

import RxSwift

public protocol EffectProtocol {
    associatedtype Action
    static func send(_ action: Action) -> Self
    static var none: Self { get }
}

public enum Effect<Action>: EffectProtocol {
    case send(Action)
    case none
    
    public var action: Action? {
        switch self {
        case .send(let action):
            return action
        case .none: return nil
        }
    }
}


