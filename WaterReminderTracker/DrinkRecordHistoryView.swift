//
//  DrinkRecordHistoryView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI
import ComposableArchitecture

struct DrinkRecordHistoryReducer: Reducer {
    struct State: Equatable {
        static func == (lhs: DrinkRecordHistoryReducer.State, rhs: DrinkRecordHistoryReducer.State) -> Bool {
            lhs.records == rhs.records
        }
        
        @UserDefault(key: "drink.records")
        var records: [DrinkRecordReducer.Model]?
    }
    enum Action: Equatable {
        case pop
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

extension DrinkRecordHistoryReducer.State {
    var recordValue: [DrinkRecordReducer.Model] {
        records ?? []
    }
    
    var recordsSouce: [[DrinkRecordReducer.Model]] {
        return recordValue.reduce([]) { (result, item) -> [[DrinkRecordReducer.Model]] in
            var result = result
            if result.count == 0 {
                result.append([item])
            } else {
                if var arr = result.last, let lasItem = arr.last, lasItem.day == item.day  {
                    arr.append(item)
                    result[result.count - 1] = arr
                } else {
                    result.append([item])
                }
            }
           return result
        }.reversed()
    }
}

struct DrinkRecordHistoryView: View {
    let store: StoreOf<DrinkRecordHistoryReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ScrollView{
                VStack{
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(viewStore.recordsSouce, id: \.self) { records in
                            VStack(alignment: .leading){
                                HStack(spacing: 10){
                                    Image("history_date").padding(.leading, 14)
                                    Text(verbatim: records.first?.day ?? "").foregroundStyle(Color("#B0B1BD")).font(.system(size: 13.0))
                                }
                                LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                                    ForEach(records, id: \.self) { record in
                                        HStack(spacing: 10){
                                            Image(record.item.icon).resizable().frame(width: 40, height: 40).padding(.vertical, 6)
                                            Text(record.name).font(.system(size: 12)).foregroundStyle(Color("#245160"))
                                            Spacer()
                                            Text("\(record.ml)ml").padding(.trailing,3).font(.system(size: 14)).foregroundStyle(.black)
                                        }.padding(.horizontal, 14).background(Color("#F2FCFF"))
                                    }
                                }.padding(.all, 14)
                            }.padding(.vertical, 12).background(.white).cornerRadius(18)
                        }
                    }
                    Spacer()
                }
            }
            .padding(.all, 16)
            .background(Color("#F0F7FC")).navigationTitle("History").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden().toolbar {
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
