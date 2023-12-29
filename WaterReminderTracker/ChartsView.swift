//
//  ChartsView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI
import GADUtil
import ComposableArchitecture

struct ChartsReducer: Reducer {
    struct Model: Codable, Hashable, Identifiable {
        var id: String = UUID().uuidString
        var progress: CGFloat
        var ml: Int
        var unit: String // 描述 类似 9:00 或者 Mon  或者03/01 或者 Jan
    }
    
    struct State: Equatable {
        static func == (lhs: ChartsReducer.State, rhs: ChartsReducer.State) -> Bool {
            lhs.records == rhs.records && lhs.item == rhs.item && lhs.adModel == rhs.adModel
        }
        
        @UserDefault(key: "drink.records")
        var records: [DrinkRecordReducer.Model]?
        let items: [Item] = Item.allCases
        var item: Item = .day
        var menusource: [Int] = Array(0..<7)
        var adModel: GADNativeViewModel = .none
    }
    enum Action: Equatable {
        case pushRecordHistoryView
        case item(State.Item)
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
    }
}

extension ChartsReducer.State {
    
    var recordsValue: [DrinkRecordReducer.Model] {
        records ?? []
    }
    
    var dataSource: [ChartsReducer.Model] {
        getDataSource()
    }
    
    var menusourceString: [String] {
        switch item {
        case .day:
             return menusource.map({
                "\($0 * 200)"
             }).reversed()
        case .week, .month:
            return menusource.map({
               "\($0 * 500)"
            }).reversed()
        case .year:
            return menusource.map({
               "\($0 * 500 * 30)"
            }).reversed()
        }
    }
    
    func getDataSource() -> [ChartsReducer.Model] {
        var max = 1
        // 数据源
        // 用于计算进度
        max = menusourceString.map({Int($0) ?? 0}).max { l1, l2 in
            l1 < l2
        } ?? 1
        switch item {
        case .day:
            return getDataUintSource().map({ time in
                let total = recordsValue.filter { model in
                    model.day == Date().day && time == model.time
                }.map({
                    $0.ml
                }).reduce(0, +)
                return ChartsReducer.Model(progress: Double(total)  / Double(max) , ml: total, unit: time)
            })
        case .week:
            return getDataUintSource().map { weeks in
                // 当前搜索目的周几 需要从周日开始作为下标0开始的 所以 unit数组必须是7123456
                let week = getDataUintSource().firstIndex(of: weeks) ?? 0
                
                // 当前日期 用于确定当前周
                let weekDay = Calendar.current.component(.weekday, from: Date())
                let firstCalendar = Calendar.current.date(byAdding: .day, value: 1-weekDay, to: Date()) ?? Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                // 目标日期
                let target = Calendar.current.date(byAdding: .day, value: week, to: firstCalendar) ?? Date()
                let targetString = dateFormatter.string(from: target)
                
                let total = recordsValue.filter { model in
                    model.day == targetString
                }.map({
                    $0.ml
                }).reduce(0, +)
                return ChartsReducer.Model(progress: Double(total)  / Double(max), ml: total, unit: weeks)
            }
        case .month:
            return getDataUintSource().reversed().map { date in
                let year = Calendar.current.component(.year, from: Date())
                
                let month = date.components(separatedBy: "/").first ?? "01"
                let day = date.components(separatedBy: "/").last ?? "01"
                
                let total = recordsValue.filter { model in
                    return model.day == "\(year)-\(month)-\(day)"
                }.map({
                    $0.ml
                }).reduce(0, +)
                
                return ChartsReducer.Model(progress: Double(total)  / Double(max), ml: total, unit: date)

            }
        case .year:
            return  getDataUintSource().reversed().map { month in
                let total = recordsValue.filter { model in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let date = formatter.date(from: model.day)
                    formatter.dateFormat = "MMM"
                    let m = formatter.string(from: date!)
                    return m == month
                }.map({
                    $0.ml
                }).reduce(0, +)
                return ChartsReducer.Model(progress: Double(total)  / Double(max), ml: total, unit: month)

            }
        }
    }
    
    func getDataUintSource() -> [String] {
        switch item {
        case .day:
            return recordsValue.filter { model in
                return model.day == Date().day
            }.compactMap { model in
                model.time
            }.reduce([]) { partialResult, element in
                return partialResult.contains(element) ?  partialResult : partialResult + [element]
            }
        case .week:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .month:
            var days: [String] = []
            for index in 0..<30 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd"
                let date = Date(timeIntervalSinceNow: TimeInterval(index * 24 * 60 * 60 * -1))
                let day = formatter.string(from: date)
                days.insert(day, at: 0)
            }
            return days
        case .year:
            var months: [String] = []
            for index in 0..<12 {
                let d = Calendar.current.date(byAdding: .month, value: -index, to: Date()) ?? Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let day = formatter.string(from: d)
                months.insert(day, at: 0)
            }
            return months
        }
    }
}

extension ChartsReducer.State {
    enum Item: String, Equatable, CaseIterable {
        case day, week, month, year
        var title: String {
            self.rawValue.uppercased()
        }
    }
}

struct ChartsView: View {
    let store: StoreOf<ChartsReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ScrollView{
                    VStack(spacing: 0){
                        HStack{
                            ButtonView(store: store)
                        }.padding(.vertical, 8).background(Color.white.cornerRadius(16)).padding(.all, 20)
                        ContentView(store: store).padding(.horizontal, 20)
                        Spacer()
                    }
                }
                Spacer()
                if viewStore.adModel != .none {
                    HStack{
                        GADNativeView(model: viewStore.adModel)
                    }.frame(height: 116).cornerRadius(12).padding(.horizontal, 20)
                }
            }
            .background(Color("#F0F7FC")).navigationTitle("Statistics").toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.pushRecordHistoryView)
                    } label: {
                        Image("charts_history")
                    }
                }
            }.onAppear {
                debugPrint("[view] charts出现了")
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
            }
        }
    }
    
    struct ButtonView: View {
        let store: StoreOf<ChartsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ForEach(viewStore.items, id:\.self) { item in
                    VStack{
                        if item == viewStore.item {
                            Text(verbatim: item.title).padding(.vertical, 14).padding(.horizontal, 20).foregroundStyle(.white).background(Color("#3CAEFF").cornerRadius(16))
                        } else {
                            Text(verbatim: item.title).padding(.vertical, 14).padding(.horizontal, 20).foregroundStyle(Color("#A6BFC8"))
                        }
                    }.font(.system(size: 12.0)).onTapGesture {
                        viewStore.send(.item(item))
                    }
                }
            }
        }
    }
    
    struct ContentView: View {
        let store: StoreOf<ChartsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                HStack(spacing: 0){
                    DataView(store: store)
                    MenuView(store: store)
                }
            }.background(Color.white.cornerRadius(18.0))
        }
    }
    
    struct MenuView: View {
        let store: StoreOf<ChartsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack(spacing: 0){
                    ForEach(viewStore.menusourceString, id: \.self) { item in
                        HStack{
                            Spacer()
                            Text(item).font(.system(size: 12.0))
                        }.foregroundColor(Color("#A6BFC8")).frame(width: 46,height: 54)
                    }
                }.padding(.trailing, 10).padding(.bottom, 38)
            }
        }
    }
    
    struct DataView: View {
        let store: StoreOf<ChartsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ZStack(alignment: .top){
                    VStack(spacing: 0){
                        ForEach(viewStore.menusource.indices, id: \.self) { _ in
                            Divider().frame(height: 54)
                        }
                    }.padding(.bottom, 38)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.flexible())]) {
                            ForEach(viewStore.dataSource, id: \.self) { item in
                                VStack(spacing: 0){
                                    VStack(spacing: 0){
                                        Color.clear
                                        LinearGradient(colors: [Color("#00DDFF"), Color("#3CAEFF")], startPoint: .top, endPoint: .bottom).cornerRadius(8).frame(height: 54 * 6 * item.progress)
                                    }.padding(.vertical, 27).frame(height: 54 * 7)
                                    Text(item.unit).padding(.bottom, 27).frame(height: 38).font(.system(size: 10.0)).foregroundColor(Color("#888996"))
                                }.frame(width: 27)
                            }
                        }
                    }.frame(height: 54 * 7 + 38)
                }
                .padding(.leading, 20)
            }
        }
    }
}

