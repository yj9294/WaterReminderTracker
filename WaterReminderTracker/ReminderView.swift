//
//  ReminderView.swift
//  WaterReminderTracker
//
//  Created by yangjian on 2023/11/29.
//

import SwiftUI
import GADUtil
import ComposableArchitecture

struct ReminderReducer: Reducer {
    struct State: Equatable {
        static func == (lhs: ReminderReducer.State, rhs: ReminderReducer.State) -> Bool {
            lhs.reminders == rhs.reminders && lhs.showDatePicker == rhs.showDatePicker && lhs.adModel == rhs.adModel
        }
        
        @UserDefault(key: "reminder")
        var reminders: [String]?
        
        var showDatePicker: Bool = false
        var picker: DatePickerReducer.State = .init()
        var adModel: GADNativeViewModel = .none
    }
    enum Action:Equatable {
        case newReminder
        case delete(String)
        case showDatePicker
        case hiddenDatePicker
        case picker(DatePickerReducer.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .delete(let item):
                state.deleteItem(item)
            case .showDatePicker:
                state.showDatePicker = true
            case .picker(.cancelButtonTapped):
                state.showDatePicker = false
            case let .picker(.dateSaveButtonTapped(item)):
                state.showDatePicker = false
                state.newItem(item)
            default:
                break
            }
            return .none
        }
        
        Scope(state: \.picker, action: /Action.picker) {
            DatePickerReducer()
        }
    }
}

extension ReminderReducer.State {
    mutating func deleteItem(_ item: String) {
        reminders = remindersValue.filter({
            $0 != item
        })
        NotificationHelper.shared.deleteNotifications(item)
    }
    
    mutating func newItem(_ item: String) {
        reminders = remindersValue.filter({
            $0 != item
        })
        reminders?.append(item)
        reminders = remindersValue.sorted(by: { l1, l2 in
            l1 < l2
        })
        NotificationHelper.shared.appendReminder(item)
    }
}

extension ReminderReducer.State {
    var remindersValue: [String] {
        reminders ?? ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00"]
    }
}

struct ReminderView: View {
    let store: StoreOf<ReminderReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ZStack{
                VStack{
                    List(viewStore.remindersValue.indices, id:\.self) { index in
                        VStack(spacing: 0){
                            HStack{
                                Text(viewStore.remindersValue[index]).padding(.all, 20).font(.system(size: 24.0))
                                Spacer()
                            }
                        }.frame(height: 72.0).swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button {
                                viewStore.send(.delete(viewStore.remindersValue[index]))
                            } label: {
                                Text("Delete")
                            }.tint(.red)
                        })
                    }
                    Spacer()
                    if viewStore.adModel != .none {
                        HStack{
                            GADNativeView(model: viewStore.adModel)
                        }.frame(height: 116).cornerRadius(12).padding(.horizontal, 20)
                    }
                    Spacer()
                }
                
                if viewStore.showDatePicker {
                    ZStack{
                        Color.black.opacity(0.3).ignoresSafeArea()
                        DatePickerView(store: store.scope(state: \.picker, action: ReminderReducer.Action.picker))
                            .frame(width: 343, height: 343)
                    }
                }
            }.onAppear{
                debugPrint("[view] reminder出现了")
                viewStore.remindersValue.forEach {
                    NotificationHelper.shared.appendReminder($0)
                }
                GADUtil.share.disappear(.native)
                GADUtil.share.load(.native)
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.showDatePicker)
                    } label: {
                        Image("reminder_new")
                    }
                }
            }
        }
    }
}

struct DatePickerReducer: Reducer {
    struct State: Equatable {}
    enum Action: Equatable {
        case dateSaveButtonTapped(String)
        case cancelButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DatePickerView: UIViewRepresentable {
    let store: StoreOf<DatePickerReducer>
    func makeUIView(context: Context) -> some UIView {
        if let view = Bundle.main.loadNibNamed("DatePickerView", owner: nil)?.first as? DateView {
            view.delegate = context.coordinator
           return view
        }
        let dateView = DateView()
        dateView.delegate = context.coordinator
        return dateView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DateViewDelegate {
        init(_ preview: DatePickerView) {
            self.parent = preview
        }
        let parent: DatePickerView
        
        func completion(time: String) {
            parent.store.send(.dateSaveButtonTapped(time))
        }
        
        func cancel() {
            parent.store.send(.cancelButtonTapped)
        }
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

protocol DateViewDelegate : NSObjectProtocol {
    func completion(time: String)
    func cancel()
}

class DateView: UIView {

    weak var delegate: DateViewDelegate?
    var selectedHours = 0
    var selectedMine = 0
    var hours:[Int] = Array(0..<13)
    var minu: [Int] = Array(0..<60)
    @IBOutlet weak var hourView: UIPickerView!
    @IBOutlet weak var minuView: UIPickerView!
    @IBOutlet weak var amLabel: UIButton!
    @IBOutlet weak var pmLabel: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        hours.append(contentsOf: Array(1..<12))
    }
    
    @IBAction func saveAction() {
        let str = String(format: "%02d:%02d", selectedHours, selectedMine)
        delegate?.completion(time: str)
    }
    
    @IBAction func cancelAction() {
        delegate?.cancel()
    }
}

extension DateView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == hourView {
            return hours.count
        }
        return minu.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 56.0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let view = view as? UIButton{
            view.isSelected = pickerView == hourView ? selectedHours == row : selectedMine == row
            view.titleLabel?.font = UIFont.systemFont(ofSize: 26)
            let str = String(format: "%02d", pickerView == hourView ? hours[row] : minu[row])
            view.setTitle(str, for: .normal)
            return view
        }
        let view = UIButton()
        view.isSelected = pickerView == hourView ? selectedHours == row : selectedMine == row
        view.setTitleColor(UIColor(named: "#2CB8FF"), for: .selected)
        view.setTitleColor(UIColor(named: "#AEBDC7"), for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 26)
        let str = String(format: "%02d", pickerView == hourView ? hours[row] : minu[row])
        view.setTitle(str, for: .normal)
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == hourView {
            selectedHours = row
        } else {
            selectedMine = row
        }
        if pickerView == hourView {
            if selectedHours < 13 {
                amLabel.isSelected = true
                pmLabel.isSelected = false
            } else {
                amLabel.isSelected = false
                pmLabel.isSelected = true
            }
        }
        pickerView.reloadComponent(0)
    }
}
