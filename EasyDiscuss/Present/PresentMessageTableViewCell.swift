//
//  TestTableViewCell.swift
//  
//
//  Created by 陳懿宏 on 2020/12/3.
//

import UIKit

class PresentMessageTableViewCell: UITableViewCell {


    @IBOutlet weak var editBtnOutlet: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var thembnailImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var responseLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
    
    
}
