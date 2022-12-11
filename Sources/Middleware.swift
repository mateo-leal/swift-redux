//
//  SwiftUIView.swift
//
//
//  Created by Mateo Leal Giraldo on 10/12/22.
//

public protocol Middleware {
    associatedtype Action

    func callAsFunction(action: Action) async -> Action?
}

struct AnyMiddleware<Action>: Middleware {
    private let wrappedMiddleware: (Action) async -> Action?

    init<M: Middleware>(_ middleware: M) where M.Action == Action {
        self.wrappedMiddleware = middleware.callAsFunction(action:)
    }

    func callAsFunction(action: Action) async -> Action? {
        return await wrappedMiddleware(action)
    }
}

extension Middleware {
    func eraseToAnyMiddleware() -> AnyMiddleware<Action> {
        return self as? AnyMiddleware<Action> ?? AnyMiddleware(self)
    }
}

struct EchoMiddleware<Action>: Middleware {
    func callAsFunction(action: Action) async -> Action? {
        return action
    }
}

struct MiddlewarePipeline<Action>: Middleware {
    private let middleware: [AnyMiddleware<Action>]

    init(_ middleware: AnyMiddleware<Action>...) {
        self.middleware = middleware
    }

    init(_ middleware: [AnyMiddleware<Action>]) {
        self.middleware = middleware
    }

    func callAsFunction(action: Action) async -> Action? {
        var currentAction: Action = action
        for m in middleware {
            guard let newAction = await m(action: currentAction) else {
                return nil
            }
            currentAction = newAction
        }
        return currentAction
    }
}

@resultBuilder
struct MiddlewareBuilder<Action> {
    static func buildArray(
        _ components: [MiddlewarePipeline<Action>]
    ) -> AnyMiddleware<Action> {
        MiddlewarePipeline(components.map { $0.eraseToAnyMiddleware() })
            .eraseToAnyMiddleware()
    }

    static func buildBlock(
        _ components: AnyMiddleware<Action>...
    ) -> MiddlewarePipeline<Action> {
        .init(components)
    }

    static func buildEither<M: Middleware>(
        first component: M
    ) -> AnyMiddleware<Action> where M.Action == Action {
        component.eraseToAnyMiddleware()
    }

    static func buildEither<M: Middleware>(
        second component: M
    ) -> AnyMiddleware<Action> where M.Action == Action {
        component.eraseToAnyMiddleware()
    }

    static func buildExpression<M: Middleware>(
        _ expression: M
    ) -> AnyMiddleware<Action> where M.Action == Action {
        expression.eraseToAnyMiddleware()
    }

    static func buildFinalResult<M: Middleware>(
        _ component: M
    ) -> AnyMiddleware<Action> where M.Action == Action {
        component.eraseToAnyMiddleware()
    }

    static func buildOptional(
        _ component: MiddlewarePipeline<Action>?
    ) -> AnyMiddleware<Action> {
        guard let component = component else {
            return EchoMiddleware<Action>().eraseToAnyMiddleware()
        }
        return component.eraseToAnyMiddleware()
    }
}
