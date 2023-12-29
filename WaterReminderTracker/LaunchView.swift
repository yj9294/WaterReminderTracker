//
//  LaunchView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/28.
//

import SwiftUI
import Combine
import GADUtil
import ComposableArchitecture

struct LaunchReducer: Reducer {
    enum CancelID {case timer}
    struct State: Equatable {
        var progress: Double = 0.0
        var duration = 12.5
    }
    enum Action: Equatable {
        case start
        case stop
        case updateProgress
        case launched
        case none
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
                let publisher = state.updateProgress()
                return .publisher {
                    publisher
                }
            default:
                break
            }
            return .none
        }
    }
}

extension LaunchReducer.State {
    
    mutating func updateProgress() -> AnyPublisher<LaunchReducer.Action, Never> {
        if progress == 1.0 {
            return Just(LaunchReducer.Action.none).eraseToAnyPublisher()
        }
        progress += 0.01 / duration
        if GADUtil.share.isLoaded(.open), progress > 0.23 {
            duration = 0.5
        }
        if progress > 1.0 {
            progress = 1.0
            let publisher = Future<LaunchReducer.Action, Never> { [progress = progress] promise in
                GADUtil.share.show(.open) { _ in
                    if progress == 1.0 {
                        promise(.success(.launched))
                    }
                }
            }
            let pub = publisher.merge(with:(Just(LaunchReducer.Action.stop).eraseToAnyPublisher()))
            return pub.eraseToAnyPublisher()
        }
        return Just(LaunchReducer.Action.none).eraseToAnyPublisher()
    }
    
    mutating func initState() {
        progress = 0.0
        duration = 12.5
        GADUtil.share.load(.interstitial)
        GADUtil.share.load(.open)
        GADUtil.share.load(.native)
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
            }.background(Image("launch_bg").resizable().scaledToFill().ignoresSafeArea()).onAppear(perform: {
                debugPrint("---------------------")
                viewStore.send(.start)
            })
        }
    }
}
