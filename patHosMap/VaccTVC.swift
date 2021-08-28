import UIKit
class VaccTVC: UITableViewController {
    let userDefault = UserDefaults()
    var userAccount:String?
    var petDatas:[[String:String]]?
    //MARK: - 生命循環
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("VACCTVCviewDidAppear")
        userAccount = userDefault.string(forKey: "account")
        getPet()
        self.tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("VACCTVCviewWillAppear")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //抬頭及在左右兩側增加編輯與新增
        print("VaccTVCDidLoad")
        self.navigationItem.title = "我的寵物"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(buttonEditAction))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "新增", style: .plain, target: self, action: #selector(buttonAddAction))
        tableView.rowHeight = 110
        userAccount = userDefault.string(forKey: "account")
        getPet()
        self.tableView.reloadData()
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
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //todo：取得rows長度
        if petDatas == nil{
            return 0
        }
        else{
            print("有幾個tablerows\(petDatas!.count)")
            return petDatas!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell
        cell.lblName.text = self.petDatas![indexPath.row]["petName"]
        cell.imgPicture.image = UIImage(named: "DefaultPhoto")
        DispatchQueue.main.async {
            cell.imageView?.image = UIImage(contentsOfFile: "DefaultPhoto")
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
    let VaccS = self.storyboard?.instantiateViewController(identifier: "VaccSchedule") as! VaccSchedule
        VaccS.petName = self.petDatas![indexPath.row]["petName"]
        VaccS.petKind = self.petDatas![indexPath.row]["petKind"]
        VaccS.vaccDate = stringConvertDate(string: self.petDatas![indexPath.row]["petBirth"]!)
        self.show(VaccS, sender: nil)
        
    }
    //左滑修改及刪除
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?{
        //準備"修改"按鈕
        let actionMore = UIContextualAction(style: .normal, title: "修改") { (action, view, completionHanlder) in
            let DetailAnimalVC = self.storyboard?.instantiateViewController(identifier: "DetailAnimalViewController") as! DetailAnimalViewController
                self.show(DetailAnimalVC, sender: nil)
            DetailAnimalVC.petdata = self.petDatas![indexPath.row]
            print("修改按鈕被按下")
        }
        actionMore.backgroundColor = .blue
        //準備"刪除"按鈕
        let actionDelete = UIContextualAction(style: .normal, title: "刪除") { [self] (action, view, completionHanlder) in
            deletePet(petname: self.petDatas![indexPath.row]["petName"]!)
            self.petDatas?.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        actionDelete.backgroundColor = .systemPink
        //將兩個按鈕合併
        let config = UISwipeActionsConfiguration(actions: [actionDelete,actionMore])
        config.performsFirstActionWithFullSwipe = true
        //回傳按鈕組合
        return config
    }
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath){
        //todo:排序
    }
    
    //MARK: - func
    func stringConvertDate(string:String, dateFormat:String="MM/dd/yy") -> Date {
            let dateFormatter = DateFormatter.init()
            dateFormatter.dateFormat = "MM/dd/yy"
            let date = dateFormatter.date(from: string)
            return date!
    }
    func getPet(){
        print("使用者帳號\(self.userAccount!)")
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/getPet.php?account=%@",self.userAccount!))!){
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
                    self.petDatas = try (JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? [[String:String]])
                    print("使用者寵物\(self.petDatas!)")
                    
                        for i in 0..<self.petDatas!.count{
                            if self.petDatas![i]["petBirth"]?.contains("z") == true{
                                self.petDatas![i]["petBirth"] = self.petDatas![i]["petBirth"]!.replacingOccurrences(of: "z", with: "/")
                            }
                        }
                }catch{
                    print("伺服器出錯\(error)")
                }
                print("這個使用者的寵物資料在這\(self.petDatas!)")
            }
        }
        task.resume()
        self.tableView.reloadData()
    }
    func deletePet(petname:String){
        print(petname)
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/deletePet.php?account=%@&petName=%@",self.userAccount!,petname).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!){
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
