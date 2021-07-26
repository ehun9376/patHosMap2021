import UIKit
import FirebaseDatabase
class RegisterViewController: UIViewController {
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    var root:DatabaseReference!
    
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func register(_ sender: UIButton) {
        var count = 0
        var is_manager = false
        let user = root.child("user")
        let account1 = self.account.text
        user.observeSingleEvent(of: .value) { (data) in
            let manager_array = data.value! as! [[String:String]]
            for manager in manager_array{
                count += 1
                if manager["account"] == account1{
                    is_manager = true
                    let alert = UIAlertController(title: "警告", message: "帳號已存在", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                        self.performSegue(withIdentifier: "toLoginVC", sender: nil)
                    }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                    break
                }
            }
            if !is_manager{
                if self.account.text != "" && self.password.text != ""{
                    print("推送\(count),創建帳號")
                    let newUser = self.root.child("user").child("\(count)")
                    let newData = ["account":"\(self.account.text!)","password":"\(self.password.text!)","favorite":""]
                    
                    let newpet = self.root.child("mypet").child("\(count+1)")
                    let petdefault=[["birthday":"","kind":"","name":""]]
                    newpet.setValue(petdefault)
                    newUser.setValue(newData)
                    let alert = UIAlertController(title: "通知", message: "帳號已創建", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in
                        self.performSegue(withIdentifier: "toLoginVC", sender: nil)
                    }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }
                else{
                    let alert = UIAlertController(title: "警告", message: "帳號或密碼不得為空", preferredStyle: .alert)
                    let button = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default) { (button) in
                    }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }

            }
        }
    
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    root = Database.database().reference()
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
}
