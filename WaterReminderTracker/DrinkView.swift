//
//  DrinkView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI

import ComposableArchitecture

struct DrinkReducer: Reducer {
    enum CancelID { case rotation}
    @Dependency(\.continuousClock) var clock
    struct State: Equatable {
        static func == (lhs: DrinkReducer.State, rhs: DrinkReducer.State) -> Bool {
            lhs.goal == rhs.goal && lhs.degree == rhs.degree && lhs.records == rhs.records
        }
        
        @UserDefault(key: "drink.goal")
        var goal: Int?
        
        @UserDefault(key: "drink.records")
        var records: [DrinkRecordReducer.Model]?

        
        var degree: Double = 0
    }
    enum Action: Equatable {
        case startRotation
        case stopRotation
        case updateRotation
        case pushToGoalView
        case pushToRecordView
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .startRotation:
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(10)) {
                        await send(.updateRotation)
                    }
                }.cancellable(id: CancelID.rotation)
            case .stopRotation:
                return .cancel(id: CancelID.rotation)
            case .updateRotation:
                state.degree += 2.0
            default:
                break
            }
            return .none
        }
    }
}

extension DrinkReducer.State {
    var goalValue: Int {
        goal ?? 2000
    }
    var goalString: String {
        "\(goalValue)ml"
    }
    var progressString: String {
        "\(Int(progress * 100.0))%"
    }
    var recordsValue: [DrinkRecordReducer.Model] {
        records ?? []
    }
    var todayRecordML: Int {
        recordsValue.filter({
            $0.day == Date().day
        }).compactMap({
            $0.ml
        }).reduce(0, +)
    }
    
    var progress: Double {
        Double(todayRecordML) / Double(goalValue)
    }
}

struct DrinkView: View {
    let store: StoreOf<DrinkReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
                ZStack(alignment: .bottom){
                    Image("drink_bg")
                    ZStack(alignment: .center){
                        Image("drink_animation").rotationEffect(.degrees(viewStore.degree))
                        Text(viewStore.progressString).foregroundStyle(.white).font(.system(size: 46))
                    }.padding(.bottom, 111)
                    HStack(spacing: 23){
                        Spacer()
                        DrinkButton(item: .record, goal: viewStore.goalString).onTapGesture {
                            viewStore.send(.pushToRecordView)
                        }
                        DrinkButton(item: .goal, goal: viewStore.goalString).onTapGesture {
                            viewStore.send(.pushToGoalView)
                        }
                        Spacer()
                    }.padding(.bottom, 24)
                }.onAppear{
                    viewStore.send(.startRotation)
                }.onDisappear{
                    viewStore.send(.stopRotation)
                }
            }.background(Color("#F0F7FC"))
        }
    }
    
    struct DrinkButton: View {
        enum Item: String, Equatable { case record, goal}
        let item: Item
        let goal: String
        var body: some View {
            HStack(){
                if item == .goal {
                    Text(goal).font(.system(size: 18, weight: .semibold))
                } else {
                    Text(item.rawValue.capitalized).font(.system(size: 18, weight: .semibold))
                }
                Spacer()
                Image("drink_" + item.rawValue)
            }.foregroundColor(.black).padding(.vertical, 20).padding(.horizontal, 24).frame(width: 150).background(Color("#FFEECF").cornerRadius(36))
        }
    }
}
