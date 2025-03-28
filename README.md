
# RxCompose
[![Version](https://img.shields.io/cocoapods/v/RxCompose.svg?style=flat)](https://cocoapods.org/pods/RxCompose)
[![License](https://img.shields.io/cocoapods/l/RxCompose.svg?style=flat)](https://cocoapods.org/pods/RxCompose)
[![Platform](https://img.shields.io/cocoapods/p/RxCompose.svg?style=flat)](https://cocoapods.org/pods/RxCompose)

RxCompose is a lightweight framework for building unidirectional architectures in iOS apps using RxSwift. It simplifies state management and side effects, making your code more predictable, testable, and easier to maintain.

## Unidirectional Architecture
RxCompose follows a unidirectional data flow to manage state and UI updates:

1. **Actions**: Triggered by the UI or external events.
2. **Reducer**: Processes actions, updates the **State**, and optionally produces **Effects**.
3. **State**: Observed by the UI to reflect changes.
4. **Effects**: Trigger additional actions, completing the cycle.

## Installation
RxCompose can be installed via Swift Package Manager (SPM) or CocoaPods.

### Swift Package Manager
Add the following to your `Package.swift`:
```Swift
dependencies: [
    .package(url: "https://github.com/ShapeKim98/RxCompose.git", from: "0.1.0")
]
```
### CocoaPods
RxCompose is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RxCompose'
```

## Usage

### Defining the Composer
The Composer is the heart of RxCompose, managing state, actions, and side effects.
- **State**: Define it with `@ComposableState` to make it observable.
- **Actions**: Use an enum to list possible actions.
- **Reducer**: Implement logic to update the state and handle effects.

#### Example: CounterComposer
```Swift
class CounterComposer: Composer {
    enum Action {
        case increment
        case decrement
        case showAlert(String)
    }

    struct State {
        var count = 0
        @PresentState var alertMessage: String?
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .increment:
            state.count += 1
            if state.count == 10 {
                return .send(.showAlert("Count reached 10!"))
            }
            return .none
        case .decrement:
            state.count -= 1
            if state.count == -10 {
                return .send(.showAlert("Count reached -10!"))
            }
            return .none
        case let .showAlert(message):
            state.alertMessage = message
            return .none
        }
    }
}
```
- `@ComposableState`: Makes the state reactive and observable.
- `reducer`: Updates the state and returns effects (e.g., showing an alert at specific thresholds).

### Using Composable in View Controllers
Integrate the composer into your view controller by:
1. Conforming to `Composable`.
2. Declaring the composer with `@Compose`.
3. Binding UI elements in the `bind()` method.

#### Example: ViewController
```Swift
class ViewController: UIViewController, Composable {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!

    @Compose var composer = CounterComposer()
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    func bind() {
        // Bind state.count to label
        composer.$state.observable
            .map(\.count)
            .map { "\($0)" }
            .distinctUntilChanged()
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)

        // Present alert when alertMessage changes
        composer.$state.present(\.$alertMessage)
            .compactMap(\.self)
            .drive(with: self) { this, message in
                let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                this.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        // Bind buttons to actions
        incrementButton.rx.tap
            .map { Composer.Action.increment }
            .bind(to: composer.action)
            .disposed(by: disposeBag)

        decrementButton.rx.tap
            .map { Composer.Action.decrement }
            .bind(to: composer.action)
            .disposed(by: disposeBag)
    }
}
```
- `@Compose`: Sets up the composer and connects actions automatically.
- `bind()`: Links UI elements to the composer’s state and actions.


### Handling Side Effects
RxCompose provides several methods to handle side effects in the `reducer`, ensuring they integrate seamlessly into the unidirectional flow.

### Swift Concurrency-Based `run`
Use this run method to handle asynchronous operations like network requests.

#### Example: DataComposer with Async Fetching
```Swift
class DataComposer: Composer {
    enum Action {
        case fetchData
        case dataLoaded(String)
        case fetchFailed(Error)
    }

    struct State {
        var data: String?
        var isLoading = false
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .fetchData:
            state.isLoading = true
            return .run { effect in
                let data = try await api.fetchData() // Assume api.fetchData() is an async method
				effect.onNext(.send(.dataLoaded(data)))
            } catch: { error in
                return .send(.fetchFailed(error))
            }
        case .dataLoaded(let data):
            state.data = data
            state.isLoading = false
            return .none
        case .fetchFailed(let error):
            state.isLoading = false
            return .none
        }
    }
}
```
- `.run`: Executes an async task and uses `effect` to dispatch actions.
- `catch`: Handles errors by returning a custom effect (e.g., `.fetchFailed`).

### Observable-Based `run`
The `Observable`-based `run` method wraps an existing `Observable` or `Single` into an effect stream, ideal for integrating RxSwift-based APIs or complex reactive workflows.

#### Example: ObservableDataComposer
```Swift
class ObservableDataComposer: Composer {
    enum Action {
        case fetchData
        case dataLoaded(String)
        case fetchFailed(Error)
    }

    struct State {
        var data: String?
        var isLoading = false
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .fetchData:
            state.isLoading = true
            let dataObservable = api.fetchDataObservable() // Assume this returns Observable<String>
            return .run(dataObservable.map {
				Action.dataLoaded($0)
			}) { error in
                return .send(.fetchFailed(error))
            }
        case .dataLoaded(let data):
            state.data = data
            state.isLoading = false
            return .none
        case .fetchFailed(let error):
            state.isLoading = false
            return .none
        }
    }
}
```
- `.run(dataObservable)`: Takes an Observable<String> and maps its emissions to .dataLoaded actions.
- `catch`: If the observable fails, it maps the error to a `.fetchFailed` action.
- **Use Case**: Perfect for leveraging existing RxSwift streams (e.g., network requests, timers) within the unidirectional flow.

Both `run` methods ensure side effects remain part of the predictable unidirectional cycle, with the `Observable`-based version offering seamless integration with RxSwift’s reactive paradigm.

### `timer` and `interval` Methods
The `timer` and `interval` methods allow you to schedule periodic actions as effects, leveraging RxSwift’s scheduling capabilities.

#### Example: TimerComposer with `timer`
```Swift
class TimerComposer: Composer {
    enum Action {
        case startTimer
        case tick
    }

    struct State {
        var count = 0
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()
	var timerDisposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .startTimer:
            return .timer(.send(.tick), dueTime: .seconds(1), period: .seconds(2), disposeBag: timerD)
        case .tick:
            state.count += 1
            return .none
        }
    }
}
```
- `.timer`: Waits for `dueTime` (1 second) before starting, then emits `.tick` every `period` (2 seconds).
- **Use Case**: Useful for delayed starts followed by periodic updates (e.g., a countdown with an initial delay).

#### Example: IntervalComposer with interval
```Swift
class IntervalComposer: Composer {
    enum Action {
        case startCounting
        case increment
    }

    struct State {
        var count = 0
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .startCounting:
            return .interval(.send(.increment), period: .seconds(1), disposeBag: disposeBag)
        case .increment:
            state.count += 1
            return .none
        }
    }
}
```
- `.interval`: Emits `.increment` every `period` (1 second) immediately upon subscription.
- **Use Case**: Ideal for continuous periodic tasks (e.g., a live counter or polling mechanism).

### Stopping `timer` and `interval` with cancel
The `cancel` method allows you to stop ongoing `timer` or `interval` effects by resetting the `DisposeBag`, effectively disposing of all active subscriptions.

#### Example: StoppableTimerComposer
```Swift
class StoppableTimerComposer: Composer {
    enum Action {
        case startTimer
        case stopTimer
        case tick
    }

    struct State {
        var count = 0
        var isRunning = false
    }

    @ComposableState var state = State()
    var action = PublishRelay<Action>()
    var disposeBag = DisposeBag()

    func reducer(_ state: inout State, _ action: Action) -> Observable<Effect<Action>> {
        switch action {
        case .startTimer:
            guard !state.isRunning else { return .none }
            state.isRunning = true
            return .timer(.send(.tick), dueTime: .seconds(0), period: .seconds(1), disposeBag: disposeBag)
        case .stopTimer:
            state.isRunning = false
            return .cancel(&disposeBag)
        case .tick:
            state.count += 1
            return .none
        }
    }
}
```
In the view controller:
```Swift
class TimerViewController: UIViewController, Composable {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    @Compose var composer = StoppableTimerComposer()
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    func bind() {
        composer.$state.observable
            .map(\.count)
            .map { "\($0)" }
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)

        startButton.rx.tap
            .map { Composer.Action.startTimer }
            .bind(to: composer.action)
            .disposed(by: disposeBag)

        stopButton.rx.tap
            .map { Composer.Action.stopTimer }
            .bind(to: composer.action)
            .disposed(by: disposeBag)
    }
}
```
- `.timer`: Starts emitting `.tick` every second when `.startTimer` is dispatched.
- `.cancel(&disposeBag)`: When .stopTimer is dispatched, it resets the disposeBag, stopping the timer by disposing of its subscription.
- `isRunning`: Prevents restarting the timer if it’s already active, ensuring clean state management.
- **Use Case**: Perfect for scenarios where periodic actions need to be paused or stopped (e.g., a stopwatch or polling that can be toggled off).

The `cancel` method ensures that side effects like `timer` and `interval` remain controllable within the unidirectional architecture by leveraging RxSwift’s disposal mechanism.

### Presenting State Changes
Use `@PresentState` to mark state properties that trigger UI presentations, such as alerts.

#### Example: Alert Presentation
In the state:
```Swift
struct State {
    var count = 0
    @PresentState var alertMessage: String?
}
```

In the view controller:
```Swift
composer.$state.present(\.$alertMessage)
    .compactMap(\.self)
    .drive(with: self) { this, message in
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        this.present(alert, animated: true)
    }
    .disposed(by: disposeBag)
```

- `@PresentState`: Flags properties for presentation tracking.
- `present(\.$alertMessage)`: Observes changes and triggers UI updates like alerts.

## Requirements
- iOS 13.0+
- RxSwift 6.9+

## Author

ShapeKim98, shapekim98@gmail.com

## License

RxCompose is available under the MIT license. See the LICENSE file for more info.
