//
//  LoginViewController.swift
//  patHosMap
//
//  Created by 陳逸煌 on 2020/7/20.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
class LoginViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var bannerview: GADBannerView!
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var busy: UIActivityIndicatorView!
    var locationManager = CLLocationManager()
    var root:DatabaseReference!
    var observer:UInt = 0
    var count = 0
    var manager_array:[[String:String]] = []
    @IBAction func login(_ sender: UIButton) {
        busy.isHidden = false
        let user = root.child("user")
        var is_manager = false
        user.observeSingleEvent(of: .value) { (data) in
            print(data.value!)
            self.manager_array = (data.value! as? [[String:String]])!
            print(self.manager_array)
            for manager in self.manager_array{
                self.count += 1
                print(manager)
                print("登入頁面\(self.count)的資料")
                if manager["account"] == self.account.text && manager["password"] == self.password.text{
                    is_manager = true
                    break
                }
            }
            if is_manager{
                print("使用者登入成功")
                let little_data_center:UserDefaults
                little_data_center = UserDefaults.init()
                little_data_center.set(self.count, forKey: "userID")
                user.removeObserver(withHandle: self.observer)
                self.observer = 0
                self.performSegue(withIdentifier: "login", sender: nil)
                self.busy.isHidden = true
            }
            else{
                print("登入失敗")
                let alert = UIAlertController(title: "警告", message: "帳密有誤", preferredStyle: .alert)
                let button = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default) { (button) in
                }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
                self.busy.isHidden = true
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        root = Database.database().reference()
        busy.isHidden = true
        locationManager.requestWhenInUseAuthorization()
        password.clearButtonMode = .always
        password.clearButtonMode = .whileEditing
        account.clearButtonMode = .always
        account.clearButtonMode = .whileEditing    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //編輯用鍵盤使用結束後收起
        self.view.endEditing(true)
    }
    @IBAction func didEndOnExit(_ sender: UITextField){
        //只需對應，即可按下Return鍵收起鍵盤！
    }
}
