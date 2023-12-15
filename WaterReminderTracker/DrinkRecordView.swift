//
//  DrinkRecordView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI
import ComposableArchitecture

struct DrinkRecordReducer: Reducer {
    struct Model: Codable, Hashable, Equatable {
        var id: String = UUID().uuidString
        var day: String // yyyy-MM-dd
        var time: String // HH:mm
        var item: State.Item // 列别
        var name: String
        var ml: Int // 毫升
    }
    
    struct State: Equatable {
        static func == (lhs: DrinkRecordReducer.State, rhs: DrinkRecordReducer.State) -> Bool {
            lhs.records == rhs.records && lhs.item == rhs.item && lhs.ml == rhs.ml && lhs.name == rhs.name
        }
        
        @UserDefault(key: "drink.records")
        var records: [Model]?
        
        let items = Item.allCases
        var item: Item = .water
        @BindingState var ml: String = "200"
        @BindingState var name: String = "Water"
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pop
        case item(State.Item)
        case saveButtonTapped
        case update([DrinkRecordReducer.Model])
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case .item(let item):
                state.item = item
                state.name = item.title
                state.ml = "200"
            case .saveButtonTapped:
                state.updateRecord()
                return .run { [records = state.recordsValue] send in
                    await send(.update(records))
                    await send(.pop)
                }
            default:
                break
            }
            return .none
        }
    }
}

extension DrinkRecordReducer.State {
    enum Item: String, Codable, CaseIterable {
        case water, drinks, coffee, tea, milk, custom
        var title: String{
            return self.rawValue.capitalized
        }
        var icon: String {
            return "record_" + self.rawValue
        }
    }
    var record: DrinkRecordReducer.Model {
        DrinkRecordReducer.Model(day: Date().day, time: Date().time, item: item, name: name, ml: Int(ml) ?? 0)
    }
    
    var recordsValue: [DrinkRecordReducer.Model] {
        records ?? []
    }
    
    mutating func updateRecord() {
        var recordsValue = self.recordsValue
        recordsValue.append(record)
        records = recordsValue
    }
}

struct DrinkRecordView: View {
    let store: StoreOf<DrinkRecordReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                VStack(alignment: .leading, spacing: 22){
                    VStack(alignment: .leading, spacing: 12){
                        Text("Selected Type").foregroundColor(.white.opacity(0.5)).font(.system(size: 18))
                        if viewStore.item == .custom {
                            TextField("", text: viewStore.$name).foregroundColor(.white).font(.system(size: 24))
                        } else {
                            Text(verbatim: viewStore.item.title).foregroundColor(.white).font(.system(size: 24))
                        }
                    }
                    VStack(alignment: .leading, spacing: 12){
                        Text("Current Goal").foregroundColor(.white.opacity(0.5)).font(.system(size: 18))
                        TextField("", text: viewStore.$ml).keyboardType(.numbersAndPunctuation).foregroundColor(.white).font(.system(size: 24))
                    }
                }.padding(.leading, 28).padding(.vertical, 24).background(Image("record_bg"))
                ScrollView{
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(viewStore.items, id: \.self) { item in
                            VStack{
                                VStack(spacing: 0){
                                    VStack(spacing: 5){
                                        Image(item.icon).frame(width: 67, height: 67)
                                        Text(item.title)
                                    }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 6).background(.white)
                                    HStack{
                                        Spacer()
                                        Text("200ml").foregroundStyle(.white).font(.system(size: 14.0))
                                        Spacer()
                                    }.padding(.vertical, 7).background(Color("#FFD74A"))
                                }.cornerRadius(8).onTapGesture {
                                    viewStore.send(.item(item))
                                }
                                Image("record_point").opacity(item == viewStore.item ? 1.0 : 0.0)
                            }
                        }
                    }
                    Button {
                        viewStore.send(.saveButtonTapped)
                    } label: {
                        Text("SAVE").font(.system(size: 24)).foregroundStyle(.white)
                    }.background(Image("record_button_bg")).padding(.top, 25)
                }.padding(.top, 20)
                Spacer()
            }.padding(.horizontal, 20)
                .background(Color("#F0F7FC")).navigationTitle("Record").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden().toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewStore.send(.pop)
                    } label: {
                        Image("goal_back")
                    }
                }
            }
        }
    }
}
