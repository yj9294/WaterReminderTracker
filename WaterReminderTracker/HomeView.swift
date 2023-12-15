//
//  HomeView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/28.
//

import SwiftUI
import ComposableArchitecture

struct HomeReducer: Reducer {
    struct State: Equatable {
        let items = Item.allCases
        var item: Item = .drink
        var drink: DrinkReducer.State = .init()
        var charts: ChartsReducer.State = .init()
        var reminder: ReminderReducer.State = .init()
    }
    enum Action: Equatable {
        case item(State.Item)
        case drink(DrinkReducer.Action)
        case charts(ChartsReducer.Action)
        case reminder(ReminderReducer.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .item(item):
                state.item = item
            default:
                break
            }
            return .none
        }
        Scope(state: \.drink, action: /Action.drink) {
            DrinkReducer()
        }
        Scope(state: \.charts, action: /Action.charts) {
            ChartsReducer()
        }
        Scope(state: \.reminder, action: /Action.reminder) {
            ReminderReducer()
        }
    }
}

extension HomeReducer.State {
    enum Item: String, CaseIterable {
        case drink, charts, reminder
    }
}


struct HomeView: View {
    let store: StoreOf<HomeReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ContentView(store: store)
                TabbarView(store: store).background(.white)
            }
        }
    }
    
    struct ContentView: View {
        let store: StoreOf<HomeReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    switch viewStore.item {
                    case .drink:
                        DrinkView(store: store.scope(state: \.drink, action: HomeReducer.Action.drink))
                    case .charts:
                        ChartsView(store: store.scope(state: \.charts, action: HomeReducer.Action.charts))
                    case .reminder:
                        ReminderView(store: store.scope(state: \.reminder, action: HomeReducer.Action.reminder))
                    }
                }.navigationTitle(viewStore.item.rawValue.capitalized).navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    struct TabbarView: View {
        let store: StoreOf<HomeReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                HStack{
                    ForEach(viewStore.items, id: \.self) { item in
                        Spacer()
                        Image(item.rawValue + (viewStore.item == item ? "_1" : "")).padding().onTapGesture { _ in
                            viewStore.send(.item(item))
                        }
                        Spacer()
                    }
                }.frame(height: 50)
            }
        }
    }
}
