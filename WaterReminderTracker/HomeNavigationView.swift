//
//  HomeNavigationView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI
import ComposableArchitecture

struct HomeNavigationReducer: Reducer {
    struct State: Equatable {
        var root: HomeReducer.State = .init()
        var path: StackState<Path.State> = .init()
    }
    enum Action: Equatable {
        case root(HomeReducer.Action)
        case path(StackAction<Path.State, Path.Action>)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .root(.drink(.pushToGoalView)):
                state.pushGoalView()
            case .root(.drink(.pushToRecordView)):
                state.pushRecordView()
            case .root(.charts(.pushRecordHistoryView)):
                state.pushHistoryView()
            case .path(.element(id: _, action: .goal(.pop))), .path(.element(id: _, action: .record(.pop))), .path(.element(id: _, action: .history(.pop))):
                state.popView()
            case let .path(.element(id: _, action: .goal(.update(goal)))):
                state.root.drink.goal = goal
            case let .path(.element(id: _, action: .record(.update(records)))):
                state.root.drink.records = records
                state.root.charts.records = records
            default:
                break
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }
        Scope.init(state: \.root, action: /Action.root) {
            HomeReducer()
        }
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case goal(DrinkGoalReducer.State)
            case record(DrinkRecordReducer.State)
            case history(DrinkRecordHistoryReducer.State)
        }
        enum Action: Equatable{
            case goal(DrinkGoalReducer.Action)
            case record(DrinkRecordReducer.Action)
            case history(DrinkRecordHistoryReducer.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.goal, action: /Action.goal) {
                DrinkGoalReducer()
            }
            Scope(state: /State.record, action: /Action.record) {
                DrinkRecordReducer()
            }
            Scope(state: /State.history, action: /Action.history) {
                DrinkRecordHistoryReducer()
            }
        }
    }
}

extension HomeNavigationReducer.State {
    mutating func pushGoalView() {
        path.append(.goal(.init()))
    }
    mutating func pushRecordView() {
        path.append(.record(.init()))
    }
    mutating func pushHistoryView() {
        path.append(.history(.init()))
    }
    mutating func popView() {
        path.removeAll()
    }
}


struct HomeNavigationView: View {
    let store: StoreOf<HomeNavigationReducer>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            HomeView(store: store.scope(state: \.root, action: HomeNavigationReducer.Action.root))
        } destination: { 
            switch $0 {
            case .goal:
                CaseLet(/HomeNavigationReducer.Path.State.goal, action: HomeNavigationReducer.Path.Action.goal, then: DrinkGoalView.init(store:))
            case .record:
                CaseLet(/HomeNavigationReducer.Path.State.record, action: HomeNavigationReducer.Path.Action.record, then: DrinkRecordView.init(store:))
            case .history:
                CaseLet(/HomeNavigationReducer.Path.State.history, action: HomeNavigationReducer.Path.Action.history, then: DrinkRecordHistoryView.init(store:))
            }
        }

    }
}
