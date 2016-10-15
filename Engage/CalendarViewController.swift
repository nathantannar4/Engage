//
//  CalendarViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import SVProgressHUD

class CalendarViewController: UIViewController, CVCalendarViewDelegate, CVCalendarMenuViewDelegate, CVCalendarViewAppearanceDelegate {
    
    private let listView: UITableView = {
        let listView = UITableView(frame: CGRect.zero, style: .grouped)
        listView.backgroundColor = .clear
        listView.contentInset.bottom = 10
        listView.sectionHeaderHeight = 0
        listView.sectionFooterHeight = 0
        listView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        listView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        listView.translatesAutoresizingMaskIntoConstraints = false
        return listView
    }()
    
    private lazy var listFormer: Former = Former(tableView: self.listView)
    
    
    func setup() {
        view.insertSubview(listView, at: 0)
        let tableConstraints = [
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[table]-0-|",
                options: [],
                metrics: nil,
                views: ["table": listView]
            ),
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[table]-0-|",
                options: [],
                metrics: nil,
                views: ["table": listView]
            )
            ].flatMap { $0 }
        view.addConstraints(tableConstraints)
    }
    
    struct Color {
        static let selectedText = UIColor.white
        static let text = UIColor.black
        static let textDisabled = UIColor.gray
        static let selectionBackground = MAIN_COLOR
    }
    
    struct EventStruct {
        let day: Int!
        let object: PFObject!
    }
    
    // MARK: - Properties
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var tableView: UITableView!
    private lazy var former: Former = Former(tableView: self.tableView)
    
    var selectedDay:DayView!
    var currentDay = NSDate()
    
    var events = [EventStruct]()
    var eventDates = [Int]()
    
    var previewView = true
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(createEvent)), UIBarButtonItem(image: UIImage(named: "Feed"), style: .plain, target: self, action: #selector(switchView))]
        
        self.menuView.backgroundColor = MAIN_COLOR
        self.tableView.separatorStyle = .none
        
        self.setup()
        self.listView.isHidden = true
        
        self.navigationItem.title = CVDate(date: NSDate() as Date).globalDescription
        
        let currentMonth = currentDay.month
        while currentDay.month == currentMonth {
            currentDay = currentDay.subtractingDays(1) as NSDate
        }
        currentDay = (currentDay.addingDays(1) as NSDate).atStartOfDay() as NSDate
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.revealViewController().frontViewPosition.rawValue == 4 {
            self.revealViewController().revealToggle(self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshMonth()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if revealViewController() != nil {
            let menuButton = UIBarButtonItem()
            menuButton.image = UIImage(named: "ic_menu_black_24dp")
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.navigationItem.leftBarButtonItem = menuButton
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            tableView.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    func refreshMonth() {
        if self.former.sectionFormers.count > 0 {
            self.former.removeAll()
            self.former.reload()
        }
        self.events.removeAll()
        self.eventDates.removeAll()
        calendarView.contentController.refreshPresentedMonth()
        loadEvents()
    }
 
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    func loadEvents() {
        SVProgressHUD.show(withStatus: "Refreshing")
        let eventQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_EVENTS_CLASS_NAME)")
        eventQuery.order(byAscending: "start")
        eventQuery.whereKey("start", greaterThan: currentDay.subtractingHours(7))
        eventQuery.whereKey("start", lessThan: (currentDay.addingMonths(1) as NSDate).addingHours(17) as NSDate)
        eventQuery.includeKey(PF_EVENTS_ORGANIZER)
        eventQuery.findObjectsInBackground { (events: [PFObject]?, error: Error?) in
            SVProgressHUD.dismiss()
            if error == nil {
                for event in events! {
                    var eventDayStart = (event[PF_EVENTS_START] as! NSDate).day
                    let eventDayEnd = (event[PF_EVENTS_END] as! NSDate).day
                    // Event does not carry over to another month
                    if eventDayStart <= eventDayEnd {
                        while eventDayStart <= eventDayEnd {
                            let newEvent = EventStruct(day: eventDayStart, object: event)
                            self.events.append(newEvent)
                            self.eventDates.append(eventDayStart)
                            eventDayStart += 1
                        }
                    } else {
                        // Event carries over to the next month
                        while eventDayStart <= 31 {
                            let newEvent = EventStruct(day: eventDayStart, object: event)
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

    // MARK: - CVCalendarViewDelegate & CVCalendarMenuViewDelegate
    
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
        print("\(dayView.date.commonDescription) is selected!")
        selectedDay = dayView
        
        // Update table
        if self.former.sectionFormers.count > 0 {
            self.former.removeAll()
            self.former.reload()
        }
        var eventRows = [CustomRowFormer<EventPreviewCell>]()
        for event in events {
            if event.day == dayView.date.day {
                eventRows.append(CustomRowFormer<EventPreviewCell>(instantiateType: .Nib(nibName: "EventPreviewCell")) {
                    $0.titleLabel.text = event.object[PF_EVENTS_TITLE] as? String
                    $0.locationLabel.text = event.object[PF_EVENTS_LOCATION] as? String
                    $0.notesLabel.text = event.object[PF_EVENTS_INFO] as? String
                    if (event.object[PF_EVENTS_ALL_DAY] as! Bool) {
                        $0.startLabel.text = "All-Day"
                        $0.endLabel.text = (event.object[PF_EVENTS_START] as? NSDate)?.shortDateString
                    } else {
                        $0.startLabel.text = (event.object[PF_EVENTS_START] as? NSDate)?.shortTimeString
                        $0.endLabel.text = (event.object[PF_EVENTS_END] as? NSDate)?.shortTimeString
                    }
                    }.configure {
                        $0.rowHeight = UITableViewAutomaticDimension
                    }.onSelected { _ in
                        self.former.deselect(animated: true)
                        
                        let eventDetailVC = EventDetailViewController()
                        eventDetailVC.event = event.object
                        Event.sharedInstance.object = event.object
                        let navVC = UINavigationController(rootViewController: eventDetailVC)
                        navVC.navigationBar.barTintColor = MAIN_COLOR!
                        self.present(navVC, animated: true, completion: nil)
                    })
            }
        }
        if eventRows.count > 0 {
            self.former.append(sectionFormer: SectionFormer(rowFormers: eventRows).set(headerViewFormer: TableFunctions.createFooter(text: "Events That Day")))
            self.former.reload()
        }
    }
    
    func presentedDateUpdated(_ date: CVDate) {
        self.navigationItem.title = date.globalDescription
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
        let ringLineColour: UIColor = MAIN_COLOR!
        
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
        return MAIN_COLOR!
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
        case (_, .selected, _), (_, .highlighted, _): return Color.selectedText
        case (_, .in, _): return Color.text
        default: return Color.textDisabled
        }
    }
    
    func dayLabelBackgroundColor(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIColor? {
        switch (weekDay, status, present) {
        case (_, .selected, _), (_, .highlighted, _): return Color.selectionBackground
        default: return nil
        }
    }
    
    // MARK: - IB Actions
    
    func createEvent(sender: UIBarButtonItem) {
        
        let navVC = UINavigationController(rootViewController: CreateSimpleEventViewController())
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        self.present(navVC, animated: true, completion: nil)
        
        /*
        let actionSheetController: UIAlertController = UIAlertController(title: "Create Event", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let simple: UIAlertAction = UIAlertAction(title: "Simple", style: .default) { action -> Void in
            let navVC = UINavigationController(rootViewController: CreateSimpleEventViewController())
         navVC.navigationBar.barTintColor = MAIN_COLOR!
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(simple)
        
        let advanced: UIAlertAction = UIAlertAction(title: "Advanced", style: .default) { action -> Void in
            let navVC = UINavigationController(rootViewController: CreateAdvancedEventViewController())
         navVC.navigationBar.barTintColor = MAIN_COLOR!
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(advanced)
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
        */
    }
    
    func switchView(sender: AnyObject?) {
        
        if self.previewView {
            
            // Update table
            if self.listFormer.sectionFormers.count > 0 {
                self.listFormer.removeAll()
                self.listFormer.reload()
            }
            var eventRows = [CustomRowFormer<EventFeedCell>]()
            for event in events {
                eventRows.append(CustomRowFormer<EventFeedCell> (instantiateType: .Nib(nibName: "EventFeedCell")) {
                    $0.title.text = event.object[PF_EVENTS_TITLE] as? String
                    $0.info.text = event.object![PF_EVENTS_INFO] as? String
                    $0.location.text = event.object![PF_EVENTS_LOCATION] as? String
                    $0.organizer.text = "Organizer: \((event.object![PF_EVENTS_ORGANIZER] as? PFUser)?.value(forKey: PF_USER_FULLNAME) as! String)"
                    $0.attendence.text = "\((event.object![PF_EVENTS_CONFIRMED] as! [PFUser]).count) Confirmed, \((event.object![PF_EVENTS_MAYBE] as! [PFUser]).count) Maybe"
                    let startDate = event.object![PF_EVENTS_START] as! NSDate
                    let endDate = event.object![PF_EVENTS_END] as! NSDate
                    $0.time.text = "Starts: \(startDate.mediumString!) \nEnds: \(endDate.mediumString!)"
                    if (event.object![PF_EVENTS_ALL_DAY] as! Bool) {
                        $0.time.text = "Starts: \(startDate.mediumDateString!) \nEnds: \(endDate.mediumDateString!)"
                    }
                    }.configure {
                        $0.rowHeight = UITableViewAutomaticDimension
                    }.onSelected { _ in
                        
                        self.former.deselect(animated: true)
                        
                        let eventDetailVC = EventDetailViewController()
                        eventDetailVC.event = event.object
                        Event.sharedInstance.object = event.object
                        let navVC = UINavigationController(rootViewController: eventDetailVC)
                        navVC.navigationBar.barTintColor = MAIN_COLOR!
                        self.present(navVC, animated: true, completion: nil)
                    })
            }
            if eventRows.count > 0 {
                self.listFormer.append(sectionFormer: SectionFormer(rowFormers: eventRows).set(headerViewFormer: TableFunctions.createFooter(text: "Events This Month")))
                self.listFormer.reload()
            } else {
                let zeroRow = LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
                    }.configure {
                        $0.rowHeight = 0
                }
                self.listFormer.append(sectionFormer: SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createFooter(text: "No Events This Month")))
                self.listFormer.reload()
            }
            self.listView.isHidden = false
            self.calendarView.isHidden = true
            self.tableView.isHidden = true
            self.menuView.isHidden = true
            self.previewView = false
            
        } else {
            self.listView.isHidden = true
            self.calendarView.isHidden = false
            self.tableView.isHidden = false
            self.menuView.isHidden = false
            self.previewView = true
        }
    }
    
    func toggleMonthViewWithMonthOffset(offset: Int) {
        let calendar = NSCalendar.current
//        let calendarManager = calendarView.manager
        var components = Manager.componentsForDate(NSDate() as Date) // from today
        
        components.month! += offset
        
        let resultDate = calendar.date(from: components)!
        
        self.calendarView.toggleViewWithDate(resultDate)
    }
    
    func didShowNextMonthView(_ date: Date)
    {
//        let calendar = NSCalendar.currentCalendar()
//        let calendarManager = calendarView.manager
        let components = Manager.componentsForDate(date as Date) // from today
        currentDay = currentDay.addingMonths(1) as NSDate
        refreshMonth()
        print("Showing Month: \(components.month)")
    }
    
    
    func didShowPreviousMonthView(_ date: Date)
    {
//        let calendar = NSCalendar.currentCalendar()
//        let calendarManager = calendarView.manager
        let components = Manager.componentsForDate(date as Date) // from today
        currentDay = currentDay.subtractingMonths(1) as NSDate
        refreshMonth()
        print("Showing Month: \(components.month)")
    }
}
