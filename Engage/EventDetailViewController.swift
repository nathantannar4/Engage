//
//  EventDetailViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import MapKit
import CoreLocation

class EventDetailViewController: FormViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: Public
    
    var event: PFObject?
    var organizer: PFUser?
    var currentUserStatus = 2
    var confirmedUsers = [PFObject]()
    var maybeUsers = [PFObject]()
    var invitedUsers = [PFObject]()
    var confirmedUserIDs = [String]()
    var maybeUserIDs = [String]()
    var invitedUserIDSs = [String]()
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Event Details"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 30
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(cancelButtonPressed))
        
        organizer = event?.object(forKey: PF_EVENTS_ORGANIZER) as? PFUser
        organizer!.fetchInBackground { (user: PFObject?, error: Error?) in
            if error == nil {
                self.insertEventDetail()
                for pointer in (self.event?.object(forKey: PF_EVENTS_CONFIRMED) as! [PFUser]) {
                    pointer.fetchInBackground(block: { (user: PFObject?, error: Error?) in
                        if error == nil {
                            if user?.objectId == PFUser.current()?.objectId {
                                self.currentUserStatus = 0
                                self.choiceRow.configure(handler: {
                                    $0.selectedIndex = self.currentUserStatus
                                })
                            }
                            self.confirmedUsers.append(user!)
                            self.confirmedUserIDs.append(user!.objectId!)
                            
                            if pointer == (self.event?.object(forKey: PF_EVENTS_CONFIRMED) as! [PFUser]).last {
                                // All users have been downloaded
                                self.insertUsers(users: self.confirmedUsers, header: "Going", section: 2)
                                if self.currentUserStatus == 0 {
                                    self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: 2), rowAnimation: .fade)
                                }
                            }
                        }
                    })
                }
                for pointer in (self.event?.object(forKey: PF_EVENTS_MAYBE) as! [PFUser]) {
                    pointer.fetchInBackground(block: { (user: PFObject?, error: Error?) in
                        if error == nil {
                            if user?.objectId == PFUser.current()?.objectId {
                                self.currentUserStatus = 1
                                self.choiceRow.configure(handler: {
                                    $0.selectedIndex = self.currentUserStatus
                                })
                            }
                            self.maybeUsers.append(user!)
                            self.maybeUserIDs.append(user!.objectId!)
                        
                            if pointer == (self.event?.object(forKey: PF_EVENTS_MAYBE) as! [PFUser]).last {
                                // All users have been downloaded
                                var section = 3
                                if self.former.sectionFormers.count < 2 {
                                    section = 2
                                }
                                self.insertUsers(users: self.maybeUsers, header: "Maybe", section: section)
                                if self.currentUserStatus == 1 {
                                    self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: section), rowAnimation: .fade)
                                }
                            }
                        }
                    })
                }
                for pointer in (self.event?.object(forKey: PF_EVENTS_INVITE_TO) as! [PFUser]) {
                    pointer.fetchInBackground(block: { (user: PFObject?, error: Error?) in
                        if error == nil {
                            self.invitedUsers.append(user!)
                            if pointer == (self.event?.object(forKey: PF_EVENTS_INVITE_TO) as! [PFUser]).last {
                                // All users have been downloaded
                                var section = 4
                                if self.former.sectionFormers.count == 2 {
                                    section = 3
                                } else if self.former.sectionFormers.count < 2 {
                                    section = 2
                                }
                                self.insertUsers(users: self.invitedUsers, header: "Invited", section: section)
                            }
                        }
                    })
                }
                if (self.event?.object(forKey: PF_EVENTS_CONFIRMED) as! [PFUser]).count == 0 {
                    self.insertEmpty(header: "Confirmed")
                }
                if (self.event?.object(forKey: PF_EVENTS_MAYBE) as! [PFUser]).count == 0 {
                    self.insertEmpty(header: "Maybe")
                }
                if (self.event?.object(forKey: PF_EVENTS_INVITE_TO) as! [PFUser]).count == 0 {
                    self.insertEmpty(header: "Invited")
                }
            }
        }
        
        if organizer?.objectId == PFUser.current()?.objectId {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonPressed))
        }
    }
    
    // MARK: Private
    
    private func insertUsers(users: [PFObject], header: String, section: Int) {
        var userRows = [LabelRowFormer<ProfileImageCell>]()
        for user in users {
            if user.objectId != PFUser.current()?.objectId {
                userRows.append(LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
                    $0.iconView.backgroundColor = MAIN_COLOR
                    $0.iconView.layer.borderWidth = 1
                    $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                    $0.iconView.image = UIImage(named: "profile_blank")
                    $0.iconView.file = user[PF_USER_PICTURE] as? PFFile
                    $0.iconView.loadInBackground()
                    $0.titleLabel.textColor = UIColor.black
                    }.configure {
                        $0.text = user[PF_USER_FULLNAME] as? String
                        $0.rowHeight = 60
                    }.onSelected { [weak self] _ in
                        self?.former.deselect(animated: true)
                        let profileVC = PublicProfileViewController()
                        profileVC.user = user
                        self?.navigationController?.pushViewController(profileVC, animated: true)
                    })
            }
        }
        self.former.insert(sectionFormer: (sectionFormer: SectionFormer(rowFormers: userRows).set(headerViewFormer: TableFunctions.createHeader(text: header))), toSection: section)
        self.former.reload()
    }
    
    private func insertEmpty(header: String) {
        let dividerRow = CustomRowFormer<DividerCell>(instantiateType: .Nib(nibName: "DividerCell")) {
            $0.divider.backgroundColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = 0
        }
        self.former.append(sectionFormer: (sectionFormer: SectionFormer(rowFormer: dividerRow).set(headerViewFormer: TableFunctions.createHeader(text: header))))
        self.former.reload()
    }
    
    private func insertEventDetail() {
        
        let lat = event?[PF_EVENTS_LATITUDE] as! Double
        let long = event?[PF_EVENTS_LONGITUDE] as! Double
        
        let mapRow = CustomRowFormer<MapCell>(instantiateType: .Nib(nibName: "MapCell")) {
            if lat != 0.0 {
                let anotation = MKPointAnnotation()
                anotation.coordinate = CLLocation(latitude: lat, longitude: long).coordinate
                let latDelta:CLLocationDegrees = 0.015
                let lonDelta:CLLocationDegrees = 0.015
                let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
                let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
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
        
        let dividerRow = CustomRowFormer<DividerCell>(instantiateType: .Nib(nibName: "DividerCell")) {
            $0.divider.backgroundColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = 8
        }
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: mapRow, eventDetailRow, dividerRow))
        self.former.append(sectionFormer: SectionFormer(rowFormer: choiceRow))
        self.former.reload()
        
        if currentUserStatus == 0 {
            self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: 2), rowAnimation: .fade)
        }
        else if currentUserStatus == 1 {
            self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: 3), rowAnimation: .fade)
        }
    }
    
    private lazy var eventDetailRow: CustomRowFormer<EventFeedCell> =  {
        CustomRowFormer<EventFeedCell> (instantiateType: .Nib(nibName: "EventFeedCell")) {
        $0.title.text = self.event![PF_EVENTS_TITLE] as? String
        $0.info.text = self.event![PF_EVENTS_INFO] as? String
        $0.location.text = self.event![PF_EVENTS_LOCATION] as? String
        $0.organizer.text = "Organizer: \(self.organizer![PF_USER_FULLNAME] as! String)"
        $0.attendence.text = "\(self.confirmedUsers.count) Confirmed, \(self.maybeUsers.count) Maybe"
        let startDate = self.event![PF_EVENTS_START] as! NSDate
        let endDate = self.event![PF_EVENTS_END] as! NSDate
        $0.time.text = "Starts: \(startDate.mediumString!) \nEnds: \(endDate.mediumString!)"
        if (self.event![PF_EVENTS_ALL_DAY] as! Bool) {
            $0.time.text = "Starts: \(startDate.mediumDateString!) \nEnds: \(endDate.mediumDateString!)"
        }
        }.configure {
            $0.rowHeight = UITableViewAutomaticDimension
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
        }
    }()

    
    private lazy var choiceRow: SegmentedRowFormer<FormSegmentedCell> = {
        SegmentedRowFormer<FormSegmentedCell>() {
        $0.titleLabel.text = "Will you attend?"
        $0.formSegmented().tintColor = MAIN_COLOR
        $0.formSegmented().selectedSegmentIndex = self.currentUserStatus
        }.configure {
            $0.segmentTitles = ["Yes", "Maybe", "No"]
            $0.selectedIndex = self.currentUserStatus
        }.onSegmentSelected { (index, choice) in
            if self.currentUserStatus != index {
                
                self.former.remove(rowFormer: self.newRow)
                self.former.reload(sections: NSIndexSet(indexesIn: NSRange(location: 2, length: 2)) as IndexSet)
                
                if index == 0 {
                    // User wants to go to the event
                    // Is there a stats change from 'Maybe'
                    if self.currentUserStatus == 1 {
                        let indexToRemove = self.maybeUserIDs.index(of: (PFUser.current())!.objectId!)
                        self.maybeUsers.remove(at: indexToRemove!)
                        self.maybeUserIDs.remove(at: indexToRemove!)
                        self.event![PF_EVENTS_MAYBE] = self.maybeUsers
                    }
                    self.confirmedUsers.append(PFUser.current()!)
                    self.confirmedUserIDs.append(PFUser.current()!.objectId!)
                    self.event![PF_EVENTS_CONFIRMED] = self.confirmedUsers
                    self.event!.saveInBackground()
                    
                    self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: 2), rowAnimation: .fade)
                }
                if index == 1 {
                    // User might go to the event event
                    // Is there a stats change from 'Yes'
                    if self.currentUserStatus == 0 {
                        let indexToRemove = self.confirmedUserIDs.index(of: (PFUser.current()!.objectId!))
                        self.confirmedUsers.remove(at: indexToRemove!)
                        self.confirmedUserIDs.remove(at: indexToRemove!)
                        self.event![PF_EVENTS_CONFIRMED] = self.confirmedUsers
                        
                        self.former.remove(rowFormer: self.newRow)
                    }
                    self.maybeUsers.append(PFUser.current()!)
                    self.maybeUserIDs.append(PFUser.current()!.objectId!)
                    
                    self.event![PF_EVENTS_MAYBE] = self.maybeUsers
                    self.event!.saveInBackground()
                    
                    self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: IndexPath(row: 0, section: 3), rowAnimation: .fade)
                }
                if index == 2 {
                    // User does not want to go
                    if self.currentUserStatus == 0 {
                        let indexToRemove = self.confirmedUserIDs.index(of: (PFUser.current()!.objectId!))
                        self.confirmedUsers.remove(at: indexToRemove!)
                        self.confirmedUserIDs.remove(at: indexToRemove!)
                        self.event![PF_EVENTS_CONFIRMED] = self.confirmedUsers
                    }
                    else if self.currentUserStatus == 1 {
                        let indexToRemove = self.maybeUserIDs.index(of: (PFUser.current()!.objectId!))
                        self.maybeUsers.remove(at: indexToRemove!)
                        self.maybeUserIDs.remove(at: indexToRemove!)
                        self.event![PF_EVENTS_MAYBE] = self.maybeUsers
                    }
                    self.event!.saveInBackground()
                }
            }
            
            self.currentUserStatus = index
            self.eventDetailRow.cellUpdate({
                $0.attendence.text = "\(self.confirmedUsers.count) Confirmed, \(self.maybeUsers.count) Maybe"
            })
        }
    }()


    private lazy var newRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.iconView.layer.borderWidth = 1
            $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
            $0.iconView.image = UIImage(named: "profile_blank")
            $0.iconView.file = PFUser.current()![PF_USER_PICTURE] as? PFFile
            $0.iconView.loadInBackground()
            $0.titleLabel.textColor = UIColor.black
            
            }.configure {
                $0.text = PFUser.current()?.value(forKey: "fullname") as? String
                $0.rowHeight = 60
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                let profileVC = PublicProfileViewController()
                profileVC.user = PFUser.current()
                self?.navigationController?.pushViewController(profileVC, animated: true)
        }
    }()
    
    // MARK: User actions
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func editButtonPressed(sender: AnyObject) {
        self.navigationController?.pushViewController(EditEventViewController(), animated: true)
    }
}

