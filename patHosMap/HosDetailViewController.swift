import UIKit
import MapKit
import CoreLocation
class HosDetailViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var strtel = ""
    var straddr = ""
    var strname = ""
    var userAccount:String?
    var userFavoriteName:String?
    var userFavoriteNameArray:[String]?
    var isFavorite = false
    let userDefault = UserDefaults()
    @IBOutlet weak var hosName: UILabel!
    //@IBOutlet weak var hosTelephone: UILabel!
    @IBOutlet weak var buttonPhone: UIButton!
    @IBOutlet weak var hosAddress: UILabel!
    @IBOutlet weak var buttonFavorite: UIButton!
    @IBOutlet weak var labelDistance: UILabel!
    @IBOutlet weak var background: UIImageView!
    //MARK: - Map相關
    @IBOutlet weak var mapView: MKMapView!
    let annomation = MKPointAnnotation()
    fileprivate let application = UIApplication.shared
    var latitude:CLLocationDegrees!
    var longitude:CLLocationDegrees!
    //locationManager，用於偵測用戶位置變化
    var locationManager = CLLocationManager()
    //MARK: - 紀錄使用者位置
    var userlatitube:CLLocationDegrees!
    var userlongitube:CLLocationDegrees!
    var stringWithLink:String!
    //MARK: - target action
    @IBAction func btnAddToFavorite(_ sender: UIButton) {
        if isFavorite == true{
            //如果已經是最愛，就取消最愛
            isFavorite = false
            DispatchQueue.main.async {
                self.buttonFavorite.imageView?.image = UIImage(named: "favorite")
            }
            if self.userFavoriteNameArray?.contains(self.strname) == true{
                self.userFavoriteNameArray = self.userFavoriteNameArray?.filter({ name in
                    name != self.strname
                })
            }
            updateFavorite()
        }
        else{
            //如果不是最愛，就加入最愛
            isFavorite = true
            DispatchQueue.main.async {
                self.buttonFavorite.imageView?.image = UIImage(named: "favorite2")
            }
            if self.userFavoriteNameArray?.contains(self.strname) == false{
                self.userFavoriteNameArray?.append(self.strname)
            }
            updateFavorite()
            
        }
    }
    @IBAction func buttonPhone(_ sender: UIButton)
    {
        if let phoneURL = URL(string: "tel://\(strtel)")
        {
            if application.canOpenURL(phoneURL)
            {
                application.open(phoneURL, options: [:], completionHandler: nil)
            }
            else
            {
                //alert
            }
        }
    }
    
    @IBAction func buttonShare(_ sender: Any)
    {
        let activityController = UIActivityViewController(activityItems: [stringWithLink!], applicationActivities: nil)
        
         self.present(activityController, animated: true) {
             print("presented")
         }
    }
    @IBAction func buttonOpenMap(_ sender: UIButton)
    {
        if self.latitude != nil && self.longitude != nil{
            let mapURL = URL(string: "http://maps.apple.com/?daddr=\(latitude!),\(longitude!)")
            print(latitude!, longitude!)
            if (UIApplication.shared.canOpenURL(mapURL!)){
                UIApplication.shared.open(mapURL!, options: [:], completionHandler: nil)
            }
            else {
            }
        }else{
            let alert = UIAlertController(title: "警告", message: "轉碼錯誤", preferredStyle: .alert)
            let button = UIAlertAction(title: "請稍後再試", style: UIAlertAction.Style.default) { (button) in }
            alert.addAction(button)
            self.present(alert, animated: true, completion: {})
        }
    }
    //MARK: - 生命循環
    override func viewDidLoad() {
        super.viewDidLoad()
        background.layer.cornerRadius = 25
        hosName.adjustsFontSizeToFitWidth = true
        self.buttonPhone.setTitle(strtel, for: .normal)
        self.hosAddress.text = straddr
        self.hosName.text = strname
        self.userAccount = self.userDefault.string(forKey: "account")
        getFavorite()
        stringWithLink = "http://maps.apple.com/?daddr=\(hosAddress.text!)"
        getDestination()
        locationManager.delegate = self  //委派給ViewController
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //設定為最佳精度
        locationManager.requestWhenInUseAuthorization()  //user授權
        locationManager.startUpdatingLocation()  //開始update user位置
        mapView.delegate = self  //委派給ViewController
        mapView.showsUserLocation = true   //顯示user位置
        mapView.userTrackingMode = .follow  //隨著user移動
        //連結資料庫取得登入本APP的使用者的資訊
    }
    //MARK: - 地圖連結
    func getDestination()
    {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(hosAddress.text!) { (placemarks, error) in
            if let err = error
            {
                print("轉碼錯誤\(err)")
            }
            else
            {
                let placemarks = placemarks
                let location = placemarks?.first?.location!
                //print(location.coordinate.latitude, location.coordinate.longitude)
                self.latitude = location!.coordinate.latitude
                self.longitude = location!.coordinate.longitude
//                print("latitude:\(self.latitude!),longitude:\(self.longitude!)")
                
                
                //annomation.coordinate = CLLocationCoordinate2DMake(24.916062, 121.210480)
                self.annomation.coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude)
                self.annomation.title = self.hosName.text
                //self.annomation.subtitle = self.hosAddress
                self.mapView.addAnnotation(self.annomation)
                
                let region = MKCoordinateRegion(center: self.annomation.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
                
                self.mapView.setRegion(region, animated: true)
                
                //計算距離
                if self.latitude != nil && self.longitude != nil && self.userlatitube != nil && self.userlongitube != nil{
                    let firsLocation = CLLocation(latitude:self.latitude, longitude:self.longitude)
                    let secondLocation = CLLocation(latitude: self.userlatitube, longitude: self.userlongitube)
                    let distance = firsLocation.distance(from: secondLocation) / 1000
                    //顯示於label上
                    self.labelDistance.text = "\(String(format:"%.01f", distance)) 公里"
                }else{
                    self.labelDistance.text = ""
                }
            }
        }
    }
    func getFavorite(){
        print("使用者帳號\(self.userAccount!)")
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/getFavorite.php?account=%@",userAccount!))!){ [self]
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
                self.userFavoriteName = String(data: data!, encoding:.utf8)!
                self.userFavoriteName = self.userFavoriteName?.filter({ Character in
                    Character != " "
                })
                print("使用者最愛在這未處理\(self.userFavoriteName!)")
                self.userFavoriteNameArray = self.userFavoriteName!.components(separatedBy: ",")
                print("使用者最愛陣列\(self.userFavoriteNameArray!)")
                print(self.strname)
                if self.userFavoriteNameArray?.contains(self.strname) == true{
                    DispatchQueue.main.async {
                        print("按鈕圖片變動")
                        self.isFavorite = true
                        buttonFavorite.imageView?.image = UIImage(named: "favorite2")
                    }
                    
                }
                
            }
        }
        task.resume()
    }
    func updateFavorite(){
        print("使用者帳號\(self.userAccount!)")
        let tempData:String? = self.userFavoriteNameArray?.joined(separator: ",")
        let session:URLSession = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: String(format: "http://yi-huang.tw/updateFavorite.php?account=%@&favorite=%@",userAccount!,tempData!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!){ [self]
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
                print("最愛已更動\(self.userFavoriteNameArray!)")
            }
        }
        task.resume()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        userlatitube = locValue.latitude
        userlongitube = locValue.longitude
    }
}
