//
//  SignUpViewController.swift
//  Yi Talk
//
//  Created by 陳懿宏 on 2020/11/26.
//

import UIKit
import Firebase
import KRProgressHUD
import FirebaseFirestore

class SignUpViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!  
    var signUpEmailNote : Note!
    var signUpDB : Firestore!
    var signCheck = true
    override func viewDidLoad() {
        super.viewDidLoad()
        signUpDB = Firestore.firestore()
        mailTextField.delegate = self
        mailTextField.layer.borderColor = UIColor.white.cgColor
        mailTextField.layer.cornerRadius = 10.0
        mailTextField.layer.borderWidth = 1.0
        mailTextField.attributedPlaceholder = NSAttributedString(string: "example@mail.com", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white ])
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.layer.borderColor = UIColor.white.cgColor
        confirmPasswordTextField.layer.cornerRadius = 10.0
        confirmPasswordTextField.layer.borderWidth = 1.0
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: "再次輸入密碼", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white ])
        passwordTextField.delegate = self
        passwordTextField.layer.borderColor = UIColor.white.cgColor
        passwordTextField.layer.cornerRadius = 10.0
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "輸入六位數以上密碼", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white ])
        accountTextField.delegate = self
        accountTextField.layer.borderColor = UIColor.white.cgColor
        accountTextField.layer.cornerRadius = 10.0
        accountTextField.layer.borderWidth = 1.0
        accountTextField.attributedPlaceholder = NSAttributedString(string: "輸入帳號", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white ])
        nicknameTextField.delegate = self
        nicknameTextField.layer.borderColor = UIColor.white.cgColor
        nicknameTextField.layer.cornerRadius = 10.0
        nicknameTextField.layer.borderWidth = 1.0
        nicknameTextField.attributedPlaceholder = NSAttributedString(string: "站內暱稱", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white ])
    }
    
    @IBAction func signUPBtnAction(_ sender: Any) {
        
        let email = self.mailTextField.text
        let password = self.passwordTextField.text
        signUpShouldInput(text: self.mailTextField.text, titleText: "電子郵件欄位要輸入哦！")
        signUpShouldInput(text: self.accountTextField.text, titleText: "帳號欄位要輸入哦！")
        signUpShouldInput(text: self.passwordTextField.text, titleText: "密碼欄位要輸入哦！")
        signUpShouldInput(text: self.confirmPasswordTextField.text, titleText: "確認密碼要輸入哦!")
        signUpShouldInput(text: self.nicknameTextField.text, titleText: "暱稱要輸入哦！")
        
        
        
        if signCheck == true {
            KRProgressHUD.show(withMessage: "註冊中，請稍候", completion: nil)
            guard let confirmPassword = self.confirmPasswordTextField.text,confirmPassword == password else{
                
                let alertController = UIAlertController(title: "密碼和確認密碼不符合", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                }
                alertController.addAction(confirmAction)
                self.present(alertController,animated: true, completion: nil)
                
                return
            }
            
            Auth.auth().createUser(withEmail: email ?? "", password: password ?? "") { (authResult, error) in
                
                guard let user = authResult?.user, error == nil else {
                    print(error?.localizedDescription as Any)
                    KRProgressHUD.dismiss()
                    let alertController = UIAlertController(title: "密碼沒有超過6位數，電子郵件格式錯誤或電子郵件已被註冊過", message: "", preferredStyle: .alert)
                    let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                        print("確認")
                    }
                    alertController.addAction(confirmAction)
                    
                    self.present(alertController,animated: true, completion: nil)
                    return
                }
                print(user.email)
                let date = NSDate()
                let dateformatter = DateFormatter()
                dateformatter.dateFormat = "yyyy-MM-dd"
                let strNowTime = dateformatter.string(from: date as Date) as String
                self.signUpDB.collection("signUpNote").document(self.mailTextField.text ?? "").collection(self.mailTextField.text ?? "").document(self.mailTextField.text ?? "") .setData(["nickname":self.nicknameTextField.text ?? "", "account":self.accountTextField.text ?? "", "password":self.passwordTextField.text ?? "", "mail":self.mailTextField.text ?? "", "time": strNowTime, "imageName":"\(self.mailTextField.text ?? "").jpg"]) {(error) in
                    if let e = error {
                        print("error \(e)")
                        KRProgressHUD.dismiss()
                        return
                    }
                }
                KRProgressHUD.dismiss()
                let alertController = UIAlertController(title: "註冊成功", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(confirmAction)
                self.present(alertController, animated: true, completion: nil)
                
            }
        }else{
            signCheck = true
        }
    }
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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

