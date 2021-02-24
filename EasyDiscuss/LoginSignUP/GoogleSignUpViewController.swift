//
//  GoogleSignUpViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2021/1/5.
//

import UIKit
import Firebase
import KRProgressHUD
import GoogleSignIn
import FirebaseFirestore

class GoogleSignUpViewController: UIViewController {
    
    @IBOutlet weak var googleNickname: UITextField!
    @IBOutlet weak var googleAccount: UITextField!
    var loginHandle: AuthStateDidChangeListenerHandle?
    var signCheck = true
    var GoogleSignUpDB : Firestore!
    let signIn = GIDSignIn.sharedInstance()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GoogleSignUpDB = Firestore.firestore()

    }
   
    @IBAction func Send(_ sender: Any) {
        
        signUpShouldInput(text: self.googleNickname.text, titleText: "暱稱要輸入哦！")
        signUpShouldInput(text: self.googleAccount.text, titleText: "會員帳號要輸入哦！")
        if signCheck == true {
            KRProgressHUD.show(withMessage: "送出中，請稍候", completion: nil)
            loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
                let email = user?.email
                let date = NSDate()
                let dateformatter = DateFormatter()
                dateformatter.dateFormat = "yyyy-MM-dd"
                let strNowTime = dateformatter.string(from: date as Date) as String
                self.GoogleSignUpDB.collection("signUpNote").document(email ?? "").collection(email ?? "").document(email ?? "").updateData(["nickname":self.googleNickname.text ?? "", "account":self.googleAccount.text ?? "", "mail":email ?? "", "time": strNowTime, "imageName":"\(email ?? "").jpg"]) {(error) in
                    if let e = error {
                        print("error \(e)")
                        return
                    }
                }
                KRProgressHUD.dismiss()
                let alertController = UIAlertController(title: "填寫完成", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(confirmAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
        }
        
        else{
            signCheck = true
        }
        
    }
    
    
    @IBAction func Cancel(_ sender: Any) {
//        let alertController = UIAlertController(title: "登入失敗，請重新登入!", message: "", preferredStyle: .alert)
//        let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
//            print("確認")
//            do {
////                try Auth.auth().signOut()
////                GIDSignIn.sharedInstance().signOut()
                self.dismiss(animated: true, completion: nil)
//                print("已登出")
//            } catch {
//                print(error)
//            }
//            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
//        }
//        alertController.addAction(confirmAction)
//        self.present(alertController, animated: true, completion: nil)
            
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
