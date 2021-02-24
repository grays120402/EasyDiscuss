//
//  memberEditViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2021/1/13.
//

import UIKit
import Firebase
import KRProgressHUD
import GoogleSignIn
import FirebaseFirestore

class memberEditViewController: UIViewController {
    var loginHandle: AuthStateDidChangeListenerHandle?
    var signCheck = true
    var GoogleSignUpDB : Firestore!
    let signIn = GIDSignIn.sharedInstance()
    @IBOutlet weak var nickNameLabel: UITextField!
    @IBOutlet weak var accountLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GoogleSignUpDB = Firestore.firestore()
    }
    
    @IBAction func editSend(_ sender: Any) {
        
        signUpShouldInput(text: self.nickNameLabel.text, titleText: "暱稱要輸入哦！")
        signUpShouldInput(text: self.accountLabel.text, titleText: "會員帳號要輸入哦！")
        if signCheck == true {
            KRProgressHUD.show(withMessage: "送出中，請稍候", completion: nil)
            loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
                let email = user?.email
                let date = NSDate()
                let dateformatter = DateFormatter()
                dateformatter.dateFormat = "yyyy-MM-dd"
                let strNowTime = dateformatter.string(from: date as Date) as String
                self.GoogleSignUpDB.collection("signUpNote").document(email ?? "").collection(email ?? "").document(email ?? "").updateData(["nickname":self.nickNameLabel.text ?? "", "account":self.accountLabel.text ?? "", "mail":email ?? "", "time": strNowTime, "imageName":"\(email ?? "").jpg"]) {(error) in
                    if let e = error {
                        print("error \(e)")
                        return
                    }
                }
                KRProgressHUD.dismiss()
                let alertController = UIAlertController(title: "填寫完成", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                   
                    self.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(confirmAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
        }
        
        else{
            signCheck = true
        }
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    func signUpShouldInput(text: String?, titleText: String?) {
        guard let signUpShouldInputText = text, signUpShouldInputText.count > 0 else {
            
            let alertController = UIAlertController(title: titleText, message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                print("確認")
            }
            alertController.addAction(confirmAction)
            self.present(alertController,animated: true, completion: nil)
            signCheck = false
            return
        }
    }
}
