//
//  Observable+Effect.swift
//  RxComposableKit
//
//  Created by 김도형 on 3/27/25.
//

import Foundation

import RxSwift

public extension Observable where Element: EffectProtocol {
    func cancellable(_ disposeBag: DisposeBag) -> Observable<Element> {
        return .create { observer in
            self.subscribe { effect in
                observer.onNext(effect)
            } onDisposed: {
                observer.onCompleted()
            }
            .disposed(by: disposeBag)
            
            return Disposables.create()
        }
    }
    
    static func timer(
        _ effect: Observable<Element>,
        dueTime: RxTimeInterval = .seconds(0),
        period: RxTimeInterval,
        scheduler: SchedulerType = MainScheduler.asyncInstance,
        disposeBag: DisposeBag
    ) -> Observable<Element> {
        return Observable.create { observer in
            Observable<Int>.timer(dueTime, period: period, scheduler: scheduler)
                .flatMap { _ in effect }
                .subscribe { effect in
                    observer.onNext(effect)
                } onDisposed: {
                    observer.onCompleted()
                }
                .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    static func interval(
        _ effect: Observable<Element>,
        period: RxTimeInterval,
        scheduler: SchedulerType = MainScheduler.asyncInstance,
        disposeBag: DisposeBag
    ) -> Observable<Element> {
        return Observable.create { observer in
            Observable<Int>.interval(period, scheduler: scheduler)
                .flatMap { _ in effect }
                .subscribe { effect in
                    observer.onNext(effect)
                } onDisposed: {
                    observer.onCompleted()
                }
                .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    static func send(_ action: Element.Action) -> Observable<Element> {
        return .just(.send(action))
    }
    
    static var none: Observable<Element> {
        return .just(.none)
    }
    
    static func run(
        _ observable: Observable<Element.Action>,
        catch onError: ((Error) -> Observable<Element>)? = nil
    ) -> Observable<Element> {
        return observable
            .map { Element.send($0) }
            .catch { onError?($0) ?? .none }
    }
    
    static func run(
        _ observable: Single<Element.Action>,
        catch onError: ((Error) -> Observable<Element>)? = nil
    ) -> Observable<Element> {
        return observable
            .map { Element.send($0) }
            .asObservable()
            .catch { onError?($0) ?? .none }
    }
    
    @MainActor
    static func run(
        priority: TaskPriority? = nil,
        _ operation: sending @escaping ( _ effect: AnyObserver<Element>) async throws -> Void,
        catch onError: ((Error) -> Element)? = nil
    ) -> Observable<Element> {
        return .create { observable in
            let task = Task(priority: priority) {
                do {
                    try await operation(observable)
                    observable.onCompleted()
                } catch {
                    observable.onNext(onError?(error) ?? .none)
                    observable.onCompleted()
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
