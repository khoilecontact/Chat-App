//
//  ChatViewController.swift
//  Chat App
//
//  Created by KhoiLe on 02/09/2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
    
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_review"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
    
}

class ChatViewController: MessagesViewController {
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        //Fix this so real device can run without error 
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email as! String)
        
        return Sender(photoURL: "", senderId: safeEmail , displayName: "Me")
        
    }()
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = self.conversationId {
            listenForMessage(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputButton()
    }
    
    private func setUpInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach media", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinate: nil)
        vc.title = "Pick a Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinate in
            let longitude: Double = selectedCoordinate.longitude
            let latitude: Double = selectedCoordinate.latitude
            
            guard let messageId = self?.createMessageId(),
                  let conversationId = self?.conversationId,
                  let name = self?.title,
                  let selfSender = self?.selfSender else {
                return
            }
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: self!.otherUserEmail, newMessage: message, completion: { success in
                if success {
                    print("Sent location message")
                } else {
                    print("Fail to sent location message")
                }
            })
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "What would you like to attach a photo from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
            
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "What would you like to attach a video from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
            
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
        
    }
    
    
    private func listenForMessage(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                }
            case .failure(let error):
                print("Fail to get all messages: \(error)")
            }
        })
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender else {
            picker.dismiss(animated: true)
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image
            storageManager.shared.uploadMessagePhoto(with: imageData, fileName: "\(fileName)", completion: { [weak self] result in
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let mediaItem = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: self!.otherUserEmail, newMessage: message, completion: { success in
                        if success {
                            print("Sent photo message")
                        } else {
                            print("Fail to sent photo message")
                        }
                    })
                case .failure(let error):
                    print("Fail to upload conversation image: \(error)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //Upload video
            storageManager.shared.uploadMessageVideo(with: videoUrl, fileName: "\(fileName)", completion: { [weak self] result in
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let mediaItem = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: self!.otherUserEmail, newMessage: message, completion: { success in
                        if success {
                            print("Sent video message")
                        } else {
                            print("Fail to sent video message")
                        }
                    })
                case .failure(let error):
                    print("Fail to upload conversation video: \(error)")
                }
            })
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        
        // send message
        if isNewConversation {
            // create new conversation in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("Message sent")
                    self?.isNewConversation = false
                } else {
                    print("Fail to send")
                }
            })
        } else {
            //append to existed conversation data
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherUserEmail,newMessage: message, completion: {
                success in
                if success {
                    print("Message sent")
                } else {
                    print("Fail to send")
                }
            })
        }
    }
    
    private func createMessageId() -> String? {
        // date - otherUserEmail - senderEmail - UUID
        let dateString = Self.dateFormatter.string(from: Date())
        guard let myEmail = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail as! String)
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("selfSender is nil")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            //Set image so user can the image rather a URL
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    ///Open photo message whenever we tap it in the conversation
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    ///This function is called whenever a message is tapped (not image or video cuz it's already handled above)
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinate = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinate: coordinate)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
