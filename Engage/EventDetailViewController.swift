//
//  EventDetailViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTUIKit
import Former
import Parse
import MapKit
import CoreLocation

class EventDetailViewController: FormViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private var event: Event!
    enum AttendenceStatus: Int {
        case accepted = 0
        case interested = 1
        case declined = 2
    }
    private var currentUserStatus = AttendenceStatus.interested
    
    // MARK: Initialization
    
    convenience init(event: Event) {
        self.init()
        self.event = event
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Event Details"
        self.tableView.contentInset.top = 0
        self.tableView.contentInset.bottom = 30
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed))

        if self.event.organizer?.id == User.current().id {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Google.edit, style: .plain, target: self, action: #selector(editButtonPressed))
        }
        
        self.navigationController?.navigationBar.isTranslucent = false
        UIApplication.shared.statusBarStyle = .default
        
        self.configure()
    }
    
    // MARK: User actions
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func editButtonPressed(sender: AnyObject) {
        self.navigationController?.pushViewController(EditEventViewController(event: self.event), animated: true)
    }
    
    // MARK: Private
    
    private func configure() {
        self.former.append(sectionFormer: SectionFormer(rowFormers: [self.mapForEvent(), self.eventDetailRow(), self.choiceRow()]))
        
        if let acceptedUsers = self.event.accepted {
            var rows = [RowFormer]()
            for id in acceptedUsers {
                if let user = Cache.retrieveUser(id) {
                    rows.append(self.row(forUser: user))
                }
            }
            self.former.insertUpdate(sectionFormer: SectionFormer(rowFormers: rows), toSection: 1, rowAnimation: .fade)
        }
        
        if let interestedUsers = self.event.invites {
            var rows = [RowFormer]()
            for id in interestedUsers {
                if let user = Cache.retrieveUser(id) {
                    rows.append(self.row(forUser: user))
                }
            }
            self.former.insertUpdate(sectionFormer: SectionFormer(rowFormers: rows), toSection: 2, rowAnimation: .fade)
        }
    }
    
    private func row(forUser user: User) -> RowFormer {
        let userRow = LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.backgroundColor = Color.defaultNavbarTint
            $0.iconView.layer.borderWidth = 1
            $0.iconView.layer.borderColor = Color.defaultNavbarTint.cgColor
            $0.iconView.image = user.image
            $0.titleLabel.textColor = UIColor.black
            }.configure {
                $0.text = user.fullname
                $0.rowHeight = 60
            }.onSelected {_ in 
                self.former.deselect(animated: true)
                let profileVC = ProfileViewController(user: user)
                self.navigationController?.pushViewController(profileVC, animated: true)
        }
        return userRow
    }
    
    private func mapForEvent() -> RowFormer {
        let mapRow = CustomRowFormer<MapCell>(instantiateType: .Nib(nibName: "MapCell")) {
            if self.event.latitude != nil && self.event.longitude != nil {
                let anotation = MKPointAnnotation()
                anotation.coordinate = CLLocation(latitude: self.event.latitude!, longitude: self.event.latitude!).coordinate
                let latDelta:CLLocationDegrees = 0.015
                let lonDelta:CLLocationDegrees = 0.015
                let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
                let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(self.event.latitude!, self.event.latitude!)
                let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
                $0.mapView.addAnnotation(anotation)
                $0.mapView.setRegion(region, animated: true)
                $0.mapView.isScrollEnabled = true
                $0.mapView.isZoomEnabled = true
                $0.mapView.showsBuildings = true
            }
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = 200
        }
        return mapRow
    }
    
    private func eventDetailRow() -> RowFormer {
        let detailRow = CustomRowFormer<EventFeedCell> (instantiateType: .Nib(nibName: "EventFeedCell")) {
            $0.title.text = self.event.title
            $0.info.text = self.event.info
            $0.location.text = self.event.location
            $0.organizer.text = "Organizer: \(self.event.organizer!.fullname!)"
            $0.attendence.text = "\(self.event.accepted!.count) Confirmed, \(self.event.invites!.count - self.event.declined!.count) Interested"
            $0.time.text = String.mediumDateShortTime(date: self.event.start!) + "\n" + String.mediumDateShortTime(date: self.event.end!)
            if self.event.isAllDay {
                $0.time.text = "All-day Event"
            }
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        return detailRow
    }
    
    private func choiceRow() -> RowFormer {
        let row = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Will you attend?"
            $0.formSegmented().tintColor = Color.defaultNavbarTint
            $0.formSegmented().selectedSegmentIndex = self.currentUserStatus.rawValue
            }.configure {
                $0.segmentTitles = ["Yes", "Interested", "No"]
                $0.selectedIndex = self.currentUserStatus.rawValue
            }.onSegmentSelected { (index, choice) in
                
        }
        return row
    }
}

