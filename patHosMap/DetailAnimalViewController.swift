import UIKit
class DetailAnimalViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var currentObjectBottomYPosition:CGFloat = 0
    weak var VaccTVC:VaccTVC!
    var petdata:[String:String]?
    var vaccTable = [vaccReminder]()
    let userDefault = UserDefaults()
    var userAccount:String?
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
        self.userAccount = userDefault.string(forKey:"account")
        self.navigationItem.title = "修改資料"
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
            updatePet()
            let alert = UIAlertController(title: "完成", message: "資料修改成功！", preferredStyle: .alert)
            let btnok = UIAlertAction(title: "確定", style: .default) { (ok) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(btnok)
            self.present(alert, animated: true, completion: {})
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
    func updatePet(){
        print("使用者帳號\(self.userAccount!)")
        let session:URLSession = URLSession(configuration: .default)
        let tempBirth = self.txtBirthday.text?.replacingOccurrences(of: "/", with: "z")
        print("修改過後的字\(tempBirth!)")
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/updatePet.php?account=%@&petName=%@&petKind=%@&petBirth=%@",self.userAccount!,self.txtName.text!,"1",tempBirth!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!){
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
            }
        }
        task.resume()
    }

    
}
