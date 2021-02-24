//
//  Note.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/11/27.
//

import Foundation
import UIKit
import Firebase

class Note : Equatable {
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.noteID == rhs.noteID
        
    }

    var text : String
    var imageName : String?
    var cellImageName : String?
    var noteID : String
    var classification : String?
    var boardclassification : String?
    var textViewText : String?
    var responseText : String?
    var time : String?
    var longtime : String?
    var eMail : String?
    var password : String?
    var nickName : String?
    var account : String?
    var comment : [sNote]?
    var respcount : [Note]?
    init(text:String) {
        noteID = UUID().uuidString
        self.text = text
    }
 
    func image() -> UIImage? {
        if let name = self.imageName {
            let homeUrl = URL(fileURLWithPath: NSHomeDirectory())
            let docUrl = homeUrl.appendingPathComponent("Documents")
            let fileUrl = docUrl.appendingPathComponent(name)
            
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                return UIImage(contentsOfFile: fileUrl.path)
            }else {
                
                let storage = Storage.storage(url: "gs://mapdd30.appspot.com").reference()
                let imageRef = storage.child("images/\(name)")
                imageRef.write(toFile: fileUrl) { (url, error) in
                    if let e = error {
                        print("下載圖檔有錯\(e)")
                    }
                    print("下載成功")
                   
                }
            }
            return UIImage(contentsOfFile: fileUrl.path)
        }
        return nil
    }
    
    func thumbnailImage()->UIImage?{
        
        if let image =  self.image() {
            
            let thumbnailSize = CGSize(width: 160,height: 160); //設定縮圖大小
            let scale = UIScreen.main.scale //找出目前螢幕的scale，視網膜技術為2.0
            //產生畫布，第一個參數指定大小,第二個參數true:不透明（黑色底）,false表示透明背景,scale為螢幕scale
            UIGraphicsBeginImageContextWithOptions(thumbnailSize,false,scale)
            
            //計算長寬要縮圖比例，取最大值MAX會變成UIViewContentModeScaleAspectFill
            //最小值MIN會變成UIViewContentModeScaleAspectFit
            let widthRatio = thumbnailSize.width / image.size.width;
            let heightRadio = thumbnailSize.height / image.size.height;
            
            let ratio = max(widthRatio,heightRadio);
            
            let imageSize = CGSize(width: image.size.width*ratio, height: image.size.height*ratio);
            
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0,y: 0,width: thumbnailSize.width,height: thumbnailSize.height))
            circlePath.addClip()
            
            image.draw(in: CGRect(x: -(imageSize.width-thumbnailSize.width)/2.0, y: -(imageSize.height-thumbnailSize.height)/2.0,
                                  width: imageSize.width, height: imageSize.height))
            //取得畫布上的縮圖
            let smallImage = UIGraphicsGetImageFromCurrentImageContext();
            //關掉畫布
            UIGraphicsEndImageContext();
            return smallImage
        }else{
            return nil;
        }
    }
}



