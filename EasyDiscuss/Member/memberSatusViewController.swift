//
//  memberSatusViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/28.
//

import UIKit
import Firebase
import SDWebImage
import FirebaseFirestore
class memberSatusViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
  
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var userNicknameLabel: UILabel!
    @IBOutlet weak var userAccountLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userSignUpDateLabel: UILabel!
    var memberEmailNote : Note!
    var memberDB : Firestore!
    var memberData : [Note] = []
    var memberNote : Note!
    var loginHandle: AuthStateDidChangeListenerHandle?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.memberImageView.layer.cornerRadius = 80
        
        self.navigationController?.navigationBar.tintColor = .white
    }
    override func viewWillAppear(_ animated: Bool) {
        print("123333")
        memberDB = Firestore.firestore()
        queryMemberFromFirebase()
        
    }
 
    @IBAction func userImageChangeAction(_ sender: Any) {
        let pickerController  = UIImagePickerController()
        pickerController.delegate = self
        
        let alertController = UIAlertController(title: "要換張照片嗎？", message: "請勿放含有腥羶色的照片", preferredStyle: .actionSheet)
        let albumImageAction = UIAlertAction(title: "從相簿更換照片", style: .default) { (action) in
            pickerController.sourceType = .savedPhotosAlbum
            self.present(pickerController, animated: true, completion: nil)
        }
        let cameraAction = UIAlertAction(title: "從相機更換照片", style: .default) { (action) in
            
            pickerController.sourceType = .camera
            self.present(pickerController, animated: true, completion: nil)
            self.postImageToFirebase()
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
            print("取消")
        }
        alertController.addAction(albumImageAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    

    func memberInformation () {
        let indexpath = IndexPath(row: 0, section: 0)
        self.userAccountLabel.text = self.memberData[indexpath.row].account
        self.userNicknameLabel.text = self.memberData[indexpath.row].nickName
        self.userEmailLabel.text = self.memberData[indexpath.row].eMail
        self.userSignUpDateLabel.text = self.memberData[indexpath.row].time
    }
    
    
    func postImageToFirebase () {
        let storage = Storage.storage(url: "gs://easy-discuss-c3218.appspot.com").reference()
        
        let fileName = String(format: "\(memberNote.eMail ?? "").jpg")
        if let image = self.memberImageView.image{
             
            if let data = image.jpegData(compressionQuality: 1){
                let storageRef = storage.child("images/\(fileName)")
                let task =  storageRef.putData(data, metadata: nil) { (metadata, error) in
                    if let e = error {
                        print("upload image error \(e)")
                        return
                    }
                }
                task.resume()
            }
        }
        
    }
    
    func postImageInfoToFirebase() {
        memberDB.collection("memberNote").document(memberNote.noteID).setData(["text":memberNote.text, "imageName": memberNote.imageName ?? ""]) {(error) in
            if let e = error {
                print("error \(e)")
                return
            }
        }
    }
    
    func downloadImageFromFirebase () {
       
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                
                let storage = Storage.storage().reference().child("images/").child("\(user.email ?? "").jpg").downloadURL { (url, error) in
                    
                    self.memberImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "head"))
                    
                }
                
            }
            
            if self.userEmailLabel.text != user?.email {
                self.checkGoogleSignIn()
            }
            
        }
      
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage{
            self.memberImageView.image = image
        }
        self.postImageToFirebase()
        self.postImageInfoToFirebase()
        self.dismiss(animated: true, completion: nil)
    }
    func checkGoogleSignIn () {
        let alertController = UIAlertController(title: "請先填寫會員資料", message: "", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
            if let googleSignUpVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "googleSignUpVC") as? GoogleSignUpViewController{
                googleSignUpVC.modalPresentationStyle = .overFullScreen
                self.present(googleSignUpVC, animated: true, completion: nil)
            }
        }
        alertController.addAction(confirmAction)
        self.present(alertController,animated: true, completion: nil)
        
    }
    
    func queryMemberFromFirebase() {
        
        memberDB.collection("signUpNote").document(self.memberEmailNote.eMail ?? "").collection(self.memberEmailNote.eMail ?? "").getDocuments{(query, error) in
            if let e = error {
                print("error123 \(e)")
                return
            }
            guard let changes = query?.documentChanges else { print("guard let fail")
                return }
            for change in changes {
                let noteID = change.document.documentID // 利用document = noteID
                if change.type == .added {//新增狀況
                    //取得資料，轉成note物件，放回self.data，呼叫insertRows
                    let memberdata = change.document.data()
                    let note = Note(text: "")
                    note.account = memberdata["account"] as? String
                    note.eMail = memberdata["mail"] as? String
                    note.nickName = memberdata["nickname"] as? String
                    note.time = memberdata["time"] as? String
                    note.imageName = memberdata["imageName"] as? String
                    note.noteID = noteID
                    self.memberData.insert(note, at: 0)
                    self.memberNote = Note(text: "")
                    self.memberNote = note
                    self.memberInformation()
                }
                self.downloadImageFromFirebase()
               
            }
            
        }
        
    }

}

