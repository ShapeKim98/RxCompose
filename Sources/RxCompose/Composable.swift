//
//  Composable.swift
//  RxCompose
//
//  Created by 김도형 on 3/28/25.
//

import Foundation

import RxSwift

public protocol Composable {
    associatedtype Composer: RxCompose.Composer
    associatedtype Action = Composer.Action
    
    var disposeBag: DisposeBag { get set }
    var composer: Composer { get set }
}
