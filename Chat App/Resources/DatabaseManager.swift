//
//  DatabaseManager.swift
//  Chat App
//
//  Created by KhoiLe on 31/08/2021.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: ",")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

extension DatabaseManager {
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: ",")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })

    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    /*
     users: [
        [
            "name":
            "safeEmail":
        ],
         [
             "name":
             "safeEmail":
         ]
     ]
     */
    
    ///insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, datareference in
            guard error ==  nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                    
                } else {
                    //create an array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            
            completion(true)
        })
    }
}

// MARK: -Sending messages / conversations

extension DatabaseManager {
    /*
     id {
        "messages": [
            {
                "id": String,
                "type": text, audio, photo,..
                "content": String
                "date": Date(),
                "sender_email": String
                "isRead": true/false
            }
        ]
     }
     
     conversation => [
        [
            "conversation_id": id
            "other_user_email":
            "latest_message": => {
                "date": Date()
                "latest_message": "message"
                "is_read": true/false
        ]
     ]
     */
    
    /// Create new conversation with other user email and first message sent to the User reference in the database
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail as! String)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            var message = ""
            
            switch firstMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dataFormatter.string(from: messageDate)
            let conversationId =  firstMessage.messageId
            
            let newConversationData: [String: Any] = [
                "id": "conversation_\(conversationId)",
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exist fir current user
                // we should append it
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            } else {
                // conversation array does not exist, create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    /// Add message to the conversationId array - hold all the message of the conversation
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        {
//            "id": String,
//            "type": text, audio, photo,..
//            "content": String
//            "date": Date(),
//            "sender_email": String
//            "isRead": true/false
//        }
        
        var message = ""
        
        switch firstMessage.kind {
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dataFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") else {
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail as! String)
        
        let colletionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                colletionMessage
            ]
        ]
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetch and return all conversations for the user which has the email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                      
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Get all messages for a given conversations
    public func getAllMessagesForConversation(with id: String, completion: (Result<String, Error>) -> Void) {
        
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: ",")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
