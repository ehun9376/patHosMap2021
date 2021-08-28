import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    var accountJudge:String?
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func register(_ sender: UIButton) {
        if self.account.text != nil && self.password.text != nil{
            regis(account: self.account.text!, password: self.password.text!)
        }
        else{
            let alert = UIAlertController(title: "警告", message: "帳號或密碼不得為空", preferredStyle: .alert)
            let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
            }
            alert.addAction(button)
            self.present(alert, animated: true, completion: {})
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        password.clearButtonMode = .always
        password.clearButtonMode = .whileEditing
        account.clearButtonMode = .always
        account.clearButtonMode = .whileEditing
        // Do any additional setup after loading the view.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //編輯用鍵盤使用結束後收起
        self.view.endEditing(true)
    }
    @IBAction func didEndOnExit(_ sender: UITextField)
    {
        //只需對應，即可按下Return鍵收起鍵盤！
    }
    func regis(account:String,password:String){
        let session:URLSession = URLSession(configuration: .default)
        //todo網址改成遠端
        let task:URLSessionDataTask = session.dataTask(with: URL(string:String(format: "http://yi-huang.tw/regis.php?account=%@&password=%@", account,password))!){ [self]
                (data,reponse,err)
                in
                if let error = err{
                    let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }
                else{
                    self.accountJudge = String(data: data!, encoding:.utf8)!.filter({ Character in
                        Character != " "
                    })
                    print(self.accountJudge!)
                    judge()
                }
            }
            task.resume()
    }
    func judge(){
        if self.accountJudge == "exist"{
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "警告", message: "帳號已存在", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
            }

        }
        else{
            print("新增帳號")
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "通知", message: "新增帳號", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                    self.dismiss(animated: true)
                }
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
            }

        }
    }
}
