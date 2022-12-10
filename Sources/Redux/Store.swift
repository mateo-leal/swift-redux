//
//  SwiftUIView.swift
//  
//
//  Created by Mateo Leal Giraldo on 10/12/22.
//

import Combine
import Foundation

protocol State {
    init()
}

actor Store<S: State, Action>: ObservableObject {
    typealias Reducer = (S, Action) -> S

    @MainActor @Published private(set) var state: S = .init()

    private let middleware: AnyMiddleware<Action>
    private let reducer: Reducer

    init<M: Middleware>(
        reducer: @escaping Reducer,
        @MiddlewareBuilder<Action> middleware: () -> M
    ) where M.Action == Action {
        self.reducer = reducer
        self.middleware = middleware().eraseToAnyMiddleware()
    }

    convenience init(reducer: @escaping Reducer) {
        self.init(
            reducer: reducer,
            middleware: {
                EchoMiddleware<Action>()
            }
        )
    }

    func dispatch(action: Action) async {
        guard let newAction = await middleware(action: action) else {
            return
        }

        await MainActor.run {
            let currentState = state
            let newState = reducer(currentState, newAction)
            state = newState
        }
    }
}

extension Store {
    func dispatch(_ factory: () async -> Action) async {
        await self.dispatch(action: await factory())
    }
}

extension Store {
    func dispatch<Seq: AsyncSequence>(
        sequence: Seq
    ) async throws where Seq.Element == Action {
        for try await action in sequence {
            await dispatch(action: action)
        }
    }
}

extension Store {
    func dispatch(future: Future<Action?, Never>) {
        var subscription: AnyCancellable?
        subscription = future.sink { _ in
            if subscription != nil {
                subscription = nil
            }
        } receiveValue: { action in
            guard let action = action else {
                return
            }

            Task {
                await self.dispatch(action: action)
            }
        }
    }
}

extension Store {
    func dispatch<P: Publisher>(publisher: P) where P.Output == Action, P.Failure == Never {
        var subscription: AnyCancellable?
        subscription = publisher.sink { _ in
            if subscription != nil {
                subscription = nil
            }
        } receiveValue: { action in
            Task {
                await self.dispatch(action: action)
            }
        }
    }
}
