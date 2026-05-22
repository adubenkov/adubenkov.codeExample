import Foundation

enum Event<Value> {
    case next(Value)
}

final class Observable<Value> {
    private var observers: [(Value) -> Void] = []

    @discardableResult
    func subscribe(onNext: @escaping (Value) -> Void) -> Disposable {
        observers.append(onNext)
        let index = observers.count - 1
        return Disposable { [weak self] in
            guard let self, self.observers.indices.contains(index) else {
                return
            }
            self.observers.remove(at: index)
        }
    }

    func on(_ event: Event<Value>) {
        if case let .next(value) = event {
            observers.forEach { observer in
                observer(value)
            }
        }
    }
}

final class Variable<Value> {
    private let observable = Observable<Value>()
    var value: Value {
        didSet {
            observable.on(.next(value))
        }
    }

    init(_ value: Value) {
        self.value = value
    }

    func asObservable() -> Observable<Value> {
        return observable
    }
}

struct Disposable {
    private let onDispose: () -> Void

    init(dispose: @escaping () -> Void) {
        self.onDispose = dispose
    }

    func dispose() {
        onDispose()
    }
}
