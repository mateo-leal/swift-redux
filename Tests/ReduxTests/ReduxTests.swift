import XCTest
@testable import Redux

struct AppState {
    var count: Int
}
extension AppState: State {
    init() {
        self.init(count: 0)
    }
}

enum AppAction {
    case incrementCount
}

typealias AppStore = Store<AppState, AppAction>

final class ReduxTests: XCTestCase {

    func testActionDispatch() async {
        let store = AppStore { state, action in
            var newState = state
            switch action {
            case .incrementCount: newState.count += 1
            }
            return newState
        }
        let current0 = await store.state.count
        XCTAssertEqual(current0, 0)
        await store.dispatch(action: .incrementCount)
        let current1 = await store.state.count
        XCTAssertEqual(current1, 1)
    }
    
//    struct ThrowMiddleware<AppAction>: Middleware {
//        func callAsFunction(action: AppAction) async -> AppAction? {
//            switch action {
//            case .incrementCount:
//            }
//        }
//    }

//    func testMiddlewareActionDispatch() async {
//        var store = AppStore { state, action in
//            var newState = state
//            switch action {
//            case .incrementCount: newState.count += 1
//            }
//            return newState
//        } middleware: {
//            ThrowMiddleware<AppAction>()
//        }
//        XCTAssertThro
//    }
}
