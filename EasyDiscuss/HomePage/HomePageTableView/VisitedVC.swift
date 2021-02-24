//
//  ChildThreeVC.swift
//  SGPagingViewExample
//
//  Created by kingsic on 2018/9/15.
//  Copyright © 2018年 kingsic. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class VisitedVC: UIViewController, UITableViewDelegate, VisitedVCDelegate {
    @IBOutlet weak var visitedTableView: UITableView!
    var visitedDb : Firestore!
    var visitedData : [Note] = []
    var loginHandle: AuthStateDidChangeListenerHandle?
    override func viewDidLoad() {
        super.viewDidLoad()
        listBoardToVisitedDelegate()
        queryFromFirebase()
        view.backgroundColor = UIColor.clear
        self.visitedTableView.backgroundColor = .clear
        self.visitedTableView.separatorStyle = .none
        self.visitedTableView.delegate = self
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
   
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.visitedTableView.reloadData()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let contentVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ContentVC") as? ContentViewController{
            
            contentVC.modalPresentationStyle = .overFullScreen
            contentVC.listToContentNote = self.visitedData[indexPath.row]
            self.navigationController?.pushViewController(contentVC, animated: true)
            
        }
        let didSelectCell = self.visitedTableView.cellForRow(at: indexPath)
        didSelectCell?.textLabel?.textColor = .red
        self.visitedTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func addVisited (note: Note){
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.visitedDb.collection("visitedNote").document(user.email ?? "").collection(user.email ?? "").document(note.noteID).delete()
                
                self.visitedDb.collection("visitedNote").document(user.email ?? "").collection(user.email ?? "").document(note.noteID).setData(["text":note.text]) {(error) in
                    if let e = error {
                        print("error \(e)")
                        return
                    }
                }
            }
        }
    }
    
    func listBoardToVisitedDelegate (){
        let listBoardVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "listVC") as? ListBoardVC
        listBoardVC?.VisitedDelegate = self
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func queryFromFirebase() {
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.visitedDb.collection("visitedNote").document(user.email ?? "").collection(user.email ?? "").addSnapshotListener{(query, error) in
                    if let e = error {
                        print("error \(e)")
                        return
                    }
                    guard let changes = query?.documentChanges else { return }
                    for change in changes {
                        let noteID = change.document.documentID // 利用document = noteID
                        if change.type == .added {//新增狀況
                            //取得資料，轉成note物件，放回self.data，呼叫insertRows
                            let data = change.document.data()
                            let note = Note(text: "")
                            note.text = data["text"] as? String ?? ""
                            note.imageName = data["imageName"] as? String
                            note.boardclassification = data["boardclassification"] as? String
                            note.noteID = noteID
                            self.visitedData.insert(note, at: 0)
                            self.visitedTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                        } else if change.type == .modified {
                            //透過noteID找到note物件在data中的位置，才能進行note物件更新，更新畫面
                            if let modifiedNote = self.visitedData.filter({ (note) -> Bool in //filter 過濾
                                return note.noteID == noteID
                            }).first,  let index = self.visitedData.firstIndex(of: modifiedNote) {
                                modifiedNote.text = change.document.data()["text"] as? String ?? ""
                                let indexpath = IndexPath(row: index, section: 0)
                                self.visitedTableView.reloadRows(at: [indexpath], with: .automatic)
                            }
                            else if change.type == .removed{
                                if let removedNote = self.visitedData.filter({ (note) -> Bool in //filter 過濾
                                    return note.noteID == noteID
                                }).first,  let index = self.visitedData.firstIndex(of: removedNote) {
                                    self.visitedData.remove(at: index)
                                    let indexpath = IndexPath(row: index, section: 0)
                                    self.visitedTableView.deleteRows(at: [indexpath], with: .automatic)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



extension VisitedVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.visitedData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellID")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cellID")
        }
        cell?.textLabel?.text = self.visitedData[indexPath.row].text
        cell?.textLabel?.textColor = .white
        cell?.backgroundColor = .clear
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
        return cell!
    }
}
