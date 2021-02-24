//
//  MessageViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/15.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol responseVCDelegate : class {
    func responseToPresent (note: sNote)
}
class ResponseViewController: UIViewController, UITextViewDelegate {
    var responseDB : Firestore!
    var responseSNote : sNote!
    var responseNickNameNote : Note!
    var loginHandle: AuthStateDidChangeListenerHandle?
    weak var responseDelegate : responseVCDelegate?
    @IBOutlet weak var responseView: UIView!
    @IBOutlet weak var responseTextview: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        responseDB = Firestore.firestore()
        queryNickName()
        self.responseTextview.delegate = self
        self.responseTextview.layer.borderWidth = 1.0
        self.responseTextview.layer.borderColor = UIColor.lightGray.cgColor
        self.responseTextview.layer.cornerRadius = 10.0
        self.responseView.layer.cornerRadius = 20.0
        
    }
    @IBAction func XcancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func responseCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func responseDone(_ sender: Any) {
        guard let responsetextStr = self.responseTextview.text, responsetextStr.count > 0 else {
            let alertController = UIAlertController(title: "內文要填寫才能回覆文章哦!", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                print("確認")
            }
            alertController.addAction(confirmAction)
            self.present(alertController,animated: true, completion: nil)
            return
        }
        let date = NSDate()
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "MM-dd HH:mm"
        let strNowTime = dateformatter.string(from: date as Date) as String
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.responseSNote = sNote(ResponseText: "")
                self.responseSNote.ResponseText = self.responseTextview.text
                self.responseSNote.time = strNowTime
                self.responseSNote.nickName = self.responseNickNameNote.nickName
                self.responseSNote.email = user.email
                self.responseDelegate?.responseToPresent(note: self.responseSNote)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func queryNickName (){
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.responseDB.collection("signUpNote").document(user.email ?? "").collection(user.email ?? "").getDocuments{(query, error) in
                    if let e = error {
                        print("queryNickName error \(e)")
                        return
                    }
                    guard let changes = query?.documentChanges else { print("guard let fail")
                        return }
                    for change in changes {
                        let noteID = change.document.documentID
                        if change.type == .added {
                            let addarticledata = change.document.data()
                            let note = Note(text: "")
                            note.nickName = addarticledata["nickname"] as? String
                            note.noteID = noteID
                            self.responseNickNameNote = note
                        }
                    }
                }
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 0.5) {
            
            textField.resignFirstResponder()
        }
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        
    }
}
extension UITextView: UITextViewDelegate {
    
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }
    
    public var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = !self.text.isEmpty
        }
    }
    
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height

            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
    
    private func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()
        
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 100
        placeholderLabel.isHidden = !self.text.isEmpty
        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
        self.delegate = self
    }
  
    
}
