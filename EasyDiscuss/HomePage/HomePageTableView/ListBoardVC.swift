//
//  ChildTwoVC.swift
//  SGPagingViewExample
//
//  Created by kingsic on 2018/9/15.
//  Copyright © 2018年 kingsic. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol listVCDelegate : class {
    func addFavorite (note: Note)
    func deleteFavorite (note: Note)
}

protocol VisitedVCDelegate : class {
    func addVisited (note: Note)
}

class ListBoardVC: UIViewController, UITableViewDelegate,FavoriteVCDelegate, contentVCDelegate{
    @IBOutlet weak var tableView: UITableView!
    var db : Firestore!
    var data : [Note] = []
    var emailData : [Note] = []
    var listNote : Note!
    var listIsFavorite = Array(repeating: false, count: 20)
    weak var FavoriteDelegate : listVCDelegate?
    weak var VisitedDelegate : VisitedVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
        longpress.minimumPressDuration = 0.6
        longpress.cancelsTouchesInView = true
        self.tableView.addGestureRecognizer(longpress)
        self.view.backgroundColor = .clear
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.tableView.delegate = self
        tableView.register(UINib(nibName: "ListBoardVCCell", bundle: nil), forCellReuseIdentifier: "BoardVCCell")
        db = Firestore.firestore()
        queryFromFirebase()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let contentVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ContentVC") as? ContentViewController{
            
            if let path = self.tableView.indexPathForSelectedRow{
                print("點擊傳入visited")
               
                    self.VisitedDelegate?.addVisited(note: self.data[path.row])
                contentVC.contentResponseData = []
                contentVC.contentDelegate = self
                contentVC.listToContentNote = self.data[indexPath.row]
            }
            contentVC.modalPresentationStyle = .overFullScreen
            self.navigationController?.pushViewController(contentVC, animated: true)
           
        }
        
        let didSelectCell = self.tableView.cellForRow(at: indexPath)
        didSelectCell?.textLabel?.textColor = .red
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func queryFromFirebase() {
        
        db.collection("Note").order(by: "text", descending: true).addSnapshotListener { (query, error) in
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
                    note.noteID = noteID
                    self.data.insert(note, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                } else if change.type == .modified {
                    //透過noteID找到note物件在data中的位置，才能進行note物件更新，更新畫面
                    if let modifiedNote = self.data.filter({ (note) -> Bool in //filter 過濾
                        return note.noteID == noteID
                    }).first,  let index = self.data.firstIndex(of: modifiedNote) {
                        modifiedNote.text = change.document.data()["text"] as? String ?? ""
                        modifiedNote.cellImageName = change.document.data()["cellImageName"] as? String ?? ""
                        let indexpath = IndexPath(row: index, section: 0)
                        self.tableView.reloadRows(at: [indexpath], with: .automatic)
                    }
                } else if change.type == .removed{
                    if let removedNote = self.data.filter({ (note) -> Bool in //filter 過濾
                        return note.noteID == noteID
                    }).first,  let index = self.data.firstIndex(of: removedNote) {
                        self.data.remove(at: index)
                        let indexpath = IndexPath(row: index, section: 0)
                        self.tableView.deleteRows(at: [indexpath], with: .automatic)
                    }
                }
            }
        }
    }
    
    func noticeFavoritedataIsDelete(note: Note) {
        if let index = self.data.firstIndex(of: note){
            self.listIsFavorite.remove(at: index)
            let indexpath = IndexPath(row: index, section: 0)
            let cell = self.tableView.cellForRow(at: indexpath) as? ListBoardVCCell
            cell?.starImageView.image = nil
            print("星星不見了")
        }
        
        else {
            print("此note不存在data")
        }
    }
    func contentToList(note: Note) {
        if let index = self.data.firstIndex(of: note){
        self.listNote = note
            let indexpath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexpath], with: .automatic)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func longPress(sender:UILongPressGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.tableView)
        print(touchPoint)
        if sender.state == .began {
            let alertController = UIAlertController(title: "你想要做什麼?", message: "", preferredStyle: .actionSheet)
            if let indexpath = self.tableView.indexPathForRow(at: touchPoint){
                
                let okTitle = self.listIsFavorite[indexpath.row] ? "從我的最愛移除" : "加入我的最愛"
                if self.listIsFavorite[indexpath.row] == false {
                    
                    let okAction = UIAlertAction(title: okTitle, style: .default) { (action) in
                        
                        self.listIsFavorite[indexpath.row] = self.listIsFavorite[indexpath.row] ? false : true
                        self.FavoriteDelegate?.addFavorite(note: self.data[indexpath.row])
                        
                        
                        print("長按傳入favorite")
                    }
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                        print("取消")
                    }
                    alertController.addAction(okAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController,animated: true, completion: nil)
                }
                else {
                    
                    let deleteAction = UIAlertAction(title: okTitle, style: .destructive) { (action) in
                        print("從我的最愛移出")
                        self.listIsFavorite[indexpath.row] = self.listIsFavorite[indexpath.row] ? false : true
                        self.FavoriteDelegate?.deleteFavorite(note: self.data[indexpath.row])
                        let cell = self.tableView.cellForRow(at: indexpath) as? ListBoardVCCell
                        cell?.starImageView.image = nil
                        print("長按刪除favorite")
                        
                    }
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                        print("取消")
                    }
                    alertController.addAction(deleteAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController,animated: true, completion: nil)
                    
                }
            }
        }
    }

}
extension ListBoardVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardVCCell") as? ListBoardVCCell
        cell?.textLabel?.text = self.data[indexPath.row].text
        cell?.textLabel?.textColor = .white
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
        cell?.backgroundColor = .clear
        cell?.starImageView.image = nil
        return cell!
    }
}
