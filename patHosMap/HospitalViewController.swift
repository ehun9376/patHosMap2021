import UIKit
import CoreLocation
class HospitalViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var table: UITableView!
    @IBOutlet var citys: [UIButton]!
    @IBOutlet weak var city: UILabel!
    var locationManager = CLLocationManager()
    var cityHosArray:[[String:String]] = [[:]]
    var hospitalsArray:[[String:String]] = [[:]]
    //各家經緯度
    var latitude:CLLocationDegrees!
    var longtude:CLLocationDegrees!
    //紀錄使用者位置
    var userlatitube:CLLocationDegrees!
    var userlongitube:CLLocationDegrees!
    //MARK: - target action
    @IBAction func changeCity(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5) {
            for city in self.citys{
                city.isHidden = !city.isHidden
                self.view.layoutIfNeeded()
            }
        }
    }
    @IBAction func choicedCity(_ sender: UIButton) {
        self.city.text = sender.titleLabel?.text
        UIView.animate(withDuration: 0.5) {
            for city in self.citys{
                city.isHidden = !city.isHidden
                self.view.layoutIfNeeded()
            }
        }
        self.cityHosArray = [[:]]
        if self.hospitalsArray != [[:]]{
            for hospital in self.hospitalsArray{
                if hospital["country"]! == sender.titleLabel!.text{
                    self.cityHosArray.append(hospital)
                }
            }
            self.cityHosArray = self.cityHosArray.filter({ array in
                array != [:]
            })
            self.table.dataSource = self
            self.table.delegate = self
            self.table.reloadData()
        }
        else{
            DispatchQueue.main.async{
                let alert = UIAlertController(title: "警告", message: "資料下載未完成，請稍待幾秒鐘再試一次", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in}
                alert.addAction(button)
                self.present(alert, animated: true, completion: {})
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.download2()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()  //開始update user位置
        self.table.rowHeight = 70
    }
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityHosArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "listCell")
        if indexPath.row <= self.cityHosArray.count{
            cell.textLabel?.text = self.cityHosArray[indexPath.row]["name"]
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.widthAnchor.constraint(equalToConstant: 711).isActive = true
            if self.cityHosArray[indexPath.row]["latitude"] == "1" {
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(self.cityHosArray[indexPath.row]["address"]!)
                { [self]
                    (arrPlaceMarks, error)
                    in
                    if let err = error
                    {
                        print("轉碼錯誤\(err)")
                    }
                    else
                    {
                        print("新請求geo")
                        let placemarks = arrPlaceMarks
                        let location = placemarks?.first?.location!
                        
                        self.latitude = location!.coordinate.latitude
                        self.longtude = location!.coordinate.longitude
                        self.updateGeo(hosName: self.cityHosArray[indexPath.row]["name"]!,latitude: self.latitude,longtude: self.longtude)
                        //計算距離
                        let firsLocation = CLLocation(latitude:self.latitude, longitude:self.longtude)
                        if self.userlatitube != nil && self.longtude != nil{
                            let secondLocation = CLLocation(latitude: self.userlatitube, longitude: self.userlongitube)
                            let distance = firsLocation.distance(from: secondLocation) / 1000
                            cell.detailTextLabel?.text = " \(String(format:"%.01f", distance)) 公里 "
                        }
                        else{
                            
                        }
                    }
                }
            }
            else{
                //有取得到地址編碼
                print("資料庫有拿到")
                self.latitude = CLLocationDegrees.init(self.cityHosArray[indexPath.row]["latitude"]!)
                self.longtude = CLLocationDegrees.init(self.cityHosArray[indexPath.row]["longtude"]!)
                //計算距離
                let firsLocation = CLLocation(latitude:self.latitude, longitude:self.longtude)
                if self.userlatitube != nil && self.longtude != nil{
                    let secondLocation = CLLocation(latitude: self.userlatitube, longitude: self.userlongitube)
                    let distance = firsLocation.distance(from: secondLocation) / 1000
                    cell.detailTextLabel?.text = " \(String(format:"%.01f", distance)) 公里 "
                }
                else{

                }
            }
            cell.detailTextLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        }
        //表格背景顏色
        cell.backgroundColor = UIColor(red: 247/255, green: 255/255, blue: 247/255, alpha: 0.8)
        //表格點擊顏色
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(displayP3Red: 255/255, green: 230/255, blue: 109/255, alpha: 0.5)
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let HosDetailVC = self.storyboard?.instantiateViewController(identifier: "HosDetailVC") as! HosDetailViewController
        HosDetailVC.strtel = self.cityHosArray[indexPath.row]["number"]!
        HosDetailVC.straddr = self.cityHosArray[indexPath.row]["address"]!
        HosDetailVC.strname = self.cityHosArray[indexPath.row]["name"]!
        self.show(HosDetailVC, sender: nil)
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
     {
         guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
         print("locations = \(locValue.latitude) \(locValue.longitude)")
         userlatitube = locValue.latitude
         userlongitube = locValue.longitude
     }
    
    func download2() -> Void {
        let session:URLSession = URLSession(configuration: .default)
        let task:URLSessionDataTask = session.dataTask(with: URL(string:"http://127.0.0.1/202108/select.php")!){
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
                    print(self.hospitalsArray)
                }catch{
                    print("伺服器出錯\(error)")
                }
            }
        }
        task.resume()
    }
    func updateGeo(hosName:String,latitude:Double,longtude:Double){
        print(hosName,latitude,longtude)
        let session = URLSession(configuration: .default)
        let str = String(format: "http://yi-huang.tw/updateGeo.php?hosName=%@&latitude=%f&longtude=%f", hosName,latitude,longtude).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        print(str!)
        let url = URL(string: str!)!
        print(url)
        let task = session.dataTask(with: url)
        {data,reponse,err in
            if let error = err{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                    let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
                    alert.addAction(button)
                    self.present(alert, animated: true, completion: {})
                }

            }
            else{
                print("新資料\(hosName),\(latitude),\(longtude)上傳成功")
            }
        }
        task.resume()
    }
}
