//
//  Struct.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/17.
//

import Foundation


struct sNote : Equatable {
    
    static func == (lhs: sNote, rhs: sNote) -> Bool {
        lhs.SnoteID == rhs.SnoteID
        
    }
    var ResponseText : String
    var SnoteID : String
    var time : String?
    var nickName : String?
    var email : String?
    init(ResponseText: String) {
        SnoteID = UUID().uuidString
        self.ResponseText = ResponseText
    }
}


