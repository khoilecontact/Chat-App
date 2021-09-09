//
//  ChatViewController.swift
//  Chat App
//
//  Created by KhoiLe on 02/09/2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
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
    public static var dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
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
        messageInputBar.delegate = self
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
        let dateString = Self.dataFormatter.string(from: Date())
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
    
    
}
