//
//  DrinkGoalView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct DrinkGoalReducer: Reducer {
    struct State: Equatable {
        static func == (lhs: DrinkGoalReducer.State, rhs: DrinkGoalReducer.State) -> Bool {
            lhs.goal == rhs.goal
        }
        
        @UserDefault(key: "drink.goal")
        var goal: Int?

    }
    enum Action: Equatable {
        case pop
        case decrease
        case reduce
        case update(Int)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .decrease:
                state.goal = state.goalValue - 100 < 100 ? 100 : state.goalValue - 100
                return .run { [goalValue = state.goalValue] send in
                    await send(.update(goalValue))
                }
            case .reduce:
                state.goal = state.goalValue + 100 > 4000 ? 4000 : state.goalValue + 100
                return .run { [goalValue = state.goalValue] send in
                    await send(.update(goalValue))
                }
            default:
                break
            }
            return .none
        }
    }
}

extension DrinkGoalReducer.State {
    var goalValue: Int {
        goal ?? 2000
    }
    
    var goalString: String {
        "\(goalValue)ml"
    }
    
    var progress: Double {
        Double(goalValue) / 4000.0
    }
}

struct DrinkGoalView: View {
    let store: StoreOf<DrinkGoalReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                VStack(alignment: .leading, spacing: 20){
                    Text("Your daily goal").foregroundStyle(.white).font(.system(size: 18)).padding(.top, 20)
                    Text(viewStore.goalString).padding(.vertical, 14).padding(.horizontal, 28).background(Color("#74DDFF")).cornerRadius(8).foregroundStyle(.white)
                    Text("Swipe the button to adjust value").foregroundStyle(.white).font(.system(size: 11.0))
                    HStack{
                        HStack(spacing: 0){
                            Button(action: {viewStore.send(.decrease)}, label: {
                                Image("goal_-").frame(width: 26, height: 26)
                            }).background(.white)
                            ZStack(alignment: .leading){
                                GeometryReader { proxy in
                                    HStack(spacing: 0){
                                        Color.white.frame(width: proxy.size.width * viewStore.progress)
                                        Color("#8CD4FF")
                                    }
                                    let leading = proxy.size.width * viewStore.progress < 13 ? 13 : proxy.size.width * viewStore.progress
                                    let leading1 = leading > proxy.size.width - 13 ? proxy.size.width - 13 : leading
                                    Image("goal_point").padding(.leading, leading1 - 13)
                                }
                            }
                            Button(action: {viewStore.send(.reduce)}) {
                                Image("goal_+").frame(width: 26, height: 26)
                            }.background(Color("#8CD4FF"))
                        }.frame(width: 186).cornerRadius(13)
                        Spacer()
                    }.frame(height: 26).padding(.bottom, 20)
                }.padding(.leading, 20).background(Image("goal_bg").resizable()).padding(.horizontal, 20).padding(.top, 28)
                Spacer()
            }.navigationTitle("Water intake").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden().toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Button {
                        viewStore.send(.pop)
                    } label: {
                        Image("goal_back")
                    }
                })
            }
        }
    }
}
