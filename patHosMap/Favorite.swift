 //
//  Favorite.swift
//  patHosMap
//
//  Created by 陳逸煌 on 2020/7/26.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class Favorite: UITableViewController, UIActionSheetDelegate {

    var hospitalsArray:[[String:String]] = [[:]]
    var userFavoriteNameArray:[String]! = []
    var userFavoriteName:String!
    let userDefault = UserDefaults()
    var userAccount:String?
    var downloadSingle = 0
    fileprivate let application = UIApplication.shared
    
    override func viewWillAppear(_ animated: Bool) {
        getFavorite()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        userAccount = self.userDefault.string(forKey: "account")
        download()
        getFavorite()
        self.navigationItem.title = "我的最愛"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(buttonEditAction))
        tableView.rowHeight = 70
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("資料載入中")
        if downloadSingle == 1{
            if userFavoriteNameArray != [""]{
                return userFavoriteNameArray.count
            }
            else{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "通知", message: "目前無資料，請先至清單增加", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                        self.tabBarController?.selectedIndex = 1
                    }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }
                return 0
            }
        }
        else{
            return 0
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = UITableViewCell()
        cell.textLabel?.text = self.userFavoriteNameArray[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        //表格背景顏色
        cell.backgroundColor = UIColor(red: 247/255, green: 255/255, blue: 247/255, alpha: 0.8)
        //表格點擊顏色
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(displayP3Red: 255/255, green: 230/255, blue: 109/255, alpha: 0.5)
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //使用者點到哪間
        print(userFavoriteNameArray[indexPath.row])
        
        //比對大資料
        for hospital in self.hospitalsArray
        {
            if hospital["name"]! == userFavoriteNameArray[indexPath.row]
            {
                print(hospital["address"]!)
                //初始化地理資訊編碼器
                let alert: UIAlertController = UIAlertController(title: "", message: "請選擇", preferredStyle: .actionSheet)
                
                let cancelActionButton = UIAlertAction(title: "取消", style: .cancel) { _ in
                    print("Cancel")
                }
                alert.addAction(cancelActionButton)

                let saveActionButton = UIAlertAction(title: "電話", style: .default)
                    { _ in
                       print("打電話")
                        let phoneNumber = hospital["number"]!
                        if let phoneURL = URL(string: "tel://\(phoneNumber)")
                        {
                            if self.application.canOpenURL(phoneURL)
                            {
                                self.application.open(phoneURL, options: [:], completionHandler: nil)
                            }
                            else
                            {
                                //alert
                            }
                        }
                }
                alert.addAction(saveActionButton)

                let deleteActionButton = UIAlertAction(title: "地圖", style: .default)
                    { _ in
                        let geoCoder = CLGeocoder()
                       geoCoder.geocodeAddressString(hospital["address"]!) { (arrPlacemark, error)
                           in
                           if error != nil
                           {
                               print("地址解碼錯誤:\(error.debugDescription)")
                               return
                           }
                
                           //arrPlacemark回傳[CLPlacemark]?是陣列選擇值
                           //當確定可以取得地址所對應的經緯度資訊時，確認陣列的第一個元素是否為nil
                           if let toPlacemark = arrPlacemark?.first
                           {
                               //將經緯度資訊轉換成導航地圖上目的地的大頭針
                               let toPin = MKPlacemark(placemark: toPlacemark)
                               //設定導航模式選項字典，給openInMaps使用，固定用法，可選開車/行走模式
                               let naviOption = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                               //產生導航地圖上目的地的大頭針
                               let destinationMapItem = MKMapItem(placemark: toPin)
                               //從現在位置導航到目的地
                               destinationMapItem.openInMaps(launchOptions: naviOption)
                           }
                       }
                }
                alert.addAction(deleteActionButton)
                self.present(alert, animated: true, completion: nil)
              
            }
            else
            {
                print("資料尚未下載完成或無資料")
            }
        }

    }
    
    // MARK: - Table view Delegate
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath){
        //修改排序
        self.userFavoriteNameArray!.insert(self.userFavoriteNameArray!.remove(at: fromIndexPath.row), at: to.row)
        print(self.userFavoriteNameArray!)
        updateFavorite()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        print("進入刪除")
        self.userFavoriteNameArray!.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        updateFavorite()
        print("刪除tableROW")
    }
    
    // MARK: - 自訂函式
    func download(){
        print("下載大資料")
        let session:URLSession = URLSession(configuration: .default)
        let task:URLSessionDataTask = session.dataTask(with: URL(string:"http://yi-huang.tw/select.php")!){
            (data,reponse,err)
            in
            if let error = err{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }

            }
            else{
                do{
                    self.hospitalsArray = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as! [[String:String]]
//                    print(self.hospitalsArray)
                }catch{
                    print("伺服器出錯\(error)")
                }
            }
        }
        task.resume()
    }
    func getFavorite() -> Void {
        print(self.userAccount!)
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/getFavorite.php?account=%@",userAccount!))!){ [self]
            (data,reponse,err)
            in
            if let error = err{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }
            }
            else{
                self.userFavoriteName = String(data: data!, encoding:.utf8)!
                self.userFavoriteName = self.userFavoriteName?.filter({ Character in
                    Character != " "
                })
                print("使用者最愛在這位處理\(self.userFavoriteName!)")
                self.userFavoriteNameArray = self.userFavoriteName.components(separatedBy: ",")
                print("使用者最愛陣列\(self.userFavoriteNameArray!)")
                DispatchQueue.main.async {
                    self.downloadSingle = 1
                    self.tableView.reloadData()
                }
                
            }
        }
        task.resume()
    }
    func updateFavorite(){
        print("使用者帳號\(self.userAccount!)")
        let tempData:String? = self.userFavoriteNameArray?.joined(separator: ",")
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/updateFavorite.php?account=%@&favorite=%@",userAccount!,tempData!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!){ [self]
            (data,reponse,err)
            in
            if let error = err{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }
            }
            else{
                print("最愛已更動\(self.userFavoriteNameArray!)")
            }
        }
        task.resume()
    }
    @objc func buttonEditAction(){
        print("編輯按鈕被按下")
        if !self.tableView.isEditing{
        self.tableView.isEditing = true
        self.navigationItem.leftBarButtonItem?.title = "完成"
        }
        else{
            self.tableView.isEditing = false
            self.navigationItem.leftBarButtonItem?.title = "編輯"
        }

    }
}
