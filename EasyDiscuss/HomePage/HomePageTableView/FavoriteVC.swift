

import UIKit
import Firebase
import FirebaseFirestore
protocol FavoriteVCDelegate : class {
    func noticeFavoritedataIsDelete(note: Note)
}

class FavoriteVC: UIViewController, UITableViewDelegate,UIActionSheetDelegate, listVCDelegate {

    public lazy var FavoriteTableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    var loginHandle: AuthStateDidChangeListenerHandle?
    var favoritedb : Firestore!
    var favoritedata : [Note] = []
    weak var favoriteVCDelegate : FavoriteVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        listBoardToFavoriteDelegate()
        favoritedb = Firestore.firestore()
        queryFromFirebase()
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
        longpress.minimumPressDuration = 0.6
        longpress.cancelsTouchesInView = true
        self.FavoriteTableView.addGestureRecognizer(longpress)
        self.FavoriteTableView.backgroundColor = .clear
        self.FavoriteTableView.separatorStyle = .none
        self.FavoriteTableView.rowHeight = 60
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        view.addSubview(self.FavoriteTableView)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.FavoriteTableView.reloadData()
    }
    func listBoardToFavoriteDelegate (){
        let listBoardVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "listVC") as? ListBoardVC
        listBoardVC?.FavoriteDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let contentVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ContentVC") as? ContentViewController{
            
            contentVC.modalPresentationStyle = .overFullScreen
            
            contentVC.listToContentNote = self.favoritedata[indexPath.row]
            
            self.navigationController?.pushViewController(contentVC, animated: true)
        }
        let didSelectCell = self.FavoriteTableView.cellForRow(at: indexPath)
        didSelectCell?.textLabel?.textColor = .red
        self.FavoriteTableView.deselectRow(at: indexPath, animated: true)
    }
    @objc func longPress(sender:UILongPressGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.FavoriteTableView)
        print(touchPoint)
        if sender.state == .began {
            let alertController = UIAlertController(title: "你想要做什麼?", message: "", preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "從我的最愛移除", style: .destructive) { (action) in
                print("加入我的最愛")
                if let indexpath = self.FavoriteTableView.indexPathForRow(at: touchPoint){
                    print("長按移除favorite")
                    self.favoriteVCDelegate?.noticeFavoritedataIsDelete(note: self.favoritedata[indexpath.row])
                    self.deleteFavorite(note: self.favoritedata[indexpath.row])
                    self.FavoriteTableView.deleteRows(at: [indexpath], with: .automatic)
                    
                }
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                print("取消")
            }
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true, completion: nil)
        }
    }
    func addFavorite (note: Note){
        if self.favoritedata.contains(note){
            
            print("note已存在")
        }
        else {
            loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    
                    self.favoritedb.collection("favoriteNote").document(user.email ?? "").collection(user.email ?? "").document(note.noteID).setData(["text":note.text]) {(error) in
                        if let e = error {
                            print("error \(e)")
                            return
                        }
                        self.favoritedata.insert(note, at: 0)
                        print("note已傳入favoritedata")
                    }
                }
            }
        }
    }
    func deleteFavorite (note: Note){
        if favoritedata.contains(note){
            if let index = self.favoritedata.firstIndex(of: note){
                self.favoritedata.remove(at: index)
                favoritedb.collection("favoriteNote").document(note.noteID).delete()
            }
        }
        else {
            print("此note不存在favoritedata")
        }
    }
    func queryFromFirebase() {
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.favoritedb.collection("favoriteNote").document(user.email ?? "").collection(user.email ?? "").getDocuments{(query, error) in
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
                            self.favoritedata.insert(note, at: 0)
                            self.FavoriteTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                        } else if change.type == .modified {
                            //透過noteID找到note物件在data中的位置，才能進行note物件更新，更新畫面
                            if let modifiedNote = self.favoritedata.filter({ (note) -> Bool in //filter 過濾
                                return note.noteID == noteID
                            }).first,  let index = self.favoritedata.firstIndex(of: modifiedNote) {
                                modifiedNote.text = change.document.data()["text"] as? String ?? ""
                                let indexpath = IndexPath(row: index, section: 0)
                                self.FavoriteTableView.reloadRows(at: [indexpath], with: .automatic)
                            }
                            else if change.type == .removed{
                                if let removedNote = self.favoritedata.filter({ (note) -> Bool in //filter 過濾
                                    return note.noteID == noteID
                                }).first,  let index = self.favoritedata.firstIndex(of: removedNote) {
                                    self.favoritedata.remove(at: index)
                                    let indexpath = IndexPath(row: index, section: 0)
                                    self.FavoriteTableView.deleteRows(at: [indexpath], with: .automatic)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


extension FavoriteVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favoritedata.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = "cellID"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellID)
        }
        cell?.textLabel?.text =  self.favoritedata[indexPath.row].text
        cell?.textLabel?.textColor = .white
        cell?.detailTextLabel?.text =  self.favoritedata[indexPath.row].text
        cell?.detailTextLabel?.textColor = .lightGray
        cell?.backgroundColor = .clear
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
        return cell!
    }
    
}


