//
//  MessageViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import SlackTextViewController
import Parse

let DEBUG_CUSTOM_TYPING_INDICATOR = false

class ChannelViewController: SLKTextViewController {
    
    var timer: Timer = Timer()
    
    var channel: Channel!
    
    var channels = Engagement.current().channelNames
    var emojis = [String]()
    var commands = ["invite", "leave"]
    
    var searchResult: [String]?
    
    var pipWindow: UIWindow?
    
    override var tableView: UITableView {
        get {
            return super.tableView!
        }
    }
    
    // MARK: - Initializers
    public convenience init(channel: Channel) {
        self.init()
        self.channel = channel
    }
    
    
    // MARK: - Initialisation

    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        return .plain
    }
    
    func commonInit() {
        
        NotificationCenter.default.addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self,  selector: #selector(ChannelViewController.textInputbarDidMove(_:)), name: NSNotification.Name.SLKTextInputbarDidMove, object: nil)
        
        // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
        self.registerClass(forTextView: MessageTextView.classForCoder())
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
            self.registerClass(forTypingIndicatorView: TypingIndicatorView.classForCoder())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ChannelViewController.configureDataSource), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.textInputbar.textView.text = String()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = self.channel.isPrivate! ? self.channel.name : "#" + self.channel.name!
        self.commonInit()
        
        // Configuration
        self.configureDataSource()
        self.configureActionItems()
        
        // SLKTVC's configuration
        self.bounces = true
        self.shakeToClearEnabled = true
        self.isKeyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.isInverted = true
        
        //self.leftButton.setImage(Icon.Google.photoCamera, for: .normal)
        self.leftButton.tintColor = Color.defaultNavbarTint
        
        self.rightButton.setTitle("Send", for: .normal)
        self.rightButton.tintColor = Color.defaultNavbarTint
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 512
        self.textInputbar.counterStyle = .split
        self.textInputbar.counterPosition = .top
        self.textInputbar.backgroundColor = UIColor.groupTableViewBackground
        self.textInputbar.isTranslucent = false
        
        self.textInputbar.editorTitle.textColor = UIColor.black
        self.textInputbar.editorLeftButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        self.textInputbar.editorRightButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == false {
            self.typingIndicatorView!.canResignByTouch = true
        }
        
        self.tableView.backgroundColor = UIColor.groupTableViewBackground
        self.tableView.register(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: MessengerCellIdentifier)
        
        self.autoCompletionView.register(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: AutoCompletionCellIdentifier)
        self.registerPrefixes(forAutoCompletion: ["@",  "#", ":", "+:", "/"])
        
        self.textView.placeholder = "Send Message";
        
        self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Bold")
        self.textView.registerMarkdownFormattingSymbol("_", withTitle: "Italics")
        //self.textView.registerMarkdownFormattingSymbol("~", withTitle: "Strike")
        //self.textView.registerMarkdownFormattingSymbol("`", withTitle: "Code")
        //self.textView.registerMarkdownFormattingSymbol("```", withTitle: "Preformatted")
        //self.textView.registerMarkdownFormattingSymbol(">", withTitle: "Quote")
    }
    
    
    // MARK: - Lifeterm

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ChannelViewController {
    
    // MARK: - Load Messages from Server
    
    func configureDataSource() {
        
        if self.channel.isNew {
            self.channel.isNew = false
            self.tableView.reloadSections([0], with: .none)
            self.updateBadge()
        }
    }
    
    func updateBadge() {
        var counter = 0
        for chat in Engagement.current().chats {
            counter += chat.isNew ? 1 : 0
        }
        for channel in Engagement.current().myChannels {
            counter += channel.isNew ? 1 : 0
        }
        if counter == 0 {
            self.tabBarController?.tabBar.items?[4].badgeValue = nil
        } else {
            self.tabBarController?.tabBar.items?[4].badgeValue = String(counter)
        }
    }
    
    func configureActionItems() {
        
        //let arrowItem = UIBarButtonItem(image: UIImage(named: "icn_arrow_down"), style: .plain, target: self, action: #selector(MessageViewController.hideOrShowTextInputbar(_:)))
        //let typeItem = UIBarButtonItem(image: UIImage(named: "icn_typing"), style: .plain, target: self, action: #selector(ChannelViewController.simulateUserTyping(_:)))
        //let appendItem = UIBarButtonItem(image: UIImage(named: "icn_append"), style: .plain, target: self, action: #selector(MessageViewController.fillWithText(_:)))
        //let pipItem = UIBarButtonItem(image: UIImage(named: "icn_pic"), style: .plain, target: self, action: #selector(MessageViewController.togglePIPWindow(_:)))
        let infoItem = UIBarButtonItem(image: Icon.Apple.info, style: .plain, target: self, action: #selector(showGroupInfo))
        self.navigationItem.rightBarButtonItems = [infoItem]
    }
    
    // MARK: - Action Methods
    
    func hideOrShowTextInputbar(_ sender: AnyObject) {
        
        guard let buttonItem = sender as? UIBarButtonItem else {
            return
        }
        
        let hide = !self.isTextInputbarHidden
        let image = hide ? UIImage(named: "icn_arrow_up") : UIImage(named: "icn_arrow_down")
        
        self.setTextInputbarHidden(hide, animated: true)
        buttonItem.image = image
    }
    
    func fillWithText(_ sender: AnyObject) {
        
        if self.textView.text.characters.count == 0 {
            var sentences = Int(arc4random() % 4)
            if sentences <= 1 {
                sentences = 1
            }
            self.textView.text = "Sentences"
        }
        else {
            self.textView.slk_insertText(atCaretRange: " Word")
        }
    }
    
    func simulateUserTyping(_ sender: AnyObject) {
        
        if !self.canShowTypingIndicator() {
            return
        }
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            guard self.typingIndicatorProxyView is TypingIndicatorView else {
                return
            }
            
            let scale = UIScreen.main.scale
            _ = CGSize(width: kTypingIndicatorViewAvatarHeight*scale, height: kTypingIndicatorViewAvatarHeight*scale)
            
            // This will cause the typing indicator to show after a delay ¯\_(ツ)_/¯
            /*
            LoremIpsum.asyncPlaceholderImage(with: imgSize, completion: { (image) -> Void in
                guard let cgImage = image?.cgImage else {
                    return
                }
                let thumbnail = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
                view.presentIndicator(withName: LoremIpsum.name(), image: thumbnail)
            })
            */
        }
        else {
            self.typingIndicatorView!.insertUsername("Typing Name")
        }
    }
    
    func togglePIPWindow(_ sender: AnyObject) {
        
        if self.pipWindow == nil {
            self.showPIPWindow(sender)
        }
        else {
            self.hidePIPWindow(sender)
        }
    }
    
    func showPIPWindow(_ sender: AnyObject) {
        
        var frame = CGRect(x: self.view.frame.width - 60.0, y: 0.0, width: 50.0, height: 50.0)
        frame.origin.y = self.textInputbar.frame.minY - 60.0
        
        self.pipWindow = UIWindow(frame: frame)
        self.pipWindow?.backgroundColor = UIColor.black
        self.pipWindow?.layer.cornerRadius = 10
        self.pipWindow?.layer.masksToBounds = true
        self.pipWindow?.isHidden = false
        self.pipWindow?.alpha = 0.0
        
        UIApplication.shared.keyWindow?.addSubview(self.pipWindow!)
        
        UIView.animate(withDuration: 0.25, animations: { [unowned self] () -> Void in
            self.pipWindow?.alpha = 1.0
        }) 
    }
    
    func hidePIPWindow(_ sender: AnyObject) {
        
        UIView.animate(withDuration: 0.3, animations: { [unowned self] () -> Void in
            self.pipWindow?.alpha = 0.0
            }, completion: { [unowned self] (finished) -> Void in
                self.pipWindow?.isHidden = true
                self.pipWindow = nil
        }) 
    }
    
    func textInputbarDidMove(_ note: Notification) {
        
        guard let pipWindow = self.pipWindow else {
            return
        }
        
        guard let userInfo = (note as NSNotification).userInfo else {
            return
        }
        
        guard let value = userInfo["origin"] as? NSValue else {
            return
        }
        
        var frame = pipWindow.frame
        frame.origin.y = value.cgPointValue.y - 60.0
        
        pipWindow.frame = frame
    }
    
    func showGroupInfo() {
        guard let members = self.channel.members else {
            Toast.genericErrorMessage()
            return
        }
        guard let isPrivate = self.channel.isPrivate else {
            Toast.genericErrorMessage()
            return
        }
        if members.count <= 2 && isPrivate {
            var userId = String()
            if members[0] != User.current().id {
                userId = members[0]
            } else {
                userId = members[1]
            }
            guard let user = Cache.retrieveUser(userId) else {
                Toast.genericErrorMessage()
                return
            }
            let vc = ProfileViewController(user: user)
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        } else {
            let vc = EditChannelViewController(channel: self.channel)
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }
    
    func selectUserFromList(users: [User]) {
        
    }
}

extension ChannelViewController {
    
    // MARK: - Overriden Methods
    
    override func ignoreTextInputbarAdjustment() -> Bool {
        return super.ignoreTextInputbarAdjustment()
    }
    
    override func forceTextInputbarAdjustment(for responder: UIResponder!) -> Bool {
        
        if #available(iOS 8.0, *) {
            guard let _ = responder as? UIAlertController else {
                // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
                return UIDevice.current.userInterfaceIdiom == .pad
            }
            return true
        }
        else {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }
    
    // Notifies the view controller that the keyboard changed status.
    override func didChangeKeyboardStatus(_ status: SLKKeyboardStatus) {
        switch status {
        case .willShow:
            print("Will Show")
        case .didShow:
            print("Did Show")
        case .willHide:
            print("Will Hide")
        case .didHide:
            print("Did Hide")
        }
    }
    
    // Notifies the view controller that the text will update.
    override func textWillUpdate() {
        super.textWillUpdate()
    }
    
    // Notifies the view controller that the text did update.
    override func textDidUpdate(_ animated: Bool) {
        super.textDidUpdate(animated)
    }
    
    // Notifies the view controller when the left button's action has been triggered, manually.
    override func didPressLeftButton(_ sender: Any!) {
        super.didPressLeftButton(sender)
        
        Log.write(.status, "Did press left button")
        self.dismissKeyboard(true)
        
        /*
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let takePictureAction: UIAlertAction = UIAlertAction(title: "Take Photo", style: .default)
        { action -> Void in
            Camera.shouldStartCamera(target: self, canEdit: true, frontFacing: true)
        }
        actionSheetController.addAction(takePictureAction)
        let choosePictureAction: UIAlertAction = UIAlertAction(title: "Choose Photo", style: .default)
        { action -> Void in
            Camera.shouldStartPhotoLibrary(target: self, canEdit: true)
        }
        actionSheetController.addAction(choosePictureAction)
        
        
        let chooseVideoAction: UIAlertAction = UIAlertAction(title: "Choose Video", style: .default)
        { action -> Void in
            Camera.shouldStartVideoLibrary(target: self, canEdit: true)
        }
        actionSheetController.addAction(chooseVideoAction)
        
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        
        self.present(actionSheetController, animated: true, completion: nil)
        */
    }
    
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    override func didPressRightButton(_ sender: Any!) {
        
        // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
        self.textView.refreshFirstResponder()
        
        self.channel.addMessage(user: User.current(), text: self.textView.text, file: nil) { (success) in
            if success {
                let indexPath = IndexPath(row: 0, section: 0)
                let rowAnimation: UITableViewRowAnimation = self.isInverted ? .bottom : .top
                let scrollPosition: UITableViewScrollPosition = self.isInverted ? .bottom : .top
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [indexPath], with: rowAnimation)
                self.tableView.endUpdates()
                
                self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        super.didPressRightButton(sender)
    }
    
    override func keyForTextCaching() -> String? {
        
        return Bundle.main.bundleIdentifier
    }
    
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    override func didPasteMediaContent(_ userInfo: [AnyHashable: Any]) {
        
        super.didPasteMediaContent(userInfo)
        
        let mediaType = (userInfo[SLKTextViewPastedItemMediaType] as? NSNumber)?.intValue
        let contentType = userInfo[SLKTextViewPastedItemContentType]
        let data = userInfo[SLKTextViewPastedItemData]
        
        print("didPasteMediaContent : \(contentType) (type = \(mediaType) | data : \(data))")
    }
    
    // Notifies the view controller when a user did shake the device to undo the typed text
    override func willRequestUndo() {
        super.willRequestUndo()
    }
    
    // Notifies the view controller when tapped on the left "Cancel" button
    override func didCancelTextEditing(_ sender: Any) {
        super.didCancelTextEditing(sender)
    }
    
    override func canPressRightButton() -> Bool {
        return super.canPressRightButton()
    }
    
    override func canShowTypingIndicator() -> Bool {
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            return true
        }
        else {
            return super.canShowTypingIndicator()
        }
    }
    
    override func shouldProcessText(forAutoCompletion text: String) -> Bool {
        return true
    }
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        
        var array:Array<String> = []
        let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", word);
        
        self.searchResult = nil
        
        if prefix == "@" {
            guard let usernames = self.channel.usernames else {
                self.showAutoCompletionView(false)
                return
            }
            if word.characters.count > 0 {
                array = usernames.filter { wordPredicate.evaluate(with: $0) }
            }
            else {
                array = usernames
            }
        }
        else if prefix == "#" {
            guard let channels = self.channels else {
                self.showAutoCompletionView(false)
                return
            }
            if word.characters.count > 0 {
                array = channels.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                array = channels
            }
        }
        else if (prefix == ":" || prefix == "+:") && word.characters.count > 0 {
            array = self.emojis.filter { wordPredicate.evaluate(with: $0) };
        }
        else if prefix == "/" && self.foundPrefixRange.location == 0 {
            if word.characters.count > 0 {
                array = self.commands.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                array = self.commands
            }
        }

        var show = false
        
        if array.count > 0 {
            let sortedArray = array.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
            self.searchResult = sortedArray
            show = sortedArray.count > 0
        }
        
        self.showAutoCompletionView(show)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        
        guard let searchResult = self.searchResult else {
            return 0
        }
        
        let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAt: IndexPath(row: 0, section: 0))
        guard let height = cellHeight else {
            return 0
        }
        return height * CGFloat(searchResult.count)
    }
}

extension ChannelViewController {
    
    // MARK: - UITableViewDataSource Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView {
            return self.channel.messages.count
        }
        else {
            if let searchResult = self.searchResult {
                return searchResult.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            return self.messageCellForRowAtIndexPath(indexPath)
        }
        else {
            return self.autoCompletionCellForRowAtIndexPath(indexPath)
        }
    }
    
    func messageCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageTableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: MessengerCellIdentifier) as! MessageTableViewCell
        cell.titleLabel.textColor = UIColor.black
        cell.indexPath = indexPath
        cell.usedForMessage = false
        cell.transform = self.tableView.transform
 
        let index = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section) - indexPath.row - 1
        
        cell.titleLabel.text = self.channel.messages[index].user?.fullname
        cell.thumbnailView.image = self.channel.messages[index].user?.image
        cell.bodyLabel.font = UIFont.systemFont(ofSize: 14)
        cell.bodyLabel.attributedText = self.channel.messages[index].text?.parseAttributes().linkUsers(fromList: self.channel.usernames!)
    
        
        return cell
    }
    
    
    
    func autoCompletionCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageTableViewCell {
        
        let cell = self.autoCompletionView.dequeueReusableCell(withIdentifier: AutoCompletionCellIdentifier) as! MessageTableViewCell
        cell.indexPath = indexPath
        cell.selectionStyle = .default
        
        // Thumbnail view

        guard let searchResult = self.searchResult else {
            return cell
        }
        
        guard let prefix = self.foundPrefix else {
            return cell
        }
        
        var text = searchResult[(indexPath as NSIndexPath).row]
        
        if prefix == "#" {
            text = "#" + text
        } else if prefix == "@" {
            text = "@" + text
        }
        else if prefix == ":" || prefix == "+:" {
            text = ":\(text):"
        }
        
        cell.titleLabel.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView {
            let message = self.channel.messages[indexPath.row]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left
            
            let pointSize = MessageTableViewCell.defaultFontSize()
            
            let attributes = [
                NSFontAttributeName : UIFont.systemFont(ofSize: pointSize),
                NSParagraphStyleAttributeName : paragraphStyle
            ]
            
            var width = tableView.frame.width-kMessageTableViewCellAvatarHeight
            width -= 25.0
            
            let titleBounds = (message.user?.object.value(forKey: PF_USER_FULLNAME) as? NSString)?.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            let bodyBounds = (message.text! as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            if message.text?.characters.count == 0 {
                return 0
            }
            
            var height = titleBounds?.height ?? 44
            height += bodyBounds.height
            height += 40
            
            if height < kMessageTableViewCellMinimumHeight {
                height = kMessageTableViewCellMinimumHeight
            }
            
            return height
        }
        else {
            return kMessageTableViewCellMinimumHeight
        }
    }
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.autoCompletionView {
            
            guard let searchResult = self.searchResult else {
                return
            }
            
            var item = searchResult[(indexPath as NSIndexPath).row]
            
            if self.foundPrefix == "@" && self.foundPrefixRange.location == 0 {
                item += ":"
            }
            else if self.foundPrefix == ":" || self.foundPrefix == "+:" {
                item += ":"
            }
            
            item += " "
            
            self.acceptAutoCompletion(with: item, keepPrefix: true)
        }
    }
}

extension ChannelViewController {
    
    // MARK: - UIScrollViewDelegate Methods
    
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    /*
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.setTextInputbarHidden(false, animated: true)
    }
 
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.setTextInputbarHidden(false, animated: true)
    }
    */
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //self.setTextInputbarHidden(true, animated: true)
        super.scrollViewDidScroll(scrollView)
        
        self.dismissKeyboard(true)
    }
 
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
        // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
        self.textView.refreshFirstResponder()
        
        // Load Previous Messages
        /*
        if self.isLoading == false {
            self.isLoading = true
            
            SVProgressHUD.show(withStatus: "Loading Messages")
            let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_CHAT_CLASS_NAME)")
            query.whereKey(PF_CHAT_GROUPID, equalTo: groupId)
            query.includeKey(PF_CHAT_USER)
            query.order(byDescending: PF_CHAT_CREATEDAT)
            query.skip = skip
            query.limit = 50
            query.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) -> Void in
                if error == nil {
                    for object in (objects as [PFObject]!).reversed() {
                        let user = object[PF_CHAT_USER] as! PFUser
                        if !self.userIDs.contains(user.objectId!) {
                            // Downloads Profile Photo Once
                            print("Downloading Profile Photo for \(user.value(forKey: PF_USER_FULLNAME))")
                            self.userIDs.append(user.objectId!)
                            self.users.append(user[PF_USER_FULLNAME] as! String)
                            
                            let pictureFile = user[PF_USER_PICTURE] as? PFFile
                            if pictureFile != nil {
                                do {
                                    let imageData = try pictureFile!.getData()
                                    self.userPhotos.append(UIImage(data:imageData)!)
                                } catch {}
                            } else {
                                self.userPhotos.append(UIImage(named: "profile_blank")!)
                            }
                        }
                        
                        self.messages.insert(Message(text: object[PF_CHAT_TEXT] as! String, username: user.value(forKey: PF_USER_FULLNAME) as! String, user: user, date: object.createdAt!), at: self.tableView.numberOfRows(inSection: 0))
                    }
                    self.skip += 50
                    SVProgressHUD.dismiss()
                } else {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
                self.isLoading = false;
            })
        }
        
        let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [indexPath], with: .top)
        self.tableView.endUpdates()
        
        // Fixes the cell from blinking (because of the transform, when using translucent cells)
        // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        */
        print("Load more messages")
    }
    
}

extension ChannelViewController {
    
    // MARK: - UITextViewDelegate Methods
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    override func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
        return true
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return super.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
    
    override func textView(_ textView: SLKTextView, shouldOfferFormattingForSymbol symbol: String) -> Bool {
        
        if symbol == ">" {
            let selection = textView.selectedRange
            
            // The Quote formatting only applies new paragraphs
            if selection.location == 0 && selection.length > 0 {
                return true
            }
            
            // or older paragraphs too
            let prevString = (textView.text as NSString).substring(with: NSMakeRange(selection.location-1, 1))
            
            if CharacterSet.newlines.contains(UnicodeScalar((prevString as NSString).character(at: 0))!) {
                return true
            }
            
            return false
        }
        
        return super.textView(textView, shouldOfferFormattingForSymbol: symbol)
    }
    
    override func textView(_ textView: SLKTextView, shouldInsertSuffixForFormattingWithSymbol symbol: String, prefixRange: NSRange) -> Bool {
        
        if symbol == ">" {
            return false
        }
        
        return super.textView(textView, shouldInsertSuffixForFormattingWithSymbol: symbol, prefixRange: prefixRange)
    }
}
