//
//  ChatViewController.swift
//  fireBaseChat
//
//  Created by Anton on 06.07.2023.
//

import UIKit
import MessageKit

struct Message: MessageType {
  
    var sender: MessageKit.SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKit.MessageKind
    
}

struct Sender: SenderType {
  
    var photoURL: String
    
    var senderId: String
    
    var displayName: String

}

class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "",
                                    senderId: "1",
                                    displayName: "Mike Ross")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender ,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello world message!")))
                        
        messages.append(Message(sender: selfSender ,
                                messageId: "2",
                                sentDate: Date(),
                                kind: .text("Hello world message! Hello world message! Hello world message! Hello world message! Hello world message!")))
                                        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

    }
    


}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
    
    
}
