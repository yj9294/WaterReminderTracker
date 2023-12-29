//
//  ContentView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/28.
//

import SwiftUI
import GADUtil
import ComposableArchitecture

struct ContentReducer: Reducer {
    struct State: Equatable {
        var item: Item = .launching
        var launch: LaunchReducer.State = .init()
        var home: HomeNavigationReducer.State = .init()
        var background: Bool = false
    }
    enum Action: Equatable {
        case launch(LaunchReducer.Action)
        case home(HomeNavigationReducer.Action)
        case item(Item)
        case background(Bool)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .item(item):
                state.item = item
                if item == .launching {
                    return .run { send in
                        await send(.launch(.start))
                    }
                } else {
                    return .run { send in
                        await send(.launch(.stop))
                    }
                }
            case let .launch(action):
                switch action {
                case .launched:
                    if state.launch.progress == 1.0 {
                        return .run { send in
                            await send(.item(.launched))
                        }
                    } else {
                        return .none
                    }
                default:
                    break
                }
            case let .background(background):
                state.background = background
            default:
                break
            }
            return .none
        }
        Scope(state: \.launch, action: /Action.launch) {
            LaunchReducer()
        }
        Scope(state: \.home, action: /Action.home) {
            HomeNavigationReducer()
        }
    }
}

extension ContentReducer {
    enum Item {
        case launching, launched
    }
}

struct ContentView: View {
    let store: StoreOf<ContentReducer>
    @Environment(\.scenePhase) var scenePhase
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack {
                VStack{
                    if viewStore.item == .launching {
                        LaunchView(store: store.scope(state: \.launch, action: ContentReducer.Action.launch))
                    } else {
                        HomeNavigationView(store: store.scope(state: \.home, action: ContentReducer.Action.home))
                    }
                }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task{
                        await GADUtil.share.dismiss()
                    }
                    viewStore.send(.item(.launching))
                    viewStore.send(.background(false))
                }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    viewStore.send(.background(true))
                }
            }
        }
    }
}
