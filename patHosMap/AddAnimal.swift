//
//  AddAnimal.swift
//  patHosMap
//
//  Created by anna on 2020/7/20.
//  Copyright © 2020 陳逸煌. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
class AddAnimal: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIPickerViewDelegate {
    
    weak var VaccTVC:VaccTVC!
    var currentObjectBottomPosition:CGFloat = 0
    var root:DatabaseReference!
    var vc:UIImagePickerController!
    var petCount:Int!
    var userID:Int!
    var storage:Storage!
    var currentObjectBottomYPosition:CGFloat = 0
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtBirthday: UITextField!
    let Picker = UIDatePicker()
    @IBOutlet weak var imgPicture: UIImageView!
    
    var kind = 0
    @IBOutlet weak var btnCat: UIButton!
    @IBOutlet weak var btnDog: UIButton!
    //MARK: - target action
    @IBAction func btndog(_ sender: UIButton) {
        DispatchQueue.main.async {
            sender.imageView?.image = UIImage(named: "fullcircle")
            self.btnCat.imageView?.image = UIImage(named: "circle")
        }
        kind = 1
    }
    @IBAction func btncat(_ sender: UIButton) {
        DispatchQueue.main.async {
            sender.imageView?.image = UIImage(named: "fullcircle")
            self.btnDog.imageView?.image = UIImage(named: "circle")
        }
        kind = 2
    }
    @IBAction func btnInsert(_ sender: UIButton) {
        if txtName.text!.isEmpty || kind == 0 || txtBirthday.text!.isEmpty || imgPicture.image == nil{
            let alert = UIAlertController(title: "資料輸入錯誤", message: "任何一個欄位都不可空白", preferredStyle: .alert)
            let btnOK = UIAlertAction(title: "確定", style: .default, handler: nil)
            alert.addAction(btnOK)
            self.present(alert, animated: true, completion: nil)
            return
        }

        let little_data_center:UserDefaults
        little_data_center = UserDefaults.init()
        let userID = little_data_center.integer(forKey: "userID") - 1
        print("增加寵物的使用者\(userID)")
        let petcount = "\(petCount!)"
        print("此使用者的第幾隻寵物\(petcount)")
        let dataAddanimal = root.child("mypet").child("\(userID)").child("\(petcount)")
        let newData = ["name":"\(self.txtName.text!)","birthday":"\(self.txtBirthday.text!)","kind":"\(self.kind)","picture":"user\(self.userID!)pet\(self.petCount!).jpeg",]
        dataAddanimal.setValue(newData)
        //處理上傳
        let picRef =  storage.reference().child("data/picture/user\(self.userID!)pet\(self.petCount!).jpeg")
        let jData = self.imgPicture.image!.jpegData(compressionQuality: 0.5)
        print("圖片資訊\(jData?.description ?? "沒有圖片資訊")")
        picRef.putData(jData!)
        //訊息視窗
        let alert = UIAlertController(title: "通知", message: "已新增寵物", preferredStyle: .alert)
        let btnOK = UIAlertAction(title: "確定", style: .default) { (ok) in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(btnOK)
        self.present(alert, animated: true, completion: nil)//顯示訊息視窗
    }
    //MARK: - UIImagePickerControllerDelegate
    @IBAction func btnCamera(_ sender: UIButton) {
        vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.cameraDevice = .rear
        vc.delegate = self
        self.present(vc, animated: true, completion: {})
    }
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage{
            //將拍照結果顯示在拍照位置
            imgPicture.image = image
            //由picker退掉相機畫面
            picker.dismiss(animated: true, completion: nil)
        }
    }
    //MARK: - 生命循環
    override func viewDidLoad() {
        super.viewDidLoad()
        txtName.clearButtonMode = .always
        txtName.clearButtonMode = .whileEditing
        txtBirthday.clearButtonMode = .always
        txtBirthday.clearButtonMode = .whileEditing
        creatDatePicker()
        root = Database.database().reference()
        storage = Storage.storage()
        let little_data_center:UserDefaults
        little_data_center = UserDefaults.init()
        self.userID = little_data_center.integer(forKey: "userID") - 1
        self.navigationItem.title = "新增寵物"
    }
    //MARK: - keyboard
    //日期鍵盤
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
    @objc func keyboardWillShow(_ sender:Notification){
        print("鍵盤彈出")
//        print("通知資訊\(sender.userInfo!)")
        if let keyBoardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height{
//            print("鍵盤高度\(keyBoardHeight)")
            //計算扣除鍵盤後的可視高度
            let visibleHeight = self.view.bounds.size.height - keyBoardHeight
//            print("可視高度\(visibleHeight)")
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
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //編輯用鍵盤使用結束後收起
        self.view.endEditing(true)
    }
    @IBAction func didEndOnExit(_ sender: UITextField)
    {

    }


}
