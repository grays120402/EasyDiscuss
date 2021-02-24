//
//  ScrollVC.swift
//  SGPagingViewExample
//
//  Created by kingsic on 2018/9/15.
//  Copyright © 2018年 kingsic. All rights reserved.
//

import UIKit
import Firebase
import KRProgressHUD
import GoogleSignIn

class ScrollVC: UIViewController, LoginVCDelegate {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("ScrollVC")
    }
    private var pageTitleView: SGPageTitleView? = nil
    private var pageContentScrollView: SGPageContentScrollView? = nil
    let oneVC = FavoriteVC()
    let twoVC = ListBoardVC()
    let threeVC = VisitedVC()
    var loginHandle: AuthStateDidChangeListenerHandle?
    var loginBool : Bool = false
    var listEmailNote : Note!
    var Email : String?
    @IBOutlet weak var loginBtnOutlet: UIBarButtonItem!
    @IBOutlet weak var checkLoginSatusBtnOutlet: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        threeVC.visitedDb = Firestore.firestore()
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        setupSGPagingView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.loginBtnOutlet.title = "登出"
                self.loginBool = true
                self.checkLoginSatusBtnOutlet.tintColor = .green
                self.listEmailNote = Note(text: "")
                self.listEmailNote.eMail = user.email
                
            }
            else{
                self.loginBtnOutlet.title = "登入"
                self.loginBool = false
                self.checkLoginSatusBtnOutlet.tintColor = .lightGray
                print("沒有 login")
            }
        }
    }
    deinit {
        print("ScrollVC - - deinit")
    }
    @IBAction func loginAction(_ sender: Any) {
        if loginBool == false {
            loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    self.loginBtnOutlet.title = "登出"
                    self.loginBool = true
                    print("\(user.email) login")
                } else {
                    print("沒有 login")
                    let alertController = UIAlertController(title: "首次登入請先註冊帳號", message: "", preferredStyle: .alert)
                    let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                        print("確認")
                        if let loginVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "loginVC") as? LoginViewController{
                            loginVC.modalPresentationStyle = .overFullScreen
                            loginVC.LoginDelegate = self
                            self.present(loginVC, animated: true, completion: nil)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                        print("取消")
                    }
                    alertController.addAction(confirmAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController,animated: true, completion: nil)
                }
            }
        }
        else {
            
            let alertController = UIAlertController(title: "確定要登出嗎？", message: "", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "確認", style: .default) { (action) in
                KRProgressHUD.show(withMessage: "登出中，請稍候", completion: nil)
                do {
                    try Auth.auth().signOut()
                    GIDSignIn.sharedInstance().signOut()
                    self.loginBtnOutlet.title = "登入"
                    self.loginBool = false
                    self.oneVC.favoritedata = []
                    self.oneVC.FavoriteTableView.reloadData()
                    print("已登出")
                } catch {
                    print(error)
                }
                KRProgressHUD.dismiss()
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                print("取消")
            }
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func checkLoginSatusBtnAction(_ sender: Any) {
        
        loginHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                
                if let memberVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "memberVC") as? memberSatusViewController{
                    self.navigationController?.pushViewController(memberVC, animated: true)
                    print(user.email)

                    memberVC.memberEmailNote = self.listEmailNote
                }
            }
            else {
                let alertController = UIAlertController(title: "你沒有登入哦，要登入嗎？", message: "", preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "登入", style: .default) { (action) in
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
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    func loginToList (note:Note){
        self.listEmailNote = note
    }
}

extension ScrollVC {
    private func setupSGPagingView() {
        let statusHeight = UIApplication.shared.statusBarFrame.height
        var pageTitleViewY: CGFloat = 0.0
        if statusHeight == 20 {
            pageTitleViewY = 64
        } else {
            pageTitleViewY = 88
        }
        
        let titles = ["我的最愛", "看板列表", "最近訪問"]
        let configure = SGPageTitleViewConfigure()
        configure.indicatorAdditionalWidth = 10 // 说明：指示器额外增加的宽度，不设置，指示器宽度为标题文字宽度；若设置无限大，则指示器宽度为按钮宽度
        configure.titleGradientEffect = true
        
        self.pageTitleView = SGPageTitleView(frame: CGRect(x: 0, y: pageTitleViewY, width: view.frame.size.width, height: 44), delegate: self, titleNames: titles, configure: configure)
        view.addSubview(pageTitleView!)
        
        let childVCs = [oneVC, twoVC, threeVC]
        twoVC.FavoriteDelegate = oneVC
        twoVC.VisitedDelegate = threeVC
        oneVC.favoriteVCDelegate = twoVC
        let contentViewHeight = view.frame.size.height - self.pageTitleView!.frame.maxY
        print(contentViewHeight)
        let contentRect = CGRect(x: 0, y: (pageTitleView?.frame.maxY)! + 3 , width: view.frame.size.width, height: contentViewHeight)
        self.pageContentScrollView = SGPageContentScrollView(frame: contentRect, parentVC: self, childVCs: childVCs)
        pageContentScrollView?.delegateScrollView = self
        view.addSubview(pageContentScrollView!)
    }
}

extension ScrollVC: SGPageTitleViewDelegate, SGPageContentScrollViewDelegate {
    func pageTitleView(pageTitleView: SGPageTitleView, index: Int) {
        pageContentScrollView?.setPageContentScrollView(index: index)
    }
    
    func pageContentScrollView(pageContentScrollView: SGPageContentScrollView, progress: CGFloat, originalIndex: Int, targetIndex: Int) {
        pageTitleView?.setPageTitleView(progress: progress, originalIndex: originalIndex, targetIndex: targetIndex)
    }
    
}



