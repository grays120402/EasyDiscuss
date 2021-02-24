//
//  PresentViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/6.
//

import UIKit
import Firebase
import FirebaseFirestore

class PresentViewController: UIViewController, UITableViewDataSource, responseVCDelegate, UITableViewDelegate {
    
    @IBOutlet weak var presentToolBar: UIToolbar!
    @IBOutlet weak var tableView: UITableView!
    var presentNote : Note!
    var presentDb : Firestore!
    var reciveContentTitle : Note!
    var reciveContenNoteID : Note!
    var presentData : [Note] = []
    var emailNote : Note!
    var loginHandle: AuthStateDidChangeListenerHandle?
    var refreshControl:UIRefreshControl!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if presentNote.comment == nil{
            return 0
        }
        else {
        return self.presentNote.comment!.count + 1
        }
    }
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let textViewCell = self.tableView.dequeueReusableCell(withIdentifier: "presenttextcell", for: indexPath) as! PresentTextTableViewCell
            textViewCell.presentTextLabel.text = "\(self.presentData[indexPath.row].textViewText ?? "") \n"
            textViewCell.presentTitleLabel.text = "[\(self.presentData[indexPath.row].classification ?? "")]   \(self.presentData[indexPath.row].text)"
            textViewCell.AuthorLabel.text = "作者： \(self.presentData[indexPath.row].nickName ?? "")"
            textViewCell.addDateLabel.text = "時間： \(self.presentData[indexPath.row].longtime ?? "")"
            return textViewCell
        }
        else  {
            
            let responseCell = self.tableView.dequeueReusableCell(withIdentifier: "presentresponsecell", for: indexPath) as! PresentMessageTableViewCell
            responseCell.editBtnOutlet.tag = indexPath.row
            responseCell.thembnailImageView.layer.cornerRadius = 35
            responseCell.responseLabel.text = self.presentNote.comment![indexPath.row - 1].ResponseText
            responseCell.nameLabel.text = self.presentNote.comment![indexPath.row - 1].nickName
            responseCell.dateLabel.text = self.presentNote.comment![indexPath.row - 1].time
            let email = self.presentNote.comment![indexPath.row - 1].email
            
            if self.tableView.dataSource != nil{
                let storage = Storage.storage().reference().child("images/").child("\(email! ).jpg").downloadURL { (url, error) in
                    
                    responseCell.thembnailImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "head"))
                }
            }
            return responseCell
            
        }
        
}
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    

    @IBAction func responseAction(_ sender: Any) {
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
               
                if let responseVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "responseVC") as? ResponseViewController {
                    responseVC.responseDelegate = self
                    responseVC.modalPresentationStyle = .overFullScreen
                    self.present(responseVC, animated: true, completion: nil)
                }
                print("\(user.email) login")
            } else {
                let alertController = UIAlertController(title: "回覆文章需要登入帳號喔！", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                    if let loginVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "loginVC") as? LoginViewController{
                        loginVC.modalPresentationStyle = .overFullScreen
                        self.present(loginVC, animated: true, completion: nil)
                    }
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                    print("取消")
                }
                alertController.addAction(confirmAction)
                alertController.addAction(cancelAction)
                self.present(alertController,animated: true, completion: nil)
                print("not login")
                return
            }
        }  
    }
    @IBAction func reloadAction(_ sender: Any) {
        
        refreshControl.beginRefreshing()
        
       
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.bounds.height)
        }) { (finish) in
            self.loadData()
            
        }
    }
    
    @IBAction func toTopAction(_ sender: Any) {
        
        let indexpath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexpath, at: .top, animated: true)
        
    }
    @IBAction func toBottomAction(_ sender: Any) {
        
       let cellCount = presentData.count - 1
        let indexpath = IndexPath(row: cellCount, section: 0)
        self.tableView.scrollToRow(at: indexpath, at: .bottom, animated: true)
        
    }
    
    @IBAction func editBtnAction(_ sender: UIButton) {
        
        let index = sender.tag
        let indexpath = IndexPath(row: index, section: 0)
        
    }
    
    
    @IBAction func reportAction(_ sender: Any) {
        
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                let alertController = UIAlertController(title: "你要舉報此則文章或回應含有情色或暴力內容嗎?", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                    
                    let alertController = UIAlertController(title: "您的舉報訊息已經傳給管理員,管理員將在24小時內審核,審核屬實將會刪除此貼文,謝謝您的舉報！", message: "", preferredStyle: .alert)
                    let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                        
                    }
                    alertController.addAction(confirmAction)
                    self.present(alertController,animated: true, completion: nil)
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                    print("取消")
                }
                alertController.addAction(confirmAction)
                alertController.addAction(cancelAction)
                self.present(alertController,animated: true, completion: nil)
            }
            else {
                let alertController = UIAlertController(title: "請先登入後才能舉報!", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                
            }
                alertController.addAction(confirmAction)
                self.present(alertController,animated: true, completion: nil)
            }
        }
        
    }
    
    func queryPresentFromFirebase() {

        presentDb.collection("commentNote").document(reciveContentTitle.boardclassification ?? "").collection(reciveContentTitle.boardclassification ?? "").document(reciveContenNoteID.noteID).collection(reciveContenNoteID.noteID).order(by: "Time", descending: false).getDocuments { (query, error) in
            if let e = error {
                print("error \(e)")
                return
        }
            guard let changes = query?.documentChanges else { return }
            self.emailNote = Note(text: "")
            self.presentNote = Note(text: "")
            self.presentNote.comment = []
            for change in changes {
                let noteID = change.document.documentID // 利用document = noteID
                if change.type == .added {//新增狀況
                    //取得資料，轉成note物件，放回self.data，呼叫insertRows
                    let data = change.document.data()
                    var note = sNote(ResponseText: "")
                    note.ResponseText = data["Responsetext"] as? String ?? ""
                    note.time = data["Time"] as? String ?? ""
                    note.nickName = data["NickName"] as? String ?? ""
                    note.email = data["email"] as? String ?? ""
                    note.SnoteID = noteID
                    self.emailNote.eMail = note.email
                    self.presentNote.comment?.append(note)
                    self.presentData.append(self.presentNote)
//                    if self.tableView.dataSource != nil {
//                        self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
//                    }
                }
            }
            
        
            self.tableView.reloadData()
        }
        
    }
    
    func responseToPresent (note: sNote) {
        if  presentNote.comment == nil {
            presentNote.comment = []
        }
        
        presentDb.collection("commentNote").document(reciveContentTitle.boardclassification ??  "").collection(reciveContentTitle.boardclassification ?? "").document(reciveContenNoteID.noteID).collection(reciveContenNoteID.noteID).document(note.SnoteID).setData(["Responsetext":note.ResponseText, "Time": note.time ?? "","NickName": note.nickName ?? "","email": note.email ?? ""]) {(error) in
            if let e = error {
                print("error \(e)")
                return
            }
        }
        
        self.presentNote.comment?.append(note)
        self.presentData.append(self.presentNote)
        self.tableView.reloadData()
    }
    @objc func loadData(){
        self.presentData = [presentData[0]]
        self.presentNote.comment = []
        self.queryPresentFromFirebase()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                
                self.refreshControl.endRefreshing()
                let cellCount = self.presentData.count - 1
                let indexpath = IndexPath(row: cellCount, section: 0)
                self.tableView.scrollToRow(at: indexpath, at: .bottom, animated: true)
            
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
   
    override func viewDidLoad() {
        super.viewDidLoad()
        presentDb = Firestore.firestore()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadData), for: UIControl.Event.valueChanged)
       // self.tableView.separatorStyle = .none
        queryPresentFromFirebase()
        self.presentToolBar.tintColor = .white
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }

}

