//
//  HomeView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/28.
//

import SwiftUI
import GADUtil
import AppTrackingTransparency
import ComposableArchitecture

struct HomeReducer: Reducer {
    struct State: Equatable {
        static func == (lhs: HomeReducer.State, rhs: HomeReducer.State) -> Bool {
            lhs.item  == rhs.item &&
            lhs.drink == rhs.drink &&
            lhs.charts == rhs.charts &&
            lhs.reminder == rhs.reminder &&
            lhs.drinkImpressionDate == rhs.drinkImpressionDate &&
            lhs.chartsImpressionDate == rhs.chartsImpressionDate &&
            lhs.reminderImpressionDate == rhs.reminderImpressionDate
        }
        
        let items = Item.allCases
        var item: Item = .drink
        var drink: DrinkReducer.State = .init()
        var charts: ChartsReducer.State = .init()
        var reminder: ReminderReducer.State = .init()
        
        @UserDefault(key: "drink.date")
        var drinkImpressionDate: Date?
        @UserDefault(key: "charts.date")
        var chartsImpressionDate: Date?
        @UserDefault(key: "reminder.date")
        var reminderImpressionDate: Date?
    }
    
    enum Action: Equatable {
        case item(State.Item)
        case drink(DrinkReducer.Action)
        case charts(ChartsReducer.Action)
        case reminder(ReminderReducer.Action)
        case updateAD(GADNativeViewModel)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .item(item):
                state.item = item
            case let .updateAD(ad):
                state.updateADModel(ad)
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
    
    mutating func updateADModel(_ ad: GADNativeViewModel) {
        if item == .drink, ad != .none {
            if Date().timeIntervalSince1970 - (drinkImpressionDate ?? Date().addingTimeInterval(-11)).timeIntervalSince1970 > 10 {
                drink.adModel = ad
                drinkImpressionDate = Date()
            } else {
                debugPrint("[AD] drink 原生广告10s间隔限制")
            }
        } else if item == .charts, ad != .none {
            if Date().timeIntervalSince1970 - (chartsImpressionDate ?? Date().addingTimeInterval(-11)).timeIntervalSince1970 > 10 {
                charts.adModel = ad
                chartsImpressionDate = Date()
            } else {
                debugPrint("[AD] charts 原生广告10s间隔限制")
            }
        } else if item == .reminder, ad != .none {
            if Date().timeIntervalSince1970 - (reminderImpressionDate ?? Date().addingTimeInterval(-11)).timeIntervalSince1970 > 10 {
                reminder.adModel = ad
                reminderImpressionDate = Date()
            } else {
                debugPrint("[AD] reminder 原生广告10s间隔限制")
            }
        } else {
            drink.adModel = .none
            charts.adModel = .none
            reminder.adModel = .none
        }
    }
}


struct HomeView: View {
    let store: StoreOf<HomeReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ContentView(store: store)
                TabbarView(store: store).background(.white)
            }.onReceive(NotificationCenter.default.publisher(for: .nativeUpdate)) { noti in
                if let ad = noti.object as? GADNativeModel {
                    viewStore.send(.updateAD(GADNativeViewModel(model: ad)))
                } else {
                    viewStore.send(.updateAD(.none))
                }
            }
        }.onAppear {
            ATTrackingManager.requestTrackingAuthorization { _ in
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
