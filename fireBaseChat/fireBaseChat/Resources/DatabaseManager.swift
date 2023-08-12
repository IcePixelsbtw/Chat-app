//
//  DatabaseManager.swift
//  fireBaseChat
//
//  Created by Anton on 18.05.2023.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - getDataFor

/// Gets data for user, usually with safeEmail and return the user struct from Database

extension DatabaseManager {
    
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: - Account Management

extension DatabaseManager {
    
    
    //MARK: userExists
    
    /// Checks if user alreadt exists in database with that email

    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value,
                                                     with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
        
    }
    
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("An error occured: failed to write data to database")
                completion(false)
                return
            }
            self
                .database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElement =
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection , withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            completion(true)
                            
                        })
                    }
                    else {
                        // create that array
                        
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
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DataBaseError: Error {
        case failedToFetch
    }
    
    
    
}

//MARK: - Sending messages / conversations

extension DatabaseManager {
    
    //MARK: createNewConversation
    
    /// Creates a new  conversation with targe t user and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let reference = database.child("\(safeEmail)")
        
        reference.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("An error occured: User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
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
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id" : conversationId,
                "other_user_email" : safeEmail,
                "name" : currentName,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                    
                ]
            ]
            
            //Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user
                //you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                
                reference.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
                
            }
            else {
                //conversation array does not exist
                userNode["conversations"] = [
                    newConversationData
                ]
                
                reference.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
                
            }
            
        })
    }
    
    //MARK: - Finish creating conversation
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void ) {
        var message = ""
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
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
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : currentUserEmail,
            "is_read" : false,
            "name" : name
        ]
        
        
        let value: [String: Any] = [
            "messages" : [
                collectionMessage
            ]
        ]
        
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    //MARK: - getAllConversations
    
    /// Fetches and returns all conversations for the user  with passed email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        
        print("Getting conversations...")
        
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            
            print("Got a snapshot from database, unpacking...")
            
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
                
                print("Successfully unpacked, returning Conversations...")
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
        
    }
    
    //MARK: - getAllMessagesForConversation
    /// Fetches and returns all messages for the conversation with passed id
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)else {
                    return nil
                }
                var kind: MessageKind?
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    //video
                    guard let videoUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    //location
                    let locationComponents = content.components(separatedBy: ",")
                   guard let longitute = Double(locationComponents[0]),
                         let latitude = Double(locationComponents[1]) else {
                       return nil
                   }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitute),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                    
                }
                
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            })
            completion(.success(messages))
        })
        
    }
    
    //MARK: - sendMessage
    
    /// Sends a message with target conversation and a message
    
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        print("Called sendMessage function")
        //MARK: Getting an email from userdefaults and converting to safeEmail
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        print("sendMessage: Got an email as a safeEmail")
        
        //MARK: - Getting messages and appending to the array a new message, afterwads appending it to the users database
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            print("sendMessage: Got into the conversation messages")
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            
            print("sendMessage: Created a message with kind and content")
            
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content" : message,
                "date" : dateString,
                "sender_email" : currentUserEmail,
                "is_read" : false,
                "name" : name
            ]
            
            print("sendMessage: Created a message entry with data and got currentUserEmail")
            
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                print("sendMessage: Appended a message into new array and successfully set a value into database")
                
                //MARK: - Dealing with conversations and last messages
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date" : dateString,
                        "is_read" : false,
                        "message" : message
                    ]
                    
                    print("sendMessage: Current user: Created empty value for dbEntryConv and created an updated value which is lastMessage")
                    
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        // we need to create conversation entry
                        print("sendMessage: Current user: Got into snapshot and assigned it to currentUserConversations")
                        
                        var targetConversation: [String: Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        print("sendMessage: Current user: Did a for loop. line: 575")
                        
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                            print("sendMessage: Current user: successfully updated values in if var line 578")
                            
                        }
                        else {
                            print("sendMessage: Current user: got into the first else case at line 585. Case should appear only if there is no such conversation in current user collection")
                            
                            let newConversationData: [String: Any] = [
                                "id" : conversation,
                                "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name" : name,
                                "latest_message" : updatedValue
                            ]
                            
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                            print("sendMessage: Current User: successfully appended a new conversation to a collection of current user")
                        }
                    }
                    else {
                        print("sendMessage: Current user: Got into second else case. This should appear only if there is no conversations at all at users collection")
                        
                        let newConversationData: [String: Any] = [
                            "id" : conversation,
                            "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name" : name,
                            "latest_message" : updatedValue
                        ]
                        
                        databaseEntryConversations = [
                            newConversationData
                        ]
                        print("sendMessage: Current User: successfully created a first conversation for current user")
                    }
                    
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations,
                                                                                        withCompletionBlock: { error, _ in
                        guard error == nil else {
                            print("An error while appending a new value to a recipient occured. Error is: \(error)")
                            completion(false)
                            return
                        }
                        
                        // Update latest message for recipient
                        
                        //MARK: Recipient (other user) part
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            
                            let updatedValue: [String: Any] = [
                                "date" : dateString,
                                "is_read" : false,
                                "message" : message
                            ]
                            
                            var databaseEntryConversations = [[String: Any]]()
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            print("sendMessage: Other user: Created empty value for dbEntryConv and created an updated value which is lastMessage")
                            
                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                
                                print("sendMessage: Other user: got a snapshot and assigned it to otherUserConversations")
                                var targetConversation: [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                print("sendMessage: Other user: did a for loop for all conversations")
                                
                                if var targetConversation = targetConversation {
                                    print("sendMessage: Other user: got into if var at line 657 where we need to just update conversation")
                                    
                                    targetConversation["latest_message"] = updatedValue
                                    
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                    print("sendMessage: Other user: Successfully updated a conversation to have a new message")
                                    
                                }
                                else {
                                    print("sendMessage: Other user: got into first else case at line 667. Should appear when there is no such conversation in other users collection")
                                    
                                    // failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id" : conversation,
                                        "other_user_email" : DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name" : currentName,
                                        "latest_message" : updatedValue
                                    ]
                                    
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                                print("sendMessage: Other user: Successfully created a new conversation and assigned it to dbEntryConversation")
                                
                            }
                            else {
                                print("sendMessage: Other user: Got into second else case. Should appear only if user does not have any conversations at all. line 684")
                                
                                // current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id" : conversation,
                                    "other_user_email" : DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name" : currentName,
                                    "latest_message" : updatedValue
                                ]
                                
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                                print("sendMessage: Other user: Successfully assigned a newConversationData to dbEntryConversation ")
                                
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations,
                                                                                                  withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    print("An error while appending a new value to a recipient occured. Error is: \(error)")
                                    completion(false)
                                    return
                                }
                                completion(true)
                                
                            })
                        })
                        
                        completion(true)
                        
                    })
                })
                
                
            }
        })
    }
    
    
    //MARK: - deleteConversation
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id: \(conversationId)")
        
        // Get all conversations for current user
        // delete conversation in collection with target id
        // reset those conversations for the user in database
        let reference = database.child("\(safeEmail)/conversations")
        reference.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                reference.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        print("An error occured while setting new value for conversations: \(error)")
                        completion(false)
                        return
                    }
                    print("Successfully deleted conversation")
                    completion(true)
                })
            }
        })
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            // iterate and find conversation with target sender
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DataBaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DataBaseError.failedToFetch))
            return
        })
        
    }
    
}

