import UIKit
class advc:UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-1884396062657178/8397059995"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
}
