//
//  ViewController.swift
//  Yi Talk
//
//  Created by 陳懿宏 on 2020/11/25.
//

import UIKit
import Firebase
import KRProgressHUD
import WebKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import AuthenticationServices
import FirebaseFirestore
import CryptoKit

protocol LoginVCDelegate : class {
    func loginToList (note:Note)
}

class LoginViewController: UIViewController, UITextFieldDelegate, GIDSignInDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    fileprivate var currentNonce: String?
    let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    let signIn = GIDSignIn.sharedInstance()
    let authorizationAppleIDButton: ASAuthorizationAppleIDButton = ASAuthorizationAppleIDButton()
    var drivefiles = [GTLRDrive_File]()
    var loginHandle: AuthStateDidChangeListenerHandle?
    private var workItem: DispatchWorkItem?
    @IBOutlet weak var GoogleLoginBtn: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var loginBtnOutlet: UIButton!
    @IBOutlet weak var signUpBtnOutlet: UIButton!
    weak var LoginDelegate : LoginVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        signIn?.delegate = self
        signIn?.presentingViewController = self
        signIn?.restorePreviousSignIn()
        signIn?.scopes = [kGTLRAuthScopeDriveFile]
        configureTextField(textField: accountTextField, text: "輸入電子郵件")
        configureTextField(textField: passwordTextField, text: "輸入密碼")
        setupAppleButton()
    }
    
    func setupAppleButton() {
        view.addSubview(appleButton)
        appleButton.cornerRadius = 10
        appleButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        appleButton.widthAnchor.constraint(equalToConstant: 240).isActive = true
        appleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        appleButton.bottomAnchor.constraint(equalTo: self.GoogleLoginBtn.bottomAnchor, constant: 55).isActive = true
    }
    

    func configureTextField(textField: UITextField, text: String) {
        textField.delegate = self
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.cornerRadius = 10.0
        textField.layer.borderWidth = 1.0
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        
    }
    
    @IBAction func privacyBtn(_ sender: Any) {
        
        if let privacyVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "privacyVC") as? UINavigationController{
            
            self.present(privacyVC, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func loginBtn(_ sender: UIButton) {
        KRProgressHUD.show(withMessage: "登入中，請稍候", completion: nil)
        Auth.auth().signIn(withEmail: "\(self.accountTextField.text ?? "")", password: "\(self.passwordTextField.text ?? "")") {(result, error) in
            
            guard error == nil else {
                print(error?.localizedDescription)
                KRProgressHUD.dismiss()
                let alertController = UIAlertController(title: "電子郵件或密碼錯誤", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                }
                alertController.addAction(confirmAction)
                self.present(alertController,animated: true, completion: nil)
                return
            }
            let loginNote = Note(text: "")
            loginNote.eMail = self.accountTextField.text
            self.LoginDelegate?.loginToList(note: loginNote)
            KRProgressHUD.dismiss()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func googleSignIn(_ sender: Any) {
        
        launchSignIn()
    }
    
    
    
    func launchSignIn() {
        
        signIn?.signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error)
            return
        }
               
        guard let authentication = user.authentication else {return}
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
       
        Auth.auth().signIn(with: credential) { (user, error) in
            let alertController = UIAlertController(title: "Goole登入的使用者請您先填寫會員資料!", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "前往填寫", style: .default) { (action) in
                if let googleVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "googleSignUpVC") as? GoogleSignUpViewController{
                    googleVC.modalPresentationStyle = .overFullScreen
                    self.present(googleVC, animated: true, completion: nil)
                }
            }
            let EditAction = UIAlertAction(title: "我想修改會員資料", style: .default) { (action) in
                if let googleVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "googleSignUpVC") as? GoogleSignUpViewController{
                    googleVC.modalPresentationStyle = .overFullScreen
                    self.present(googleVC, animated: true, completion: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "我填寫過了", style: .cancel) { (action) in
                print("取消")
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            alertController.addAction(EditAction)
            self.present(alertController,animated: true, completion: nil)
            
            if let error = error {
                print(error)
                return
            }
           
        }
    }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 0.5){
            
            textField.resignFirstResponder()
            
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
        
    }
    @available(iOS 13, *)
      @objc func startSignInWithAppleFlow() {
        
          let nonce = randomNonceString()
          currentNonce = nonce
          let appleIDProvider = ASAuthorizationAppleIDProvider()
          let request = appleIDProvider.createRequest()
          request.requestedScopes = [.fullName, .email]
          request.nonce = sha256(nonce)
          
          let authorizationController = ASAuthorizationController(authorizationRequests: [request])
          authorizationController.delegate = self
          authorizationController.presentationContextProvider = self
          authorizationController.performRequests()
        
        print("apple")
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
               
                let alertController = UIAlertController(title: "Apple登入的使用者請您先填寫會員資料!", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "前往填寫", style: .default) { (action) in
                    if let googleVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "googleSignUpVC") as? GoogleSignUpViewController{
                        googleVC.modalPresentationStyle = .overFullScreen
                        self.present(googleVC, animated: true, completion: nil)
                    }
                }
                let EditAction = UIAlertAction(title: "我想修改會員資料", style: .default) { (action) in
                    if let googleVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "googleSignUpVC") as? GoogleSignUpViewController{
                        googleVC.modalPresentationStyle = .overFullScreen
                        self.present(googleVC, animated: true, completion: nil)
                    }
                }
                let cancelAction = UIAlertAction(title: "我填寫過了", style: .cancel) { (action) in
                    print("取消")
                    self.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(confirmAction)
                alertController.addAction(cancelAction)
                alertController.addAction(EditAction)
                self.present(alertController,animated: true, completion: nil)
            }
        }
      }
      
      @available(iOS 13, *)
      private func sha256(_ input: String) -> String {
          let inputData = Data(input.utf8)
          let hashedData = SHA256.hash(data: inputData)
          let hashString = hashedData.compactMap {
              return String(format: "%02x", $0)
          }.joined()
          
          return hashString
      }
}

@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerDelegate {
  
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
          guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
          }
          guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
          }
          guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
          }
          // Initialize a Firebase credential.
          let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
          // Sign in with Firebase.
          Auth.auth().signIn(with: credential) { (authResult, error) in
            if (error != nil) {
              // Error. If error.code == .MissingOrInvalidNonce, make sure
              // you're sending the SHA256-hashed nonce as a hex string with
              // your request to Apple.
              print(error!.localizedDescription)
              return
            }
            
            // User is signed in to Firebase with Apple.
            // ...
          }
        }
      }

      func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
      }

    }

