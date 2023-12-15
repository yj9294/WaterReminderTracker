//
//  LaunchView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/28.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct LaunchReducer: Reducer {
    enum CancelID {case timer}
    struct State: Equatable {
        var progress: Double = 0.0
        var duration = 2.5
        var isLaunched = false
    }
    enum Action: Equatable {
        case start
        case stop
        case updateProgress
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .start:
                state.initState()
                let publiser = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().map{_ in LaunchReducer.Action.updateProgress}
                return .publisher {
                    publiser
                }.cancellable(id: CancelID.timer)
            case .stop:
                return .cancel(id: CancelID.timer)
            case .updateProgress:
                state.updateProgress()
            }
            return .none
        }
    }
}

extension LaunchReducer.State {
    
    mutating func updateProgress() {
        progress += 0.01 / duration
        if progress > 1.0 {
            progress = 1.0
            isLaunched = true
        }
    }
    
    mutating func initState() {
        progress = 0.0
        duration = 2.5
        isLaunched = false
    }
}


struct LaunchView: View {
    let store: StoreOf<LaunchReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                HStack{Spacer()}
                Spacer()
                Image("launch_title").padding(.bottom, 40)
                ProgressView(value: viewStore.progress, total: 1.0).tint(Color("#0BD9FF")).padding(.bottom, 20).padding(.horizontal, 42)
            }.background(Image("launch_bg").resizable().scaledToFill().ignoresSafeArea())
        }
    }
}