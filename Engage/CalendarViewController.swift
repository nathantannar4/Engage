//
//  CalendarViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTUIKit
import Former
import Parse

class CalendarViewController: UIViewController, CVCalendarViewDelegate, CVCalendarMenuViewDelegate, CVCalendarViewAppearanceDelegate {
  
    struct EventStruct {
        let day: Int!
        let model: Event!
    }
    
    var calendarView: CVCalendarView = CVCalendarView()
    var menuView: CVCalendarMenuView = CVCalendarMenuView()
    var tableView: UITableView = UITableView()
    private lazy var former: Former = Former(tableView: self.tableView)
    
    var selectedDay:DayView!
    var currentDay = NSDate()
    
    var events = [EventStruct]()
    var eventDates = [Int]()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.menuView)
        self.view.addSubview(self.calendarView)
        self.view.addSubview(self.tableView)
        self.menuView.bindFrameToSuperviewTopBounds(withHeight: 50)
        self.calendarView.bindFrameToSuperviewTopBounds(withHeight: 350, withTopInset: 50)
        self.tableView.bindFrameToSuperviewBounds(withTopInset: 400)
        self.menuView.delegate = self
        self.calendarView.calendarDelegate = self
        self.calendarView.calendarAppearanceDelegate = self
        
        
        self.setTitleView(title: "Events", subtitle: CVDate(date: NSDate() as Date).globalDescription, titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
        self.menuView.backgroundColor = Color.defaultNavbarTint
        self.tableView.separatorStyle = .none
        
        let currentMonth = currentDay.month
        while currentDay.month == currentMonth {
            currentDay = currentDay.subtractingDays(1) as NSDate
        }
        
        self.currentDay = (currentDay.addingDays(1) as NSDate).atStartOfDay() as NSDate
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createEvent))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshMonth()
    }

    func refreshMonth() {
        if self.former.sectionFormers.count > 0 {
            self.former.removeAllUpdate(rowAnimation: .fade)
        }
        self.events.removeAll()
        self.eventDates.removeAll()
        self.calendarView.contentController.refreshPresentedMonth()
        self.loadEvents()
    }
 
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.calendarView.commitCalendarViewUpdate()
        self.menuView.commitMenuViewUpdate()
    }
    
    // MARK: User Actions
    
    func createEvent() {
        let navVC = UINavigationController(rootViewController: EditEventViewController())
        self.present(navVC, animated: true, completion: nil)
    }
    
    // MARK: Backend
    
    func loadEvents() {
        let eventQuery = PFQuery(className: Engagement.current().queryName! + PF_EVENT_CLASS_NAME)
        eventQuery.order(byAscending: PF_EVENT_START)
        eventQuery.whereKey(PF_EVENT_START, greaterThan: currentDay.subtractingHours(7))
        eventQuery.whereKey(PF_EVENT_START, lessThan: (currentDay.addingMonths(1) as NSDate).addingHours(17) as NSDate)
        eventQuery.includeKey(PF_EVENT_ORGANIZER)
        eventQuery.findObjectsInBackground { (events: [PFObject]?, error: Error?) in
            if error == nil {
                for event in events! {
                    var eventDayStart = (event[PF_EVENT_START] as! NSDate).day
                    let eventDayEnd = (event[PF_EVENT_END] as! NSDate).day
                    // Event does not carry over to another month
                    if eventDayStart <= eventDayEnd {
                        while eventDayStart <= eventDayEnd {
                            let newEvent = EventStruct(day: eventDayStart, model: Event(fromObject: event))
                            self.events.append(newEvent)
                            self.eventDates.append(eventDayStart)
                            eventDayStart += 1
                        }
                    } else {
                        // Event carries over to the next month
                        while eventDayStart <= 31 {
                            let newEvent = EventStruct(day: eventDayStart, model: Event(fromObject: event))
                            self.events.append(newEvent)
                            self.eventDates.append(eventDayStart)
                            eventDayStart += 1
                        }
                    }
                }
                self.calendarView.contentController.refreshPresentedMonth()
            }
        }
    }

    // MARK: CVCalendarViewDelegate & CVCalendarMenuViewDelegate
    
    /// Required method to implement!
    func presentationMode() -> CalendarMode {
        return .monthView
    }
    
    /// Required method to implement!
    func firstWeekday() -> Weekday {
        return .sunday
    }
    
    // MARK: Optional methods
    
    func dayOfWeekTextColor(by weekday: Weekday) -> UIColor {
        return UIColor.white
    }
    
    func shouldShowWeekdaysOut() -> Bool {
        return false
    }
    
    func shouldAnimateResizing() -> Bool {
        return false // Default value is true
    }
    
    private func shouldSelectDayView(dayView: DayView) -> Bool {
        // Allows disabling of cells (days)
        return true
    }
    
    func didSelectDayView(_ dayView: CVCalendarDayView, animationDidFinish: Bool) {
        self.selectedDay = dayView
        
        // Update table
        self.former.removeAllUpdate(rowAnimation: .fade)
        
        var eventRows = [CustomRowFormer<EventPreviewCell>]()
        for event in events {
            if event.day == dayView.date.day {
                eventRows.append(CustomRowFormer<EventPreviewCell>(instantiateType: .Nib(nibName: "EventPreviewCell")) {
                    $0.titleLabel.text = event.model.title
                    $0.locationLabel.text = event.model.location
                    $0.notesLabel.text = event.model.info
                    if (event.model.isAllDay) {
                        $0.startLabel.text = "All-Day"
                        $0.endLabel.text = String.mediumDateNoTime(date: event.model.start!)
                    } else {
                        $0.startLabel.text = String.mediumDateShortTime(date: event.model.start!)
                        $0.endLabel.text = String.mediumDateShortTime(date: event.model.end!)
                    }
                    }.configure {
                        $0.rowHeight = UITableViewAutomaticDimension
                    }.onSelected { _ in
                        self.former.deselect(animated: true)
                        let navVC = UINavigationController(rootViewController: EventDetailViewController(event: event.model))
                        self.present(navVC, animated: true, completion: nil)
                    })
            }
        }
        if eventRows.count > 0 {
            self.former.insertUpdate(sectionFormer: SectionFormer(rowFormers: eventRows), toSection: 0, rowAnimation: .fade)
        }
    }
    
    func presentedDateUpdated(_ date: CVDate) {
        self.setTitleView(title: "Events", subtitle: date.globalDescription, titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
    }
    
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
    
    func dotMarker(shouldShowOnDayView dayView: CVCalendarDayView) -> Bool {
        if dayView.date != nil {
            let day = dayView.date.day
            
            if self.eventDates.contains(day) {
                return true
            }
        }
        
        return false
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        
        let color = UIColor.black
        
        let day = dayView.date.day
        var numberOfDots = 0
        for index in 0..<self.eventDates.count {
            if day == self.eventDates[index] {
                numberOfDots += 1
            }
        }
        switch(numberOfDots) {
        case 2:
            return [color, color]
        case 3:
            return [color, color, color]
        default:
            return [color] // return 1 dot
        }
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }

    func dotMarker(sizeOnDayView dayView: DayView) -> CGFloat {
        return 13
    }

    
    func weekdaySymbolType() -> WeekdaySymbolType {
        return .short
    }
    
    func selectionViewPath() -> ((CGRect) -> (UIBezierPath)) {
        return { UIBezierPath(rect: CGRect(x: 0, y: 0, width: $0.width, height: $0.height)) }
    }
    
    func shouldShowCustomSingleSelection() -> Bool {
        return false
    }

    func preliminaryView(viewOnDayView dayView: DayView) -> UIView {
        let circleView = CVAuxiliaryView(dayView: dayView, rect: dayView.bounds, shape: CVShape.circle)
        circleView.fillColor = .colorFromCode(0xCCCCCC)
        return circleView
    }
    
    func preliminaryView(shouldDisplayOnDayView dayView: DayView) -> Bool {
        if (dayView.isCurrentDay) {
            return true
        }
        return false
    }
    
    func supplementaryView(viewOnDayView dayView: DayView) -> UIView {
        let π = M_PI
        
        let ringSpacing: CGFloat = 3.0
        let ringInsetWidth: CGFloat = 1.0
        let ringVerticalOffset: CGFloat = 1.0
        var ringLayer: CAShapeLayer!
        let ringLineWidth: CGFloat = 4.0
        let ringLineColour: UIColor = Color.defaultNavbarTint
        
        let newView = UIView(frame: dayView.bounds)
        
        let diameter: CGFloat = (newView.bounds.width) - ringSpacing
        let radius: CGFloat = diameter / 2.0
        
        let rect = CGRect(x: newView.frame.midX-radius, y: newView.frame.midY-radius-ringVerticalOffset, width: diameter, height: diameter)
        
        ringLayer = CAShapeLayer()
        newView.layer.addSublayer(ringLayer)
        
        ringLayer.fillColor = nil
        ringLayer.lineWidth = ringLineWidth
        ringLayer.strokeColor = ringLineColour.cgColor
        
        let ringLineWidthInset: CGFloat = CGFloat(ringLineWidth/2.0) + ringInsetWidth
        let ringRect: CGRect = rect.insetBy(dx: ringLineWidthInset, dy: ringLineWidthInset)
        let centrePoint: CGPoint = CGPoint(x: ringRect.midX, y: ringRect.midY)
        let startAngle: CGFloat = CGFloat(-π/2.0)
        let endAngle: CGFloat = CGFloat(π * 2.0) + startAngle
        let ringPath: UIBezierPath = UIBezierPath(arcCenter: centrePoint, radius: ringRect.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        ringLayer.path = ringPath.cgPath
        ringLayer.frame = newView.layer.bounds
        
        return newView
    }
    
    func supplementaryView(shouldDisplayOnDayView dayView: DayView) -> Bool {
        if dayView.date != nil {
            let day = dayView.date.day
            
            if self.eventDates.contains(day) {
                return true
            }
        }
        
        return false
    }
    
    func dayOfWeekTextColor() -> UIColor {
        return UIColor.white
    }
    
    func dayOfWeekBackGroundColor() -> UIColor {
        return Color.defaultNavbarTint
    }
    
    // MARK: - CVCalendarViewAppearanceDelegate

    func dayLabelPresentWeekdayInitallyBold() -> Bool {
        return false
    }
    
    func spaceBetweenDayViews() -> CGFloat {
        return 2
    }
    
    func dayLabelFont(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIFont {
        return UIFont.systemFont(ofSize: 14)
    }
    
    func dayLabelColor(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIColor? {
        switch (weekDay, status, present) {
        case (_, .selected, _), (_, .highlighted, _): return Color.defaultTitle
        case (_, .in, _): return Color.defaultSubtitle
        default: return UIColor.black
        }
    }
    
    func dayLabelBackgroundColor(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIColor? {
        switch (weekDay, status, present) {
        case (_, .selected, _), (_, .highlighted, _): return Color.defaultNavbarTint
        default: return nil
        }
    }
    
    func toggleMonthViewWithMonthOffset(offset: Int) {
        let calendar = NSCalendar.current
        var components = Manager.componentsForDate(Date())
        
        components.month! += offset
        
        let resultDate = calendar.date(from: components)!
        
        self.calendarView.toggleViewWithDate(resultDate)
    }
    
    func didShowNextMonthView(_ date: Date) {
        self.currentDay = currentDay.addingMonths(1) as NSDate
        self.refreshMonth()
    }
    
    
    func didShowPreviousMonthView(_ date: Date) {
        self.currentDay = currentDay.subtractingMonths(1) as NSDate
        self.refreshMonth()
    }
}
