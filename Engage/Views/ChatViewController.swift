//
//  ChatViewController.swift
//  SwiftExample
//
//  Created by Dan Leonard on 5/11/16.
//  Copyright © 2016 MacMeDan. All rights reserved.
//

import NTComponents
import Parse
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var timer = Timer()
    var isLoading: Bool = false
    
    var users = [PFUser]()
    var channel: Channel?
    var messages = [JSQMessage]()
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    
    var bubbleFactory = JSQMessagesBubbleImageFactory() //(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: .zero)
    var outgoingBubbleImage: JSQMessagesBubbleImage!
    var incomingBubbleImage: JSQMessagesBubbleImage!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = User.current()?.id
        senderDisplayName = User.current()?.fullname
        
        
        outgoingBubbleImage = bubbleFactory?.outgoingMessagesBubbleImage(with: Color.Default.Tint.View)
        incomingBubbleImage = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
        let sendButton = NTButton()
        sendButton.image = Icon.Send
        sendButton.tintColor = .white
        sendButton.layer.cornerRadius = 8
        
        inputToolbar.contentView.rightBarButtonItem = sendButton
        inputToolbar.contentView.leftBarButtonItemWidth = 0

        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView.collectionViewLayout.springinessEnabled = false
        automaticallyScrollsToMostRecentMessage = true
        
        loadMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ChatViewController.loadMessages), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    // Mark: - Backend methods
    
    func loadMessages() {
        if self.isLoading == false {
            self.isLoading = true
            
            guard let query = channel?.messages?.query() else {
                return
            }
            if let lastMessage = messages.last {
                query.whereKey(PF_CHAT_CREATEDAT, greaterThan: lastMessage.date)
            }
            query.includeKey(PF_CHAT_USER)
            query.order(byDescending: PF_CHAT_CREATEDAT)
            query.limit = 200
            
            query.findObjectsInBackground { (objects, error) in
                guard let objects = objects else {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                    return
                }
                
                let messages = objects.reversed().map({ (object) -> Message in
                    let message = Message(object)
                    message.channel = self.channel
                    return message
                })
                for message in messages {
                    self.addMessage(message)
                }
                self.finishReceivingMessage()
                self.isLoading = false
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    func addMessage(_ message: Message) {
        var jsqMessage: JSQMessage!
        
        let videoFile = message.object[PF_CHAT_VIDEO] as? PFFile
        let pictureFile = message.object[PF_CHAT_PICTURE] as? PFFile
        
        
        if videoFile == nil && pictureFile == nil {
            jsqMessage = JSQMessage(senderId: message.userPointer?.objectId, senderDisplayName: message.userPointer?.value(forKey: PF_USER_FULLNAME) as! String, date: message.createdAt, text: message.text)
        }
        
//        if let videoFile = videoFile {
//            let mediaItem = JSQVideoMediaItem(fileURL: NSURL(string: videoFile.url!), isReadyToPlay: true)
//            mediaItem.appliesMediaViewMaskAsOutgoing = (user.objectId == self.senderId)
//            jsqMessage = JSQMessage(senderId: user.objectId, senderDisplayName: name, date: object.createdAt, media: mediaItem)
//        }
//        
//        if let pictureFile = pictureFile {
//            let mediaItem = JSQPhotoMediaItem(image: nil)
//            mediaItem.appliesMediaViewMaskAsOutgoing = (user.objectId == self.senderId)
//            jsqMessage = JSQMessage(senderId: user.objectId, senderDisplayName: name, date: object.createdAt, media: mediaItem)
//            
//            pictureFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
//                if error == nil {
//                    mediaItem.image = UIImage(data: imageData!)
//                    self.collectionView.reloadData()
//                }
//            })
//        }
        
        users.append(message.userPointer!)
        messages.append(jsqMessage)
    }
    
    func sendMessage(text: String, video: NSURL?, picture: UIImage?) {
        let newText = text
//        var videoFile: PFFile!
//        var pictureFile: PFFile!
        
//        if let video = video {
//            newText = "[Video message]"
//            videoFile = PFFile(name: "video.mp4", data: NSFileManager.defaultManager().contentsAtPath(video.path!)!)
//            
//            videoFile.saveInBackgroundWithBlock({ (succeeed: Bool, error: NSError?) -> Void in
//                if error != nil {
//                    print("Network error")
//                }
//            })
//        }
//        
//        if let picture = picture {
//            newText = "[Picture message]"
//            pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(picture, 0.6)!)
//            pictureFile.saveInBackgroundWithBlock({ (suceeded: Bool, error: NSError?) -> Void in
//                if error != nil {
//                    print("Picture save error")
//                }
//            })
//        }
        
        channel?.addMessage(User.current()!, text: newText)
        
        loadMessages()
        
//        if let videoFile = videoFile {
//            object[PF_CHAT_VIDEO] = videoFile
//        }
//        if let pictureFile = pictureFile {
//            object[PF_CHAT_PICTURE] = pictureFile
//        }
        
//        PushNotication.sendPushNotificationMessage(groupId, text: "\(PFUser.currentUser()!.valueForKey("fullname")!): \(text)")
        
        self.finishSendingMessage()
    }
    
    // MARK: - JSQMessagesViewController method overrides
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        self.sendMessage(text: text, video: nil, picture: nil)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.view.endEditing(true)
        
        //Create the AlertController
//        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
//        
//        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
//            //Just dismiss the action sheet
//        }
//        actionSheetController.addAction(cancelAction)
//        let takePictureAction: UIAlertAction = UIAlertAction(title: "Take Photo", style: .Default)
//        { action -> Void in
//            Camera.shouldStartCamera(self, canEdit: true, frontFacing: true)
//        }
//        actionSheetController.addAction(takePictureAction)
//        let choosePictureAction: UIAlertAction = UIAlertAction(title: "Choose Photo", style: .Default)
//        { action -> Void in
//            Camera.shouldStartPhotoLibrary(self, canEdit: true)
//        }
//        actionSheetController.addAction(choosePictureAction)
//        let chooseVideoAction: UIAlertAction = UIAlertAction(title: "Choose Video", style: .Default)
//        { action -> Void in
//            Camera.shouldStartVideoLibrary(self, canEdit: true)
//        }
//        actionSheetController.addAction(chooseVideoAction)
//        
//        //Present the AlertController
//        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - JSQMessages CollectionView DataSource
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            return outgoingBubbleImage
        }
        return incomingBubbleImage
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let user = self.users[indexPath.item]
        if self.avatars[user.objectId!] == nil {
            let thumbnailFile = user[PF_USER_PICTURE] as? PFFile
            thumbnailFile?.getDataInBackground(block: { (imageData: Data?, error: Error?) -> Void in
                if error == nil {
                    self.avatars[user.objectId!] = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: imageData!), diameter: 30)
                    self.collectionView.reloadData()
                }
            })
            return JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: "", backgroundColor: Color.Default.Tint.View.darker(), textColor: .white, font: Font.Default.Body.withSize(12), diameter: 20)
        } else {
            return self.avatars[user.objectId!]
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            return nil
        }
        
        if indexPath.item > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return nil
    }
    
    // MARK: - UICollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    // MARK: - UICollectionView flow layout
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            return 0
        }
        
        if indexPath.item > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return 0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0
    }
    
    // MARK: - Responding to CollectionView tap events
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("didTapLoadEarlierMessagesButton")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        print("didTapAvatarImageview")
        
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("didTapMessageBubble")
//        let message = self.messages[indexPath.item]
//        if message.isMediaMessage {
//            if let mediaItem = message.media as? JSQVideoMediaItem {
//                let moviePlayer = MPMoviePlayerViewController(contentURL: mediaItem.fileURL)
//                self.presentMoviePlayerViewControllerAnimated(moviePlayer)
//                moviePlayer.moviePlayer.play()
//            } else if let mediaItem = message.media as? JSQPhotoMediaItem {
//                let agrume = Agrume(image: mediaItem.image!)
//                agrume.showFrom(self)
//            }
//        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapCellAt indexPath: IndexPath!, touchLocation: CGPoint) {
        print("didTapCellAtIndexPath")
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let video = info[UIImagePickerControllerMediaURL] as? NSURL
        let picture = info[UIImagePickerControllerEditedImage] as? UIImage
        
        self.sendMessage(text: "", video: video, picture: picture)
        
        picker.dismiss(animated: true, completion: nil)
    }
}
