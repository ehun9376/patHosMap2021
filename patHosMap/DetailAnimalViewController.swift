//
//  DetailAnimalViewController.swift
//  patHosMap
//
//  Created by 123 on 2020/7/22.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
class DetailAnimalViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var currentObjectBottomYPosition:CGFloat = 0
    weak var VaccTVC:VaccTVC!
    var currentData = 0
    var userID = 0
    var petID:Int!
    var petdata:[String:String]!
    var root:DatabaseReference!
    var editPet:DatabaseReference!
    var picRef : StorageReference!
    var storage = Storage.storage()
    var vaccTable = [vaccReminder]()
    var originalPet = ""
    var newPet = ""
    var vc:UIImagePickerController!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtBirthday: UITextField!
    let Picker = UIDatePicker()
    @IBOutlet weak var imgPicture: UIImageView!
    
    //鍵盤跳出及收回
    @IBAction func editDidBegin(_ sender: UITextField){
        print("開始編輯")
    }
    @IBAction func didEndOnExit(_ sender: UITextField)
    {
        //只需對應，即可按下Return鍵收起鍵盤！
    }
    @objc func keyboardWillShow(_ sender:Notification){
        print("鍵盤彈出")
        print("通知資訊\(sender.userInfo!)")
        if let keyBoardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height{
            print("鍵盤高度\(keyBoardHeight)")
            //計算扣除鍵盤後的可視高度
            let visibleHeight = self.view.bounds.size.height - keyBoardHeight
            print("可視高度\(visibleHeight)")
            //如果『Ｙ軸底緣位置』比『可視高度』還高，表示元件被鍵盤遮住
            if currentObjectBottomYPosition > visibleHeight{
                //移動『Ｙ軸底緣位置』與『可視高度之間的差值』（即被遮住的範圍高度，再少10點）
                self.view.frame.origin.y -= currentObjectBottomYPosition - visibleHeight + 10
            }
        }
    }
    @objc func keyboardWillHide(){
        print("鍵盤收合")
        //將畫面移回原來的位置
        self.view.frame.origin.y = 0
    }
    //MARK: - 滾輪轉換日期
    func creatDatePicker(){
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePressed))
        toolbar.setItems([done], animated: false)
        txtBirthday.inputAccessoryView = toolbar
        txtBirthday.inputView = Picker
        Picker.datePickerMode = .date
    }
    @objc func donePressed(){
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        //formatter.dateFormat = "yyyy.mm.dd"
        formatter.timeStyle = .none
        let dateString = formatter.string(from: Picker.date)
        
        txtBirthday.text = "\(dateString)"
        self.view.endEditing(true)
    }
    @IBAction func editingDidBegin(_ sender: UITextField) {
        print("開始編輯")
        switch sender.tag {
        case 3: //電話
            sender.keyboardType = .phonePad
        case 6:
            sender.keyboardType = .emailAddress
        default:
            sender.keyboardType = .default
        }
        //計算輸入元件的Ｙ軸底緣位置
        currentObjectBottomYPosition = sender.frame.origin.y + sender.frame.height
    }
    //MARK: - 生命循環
    override func viewDidLoad() {
        super.viewDidLoad()
        txtName.clearButtonMode = .always
        txtName.clearButtonMode = .whileEditing
        txtBirthday.clearButtonMode = .always
        txtBirthday.clearButtonMode = .whileEditing
        creatDatePicker()
        self.navigationItem.title = "修改資料"
        let notificationCenter = NotificationCenter.default
        //向通知中心註冊鍵盤彈出通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //向通知中心註冊鍵盤收合通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //todo
        
        let mypet_data_center:UserDefaults
        mypet_data_center = UserDefaults.init()
        self.userID = mypet_data_center.integer(forKey: "userID") - 1
        print("\(self.petID!)")
        self.root = Database.database().reference()
        self.editPet = self.root.child("mypet").child("\(self.userID)").child("\(self.petID!)/")
        editPet.observeSingleEvent(of: .value) { (shot) in
            self.petdata = (shot.value! as! [String:String])
            self.txtName.text = self.petdata["name"]
            self.txtBirthday.text = self.petdata["birthday"]
            self.originalPet = "\(self.userID)" + self.petdata["name"]!
            self.loadlist()
            self.storage = Storage.storage()
            self.picRef = self.storage.reference().child("data/picture/user\(self.userID)pet\(self.petID!).jpeg")
            DispatchQueue.main.async {
                self.picRef.getData(maxSize: 10000000) { (bytes, error) in
                    if let err = error{
                        print("下載出錯\(err)")
                    }else{
                        let petPic = UIImage(data: bytes!)
                        self.imgPicture.image = petPic
                    }
                }
            }
        }
    }
    //MARK: - target action
    @IBAction func btnUpdate(_ sender: UIButton) {
        if txtName.text!.isEmpty || txtBirthday.text!.isEmpty{
            let alert = UIAlertController(title: "資料輸入錯誤", message: "任一欄位都不可為空", preferredStyle: .alert)

            let btnok = UIAlertAction(title: "確認", style: .default, handler: nil)
            alert.addAction(btnok)
            self.present(alert, animated: true, completion: nil)
            return
        }
        else{
            self.petdata["name"] = self.txtName.text
            self.newPet = "\(userID)" + self.txtName.text!
            self.petdata["birthday"] = self.txtBirthday.text
            self.editPet.setValue(petdata)
            self.picRef = storage.reference().child("data/picture/user\(self.userID)pet\(self.petID!).jpeg")
            let jData = self.imgPicture.image!.jpegData(compressionQuality: 0.5)
            picRef.putData(jData!)
            let alert = UIAlertController(title: "完成", message: "資料修改成功！", preferredStyle: .alert)
            let btnok = UIAlertAction(title: "確定", style: .default) { (ok) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(btnok)
            self.present(alert, animated: true, completion: {})
            self.saveList()
            
        }
        
    }
    //相機
        @IBAction func btnCamera(_ sender: UIButton) {
            vc = UIImagePickerController()

            vc.sourceType = .camera
            vc.allowsEditing = true
            vc.cameraDevice = .rear
            vc.delegate = self
            self.present(vc, animated: true, completion: {})
        }
        //相簿
        @IBAction func btnPhotoAlbum(_ sender: UIButton) {
            if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                   print("此裝置沒有相簿")
                   return
               }
               //初始化影像挑選控制器
               let imagePicker = UIImagePickerController()
               //設定影像挑選控制器為相機
               imagePicker.sourceType = .photoLibrary
               //允許編輯相片
               imagePicker.allowsEditing = true
               
               //設定相機相關的代理事件
               imagePicker.delegate = self
               //開啟相簿
               self.show(imagePicker, sender: nil)
        }

        //MARK - UIImagePickerControllerDelegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("影像資訊:\(info)")
            if let image = info[.originalImage] as? UIImage{
                //將拍照結果顯示在拍照位置
                imgPicture.image = image
                //由picker退掉相機畫面
                picker.dismiss(animated: true, completion: nil)
            }
        }
    func saveList()
    {
           
        let vaccItemsDic = vaccTable.map { (Item) -> [String: Any] in

        return ["title": Item.title , "date": Item.date, "done": Item.done]
           }

           UserDefaults.standard.set(vaccItemsDic, forKey: newPet)
        UserDefaults.standard.removeObject(forKey: originalPet)
       }
    
    func loadlist()
    {
        
        print("petName is \(originalPet)")
        if let userVaccList = UserDefaults.standard.array(forKey: originalPet) as? [[String:Any]]
        {
            vaccTable = []
            for (index,item) in userVaccList.enumerated()
            {
                let title = userVaccList[index]["title"] as! String
                let date = userVaccList[index]["date"] as! Date
                let done = userVaccList[index]["done"] as! Bool
                
                vaccTable.append(vaccReminder(title: title, date: date, done: done))
            }
            //print("vacc陣列儲存到\(NSHomeDirectory())")
            //print(vaccTable)
        }
        else
        {
           //do nothing
        }
    }
    
}
