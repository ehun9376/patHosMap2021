import UIKit

class MyCell: UITableViewCell
{
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imgPicture: UIImageView!
    
    //當儲存格參考storyboard的畫面配置被初始化成功時
    override func awakeFromNib()
    {
        super.awakeFromNib()
        //<方法二>取大頭照圓角
        imgPicture.clipsToBounds = true
        imgPicture.contentMode = .scaleAspectFill
        imgPicture.layer.cornerRadius = imgPicture.bounds.size.width / 2
        //儲存格背景色以系統色調配（可適應深色模式dark mode）
        self.backgroundColor = UIColor.systemFill
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
