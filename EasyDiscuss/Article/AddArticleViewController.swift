//
//  AddArticleViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/13.
//

import UIKit
import ZHDropDownMenu
import Firebase

protocol addArticleViewControllerDelegate : class {
    func addArticleToContent(note: Note)
}

class AddArticleViewController: UIViewController, ZHDropDownMenuDelegate, UITextFieldDelegate {
    var articleData : [Note] = []
    var articlecurrentNote : Note!
    var loginHandle: AuthStateDidChangeListenerHandle?
    var articleDB : Firestore!
    var articleNote : Note!
    weak var addArticleDelegate : addArticleViewControllerDelegate?
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var classification: ZHDropDownMenu!
    @IBOutlet weak var boardclassification: ZHDropDownMenu!
    @IBOutlet weak var articleTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        articleDB = Firestore.firestore()
        queryNickName()
        articleTextView.text = ""
        classification.options = ["問卦", "揪團", "討論", "新聞", "問題", "閒聊"]
        classification.menuHeight = 100
        classification.delegate = self
        classification.showBorder = true
        boardclassification.options = ["Job","MAPD30","iOS", "健身", "八卦", "寵物", "手機遊戲", "男女", "表特","運動", "電影","飲食"]
        boardclassification.menuHeight = 100
        boardclassification.delegate = self
        boardclassification.showBorder = true
        configureTextField(textField: titleTextField, text: "輸入標題")
        articleTextView.layer.borderWidth = 1.0
        articleTextView.layer.cornerRadius = 10.0
        articleTextView.layer.borderColor = UIColor.lightGray.cgColor
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
   
    }
    
    func dropDownMenu(_ menu: ZHDropDownMenu, didEdit text: String) {
        print("\(menu) input text \(text)")
    }
    
    func dropDownMenu(_ menu: ZHDropDownMenu, didSelect index: Int) {
        print("\(menu) input index \(index)")
    }
    
    func configureTextField(textField: UITextField, text: String) {
        textField.delegate = self
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 10.0
        textField.layer.borderWidth = 1.0
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    @IBAction func Done(_ sender: Any) {
        
        guard let boardclassification = self.boardclassification.contentTextField.text, boardclassification.count > 0 else {
            let alertController = UIAlertController(title: "看板類別要選擇發文哦!", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                print("確認")
            }
            alertController.addAction(confirmAction)
            self.present(alertController,animated: true, completion: nil)
            return
        }
        
        guard let classification = self.classification.contentTextField.text, classification.count > 0 else {
            let alertController = UIAlertController(title: "發表文章要選擇看板哦!", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                print("確認")
            }
            alertController.addAction(confirmAction)
            self.present(alertController,animated: true, completion: nil)
            return
        }
        
        guard let textStr = self.articleTextView.text, textStr.count > 0 else {
            let alertController = UIAlertController(title: "發表文章標題和內文都要填寫哦!", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                print("確認")
            }
            alertController.addAction(confirmAction)
            self.present(alertController,animated: true, completion: nil)
            return
        }
        let date = NSDate()
        let dateformatter = DateFormatter()
        let longDateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd"
        longDateformatter.dateFormat = "yyyy-MM-dd HH:mm"
        let strNowTime = dateformatter.string(from: date as Date) as String
        let longstrNowTime = longDateformatter.string(from: date as Date) as String
        articlecurrentNote = Note(text: textStr)
        self.articlecurrentNote.text = self.titleTextField.text ?? ""
        self.articlecurrentNote.classification = self.classification.contentTextField.text
        self.articlecurrentNote.textViewText = textStr
        self.articlecurrentNote.boardclassification = self.boardclassification.contentTextField.text
        self.articlecurrentNote.time = strNowTime
        self.articlecurrentNote.longtime = longstrNowTime
        self.articlecurrentNote.nickName = self.articleNote.nickName
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.articlecurrentNote.imageName = user?.email
            self.addArticleDelegate?.addArticleToContent(note:self.articlecurrentNote)
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 0.5) {
            
            self.titleTextField.resignFirstResponder()
        }
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        
    }
    func queryNickName (){
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.articleDB.collection("signUpNote").document(user.email ?? "").collection(user.email ?? "").getDocuments{(query, error) in
                    if let e = error {
                        print("queryNickName error \(e)")
                        return
                    }
                    guard let changes = query?.documentChanges else { print("guard let fail")
                        return }
                    for change in changes {
                        let noteID = change.document.documentID // 利用document = noteID
                        if change.type == .added {//新增狀況
                            print("memberadded")
                            //取得資料，轉成note物件，放回self.data，呼叫insertRows
                            let addarticledata = change.document.data()
                            let note = Note(text: "")
                            note.nickName = addarticledata["nickname"] as? String
                            note.noteID = noteID
                            self.articleNote = note
                        }
                    }
                }
            }
        }
    }
}
