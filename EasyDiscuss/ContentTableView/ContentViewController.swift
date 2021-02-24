//
//  ContentViewController.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/2.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol contentVCDelegate : class {
    func contentToList(note: Note)
}
protocol contentVCToPresentDelegate : class {
    func reciveContentTitle (note: Note)
    func reciveContentNoteID(note: Note)
}

class ContentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, addArticleViewControllerDelegate{
 
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var tableView: UITableView!
    var contentdb : Firestore!
    var contentData : [Note] = [ ]
    var contentCurrentNote : Note!
    var listToContentNote : Note!
    var contentTitleToPresent : Note!
    var contentNoteIDToPresent : Note!
    var contentBoardClassification : Note!
    var contentResponseData : [Note] = []
    var contentNoteIDData : [Note] = []
    var NoteIDNote : Note!
    var loginHandle: AuthStateDidChangeListenerHandle?
    var refreshControl:UIRefreshControl!
    weak var contentDelegate : contentVCDelegate?
    weak var contentVCToPresentVCDelegate : contentVCToPresentDelegate?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.contentData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contentcell", for: indexPath) as! ContentTableViewCell
        cell.titleLabelOutlet.text = self.contentData[indexPath.row].text
        cell.classificationLabelOutlet.text = self.contentData[indexPath.row].classification
        cell.authorLabelOutlet.text = "作者：\(self.contentData[indexPath.row].nickName ?? "")"
        cell.backgroundColor = .clear
        cell.moreOutlet.tag = indexPath.row
        cell.dateLabelOutlet.text = self.contentData[indexPath.row].time
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    @IBAction func addArticle(_ sender: Any) {
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                
                if let addArticleVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "articleVC") as? AddArticleViewController{
                    addArticleVC.addArticleDelegate = self
                    addArticleVC.modalPresentationStyle = .overFullScreen
                    self.present(addArticleVC, animated: true, completion: nil)
                }
            }
            else {
                let alertController = UIAlertController(title: "發表文章需要登入帳號喔！", message: "", preferredStyle: .alert)
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
    @IBAction func refreshTable(_ sender: Any) {
        
       
        refreshControl.beginRefreshing()
        
       
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.bounds.height)
        }) { (finish) in
            self.loadData()
            
        }
        
    }
    
    func addArticleToContent(note: Note) {
        contentBoardClassification = note
        
        guard let contentBC = contentBoardClassification.boardclassification else {return}
        
        contentdb.collection("commentNote").document(contentBC).collection(contentBC).document(note.noteID).setData(["text":note.text, "classification":note.classification ?? "", "textViewText":note.textViewText ?? "" ,"boardclassification":note.boardclassification ?? "","time": note.time ?? "", "longtime": note.longtime ?? "", "nickName":note.nickName ?? "","imageName": note.imageName ?? "" ])
        {(error) in
            if let e = error {
                print("error \(e)")
                return
            }
            self.contentCurrentNote = note
            self.contentTitleToPresent = note
            self.contentNoteIDToPresent = note
            self.contentData.insert(note, at: 0)
            self.tableView.reloadData()
            self.contentDelegate?.contentToList(note: self.contentCurrentNote)
        }
        
    }
    @IBAction func contentToTop(_ sender: Any) {
        if contentData != [] {
            let indexpath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexpath, at: .top, animated: true)
        }
    }
    @IBAction func contentToBottom(_ sender: Any) {
        if contentData != [] {
            let cellCount = self.contentData.count - 1
            let indexpath = IndexPath(row: cellCount, section: 0)
            self.tableView.scrollToRow(at: indexpath, at: .bottom, animated: true)
        }
    }
    @objc func loadData(){
        self.contentData = []
        self.queryContentFromFirebase()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                
                self.refreshControl.endRefreshing()
                if self.contentData != []{
                let indexpath = IndexPath(row: 0, section: 0)
                self.tableView.scrollToRow(at: indexpath, at: .top, animated: true)
                }
            }
      
        }
    
    @IBAction func MoreAction(_ sender: UIButton) {
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            let index = sender.tag
            let indexpath = IndexPath(row: index, section: 0)
            
            if self.contentData[indexpath.row].imageName == user?.email {
                let alertController = UIAlertController(title: "你想要做什麼？", message: "", preferredStyle: .actionSheet)
                let editAction = UIAlertAction(title: "編輯文章內容", style: .default) { (action) in
                    let textAlertController = UIAlertController(title: "下方更改你的發文內容", message: "", preferredStyle: .alert)
                    
                    textAlertController.addTextField { (textField) in
                        textField.text = self.contentData[indexpath.row].textViewText
                        
                        let confirmAction = UIAlertAction(title: "修改發文", style: .default) { (action) in
                            
                            guard let contentBC = self.contentBoardClassification.boardclassification else {return}
                            self.contentdb.collection("commentNote").document(contentBC).collection(contentBC).document(self.contentData[indexpath.row].noteID).updateData(["textViewText": textField.text ?? "" ]){(error) in
                                if let e = error {
                                    print("error \(e)")
                                    return
                                }
                            }
                            self.contentData = []
                            self.queryContentFromFirebase()
                            
                        }
                        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                            print("取消")
                        }
                        textAlertController.addAction(confirmAction)
                        textAlertController.addAction(cancelAction)
                        self.present(textAlertController, animated: true, completion: nil)
                    }
                }
                let deleteAction = UIAlertAction(title: "刪除文章", style: .destructive) { (action) in
                    guard let contentBC = self.contentBoardClassification.boardclassification else {return}
                    
                    self.contentdb.collection("commentNote").document(contentBC).collection(contentBC).document(self.contentBoardClassification.noteID).delete()
                    self.contentData.remove(at: index)
                    self.tableView.deleteRows(at: [indexpath], with: .automatic)
                    
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                    print("取消")
                }
                alertController.addAction(editAction)
                alertController.addAction(deleteAction)
                alertController.addAction(cancelAction)
                self.present(alertController,animated: true, completion: nil)
            }
            else {
                print("Email錯誤")
                let errorAlertController = UIAlertController(title: "您沒有權限做此動作", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                    print("確認")
                }
                errorAlertController.addAction(confirmAction)
                self.present(errorAlertController, animated: true, completion: nil)
            }
        }
    }
    func queryContentFromFirebase() {
       
        let firebaseName = listToContentNote.text
        
        contentdb.collection("commentNote").document(firebaseName).collection(firebaseName).order(by: "longtime", descending: false).getDocuments{(query, error) in
            if let e = error {
                print("error123 \(e)")
                return
            }
            guard let changes = query?.documentChanges else { print("guard let fail")
                return }
            for change in changes {
                let noteID = change.document.documentID
                if change.type == .added {
                    let contentdata = change.document.data()
                    let note = Note(text: "")
                    note.text = contentdata["text"] as? String ?? ""
                    note.imageName = contentdata["imageName"] as? String
                    note.classification = contentdata["classification"] as? String
                    note.responseText = contentdata["responseText"] as? String
                    note.textViewText = contentdata["textViewText"] as? String
                    note.boardclassification = contentdata["boardclassification"] as? String
                    note.comment = contentdata["comment"] as? [sNote]
                    note.time = contentdata["time"] as? String
                    note.longtime = contentdata["longtime"] as? String
                    note.nickName = contentdata["nickName"] as? String
                    note.eMail = contentdata["imageNames"] as? String
                    note.noteID = noteID
                    self.contentData.insert(note, at: 0)
                    self.NoteIDNote = note
                    self.contentBoardClassification = note
                    self.contentNoteIDData.append(self.NoteIDNote)
                    self.queryResponseFromFirebase()
                    self.tableView.reloadData()
                    
                } else if change.type == .modified {
        
                    print("modifed")
                    if let modifiedNote = self.contentData.filter({ (note) -> Bool in 
                        return note.noteID == noteID
                    }).first,  let index = self.contentData.firstIndex(of: modifiedNote) {
                        modifiedNote.text = change.document.data()["text"] as? String ?? ""
                        modifiedNote.imageName = change.document.data()["imageName"] as? String
                        modifiedNote.classification = change.document.data()["classification"] as? String
                        modifiedNote.responseText = change.document.data()["responseText"] as? String
                        modifiedNote.textViewText = change.document.data()["textViewText"] as? String
                        modifiedNote.boardclassification = change.document.data()["boardclassification"] as? String
                        modifiedNote.comment = change.document.data()["comment"] as? [sNote]
                        let indexpath = IndexPath(row: index, section: 0)
                        self.tableView.reloadRows(at: [indexpath], with: .automatic)
                    }
                }
            }
        }
        
    }
    func queryResponseFromFirebase() {
       
        
        let firebaseName = listToContentNote.text

        contentdb.collection("commentNote").document(firebaseName).collection(firebaseName).document(self.NoteIDNote.noteID).collection(self.NoteIDNote.noteID).getDocuments{(query, error) in
            if let e = error {
                print("error123 \(e)")
                return
            }
            guard let changes = query?.documentChanges else { print("guard let fail")
                return }
            for change in changes {
                let noteID = change.document.documentID
                if change.type == .added {
                    let contentdata = change.document.data()
                    let note = Note(text: "")
                    note.text = contentdata["Responsetext"] as? String ?? ""
                    note.noteID = noteID
                    let resNote = note
                    if resNote.respcount == nil {
                        resNote.respcount = []
                    }
                    
                    resNote.respcount?.append(note)
                    self.contentResponseData.append(resNote)
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "presentVCSegue" {
            if let indexpath = self.tableView.indexPathForSelectedRow {
                let presentVC = segue.destination as! PresentViewController
                presentVC.presentData.insert(self.contentData[indexpath.row], at: 0)
                presentVC.presentNote = self.contentData[indexpath.row]
                presentVC.reciveContentTitle = self.contentData[indexpath.row]
                presentVC.reciveContenNoteID = self.contentData[indexpath.row]
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        contentdb = Firestore.firestore()
        queryContentFromFirebase()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadData), for: UIControl.Event.valueChanged)
        self.navigationController?.navigationBar.tintColor = .white
        self.toolBar.tintColor = .white
        
    }
    
}

