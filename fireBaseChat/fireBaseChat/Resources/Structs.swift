//
//  Structs.swift
//  fireBaseChat
//
//  Created by Anton on 19.07.2023.
//

import Foundation
import MessageKit

struct Message: MessageType {
  
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
    
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
            return "vieo"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        case .linkPreview(_):
            return "link"
        }
    }
    
}

struct Sender: SenderType {
  
   public var photoURL: String
   public var senderId: String
   public var displayName: String

}


struct Conversation {
    
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
    
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
    
}
