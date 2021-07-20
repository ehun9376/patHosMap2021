//
//  VaccTVC.swift
//  patHosMap
//
//  Created by anna on 2020/7/27.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import Firebase
class VaccTVC: UITableViewController {
    var array:[[String:String]]!
    var userID = 0
    var signal = 0
    var count = 0
    var section = 0
    var rows = 0
    var root:DatabaseReference!
    var picRef : StorageReference!
    var storage = Storage.storage()
    //MARK: - 生命循環
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.signal = 0
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.root = Database.database().reference()
        //抬頭及在左右兩側增加編輯與新增
        self.navigationItem.title = "我的寵物"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(buttonEditAction))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "新增", style: .plain, target: self, action: #selector(buttonAddAction))
        tableView.rowHeight = 110
    }
    //MARK: - target action
    @objc func buttonEditAction()
    {
        print("編輯按鈕被按下")
        if !self.tableView.isEditing//如果表格不在編輯狀態
        {
        self.tableView.isEditing = true
        self.navigationItem.leftBarButtonItem?.title = "完成"
        }
        else
        {
            self.tableView.isEditing = false
            self.navigationItem.leftBarButtonItem?.title = "編輯"
        }
    }
    @objc func buttonAddAction(){
        print("新增按鈕被按下")
        let addVC = self.storyboard!.instantiateViewController(identifier: "AddAnimal") as! AddAnimal
        addVC.VaccTVC = self
        self.show(addVC, sender: nil)
        if array != nil{
            addVC.petCount = array.count
        }
        else{
            addVC.petCount = 0
        }
        
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("資料載入中")
        if self.signal != 1{
            DispatchQueue.main.async {
                let mypet_data_center:UserDefaults
                mypet_data_center = UserDefaults.init()
                self.userID = mypet_data_center.integer(forKey: "userID") - 1
                self.root = Database.database().reference()
                let addPet = self.root.child("mypet").child("\(self.userID)")
                print(addPet)
                addPet.observeSingleEvent(of: .value) { (shot) in
                    if shot.value != nil{
                        let data = shot.value as? [[String:String]] ?? []
                        print("從網路下載的\(data)")
                        if data != [["birthday": "", "name": "", "kind": ""]]{
                            self.array = data
                            print("下載後的陣列\(self.array!)")
                            self.signal = 1
                            self.rows = self.array.count
                            self.tableView.reloadData()
                        }
                        else {
                            let alert = UIAlertController(title: "警告", message: "請先新增寵物", preferredStyle: .alert)
                            let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                            }
                            alert.addAction(button)
                            self.present(alert, animated: true, completion: {})
                        }

                    }
                    else{
                        let alert = UIAlertController(title: "警告", message: "資料下載中", preferredStyle: .alert)
                        let button = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default) { (button) in
                        }
                        alert.addAction(button)
                        self.present(alert, animated: true, completion: {})
                    }
                    
                }
            }
        }
        else{
            self.rows = self.array.count
        }

        return self.rows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell
//        cell.textLabel?.text=self.array[indexPath.row]["name"]
//        cell.imageView?.image = UIImage(named: "DefaultPhoto")
        cell.lblName.text = self.array[indexPath.row]["name"]
        cell.imgPicture.image = UIImage(named: "DefaultPhoto")
        
        self.storage = Storage.storage()
        DispatchQueue.main.async {
            self.picRef = self.storage.reference().child("data/picture/user\(self.userID)pet\(indexPath.row).jpeg")
            self.picRef.getData(maxSize: 100000000) { (bytes, error) in
                if let err = error{
                    print("下載出錯\(err)")
                    cell.imgPicture.image = UIImage(named: "DefaultPhoto")
                }else{
                    let petPic = UIImage(data: bytes!)
                    cell.imgPicture.image = petPic
                    
                }
            }
        }
        cell.accessoryType = .disclosureIndicator
        //表格背景顏色
        cell.backgroundColor = UIColor(red: 247/255, green: 255/255, blue: 247/255, alpha: 0.8)
        //表格點擊顏色
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(displayP3Red: 255/255, green: 230/255, blue: 109/255, alpha: 0.5)
        cell.selectedBackgroundView = bgColorView
        return cell
        
    }
    //畫面轉入VaccSchedule
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    count = indexPath.row
    let VaccS = self.storyboard?.instantiateViewController(identifier: "VaccSchedule") as! VaccSchedule
        self.show(VaccS, sender: nil)
        let d1 = array[indexPath.row]["birthday"]!
        let str = stringConvertDate(string: d1)
        print(str)
        VaccS.vaccDate = str
        VaccS.petName = array[indexPath.row]["name"]!
        VaccS.petKind = array[indexPath.row]["kind"]!
    }
    
    
    //左滑修改及刪除
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?{
        //準備"修改"按鈕
        let actionMore = UIContextualAction(style: .normal, title: "修改") { (action, view, completionHanlder) in
            let DetailAnimalVC = self.storyboard?.instantiateViewController(identifier: "DetailAnimalViewController") as! DetailAnimalViewController
                self.show(DetailAnimalVC, sender: nil)
            DetailAnimalVC.petID = indexPath.row
            print("修改按鈕被按下")
        }
        actionMore.backgroundColor = .blue
        //準備"刪除"按鈕//todo尚未完全 
        let actionDelete = UIContextualAction(style: .normal, title: "刪除") { (action, view, completionHanlder) in
            print("刪除tableROW, 刪除的寵物名稱是\("\(self.userID)" + self.array[indexPath.row]["name"]!)")
            UserDefaults.standard.removeObject(forKey: "\(self.userID)" + self.array[indexPath.row]["name"]!)
            print("刪除按鈕被按下")
            self.array.remove(at: indexPath.row)
            print("刪除本地陣列")
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            self.root = Database.database().reference()
            
            let delPet = self.root.child("mypet").child("\(self.userID)")
            
            if self.array == []{
                let data = [["birthday": "", "name": "", "kind": ""]]
                delPet.setValue(data)
                print("將資料庫資料設為data")
            }else{
                delPet.setValue(self.array!)
            }
            
            print("刪除後陣列：\(self.array!)")
        }
        actionDelete.backgroundColor = .systemPink
        //將兩個按鈕合併
        let config = UISwipeActionsConfiguration(actions: [actionDelete,actionMore])
        config.performsFirstActionWithFullSwipe = true
        //回傳按鈕組合
        return config
    }
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath){
        print("排序前陣列\(self.array!)")
        self.array!.insert(self.array!.remove(at: fromIndexPath.row), at: to.row)
        let movePet = self.root.child("mypet").child("\(self.userID)")
        movePet.setValue(self.array!)
    }
    
    func stringConvertDate(string:String, dateFormat:String="MMM dd, yyyy") -> Date {
            let dateFormatter = DateFormatter.init()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            let date = dateFormatter.date(from: string)
            return date!
    }
}
