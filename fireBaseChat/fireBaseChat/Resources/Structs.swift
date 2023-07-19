//
//  Structs.swift
//  fireBaseChat
//
//  Created by Anton on 19.07.2023.
//

import Foundation
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
