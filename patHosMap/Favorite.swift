 //
//  Favorite.swift
//  patHosMap
//
//  Created by 陳逸煌 on 2020/7/26.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit

class Favorite: UITableViewController, UIActionSheetDelegate {

    var hospitalsArray:[[String:String]] = [[:]]
    var userFavoriteNameArray:[String]!
    var root:DatabaseReference!
    var datafavorite:DatabaseReference!
    var userFavoriteName:String!
    var count = 0
    var userID = 0
    var signal = 0
    var rows = 0
    fileprivate let application = UIApplication.shared
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.signal = 0
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.download()
        self.root = Database.database().reference()
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
        if self.signal != 1{
            
            DispatchQueue.main.async {
                print("進入非信號1")
                let little_data_center:UserDefaults
                little_data_center = UserDefaults.init()
                self.userID = little_data_center.integer(forKey: "userID") - 1
                print("最愛頁的\(self.userID)")
                self.root = Database.database().reference()
                self.datafavorite =  self.root.child("user").child("\(self.userID)").child("favorite")
                self.root.child("user").child("\(self.userID)").observeSingleEvent(of: .value) { (shot) in
                    print("最愛頁的\(shot.value!)")
                    let shotValue = shot.value as? [String:String] ?? [:]
                    let data = shotValue["favorite"] ?? ""
                    print(data)
                    if data != ""{
                        self.userFavoriteNameArray = data.components(separatedBy: ",")
                        print(self.userFavoriteNameArray!)
                        self.signal = 1
                        self.rows = self.userFavoriteNameArray.count
                        self.tableView.reloadData()
                    }
                    else{
                        print("找不到資料")
                        let alert = UIAlertController(title: "警告", message: "找不到資料，請先至清單頁新增醫院", preferredStyle: .alert)
                        let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                        }
                        alert.addAction(button)
                        self.present(alert, animated: true, completion: {})
                    }
                }
            }
        }
        else{
            self.rows = self.userFavoriteNameArray.count
        }
        print(self.signal)
        
        return self.rows
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
            if hospital["機構名稱"]! == userFavoriteNameArray[indexPath.row]
            {
                //print(hospital["機構地址"]!)
                //初始化地理資訊編碼器
                let alert: UIAlertController = UIAlertController(title: "", message: "請選擇", preferredStyle: .actionSheet)
                
                let cancelActionButton = UIAlertAction(title: "取消", style: .cancel) { _ in
                    print("Cancel")
                }
                alert.addAction(cancelActionButton)

                let saveActionButton = UIAlertAction(title: "電話", style: .default)
                    { _ in
                       print("打電話")
                        let phoneNumber = hospital["機構電話"]!
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
                       geoCoder.geocodeAddressString(hospital["機構地址"]!) { (arrPlacemark, error)
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
        self.userFavoriteNameArray!.insert(self.userFavoriteNameArray!.remove(at: fromIndexPath.row), at: to.row)
        self.datafavorite =  self.root.child("user").child("user\(self.userID)").child("favorite")
        self.datafavorite.setValue(self.userFavoriteNameArray!.joined(separator: ","))
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        print("進入刪除")
        self.userFavoriteNameArray!.remove(at: indexPath.row)
        print("刪除本地陣列")
        
        self.datafavorite =  self.root.child("user").child("user\(self.userID)").child("favorite")
        self.datafavorite.setValue(self.userFavoriteNameArray!.joined(separator: ","))
        print("修改資料酷")
        
        tableView.deleteRows(at: [indexPath], with: .fade)
        print("刪除tableROW")
        
        

    }
    
    // MARK: - 自訂函式
    func download() -> Void {
        let session:URLSession = URLSession(configuration: .default)
        let task:URLSessionDataTask = session.dataTask(with: URL(string:"https://data.coa.gov.tw/Service/OpenData/DataFileService.aspx?UnitId=078&$top=1000&$skip=0")!){
            (data,reponse,err)
            in
            if let error = err{
                let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
            }
            else{
                do{
                    self.hospitalsArray = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as! [[String:String]]
                    
                }catch{
                    print("伺服器出錯\(error)")
                }
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
