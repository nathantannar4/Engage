//
//  DelegatePackageViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/25/16.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import JSQWebViewController
import MapKit

class DelegatePackageViewController: FormViewController  {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 60
        title = "Delegate Package"
        
        configure()
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    let createInfo: ((String, String, (() -> Void)?) -> RowFormer) = { title, text, onSelected in
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = title
            $0.body = text
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = UIImage(named: "banff-park.jpg")
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                let agrume = Agrume(image: UIImage(named: "banff-park.jpg")!)
                agrume.showFrom(self)
            })
    }()
    
    private lazy var infoRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Welcome to WEC 2017"
            $0.body = "Welcome all delegates, sponsors, volunteers and observers to the Western Engineering Competition 2016. Over the following three days, all participants will have the opportunity to network with peers and working professionals, enjoy a warm social environment and compete in seven distinct engineering competitions. These competitions have been designed to break the boundaries of innovative thinking for all competitors, fostering a creative spark that will serve you throughout your respective careers. All of these activities provide attendees with a range of avenues for professional development, which we strongly encourage, as they offer opportunities for growth outside of those typically available through a core university education. In this train of thought, the spirit of WEC 2016 is breaking boundaries, for all delegates to add professional and personal growth beyond their current standing. Please take our invitation to explore every avenue of this professional event and enjoy the three days to their fullest.\n\n- Your WEC 2017 OC"
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
    }()
    
    private lazy var mapRow: CustomRowFormer<MapCell> = {
        CustomRowFormer<MapCell>(instantiateType: .Nib(nibName: "MapCell")) {
            /*
            let anotation = MKPointAnnotation()
            anotation.coordinate = CLLocation(latitude: self.business[PF_BUSINESS_LAT] as! Double, longitude: self.business[PF_BUSINESS_LONG] as! Double).coordinate
            anotation.title = self.business[PF_BUSINESS_NAME] as? String
            anotation.subtitle = self.business[PF_BUSINESS_INFO] as? String
            $0.mapView.addAnnotation(anotation)
            */
            let latitude = 51.1729518
            let longitude = -115.5661099
            let latDelta:CLLocationDegrees = 0.009
            let lonDelta:CLLocationDegrees = 0.009
            
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            
            let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            
            let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            
            $0.mapView.setRegion(region, animated: true)
            $0.selectionStyle = .none
        }.configure {
            $0.rowHeight = 400
        }
    }()
    
    private func configure() {
        let scheduleRow = self.createMenu("View Schedule") { [weak self] in
            self?.former.deselect(animated: true)
        }
        let schoolRow = self.createMenu("View Delegates by School") { [weak self] in
            self?.former.deselect(animated: true)
            //self?.navigationController?.pushViewController(ConferenceSchoolsTableViewController(), animated: true)
        }
        let fullMapRow = self.createMenu("View Map") { [weak self] in
            self?.former.deselect(animated: true)
        }
        
        let competitions = ["Senior Design", "Junior Design", "Re-Engineering", "Consulting Engineering", "Engineering Communications", "Impromptu Debate", "Innovative Design"]
        let competitionsInfo = ["Teams of four or third fourth year students are given twelve hours to design and construct a working prototype from given materials that can solve an engineering challenge. This challenge tests the competitors’ technical skills, as well as time management and teamwork. Teams present their solutions to judges using real-world justifications, then test the prototype according to the given functional requirements.", "Teams of four students are given four hours to solve an engineering problem using creativity and limited resources. These students are in their first or second year of engineering making this challenge a test of their intuition as engineers and ability to work under pressure. Following the building session, teams do a short presentation for the judges before testing their prototypes with the provided equipment.", "This challenge tests the competitors’ creativity and understanding of real world engineering problems. In eight hours, teams of two students are presented with a practical objective which must be accomplished by redesigning an existing product or process such that its functionality is improved or re-purposed. They present their solutions to a panel of judges, and are evaluated based on functionality, practicality, cost, and marketability.", "During the given time, teams of four must develop an economically feasible solution to a current real world problem. This challenge is the largest in scope of all competitions, and tests the students’ abilities in balancing ambition with practicality, technical capabilities with economics, and social benefits with environmental costs. Successful solutions will have considered every stage of the engineering design process.", "Competitors are asked to describe a technical subject in lay-man’s terms. They must consider the economic and environmental aspects of their subject, and provide a persuasive conclusion regarding the potential benefits, risks, or effect their subject has on the world.", "The Impromptu Debate category challenges participants to defend, from a given viewpoint, a topic disclosed just before the debate. Each team is composed of two members and they are expected to present a structured defense of the assigned non-technical topic. They are given just 10 minutes to prepare and will need to rely on their intelligence and wit to construct and deliver convincing arguments.", "This category can be one of the most technical categories at WEC. A team of 1-4 students must present a ground-breaking solution to a problem of their choosing, though it is encouraged to align with the theme. The solutions are expected to be fully researched, developed, and in most cases prototyped by the date of the competition. Many students have created their own businesses using their innovative designs. Students present their devices in a fair-like setting which is open to the public, and of course, judges."]
        var competitonRows = [RowFormer]()
        var index = 0
        while index <= competitions.count - 1 {
            competitonRows.append(self.createInfo(competitions[index], competitionsInfo[index]) { [weak self] in
                self?.former.deselect(animated: true)
            })
            competitonRows.append(self.createMenu("View Competitors") { [weak self] in
                self?.former.deselect(animated: true)
            })
            index += 1
        }
    
        let introSection = SectionFormer(rowFormer: onlyImageRow, infoRow, scheduleRow, schoolRow)
        let activitiesSection = SectionFormer(rowFormer: mapRow, fullMapRow).set(headerViewFormer: TableFunctions.createHeader(text: "Activities and Amenities"))
        
        let competitionSection = SectionFormer(rowFormers: competitonRows).set(headerViewFormer: TableFunctions.createHeader(text: "Competitions"))
        
        self.former.append(sectionFormer: introSection, activitiesSection, competitionSection)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
