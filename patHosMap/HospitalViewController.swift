import UIKit
import CoreLocation
class HospitalViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var table: UITableView!
    @IBOutlet var citys: [UIButton]!
    @IBOutlet weak var city: UILabel!
    var locationManager = CLLocationManager()
    var cityHosArray:[[String:String]] = [[:]]
    var hospitalsArray:[[String:String]] = [[:]]
    var hosNameArray:[String] = []
    var hosTelArray:[String] = []
    var hosAddrArray:[String] = []
    //各家經緯度
    var latitude:CLLocationDegrees!
    var longitude:CLLocationDegrees!
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
        self.hosNameArray = []
        self.hosTelArray = []
        self.hosAddrArray = []
        if self.hospitalsArray != [[:]]{
            for hospital in self.hospitalsArray{
                if hospital["縣市"]! == sender.titleLabel!.text{
                    self.cityHosArray.append(hospital)
                    self.hosNameArray.append(hospital["機構名稱"]!)
                    self.hosTelArray.append(hospital["機構電話"]!)
                    self.hosAddrArray.append(hospital["機構地址"]!)
                }
                self.hospitalsArray[0]["距離"] = "20"
                 //print("\(self.hospitalsArray[0])")
                 for i in 0..<self.hospitalsArray.count{
                    self.hospitalsArray[i]["距離"] = "20"
                 }
            }
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
        self.download()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()  //開始update user位置
        self.table.rowHeight = 70
    }
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hosNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "listCell")
        if indexPath.row <= self.hosNameArray.count{
            cell.textLabel?.text = hosNameArray[indexPath.row]
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(hosAddrArray[indexPath.row])
            {
                (arrPlaceMarks, error)
                in
                if let err = error
                {
                    print("轉碼錯誤\(err)")
                }
                else
                {
                    let placemarks = arrPlaceMarks
                    let location = placemarks?.first?.location!
                    self.latitude = location!.coordinate.latitude
                    self.longitude = location!.coordinate.longitude
                    
                    //計算距離
                    let firsLocation = CLLocation(latitude:self.latitude, longitude:self.longitude)
                    if self.userlatitube != nil && self.longitude != nil{
                        let secondLocation = CLLocation(latitude: self.userlatitube, longitude: self.userlongitube)
                        let distance = firsLocation.distance(from: secondLocation) / 1000
                        cell.detailTextLabel?.text = " \(String(format:"%.01f", distance)) 公里 "
                    }
                    else{
                        
                    }
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
        HosDetailVC.strtel = self.hosTelArray[indexPath.row]
        HosDetailVC.straddr = self.hosAddrArray[indexPath.row]
        HosDetailVC.strname = self.hosNameArray[indexPath.row]
        self.show(HosDetailVC, sender: nil)
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
     {
         guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
         print("locations = \(locValue.latitude) \(locValue.longitude)")
         userlatitube = locValue.latitude
         userlongitube = locValue.longitude
     }
    
    func download() -> Void {
        let session:URLSession = URLSession(configuration: .default)
        let task:URLSessionDataTask = session.dataTask(with: URL(string:"https://data.coa.gov.tw/Service/OpenData/DataFileService.aspx?UnitId=078&$top=1000&$skip=0")!){
            (data,reponse,err)
            in
            if let error = err{
                let alert = UIAlertController(title: "警告", message: "連線出現問題！\n\(error.localizedDescription)", preferredStyle: .alert)
                let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (button) in }
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
}
