import UIKit
class LoginViewController: UIViewController {
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var busy: UIActivityIndicatorView!
    var ismember:String?
    let userDefault = UserDefaults()
    @IBAction func login(_ sender: UIButton) {
        busy.isHidden = false
        if self.account.text != "" && self.password.text != ""{
            self.download(account: self.account.text!, password: self.password.text!)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        busy.isHidden = true
        password.clearButtonMode = .always
        password.clearButtonMode = .whileEditing
        account.clearButtonMode = .always
        account.clearButtonMode = .whileEditing
        if self.userDefault.string(forKey: "account") != nil{
            self.account.text = self.userDefault.string(forKey: "account")
        }
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //編輯用鍵盤使用結束後收起
        self.view.endEditing(true)
    }
    @IBAction func didEndOnExit(_ sender: UITextField){
        //只需對應，即可按下Return鍵收起鍵盤！
    }
    func download(account:String,password:String){
        let session:URLSession = URLSession(configuration: .default)
        let task:URLSessionDataTask = session.dataTask(with: URL(string:String(format: "http://yi-huang.tw/login.php?account=%@&password=%@", account,password))!){ [self]
                (data,reponse,err)
                in
                if let error = err{
                    DispatchQueue.main.async
                    {
                        let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                        let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                        alert.addAction(button)
                        self.present(alert, animated: true, completion: {})
                    }
                    
                }
                else{
                    DispatchQueue.main.sync
                    {
                        self.ismember = String(data: data!, encoding:.utf8)!
                        self.ismember = self.ismember?.filter({ Character in
                            Character != " "
                        })
                        print(self.ismember!)
                        judge()
                    }
                }
            }
            task.resume()
    }
    func judge(){
        print("判斷裡的\(self.ismember!)")
        if self.ismember == "lier"{
                let alert = UIAlertController(title: "警告", message: "帳號密碼錯誤", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
        }
        else if self.ismember == "passwordFalse" {
                let alert = UIAlertController(title: "警告", message: "密碼錯誤", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
        }
        else if  self.ismember == "ismember"{
            userDefault.setValue(self.account.text, forKey: "account")
            DispatchQueue.main.async {
                self.busy.isHidden = true
                let alert = UIAlertController(title: "通知", message: "登入成功", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                    self.performSegue(withIdentifier: "login", sender: nil)
                       self.busy.isHidden = true
                }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {   })
            }
        }
    }
}
